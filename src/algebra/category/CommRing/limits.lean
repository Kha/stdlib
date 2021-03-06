/-
Copyright (c) 2019 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import algebra.category.CommRing.basic
import category_theory.limits.types
import category_theory.limits.preserves
import ring_theory.subring
import algebra.pi_instances

/-!
# The category of commutative rings has all limits

Further, these limits are preserves by the forgetful functor --- that is,
the underlying types are just the limits in the category of types.

## Further work
A lot of this should be generalised / automated, as it's quite common for concrete
categories that the forgetful functor preserves limits.
-/

open category_theory
open category_theory.limits

universe u

namespace CommRing

variables {J : Type u} [small_category J]

instance comm_ring_obj (F : J ⥤ CommRing.{u}) (j) :
  comm_ring ((F ⋙ forget CommRing).obj j) :=
by { dsimp, apply_instance }

instance sections_submonoid (F : J ⥤ CommRing.{u}) :
  is_submonoid (F ⋙ forget CommRing).sections :=
{ one_mem := λ j j' f,
  begin
    erw [functor.comp_map, forget_map_eq_coe, (F.map f).map_one],
    refl
  end,
  mul_mem := λ a b ah bh j j' f,
  begin
    erw [functor.comp_map, forget_map_eq_coe, (F.map f).map_mul],
    dsimp [functor.sections] at ah,
    rw ah f,
    dsimp [functor.sections] at bh,
    rw bh f,
    refl,
  end }

instance sections_add_submonoid (F : J ⥤ CommRing.{u}) :
  is_add_submonoid (F ⋙ forget CommRing).sections :=
{ zero_mem := λ j j' f,
  begin
    erw [functor.comp_map, forget_map_eq_coe, (F.map f).map_zero],
    refl,
  end,
  add_mem := λ a b ah bh j j' f,
  begin
    erw [functor.comp_map, forget_map_eq_coe, (F.map f).map_add],
    dsimp [functor.sections] at ah,
    rw ah f,
    dsimp [functor.sections] at bh,
    rw bh f,
    refl,
  end }

instance sections_add_subgroup (F : J ⥤ CommRing.{u}) :
  is_add_subgroup (F ⋙ forget CommRing).sections :=
{ neg_mem := λ a ah j j' f,
  begin
    erw [functor.comp_map, forget_map_eq_coe, (F.map f).map_neg],
    dsimp [functor.sections] at ah,
    rw ah f,
    refl,
  end,
  ..(CommRing.sections_add_submonoid F) }

instance sections_subring (F : J ⥤ CommRing.{u}) :
  is_subring (F ⋙ forget CommRing).sections :=
{ ..(CommRing.sections_submonoid F),
  ..(CommRing.sections_add_subgroup F) }

instance limit_comm_ring (F : J ⥤ CommRing.{u}) :
  comm_ring (limit (F ⋙ forget CommRing)) :=
@subtype.comm_ring ((Π (j : J), (F ⋙ forget _).obj j)) (by apply_instance) _
  (by convert (CommRing.sections_subring F))

instance limit_π_is_ring_hom (F : J ⥤ CommRing.{u}) (j) :
  is_ring_hom (limit.π (F ⋙ forget CommRing) j) :=
{ map_one := by { simp only [types.types_limit_π], refl },
  map_mul := λ x y, by { simp only [types.types_limit_π], refl },
  map_add := λ x y, by { simp only [types.types_limit_π], refl } }

-- The next two definitions are used in the construction of `has_limits CommRing`.
-- After that, the limits should be constructed using the generic limits API,
-- e.g. `limit F`, `limit.cone F`, and `limit.is_limit F`.

private def limit (F : J ⥤ CommRing.{u}) : cone F :=
{ X := ⟨limit (F ⋙ forget _), by apply_instance⟩,
  π :=
  { app := λ j, ring_hom.of $ limit.π (F ⋙ forget _) j,
    naturality' := λ j j' f,
      ring_hom.coe_inj ((limit.cone (F ⋙ forget _)).π.naturality f) } }

private def limit_is_limit (F : J ⥤ CommRing.{u}) : is_limit (limit F) :=
begin
  refine is_limit.of_faithful
    (forget CommRing) (limit.is_limit _)
    (λ s, ⟨_, _, _, _, _⟩) (λ s, rfl); dsimp,
  { apply subtype.eq, funext, dsimp,
    erw (s.π.app j).map_one, refl },
  { intros x y, apply subtype.eq, funext, dsimp,
    erw (s.π.app j).map_mul, refl },
  { apply subtype.eq, funext, dsimp,
    erw (s.π.app j).map_zero, refl },
  { intros x y, apply subtype.eq, funext, dsimp,
    erw (s.π.app j).map_add, refl }
end

/-- The category of commutative rings has all limits. -/
instance CommRing_has_limits : has_limits.{u} CommRing.{u} :=
{ has_limits_of_shape := λ J 𝒥,
  { has_limit := λ F, by exactI { cone := limit F, is_limit := limit_is_limit F } } }

/--
The forgetful functor from commutative rings to types preserves all limits. (That is, the underlying
types could have been computed instead as limits in the category of types.)
-/
instance forget_preserves_limits : preserves_limits (forget CommRing.{u}) :=
{ preserves_limits_of_shape := λ J 𝒥,
  { preserves_limit := λ F,
    by exactI preserves_limit_of_preserves_limit_cone
      (limit.is_limit F) (limit.is_limit (F ⋙ forget _)) } }

end CommRing
