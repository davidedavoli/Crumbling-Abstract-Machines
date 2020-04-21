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

let rec has_member l (e:Variable) on l :=
 match l with
 [ nil ⇒ false
 | cons h t ⇒ if (veqb e h) then true else (has_member t e)
 ]
 .
 
let rec rem_from_list l v on l ≝
 match l with
 [ nil ⇒ nil Variable
 | cons h t ⇒ if (veqb h v) then (rem_from_list t v) else (cons Variable h (rem_from_list t v))
 ]
 .
 
let rec rem_dup_var l on l ≝
 match l with
 [ nil ⇒ nil Variable
 | cons h t ⇒ cons Variable h (rem_from_list t h)
 ]
 .
 
 
let rec dom_list (e:Environment) on e ≝ 
 match e with
 [ Epsilon ⇒ []
 | Cons e s ⇒ if (has_member (dom_list e) (var_from_subst s)) then (dom_list e) else (cons Variable (var_from_subst s) (dom_list e))
 ]
 . 

let rec dom c ≝
 match c with
 [ CCrumble b e ⇒ dom_list e].
 
let rec l_subtr l1 l2 ≝
 match l1 with
 [ nil ⇒ nil Variable
 | cons h t ⇒ if (has_member l2 h) then t else cons Variable h (l_subtr t l2)
 ]
 .


let rec fv c ≝
 match c with
 [ CCrumble b e ⇒ rem_dup_var (append Variable (l_subtr (fv_byte b) (dom_list e)) (fv_env e))]

and

fv_env e ≝
 match e with
 [ Epsilon ⇒ nil Variable
 | Cons e s ⇒ match s with [subst x b ⇒ rem_dup_var (append Variable (rem_from_list (fv_env e) (x)) (fv_byte b))]
 ]
 
and

fv_val x ≝
 match x with
 [ var v ⇒ cons Variable v (nil Variable)
 | lambda v c ⇒ rem_from_list (fv c) v
 ]

and

fv_byte b ≝
 match b with
 [ CValue x ⇒ fv_val x
 | AppValue x y ⇒ rem_dup_var (append Variable (fv_val x) (fv_val y))
 ]
 .
 
let rec fresh_var e ≝
 match e with 
 [ Epsilon ⇒  O
 | Cons e' s ⇒  match s with [ subst v b ⇒ match v with [ variable n ⇒ max (S n) (fresh_var e')]]
 ]
 .

(*
let rec underline_pifTerm (t: pifTerm) :Crumble ≝
 match t with
 [ val_to_term v ⇒ 〈CValue (overline v), Epsilon〉
 | appl t1 t2 ⇒ match t2 with
                [ val_to_term v2 ⇒ match t1 with
                                   [ val_to_term v1 ⇒ 〈AppValue (overline v1) (overline v2), Epsilon 〉
                                   | appl u1 u2 ⇒ match underline_pifTerm t1 with [CCrumble b e ⇒ 〈AppValue (var ν(fresh_var e)) (overline v2), push e [ν(fresh_var e)←b]〉]
                                   ]
                | appl u1 u2 ⇒ match underline_pifTerm t2 with [ CCrumble b e ⇒ at (underline_pifTerm (appl t1 (val_to_term (pvar ν(fresh_var e))))) (push e [ν(fresh_var e)←b]) ]
                ]
 ]
*)

let rec underline_pifTerm (t: pifTerm):Crumble ≝
 match t with
 [ val_to_term v ⇒ CCrumble (CValue (overline v)) Epsilon
 | appl t1 t2 ⇒ match t2 with
                [ val_to_term v2 ⇒ match t1 with
                                   [ val_to_term v1 ⇒ 〈AppValue (overline v1) (overline v2), Epsilon〉
                                   | appl u1 u2 ⇒ match underline_pifTerm t1 with [ CCrumble b e ⇒ 〈AppValue (var ν(fresh_var e)) (overline v2), push e [(ν(fresh_var e)) ← b]〉]
                                   ]
                | appl u1 u2 ⇒ match underline_pifTerm t2 with [CCrumble b1 e1 ⇒ match t1 with
                                                                                     [ val_to_term v1 ⇒ at 〈AppValue (overline v1) (var ν(fresh_var e1)), Epsilon〉 (push e1 [ν(fresh_var e1)←b1])
                                                                                     | appl u1 u2 ⇒ match underline_pifTerm t1 with [CCrumble b e ⇒ 〈AppValue (var (ν(fresh_var e))) (var (ν(fresh_var e1))), concat (push e1 [ν(fresh_var e) ← b1]) (push e [ν(fresh_var e1) ← b])〉]
                                                                                     ]
                                                               ]
                ]
 ]
and
 
overline (x:pifValue): Value ≝
 match x with
 [ pvar v ⇒ var v
 | abstr v t ⇒ lambda (v) (underline_pifTerm t)
 ]
 .

let rec pif_subst t s ≝
 match t with
 [ val_to_term v ⇒ match v with [ pvar x ⇒ match s with [psubst v' t ⇒ match veqb v' x with [true ⇒ t | false ⇒ val_to_term v]]
                                | abstr x t1 ⇒ match s with [psubst v' t2 ⇒ match veqb v' x with [true ⇒ val_to_term v | false ⇒ val_to_term (abstr x (pif_subst t1 s))]]
                                ]
 | appl t' u ⇒  appl (pif_subst t' s) (pif_subst u s)
 ]
 .
(*
let rec c_size c on c ≝
 match c with
 [ CCrumble b e ⇒ c_size_b b + c_size_e e ]

and 

c_size_b b on b ≝
 match b with
 [ CValue v ⇒ c_size_v v
 | AppValue v w ⇒ c_size_v v + c_size_v w 
 ]

and

c_size_e e on e ≝
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒ S (c_size_e e) 
 ]
 
and

c_size_v v on v ≝
 match v with
 [ var x ⇒ O
 | lambda x c ⇒ c_size c
 ]
 .*)

let rec c_size c on c ≝
 match c with
 [ CCrumble b e ⇒ S (c_size_b b + c_size_e e) ]

and 

c_size_b b on b ≝
 match b with
 [ CValue v ⇒ c_size_v v
 | AppValue v w ⇒ S (c_size_v v + c_size_v w)  
 ]

and

c_size_e e on e ≝
 match e with
 [ Epsilon ⇒ O
 | Cons e s ⇒(c_size_e e) + c_size_s s
 ]
 
and

c_size_v v on v ≝
 match v with
 [ var x ⇒ S O
 | lambda x c ⇒ S (c_size c)
 ]
 
and

c_size_s s on s ≝
 match s with
 [ subst x b ⇒ S (c_size_b b)]
 .
 
let rec c_len_e e on e ≝ match e with [Epsilon ⇒ O | Cons e s ⇒ 1 + c_len_e e].
 
let rec c_len c on c ≝
 match c with
 [ CCrumble b e ⇒ c_len_e e].
 
let rec e_pop e on e ≝ 
 match e with
 [ Epsilon ⇒ e
 | Cons e s ⇒ e
 ]
 .

lemma env_len: ∀e: Environment. (e = Epsilon → False ) →  S (c_len_e (e_pop e))=(c_len_e e).
#e cases e [ normalize #Abs cut False [ cut (Epsilon=Epsilon) [ //| @Abs] | #Abs
@False_ind] @Abs | #e1 #s #H1 normalize //] qed.

lemma succ_eq: ∀n, m:nat. S n = S m → n = m.
#n #m #H destruct // qed.

lemma subtr_1: ∀a,b,c:nat. a+b-(a+c)=b-c.
#a #b #c elim a // qed.

(* Definizione 1: naïve, restituisce il clasico errore: *)
(* NTypeChecker failure: Recursive call (read_back_b b), b is not smaller.

let rec read_back x on x ≝ 
 match x with
 [ CCrumble b e ⇒ match e with
                  [ Epsilon ⇒ read_back_b b 
                  | Cons e1 s ⇒ match s with [ subst x' b1 ⇒ pif_subst (read_back 〈b, e1〉) (psubst x' (read_back_b b1))]
                  ]
 ]                
 
and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ val_to_term (abstr x (read_back c)) 
 ]
 .
*)

(* Definizione 2: come da lei consigliato, spezzo la read_back c in read_back b e *)
(* in modo che l'induzione su e mi assicuri la diminuzione della dimensione del termine*)
(* purtroppo però, la chiamata ricorsiva sul byte non mi assicura che la dimensione diminuisca*)
(* suppongo che questo sia dovuto al fatto che un byte può a sua volta contenere un  *)
(* crumble la cui dimensione è arbitraria *)


let rec aux_read_back rbb e on e ≝ 
 match e with
 [ Epsilon ⇒ rbb 
 | Cons e1 s ⇒ match s with [ subst x' b1 ⇒ pif_subst (aux_read_back rbb e1) (psubst x' (read_back_b b1))]
 ]                
 
and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ match c with 
                [ CCrumble b e ⇒ val_to_term (abstr x (aux_read_back (read_back_b b) e))]
 ]
 .
 
let rec read_back c on c ≝
 match c with
 [ CCrumble b e ⇒ aux_read_back (read_back_b b) e]
 .

(* Definizione 3: ragionevolmente giusta, ma dà il seguente errore: read_back_b b *)
(* is not smaller. Faccio fatica a capirne il motivo, perché il fatto che la *)
(* lunghezza degli environment dei crumble di livello più esterno diminuisca ad *) 
(* ogni chiamata, dovrebbe assicurare la terminazione, ma suppongo anche *)
(* che Matita si aspetti che le chiamate per induzione sulla dimensione di *)
(* un termine abbiano come taglia un intero sempre decrescente, cosa che, con *)
(* la definizione di taglia data da c_len non si verifica. L'errore, dunque, *)
(* dovrebbe somigliare a quello del punto precedente.
*)

(*
let rec read_back (n: nat) : Πc: Crumble. c_len c = n → pifTerm ≝
 match n return λn.Πc: Crumble. c_len c = n → pifTerm with
 [ O ⇒ λc. match c return λc.c_len c = O → pifTerm with 
          [ CCrumble b e ⇒ λp.(read_back_b b)]
 | S m ⇒ λc. match c return λc.c_len c = S m → pifTerm with
    [ CCrumble b e ⇒ match e with 
        [ Epsilon ⇒  λabs.(read_back_b b) 
        | Cons e1 s ⇒ λp.match s with [ subst x' b1 ⇒ pif_subst (read_back m 〈b, e_pop e〉 ?) (psubst x' (read_back_b b1))]
        ]
    ]
 ]      

and

read_back_b b ≝
 match b with
 [ CValue v ⇒ read_back_v v
 | AppValue v w ⇒ appl (read_back_v v) (read_back_v w)
 ]

and

read_back_v v ≝
 match v with
 [ var x ⇒ val_to_term (pvar x)
 | lambda x c ⇒ val_to_term (abstr x (read_back (c_len c) c (refl …))) 
 ]
 .

lapply p
normalize cases e normalize [ #H destruct | #e1 #s1 // ]
qed.
*)

(* Definizione 4: provo a definire una funzione size più accurata: la taglia *) 
(* di un crumble equivale alla lunghezza ti tutti gli environment in esso *)
(* annidati ney byte al primo membro. In questo modo dovrei riuscire ad evitare l'errore perché *)
(* la suddetta definizione mi garantirebbe la diminuzione della taglia del *) 
(* termine ad ogni chiamata ricorsiva. Ma quando vado a fornire la dimostrazione *)
(* mi si solleva un altro problema: come faccio ad esprimere il fatto che e = Cons e1 s ?
*)

(*
let rec read_back (n: nat) : Πc: Crumble. c_size c = n → pifTerm ≝
 match n return λn.Πc: Crumble. c_size c = n → pifTerm with
 [ O ⇒ λc.λabs. ?
 | S m ⇒ λc. match c return λc.c_size c = S m → pifTerm with
    [ CCrumble b e ⇒ match e return λe. c_size (CCrumble b e) = S m → pifTerm with 
        [ Epsilon ⇒  λp.(read_back_b (m) b (?))
        | Cons e1 s ⇒ match s return λs. c_size (CCrumble b (Cons e1 s)) = S m → pifTerm with [ subst x' b1 ⇒ λp. pif_subst (read_back ((S m) - (c_size_s [x'← b1])) 〈b, e1〉 ?) (psubst x' (read_back_b (m - c_size 〈b, e1〉) b1 ?))]
        ]
    ]
 ]
 

and

read_back_b (n: nat): Πb: Byte. c_size_b b = n → pifTerm ≝
 match n return λn.Πb: Byte. c_size_b b = n → pifTerm with
 [ O ⇒ λb. match b return λb. c_size_b b = O → pifTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λabs. ?
    ]
 | S m ⇒ λb. match b return λb. c_size_b b = S m → pifTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λp. appl (read_back_v (c_size_v v) v (refl …)) (read_back_v (c_size_v w) w (refl …))
    ]
 ]

and

read_back_v (n: nat): Πv: Value. c_size_v v = n → pifTerm≝
 match n return λn.Πv: Value. c_size_v v = n → pifTerm with
 [ O ⇒ λv. match v return λv. c_size_v v = O → pifTerm with
     [ var x ⇒ λp.val_to_term (pvar x)
     | lambda x c ⇒ λp.val_to_term (abstr x (read_back (c_size c) c (refl …))) 
     ]
 | S m ⇒ λv. match v return λv. c_size_v v = S m → pifTerm with
     [ var x ⇒ λp. val_to_term (pvar x)
     | lambda x c ⇒ λp. val_to_term (abstr x (read_back (c_size c) c (refl …))) 
     ]
 ]

 .
(*
[lapply p normalize cases (c_size_b b) [ normalize // | #n cases (c_size_e e1) [
#H // | #p #H cut (S ((S n)+(S p))=S m) [ // | @succ_eq] ] ]  qed.
*)
[ lapply abs cases c #b #e normalize cases (b) [ #v cases (v)[ #x normalize #abs
destruct | #x #d normalize #abs destruct] | #v #w normalize #abs destruct ] 
| lapply p normalize //
| normalize in p; destruct normalize cases (c_size_b b1)
 [ normalize // | #q normalize /2/]  
|  lapply p normalize #H destruct /2/
| normalize in abs; destruct] qed.
*)
(*
lemma value_lemma: ∀v: pifValue. read_back_v (overline v) = val_to_term v.
#v cases v
 [ #x normalize //
 | #x #t elim x #nx cases nx 
  [ normalize cases t [ normalize #v'   
*)

inductive list' (A: Type[0]) : nat → Type[0] ≝
   Nil' : list' A 0
 | Cons' : ∀n. A → list' A n → list' A (S n).

let rec list_ind' (A: Type[0]) (P : ∀m. list' A m → Prop)
(H1 : P 0 (Nil' A)) (H2: ∀m. ∀hd. ∀tl. P m tl → P (S m) (Cons' A m hd tl))
(n: nat) (l : list' A n) on l
: P n l
≝
 match l
 return λn.λl. P n l
 with
  [ Nil' ⇒ H1
  | Cons' m hd tl ⇒
     H2 m hd tl (list_ind' A P H1 H2 m tl)
  ].


inductive T1 (A: Type[0]) : nat → Type[0] ≝
  B : T1 A 0
| K : ∀n. T2 A n → T1 A (S n)

with T2 : nat → Type[0] ≝
  K2 : ∀n. T1 A n → T2 A n. 

let rec T1_ind (A: Type[0]) (P : ∀n. T1 A n → Prop) (Q: ∀n. T2 A n → Prop)
(H1: P 0 (B A))
(H2: ∀m. ∀y. Q m y → P (S m) (K A m y))
(H3: ∀n. ∀x. P n x → Q n (K2 A n x))
(n: nat) (x: T1 A n) on x : P n x
≝
 match x
 return λn.λx. P n x
 with
 [ B ⇒ H1
 | K m y ⇒ H2 m y (T2_ind A P Q H1 H2 H3 m y)
 ]

and T2_ind (A: Type[0]) (P : ∀n. T1 A n → Prop) (Q: ∀n. T2 A n → Prop)
(H1: P 0 (B A))
(H2: ∀m. ∀y. Q m y → P (S m) (K A m y))
(H3: ∀n. ∀x. P n x → Q n (K2 A n x))
 (n: nat) (y: T2 A n) on y: Q n y
≝ 
 match y
 return λn.λy. Q n y
 with
 [ K2 n x ⇒ H3 n x (T1_ind A P Q H1 H2 H3 n x)
 ].

(*
axiom pifTerm_ind: ∀P: pifTerm →  Prop. (∀v: pifValue. P (val_to_term v)) → (∀t1: pifTerm. ∀t2: pifTerm. ((P t1) → (P t2) → P (appl t1 t2))) → ∀t: pifTerm. P t.
*)
axiom pifValue_ind: ∀P: pifValue → Prop. ∀x: Variable. P (pvar x) → ∀v. P v.

theorem test: ∀n. S n = n → False. 
#n elim n [ #abs destruct | #x #H #Abs destruct @(H e0)] qed.

(*
lemma c4: ∀e: Environment. ∀x:Variable. ((has_member (dom_list e) x) = false)  → ((has_member (fv_env e) x) = false) → 
          ∀c: Crumble. ∀b: Byte. read_back (at c (push e [x←b]))= pif_subst (read_back (at c e)) (psubst x  (read_back 〈b, e〉)).

#e #x #H1 #H2 #c #b cases (c) #b' #e' cases e [ normalize cases e'[ normalize //
 | #e'' #s normalize cases s #b'' #x normalize
*)

lemma value_lemma: ∀v: pifValue. read_back_v (overline v) = val_to_term v.
#v elim v

lemma term_lemma: ∀t: pifTerm. read_back (underline_pifTerm t)  = t.
#t elim t
[ #v normalize cases v
 [ #x elim (x) #nx normalize // | #x #u cases (value_lemma (abstr x u)) //]
| #t1 #t2 #H1 #H2 cases t1 
 [ #v normalize