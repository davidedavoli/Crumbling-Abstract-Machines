(**************************************************************************)
(*       ___                                                              *)
(*      ||M||                                                             *)
(*      ||A||       A project by Andrea Asperti                           *)
(*      ||T||                                                             *)
(*      ||I||       Developers:                                           *)
(*      ||T||         The HELM team.                                      *)
(*      ||A||         http://helm.cs.unibo.it                             *)
(*      \   /                                                             *)
(*       \ /        This file is distributed under the terms of the       *)
(*        v         GNU General Public License Version 2                  *)
(*                                                                        *)
(**************************************************************************)

include "crumbles.ma".
include "variable finite set.ma".

notation "[ term 19 v ← term 19 b ]" non associative with precedence 90 for @{ 'substitution $v $b }.
interpretation "Substitution" 'substitution v b =(subst v b).

(*notation "〈 b break, e 〉" non associative with precedence 90 for @{ 'ccrumble $b $e }.
*)
interpretation "Crumble creation" 'pair b e =(CCrumble b e).

notation "𝛌 x . y" right associative with precedence 40 for @{ 'lambda $x $y}.
interpretation "Abstraction" 'lambda x y = (lambda x y ).

notation "ν x" non associative with precedence 90 for @{ 'variable $x}.
interpretation "Variable contruction" 'variable x = (variable x).

notation "hvbox(c @ e)" with precedence 35 for @{ 'at $c $e }.
interpretation "@ operation" 'at c e =(at c e).

definition var_from_subst ≝  λx:Substitution.
 match x with
 [ subst y z ⇒ y
 ]
.

let rec has_member l e on l :=
 match l with
 [ nil ⇒ false
 | cons h t ⇒ if (veqb e h) then true else (has_member t e)
 ]
 .
 
let rec dom_list (e:Environment) on e ≝ 
 match e with
 [ Epsilon ⇒ []
 | Cons e s ⇒ if (has_member (dom_list e) (var_from_subst s)) then (dom_list e) else (cons Variable (var_from_subst s) (dom_list e))
 ]
 .
 
let wrec rem_from_list l v on l ≝
 match l with
 [ nil ⇒ nil Variable
 | cons h t ⇒ if (veqb h v) then (rem_from_list t v) else (cons Variable h (rem_from_list t v))
 ]
 .

let rec fv_crumble c on c ≝
 match c with
 [ CCrumble b e ⇒ ]
 
let rec fv_val x on x ≝
 match x with
 [ var v ⇒ cons Variable var v nil
 | lambda v c ⇒ rem_from_list fv_crumble c v
 ]
 . 

let rec fv_byte b on b ≝
 match b with
 [ CValue x ⇒ fv_val x
 | AppValue x y ⇒ elim_dup_var (concat (fv_val x) (fv_val y))
 ]
 .