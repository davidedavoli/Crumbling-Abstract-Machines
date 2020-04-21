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

include "arithmetics/nat.ma".

inductive Variable: Type[0] ≝
 | variable: nat → Variable
.

(*record variable instead*)

inductive Crumble : Type[0] ≝
 | CCrumble: Byte → Environment → Crumble 
 
with Byte : Type[0] ≝
 | CValue: Value → Byte
 | AppValue: Value → Value → Byte

with Value : Type[0] ≝
 | var : Variable → Value
 | lambda: Variable → Crumble → Value
  
with Environment : Type[0] ≝
 | Epsilon: Environment
 | Cons: Environment → Substitution → Environment
 
with Substitution: Type[0] ≝
 | subst: Variable → Byte → Substitution
.

inductive pifTerm : Type[0] ≝
 | val_to_term: pifValue → pifTerm
 | appl: pifTerm → pifTerm → pifTerm
 
with pifValue : Type[0] ≝
 | pvar: Variable → pifValue
 | abstr: Variable → pifTerm → pifValue
 .
 
inductive pifSubst : Type[0] ≝
 | psubst: Variable → pifTerm → pifSubst
 .

notation "[ term 19 v ← term 19 b ]" non associative with precedence 90 for @{ 'substitution $v $b }.
interpretation "Substitution" 'substitution v b =(subst v b).

(*notation "〈 b break, e 〉" non associative with precedence 90 for @{ 'ccrumble $b $e }.
*)
interpretation "Crumble creation" 'pair b e =(CCrumble b e).

notation "𝛌 x . y" right associative with precedence 40 for @{ 'lambda $x $y}.
interpretation "Abstraction" 'lambda x y = (lambda x y ).

notation "ν x" non associative with precedence 90 for @{ 'variable $x}.
interpretation "Variable contruction" 'variable x = (variable x).

lemma test_lambda0: ∀x: Variable. ∀y:Crumble. (𝛌x.y) = (lambda x y).
#x #y normalize // qed.

let rec push e a ≝  
 match e with
 [ Epsilon ⇒ Cons Epsilon a
 | Cons e1 a1 ⇒ Cons (push e1 a) (a1)
 ].
 
let rec e_size e ≝ 
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒ S (e_size e)
 ]
. 
 
lemma push_test0: Cons (Cons Epsilon [ν0 ← CValue (var ν0)]) [ν1 ← CValue (var ν3)] = push ((Cons Epsilon [ν1 ← CValue (var ν3)])) ([ν0 ← CValue (var ν0)]).
normalize //. qed. 

let rec concat a b ≝ 
 match a with
 [ Epsilon ⇒ b
 | Cons e a' ⇒ match b with 
                      [ Epsilon ⇒ Cons e a'
                      | Cons e' b' ⇒ Cons (concat e (push e' a')) b'
                      ]
 ].

lemma concat_test0: concat (Cons (Cons Epsilon [ν0 ← CValue (var ν 0)]) [ν1 ← CValue (var \nu 3)]) (Cons (Cons Epsilon [ν2 ← CValue (var \nu 3)]) [ν1 ← CValue (var \nu 2)])=
(Cons (Cons (Cons (Cons Epsilon [ν0 ← CValue (var \nu 0)]) [ν1 ← CValue (var \nu 3)]) [ν2 ← CValue (var \nu 3)]) [ν1 ← CValue (var \nu 2)]).//. qed.

definition at: Crumble → Environment → Crumble ≝ λa,b.
match a with
[ CCrumble byte e  ⇒ CCrumble byte (concat e b) 
].

notation "hvbox(c @ e)" with precedence 35 for @{ 'at $c $e }.
interpretation "@ operation" 'at c e =(at c e).

definition v0: Value ≝ var ν0.
definition b0: Byte ≝ CValue v0.
definition e0: Environment ≝ Epsilon.
definition e1: Environment ≝ Cons e0 [ν0 ← b0].

definition v1: Value ≝ var \nu 1.
definition e2: Environment ≝ Cons e0 [ν1 ← b0].

definition c0: Crumble ≝ 〈 b0, e1 〉.
lemma test1:  e2 = e2. // qed.

lemma test2: c0 = CCrumble b0 e1. // qed.

lemma test3: (〈 b0, e1 〉 @ e2) = 〈 b0, concat e1 e2 〉.
// qed.