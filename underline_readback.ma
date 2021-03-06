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
include "basics/types.ma".
include "libnat.ma".
include "variables.ma".
include "utils.ma".
include "size.ma".
include "alternative_pif_subst.ma".
include "closed.ma".

let rec underline_pTerm (t: pTerm) (s: nat): Crumble × nat≝
 match t with
 [ val_to_term v ⇒ match overline v s with
   [ mk_Prod vv n ⇒  mk_Prod Crumble nat 〈(CValue vv), Epsilon 〉 n]
 | appl t1 t2 ⇒ match t2 with
   [ val_to_term v2 ⇒ match t1 with
     [ val_to_term v1 ⇒ match overline v1 s with
       [ mk_Prod vv n ⇒ match overline v2 n with
         [ mk_Prod ww m ⇒ mk_Prod Crumble nat 〈AppValue (vv) (ww), Epsilon〉 m ]
       ]
     | appl u1 u2 ⇒ match underline_pTerm t1 s with
       [ mk_Prod c n ⇒ match c with
         [ CCrumble b e ⇒ match overline v2 n with
           [ mk_Prod vv m ⇒ mk_Prod Crumble nat 〈AppValue (var ν(m)) (vv), push e [(ν(m)) ← b]〉 (S m)]
         ]
       ]
     ]
   | appl u1 u2 ⇒ match underline_pTerm t2 s with
     [ mk_Prod c n ⇒ match c with
       [ CCrumble b1 e1 ⇒ match t1 with
         [ val_to_term v1 ⇒ match overline v1 n with
           [ mk_Prod vv m ⇒  mk_Prod Crumble nat (at 〈AppValue (vv) (var (νm)), Epsilon〉 (push e1 [νm←b1])) (S m)]
         | appl u1 u2 ⇒ match underline_pTerm t1 n with
          [ mk_Prod c1 n1 ⇒ match c1 with
            [ CCrumble b e ⇒ mk_Prod Crumble nat 〈AppValue (var (ν(S(n1)))) (var (νn1)), concat (push e [ν(S(n1)) ← b]) (push e1 [νn1 ← b1])〉 (S (S (n1)))]
          ]
         ]
       ]
     ]
   ]
 ]

and

overline (x:pValue) (s: nat): Value × nat≝
 match x with
 [ pvar v ⇒ mk_Prod Value nat (var v) s
 | abstr v t ⇒ match underline_pTerm t s with
   [ mk_Prod c n ⇒ mk_Prod Value nat (lambda (v) (c)) n  ]
 ]
 .

lemma line_monotone_names:
 (∀t.∀s.  snd … (underline_pTerm t s) ≥ s) ∧
  (∀v.∀s. snd … (overline v s) ≥ s).

@pValueTerm_ind
[ #v #HI #s lapply (HI s) normalize cases (overline v s) //
| #t1 #t2 cases t2
  [ #v2 cases t1
    [ #v1 normalize #H1 #H2 #s lapply (H1 s) cases (overline v1 s) #vv #n
      normalize lapply (H2 n) cases (overline v2 n) #ww #m normalize
      #H2 #H1 @(transitive_le … H1 H2)
    | #u1 #u2 normalize #H1 #H2 #s lapply (H1 s)
      change with (underline_pTerm (appl u1 u2) ?)
        in match ( match u2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n normalize -H1 #H1
      lapply (H2 n) cases (overline v2 n) #ww #m normalize #H2 @le_S
      @(transitive_le … H1 H2)
    ]
    | #u1 #u2 #Hu1 #Hu2 #s lapply (Hu2 s) normalize
      change with (underline_pTerm (appl u1 u2) ?)
        in match ( match u2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl u1 u2) s) * #b1 #e1 #n -Hu2 #Hu2
      lapply Hu1 cases t1 normalize
      [ #v1 -Hu1 #Hu1 lapply (Hu1 n) cases (overline v1 n) #vv #m normalize #Hn
        @le_S @(transitive_le … Hu2 Hn)
      | #u1 #u2 #Hu2 lapply (Hu2 n)
        change with (underline_pTerm (appl u1 u2) n)
          in match ( match u2 in pTerm with [_⇒ ?]);
        cases (underline_pTerm (appl u1 u2) n) * #b #e #m normalize
        #Hm @le_S @le_S -Hu2 @(transitive_le … Hu2 Hm)
      ]
    ]
| #x #s normalize //
| #t * #x #H #s lapply (H s) normalize cases ((underline_pTerm t s)) #c #n
  normalize #H @H
] qed.

lemma line_names:
 (∀t.∀s. s ≥ fresh_var_t t → snd … (underline_pTerm t s) ≥ fresh_var (fst … (underline_pTerm t s))) ∧
  (∀v.∀s. s ≥ fresh_var_tv v → snd … (overline v s) ≥ fresh_var_v (fst … (overline v s))).

@pValueTerm_ind
[ #v #HI #s normalize #H lapply (HI s) -HI #HI lapply (HI H) -HI cases (overline v s)
  #vv #n normalize #Hn cases (leb) //
| 3: * #x #s normalize //
| 4: #t * #x #H #s normalize
  change with (max (S x) (fresh_var_t t)) in match (if match pi1 ℕ (λn:ℕ.∀x0:ℕ.1≤free_occ_t (νx0) t→S x0≤n) (fresh_var_t_Sig t)
         in nat
         return λ_:ℕ.bool
         with 
        [O⇒false|S (q:ℕ)⇒leb x q] 
   then pi1 ℕ (λn:ℕ.∀x0:ℕ.1≤free_occ_t (νx0) t→S x0≤n) (fresh_var_t_Sig t) 
   else S x );
  #Hs change with (if leb ? ? then ? else ?) in match (max ? ?) in Hs;
  change with (max ? ? ≤s) in Hs;
  lapply (H s (le_maxr … Hs))
  lapply (line_monotone_names) * #Hmonotone #_ lapply (Hmonotone t s)
  cases underline_pTerm #c #n normalize
  change with (max (S ?) ?) in match (if ? then ?  else ?);
  #Hsn #Hcn @to_max //
  @(transitive_le … (le_maxl … Hs) Hsn)
| #t1 #t2 cases t2
  [ #v2 cases t1
    [ #v1 normalize #H1 #H2 #s lapply (H1 s)
      lapply line_monotone_names * #_ #Hmono
      lapply (Hmono v1 s)
      cases (overline v1 s) #vv #n #Hns normalize
      lapply (H2 n) lapply (Hmono v2 n)
      cases (overline v2 n) #ww #m #Hmn normalize
      change with (fresh_var_tv ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_v (νx) v1→S x≤n0) (fresh_var_tv_Sig v1));
      change with (fresh_var_tv ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_v (νx) v2→S x≤n0) (fresh_var_tv_Sig v2));
      change with (max ? ?) in match (if leb ? ? then ? else ?);
      change with (max ? ?) in match (if leb ? (fresh_var_tv ?) then ? else ?);
      change with (max ? ?) in match (if leb ? (fresh_var_v ?) then ? else ?);
      change with (max ? ?) in match (if leb (max ? ?) 0 then 0 else ?);
      change with (max ? ?) in match (if leb (fresh_var_v vv) O then O else ?);
      >max_O >max_O >max_O #H2 #H1 #Hb lapply (le_maxl …Hb) lapply (le_maxr …Hb)
      #Hv2 #Hv1 lapply (H2 (transitive_le … Hv2 Hns)) #Hww
      lapply (transitive_le …(H1 Hv1) Hmn) #Hvv
      @to_max //
    | #u1 #u2 normalize #H1 #H2 #s lapply (H1 s)
      change with (underline_pTerm (appl u1 u2) ?)
        in match ( match u2 in pTerm with [_⇒ ?]);
      lapply (line_monotone_names) * #Hmono1 #Hmono2 lapply (Hmono1 (appl u1 u2) s)
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n normalize -H1 #Hsn
      lapply (Hmono2 v2 n)
      lapply (H2 n) cases (overline v2 n) #ww #m normalize
      change with (fresh_var_t ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u1→S x≤n0) (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u2→S x≤n0) (fresh_var_t_Sig u2));
      change with (fresh_var_tv ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_v (νx) v2→S x≤n0) (fresh_var_tv_Sig v2));
      change with (max ? ?) in match (if ? then ? else ? ); >max_O #H1 #Hnm
      change with (max ? ?) in match (if ? then ? else ? );
      change with (max ? ?) in match (if leb (fresh_var_b ?) ? then ? else ?);
      change with (max ? ?) in match (if leb (max ? ?)? then ? else ?); #H2 #H
      change with (leb (S ?) ?) in match (match ? in nat with [_ ⇒ ?]);
      change with (max ? ?) in match (if ? then ? else ?);
      change with (max (?) ?) in match ((if leb (S m) (fresh_var_v ww) then fresh_var_v ww else S m ));
      <(fresh_var_push e [νm ← b])
      whd in match (fresh_var_e ?) in ⊢%;
      change with (max ? ?) in match (if ? then ? else fresh_var_e e);
      @to_max @to_max
      [ //
      | @(le_S …(H1 (transitive_le … (le_maxr … H ) Hsn)))
      | @(le_S …(le_maxr …(transitive_le … (H2 (le_maxl … H)) Hnm)))
      | change with (max (S m) ?) in match (fresh_var_s ?); @to_max
        [ //
        | @(le_S … (le_maxl … (transitive_le … (H2 (le_maxl … H)) Hnm)))
        ]
      ]
    ]
  | #u1 #u2 #Hu1 #Hu2 #s lapply (Hu2 s) normalize
      change with (underline_pTerm (appl u1 u2) ?)
        in match ( match u2 in pTerm with [_⇒ ?]);
      lapply (line_monotone_names) * #Hmono1 #Hmono2 lapply (Hmono1 (appl u1 u2) s)
      cases (underline_pTerm (appl u1 u2) s) * #b1 #e1 #n #Hsn
      lapply Hu1 cases t1 normalize
      [ #v1 -Hu1 #Hu1 lapply (Hu1 n)
        lapply (Hmono2 v1 n)  cases (overline v1 n) #vv #m normalize #Hnm
        change with (fresh_var_t ?)
        in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u1→S x≤n0) (fresh_var_t_Sig u1));
        change with (fresh_var_t ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u2→S x≤n0) (fresh_var_t_Sig u2));
        change with (fresh_var_tv ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_v (νx) v1→S x≤n0) (fresh_var_tv_Sig v1));
        change with (max ? ?) in match (if ? then ? else ? ); >max_O #H1
        change with (max ? ?) in match (if ? then ? else ? );
        change with (max ? ?) in match (if leb (fresh_var_b ?) ? then ? else ?); #H2
        change with (max ? ?) in match (if leb (max ? ?)? then ? else ?);
        change with (max ? ?) in match (if leb (fresh_var_tv ?) ? then ? else ?);
        change with (max ? ?) in match (if leb (fresh_var_v ?) ? then ? else ?); #H
        >concat_epsilon_e <fresh_var_push
        change with (max ? ?) in match (fresh_var_e ?);
        change with (max ? ?) in match (fresh_var_s ?);
        @to_max
        [ @to_max
          [ @(le_S …(H1 (transitive_le … (le_maxl … H ) Hsn)))
          | //
          ]
        | @to_max
          [ @(le_S …(le_maxr …(transitive_le … (H2 (le_maxr … H)) Hnm)))
          | @to_max // @(le_S …(le_maxl …(transitive_le … (H2 (le_maxr … H)) Hnm)))
          ]
        ]
      | #t1 #t2 #Ht2 lapply (Ht2 n)
        change with (underline_pTerm (appl t1 t2) n)
          in match ( match t2 in pTerm with [_⇒ ?]);
        lapply (line_monotone_names) * #Hmono1 #Hmono2 lapply (Hmono1 (appl t1 t2) n)
        cases (underline_pTerm (appl t1 t2) n) * #b #e #m normalize #Hnm
        change with (fresh_var_t ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u1→S x≤n0) (fresh_var_t_Sig u1));
        change with (fresh_var_t ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) u2→S x≤n0) (fresh_var_t_Sig u2));
        change with (fresh_var_t ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) t1→S x≤n0) (fresh_var_t_Sig t1));
        change with (fresh_var_t ?)
          in match (pi1 ℕ (λn0:ℕ.∀x:ℕ.1≤free_occ_t (νx) t2→S x≤n0) (fresh_var_t_Sig t2));
        change with (max ? ?) in match (if  ? then ?  else ?);
        change with (max ? ?) in match (if leb (fresh_var_b b) (fresh_var_e e) 
                                        then ? else ?); #H1
        change with (max (fresh_var_t ?) (fresh_var_t ?)) in match (if  ? then ?  else ?);
        change with (max ? ?) in match (if leb (fresh_var_b b1) ? 
                                        then ? else ?); #H2
        change with (max ? ?) in match (if ? then ? else ?) in ⊢ (% → ?);
        #H
        change with (max (S (S m)) (S m)) in match (if match m in nat with [_ ⇒ ?] 
            then S m 
            else S (S m));
        change with (max ? ?)
          in match (if leb (max (S (S m)) (S m))
                    (fresh_var_e (concat (push e1 [νm←b1]) (push e [ν(S m)←b]))) 
                    then fresh_var_e (concat (push e1 [νm←b1]) (push e [ν(S m)←b])) 
                    else max (S (S m)) (S m));
        >fresh_var_concat <fresh_var_push <fresh_var_push
        whd in match (fresh_var_e (Snoc e1 [νm←b1]));
        whd in match (fresh_var_s ?);
        whd in match (fresh_var_e (Snoc e [ν(S m)←b]));
        whd in match (fresh_var_s ?);

        change with (max ? ?) in match (if leb (S m) ? then ? else ?);
        change with (max ? ?) in match (if leb (S m) (fresh_var_b ?) then ? else ?);
        change with (max ? ?) in match (if leb (fresh_var_e e1) ? then ? else ?);
        change with (max ? ?) in match (if leb (fresh_var_e e) ? then ? else ?);
        change with (max ? ?)
          in match (if leb (S (S m)) (fresh_var_b b) then fresh_var_b b else S (S m));
        @to_max
        [ @to_max //
        | @to_max
          [ @to_max
            [ @(le_S …(le_S … (le_maxr … (H1 (transitive_le … (le_maxl … H)Hsn)))))
            | @to_max //
              @(le_S …(le_S … (le_maxl … (H1 (transitive_le … (le_maxl … H) Hsn)))))
            ]
          | @to_max
            [ @(le_S …(le_S … (transitive_le … (le_maxr … (H2 (le_maxr … H))) Hnm)))
            | @to_max //
              @(le_S …(le_S … (transitive_le … (le_maxl … (H2 (le_maxr … H))) Hnm)))
            ]
          ]
        ]
      ]
    ]
] qed.

definition interval_dom ≝  λe, b. ∀x. domb_e (νx) e =true → b ≤ x.
definition bound_dom ≝ λe, b. ∀x. domb_e  (νx) e = true → S x ≤ b.

lemma interval_lemma:  ∀x, e, s. interval_dom (Snoc e s) x → interval_dom e x.
#x #e #s  @(Environment_simple_ind2 … e)
[ #H normalize #x #abs destruct
| cases s #y #t normalize #e' #s' elim y #ny normalize #H #H' #x0 lapply (H' x0)
  cases (neqb x0 ny)
  [ normalize #Htot #_ @Htot //
  | normalize #Htot @Htot
  ]
]
qed.

lemma bound_lemma:  ∀x, e, s. bound_dom (Snoc e s) x → bound_dom e x.
#x #e #s  @(Environment_simple_ind2 … e)
[ #H normalize #x #abs destruct
| cases s #y #t normalize #e' #s' elim y #ny normalize #H #H' #x0 lapply (H' x0)
  cases (neqb x0 ny)
  [ normalize #Htot #_ @Htot //
  | normalize #Htot @Htot
  ]
]
qed.


lemma line_dom:
 (∀t. ∀s. (interval_dom match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e] s)).

#t elim t

[ @(λv. True)
| #v #_ #s normalize cases (overline v s) #vv #n #x normalize #abs destruct
| lapply (line_monotone_names) * #Hmono1 #Hmono2 #t1 #t2 #H1 #H2 #s lapply H2
  cases (t2)
  [ #v2 lapply H1 cases t1
    [ #v1 normalize cases (overline v1 s) #vv #n normalize
      cases (overline v2 n) #ww #m
      normalize #_ #_ #x #abs destruct
    | #u1 #u2 normalize #H1 #H2 lapply (H1 s)
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);     lapply (Hmono1 (appl u1 u2) s)
     cases (underline_pTerm (appl u1 u2) s) *
     #b #e #n normalize #Hsn
     lapply (H2 n)
     lapply (Hmono2 v2 n)
     cases (overline v2 (n)) #vv #m normalize #Hnm
     -H1 -H2 #H2' #H1'
     #x >dom_push normalize
     lapply (H1' x)
     cut (neqb x m=true ∨ neqb x m=false) // * #Htf >Htf normalize
     [ lapply (neqb_iff_eq x m) * #Heq #_ lapply(Heq Htf) -Heq #Heq
       destruct #_ #_ @(transitive_le … Hsn Hnm)
     | #Hdomb #HH @(Hdomb HH)
     ]
   ]
 | #u1 #u2 #H2' lapply (H2' s) normalize
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);
   lapply (Hmono1 (appl u1 u2) s)
   cases (underline_pTerm (appl u1 u2) s)
   * #b1 #e1 #n normalize #Hsn
   lapply (H1 n) cases t1
   [ #v1 normalize lapply (Hmono2 v1 n)
     cases (overline v1 n)
     #vv #m normalize #Hnm #_
     #H2' #x lapply (H2' x) normalize
     cut (neqb x m=true ∨ neqb x m=false) // * #Htf
     [ lapply (neqb_iff_eq x m) * #Heq #_
       lapply (Heq Htf) -Heq #Heq destruct >concat_epsilon_e >dom_push
       normalize
       >neqb_refl normalize #_ #_ @(transitive_le … Hsn Hnm)
     | >concat_epsilon_e >dom_push #HH
       normalize >Htf >if_f @H2'
     ]
   | #u1 #u2 lapply (Hmono1 (appl u1 u2) n)
     cases (underline_pTerm (appl u1 u2) n)
     * #b #e #n1 normalize #Hnn1
     #H1' #H2'' #x lapply (H2'' x) lapply (H1' x) -H2'' -H1'
     #H1' #H2'' normalize >domb_concat_distr >dom_push >dom_push
     normalize cut (neqb x n1=true ∨ neqb x n1=false) // * #Htf
     [ lapply (neqb_iff_eq x n1) * #Heq #_
       lapply (Heq Htf) -Heq #Heq destruct >Htf #_
       @(transitive_le … Hsn Hnn1)
     | cut (neqb x (S n1)=true ∨ neqb x (S n1)=false) // *
       #Htf'
       [ lapply (neqb_iff_eq x (S n1)) * #Heq #_
         lapply (Heq Htf') -Heq #Heq destruct #_
         @le_S @(transitive_le … Hsn Hnn1)
       | >Htf >Htf' normalize -Htf -Htf'
         cut (domb_e (νx) e1 = true ∨ domb_e (νx) e1 =false) // *
         #Htf >Htf
         [ #_ @(H2'' Htf)
         | >if_then_true_else_false #H @(transitive_le … Hsn (H1' H))
         ]
       ]
     ]
   ]
 ]

|  #_ //
|  #t #x #_ //
] qed.

lemma env_bound_lemma:
 (∀t. ∀s. (bound_dom match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e] (snd … (underline_pTerm t s)))).

#t elim t

[ @(λv. True)
| #v #_ #s normalize cases (overline v s) #vv #n #x normalize #abs destruct
| lapply (line_monotone_names) * #Hmono1 #Hmono2 #t1 #t2 #H1 #H2 #s lapply H2
  cases (t2)
  [ #v2 lapply H1 cases t1
    [ #v1 normalize cases (overline v1 s) #vv #n normalize
      cases (overline v2 n) #ww #m
      normalize #_ #_ #x #abs destruct
    | #u1 #u2 normalize #H1 #H2 lapply (H1 s)
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);     lapply (Hmono1 (appl u1 u2) s)
     cases (underline_pTerm (appl u1 u2) s) *
     #b #e #n normalize #Hsn
     lapply (H2 n)
     lapply (Hmono2 v2 n)
     cases (overline v2 (n)) #vv #m normalize #Hnm
     -H1 -H2 #H2' #H1'
     #x >dom_push normalize
     lapply (H1' x)
     cut (neqb x m=true ∨ neqb x m=false) // * #Htf >Htf normalize
     [ lapply (neqb_iff_eq x m) * #Heq #_ lapply(Heq Htf) -Heq #Heq
       destruct #_ #_ //
     | #Hdomb #HH @le_S @(transitive_le … (Hdomb HH) Hnm)
     ]
   ]
 | #u1 #u2 #H2' lapply (H2' s) normalize
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);
   lapply (Hmono1 (appl u1 u2) s)
   cases (underline_pTerm (appl u1 u2) s)
   * #b1 #e1 #n normalize #Hsn
   lapply (H1 n) cases t1
   [ #v1 normalize lapply (Hmono2 v1 n)
     cases (overline v1 n)
     #vv #m normalize #Hnm #_
     #H2' #x lapply (H2' x) normalize
     cut (neqb x m=true ∨ neqb x m=false) // * #Htf
     [ lapply (neqb_iff_eq x m) * #Heq #_
       lapply (Heq Htf) -Heq #Heq destruct >concat_epsilon_e >dom_push
       normalize
       >neqb_refl normalize #_ #_ //
     | >concat_epsilon_e >dom_push #HH
       normalize >Htf >if_f #Hg @le_S
       @(transitive_le … (HH Hg) Hnm)
     ]
   | #u1 #u2 lapply (Hmono1 (appl u1 u2) n)
     cases (underline_pTerm (appl u1 u2) n)
     * #b #e #n1 normalize #Hnn1
     #H1' #H2'' #x lapply (H2'' x) lapply (H1' x) -H2'' -H1'
     #H1' #H2'' normalize >domb_concat_distr >dom_push >dom_push
     normalize cut (neqb x n1=true ∨ neqb x n1=false) // * #Htf
     [ lapply (neqb_iff_eq x n1) * #Heq #_
       lapply (Heq Htf) -Heq #Heq destruct >Htf #_
       @le_S //
     | cut (neqb x (S n1)=true ∨ neqb x (S n1)=false) // *
       #Htf'
       [ lapply (neqb_iff_eq x (S n1)) * #Heq #_
         lapply (Heq Htf') -Heq #Heq destruct #_ //
       | >Htf >Htf' normalize -Htf -Htf'
         cut (domb_e (νx) e1 = true ∨ domb_e (νx) e1 =false) // *
         #Htf >Htf
         [ #_ @le_S @le_S @(transitive_le … (H2'' Htf) Hnn1)
         | >if_then_true_else_false #H @le_S @le_S @H1' @H
         ]
       ]
     ]
   ]
 ]
|  #_ //
|  #t #x #_ //
] qed.

lemma free_var_bound:
 (∀t.∀s.∀x. s ≥ fresh_var_t t → fvb (νx) (fst … (underline_pTerm t s))=true → x ≤ snd … (underline_pTerm t s)) ∧
  (∀v.∀s.∀x. s ≥ fresh_var_tv v → fvb_v (νx) (fst … (overline v s))=true → x ≤ snd … (overline v s)).
@pValueTerm_ind
[ #v #HI #s #x normalize #H lapply (HI s x) -HI #HI lapply (HI H) -HI cases (overline v s)
  #vv #n normalize >if_then_true_else_false >if_then_true_else_false #H @H
| 3: * #y #s #x normalize lapply (neqb_iff_eq x y) * #Heq #_ #HI #Hneqb
  lapply (Heq Hneqb) -Heq #Heq destruct @(le_S_S_to_le … (le_S …HI))
| 4: #t * #y #H #s #x normalize lapply (H s x)
  cases (underline_pTerm t s) * #b #e #n normalize
  >neq_simm
  change with (fresh_var_t ?) in match (pi1 ? ? (fresh_var_t_Sig t));
  change with (max (S y) (fresh_var_t t)) in match (if ? then (fresh_var_t t) else S y);
  #H' #Hm cases neqb normalize
  [ #abs destruct
  | #H1 @(H' (le_maxr … Hm) H1)
  ]
| lapply (line_monotone_names) * #Hmono1 #Hmono2
  lapply (line_names) * #Hline1 #Hline2
  lapply (line_dom) #Hldom
  lapply (env_bound_lemma) #Hbound #t1 #t2 cases t2
  [ #v2 cases t1
    [ #v1 normalize #H1 #H2 #s #x
      change with (max (fresh_var_tv ?) (fresh_var_tv ?))
        in match (if ? then ? else ?); #H
      lapply (H1 s x)
      lapply (Hmono2 v1 s)
      cases (overline v1 s) #vv #n normalize
      lapply (H2 n x)
      lapply (Hmono2 v2 n)
      cases (overline v2 n) #ww #m normalize
      >if_then_true_else_false
      >if_then_true_else_false
      >if_then_true_else_false
      >if_then_true_else_false
      >if_then_true_else_false
      >if_then_true_else_false
      #Hnm #H2' #Hsn #H1'
      #H lapply (orb_to_prop … H) *
      [ 2: -H #Hvv @(H2' (transitive_le … (le_maxr … H) Hsn) Hvv)
      | -H #Hvv @(transitive_le … (H1' (le_maxl … H) Hvv) Hnm)
      ]
    | #u1 #u2 normalize #H1 #H2 #s #x
      change with (max (max (fresh_var_t ?) (fresh_var_t ?)) (fresh_var_tv ?))
        in match (if ? then ? else ?); #H
      lapply (H1 s x)
      lapply (Hbound (appl u1 u2) s)
      lapply (Hldom (appl u1 u2) s)
      lapply (Hmono1 (appl u1 u2) s)
      lapply (Hline1 (appl u1 u2) s)
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n
      normalize
      change with (max (fresh_var_t ?) (fresh_var_t ?))
        in match (if ? then ? else ?);
      change with (max ? ?)
        in match (if ? then ? else (fresh_var_b ?));
      #Hline1 #Hsn #Hldom1 #Hbound1 #H1'
      lapply (H2 n x)
      lapply (Hbound (val_to_term v2) n)
      lapply (Hldom (val_to_term v2) n) normalize
      lapply (Hmono2 v2 n)
      lapply (Hline2 v2 n)
      cases (overline v2 n) #vv #m normalize
      change with (fresh_var_tv ?)
        in match (pi1 nat ? ?);
      #Hline2 #Hnm #Hldom2 #Hbound2 #H2'


      >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (veqb ? ?);
      lapply (H1' (le_maxl … H))
      -H1' #H1'
      lapply (H2' (transitive_le … (le_maxr … H) Hsn))
      -H2' >if_then_true_else_false >if_then_true_else_false #H2'
      cut (neqb (x) (m)=true ∨ neqb (x) (m)=false) // * #Htf
      [ lapply (neqb_iff_eq x m) * #Heq #_
        lapply (Heq Htf) -Heq #Heq destruct
        #_ @le_S //
      | >Htf >if_f >if_f
        lapply H2'
        cases fvb_v
        [ #H #_ @le_S @H @refl
        | #_ >if_f lapply H1' cases domb_e
          [ normalize >if_monotone >if_f >if_then_true_else_false
            #Hu #Hj @le_S @(transitive_le … Hnm) @Hu @Hj
          | normalize >if_then_true_else_false
            #Hu #Hj @le_S @(transitive_le … Hnm) @Hu
            lapply Hj cases fvb_b cases fvb_e //
          ]
        ]
      ]
    ]
  | #u1 #u2 normalize #H1 #H2 #s #x
    lapply (H2 s x)
    change with (underline_pTerm (appl u1 u2) s)
      in match ( match u2 in pTerm with [_⇒ ?]);
    lapply (Hbound (appl u1 u2) s)
    lapply (Hldom (appl u1 u2) s)
    lapply (Hmono1 (appl u1 u2) s)
    lapply (Hline1 (appl u1 u2) s)
    cases (underline_pTerm (appl u1 u2) s) * #b1 #e1 #n
    lapply H1 -H1
    cases t1
    [ #v1 #H1 normalize
      lapply (H1 n x) normalize
      lapply (Hbound (val_to_term v1) n)
      lapply (Hldom (val_to_term v1) n) normalize
      lapply (Hmono2 v1 n)
      lapply (Hline2 v1 n)
      cases (overline v1 n) #vv #m
      normalize
      change with (fresh_var_tv ?)
        in match (pi1 ? ? (fresh_var_tv_Sig ?));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u2));
      change with (max ? ?)
        in match (if ? then fresh_var_t ? else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e ? else ?);
      change with (max ? ?)
        in match (if ? then max ? ? else ?);
      #Hline1 #Hnm #Hldom1 #Hbound1
      #H1
      #Hline2 #Hsn #Hldom2 #Hbound2
      #H2 #Hm
      #H
      lapply (H2 (le_maxr … Hm)) -H2 #H2
      lapply (H1 (transitive_le … (le_maxl … Hm) Hsn)) -H1 #H1


      lapply H lapply H1 lapply H2 >concat_epsilon_e
      >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      >if_then_true_else_false >if_then_true_else_false
      cases fvb_v normalize
      [ #_ #Hy #_ @le_S @Hy @refl ]
      cut (neqb (x) (m)=true ∨ neqb (x) (m)=false) // * #Htf
      [ lapply (neqb_iff_eq x m) * #Heq #_
        lapply (Heq Htf) -Heq #Heq destruct
        #_ #_ #_ @le_S @le_n
      | >Htf normalize
        cases fvb_e
        [ >if_monotone #Hj #_ #_ @le_S @(transitive_le … Hnm) @Hj @refl ]
        >if_then_true_else_false
        cases fvb_b cases domb_e normalize
        [ #_ #_ #abs destruct
        | #Hj #_ #_ @le_S @(transitive_le … Hnm) @Hj @refl
        | #_ #_ #abs destruct
        | #_ #_ #abs destruct
        ]
      ]
    | #r1 #r2 #H1 normalize
      lapply (H1 n x) normalize
      lapply (Hbound (appl r1 r2) n)
      lapply (Hldom (appl r1 r2) n)
      lapply (Hmono1 (appl r1 r2) n)
      lapply (Hline1 (appl r1 r2) n)
      change with (underline_pTerm (appl r1 r2) n)
        in match ( match r2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl r1 r2) n ) * #b #e #m
      normalize
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u2));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig r1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig r2));
      change with (max ? ?)
        in match (if ? then fresh_var_t r2 else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_t u2 else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e e else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e e1 else ?);
      change with (max ? ?)
        in match (if ? then max ? ? else ?);
      #Hline1 #Hnm #Hldom1 #Hbound1
      #H1'
      #Hline2 #Hsn #Hldom2 #Hbound2
      #H2' #Hm
      #H
      lapply (H2' (le_maxr … Hm)) -H2' #H2'
      lapply (H1' (transitive_le … (le_maxl … Hm) Hsn)) -H1' #H1'


      lapply H2' lapply H1' lapply H
      >domb_concat_distr >dom_push >dom_push
      >fv_concat >fv_push >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (domb_e ? (Snoc ? ?));
      change with (neqb ? ?) in match (veqb ? (νm));
      change with (neqb ? ?) in match (veqb ? (ν(S m)));
      cut (neqb (x) (m)=true ∨ neqb (x) (m)=false) // * #Htf
      [ lapply (neqb_iff_eq x m) * #Heq #_
        lapply (Heq Htf) -Heq #Heq destruct
        #_ #_ #_ @le_S @le_S @le_n
      ]
      cut (neqb (x) (S m)=true ∨ neqb (x) (S m)=false) // * #Htf1
      [ lapply (neqb_iff_eq x (S m)) * #Heq #_
        lapply (Heq Htf1) -Heq #Heq destruct
        #_ #_ #_ @le_S @le_n
      ]
      >Htf >Htf1 normalize
      cut (fvb_e (νx) e=true ∨ fvb_e (νx) e=false) // * #Hfe >Hfe normalize
      [ >if_monotone  #_ #Hj #_
        @le_S @le_S @Hj @refl ]
      >if_then_true_else_false

      cut (∀x0:ℕ.m ≤ x0→ domb_e (νx0) e=false)
      [ #x lapply (Hbound1 x) cases domb_e // #H1 #H2 @False_ind
        lapply (transitive_le … (H1 (refl …)) H2) /2/
      ]
      cut (∀x0:ℕ.n ≤ x0→ domb_e (νx0) e1=false)
      [ #x lapply (Hbound2 x) cases domb_e // #H1 #H2 @False_ind
        lapply (transitive_le … (H1 (refl …)) H2) /2/
      ]
      #Hbound2' #Hbound1'
      cut (leb m x =true ∨ leb m x =false) // * #Hleb
      [ lapply(leb_true_to_le … Hleb) #Hle
        >Hbound1' //
(*        [ 2:  @(le_S_S_to_le … (le_S … Hle)) ] *)
        >Hbound2'
(*        [ 2: @(transitive_le … Hnm (le_S_S_to_le … (le_S … Hle))) ]*)
      [ 2: @(transitive_le … Hnm  Hle) ]
      cut (fvb_b (νx) b1 = false)
        [ lapply (transitive_le … (le_maxl … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb @(transitive_le … Hfvb Hle)
        ] #Hfvb1
        cut (fvb_b (νx) b = false)
        [ lapply (le_maxl … (Hline1 (transitive_le … (le_maxl … Hm) Hsn)))
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb @(transitive_le … Hfvb Hle)
        ]
        #Hfvb
        cut (fvb_e (νx) e = false)
        [ lapply (le_maxr … (Hline1 (transitive_le … (le_maxl … Hm) Hsn)))
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He @(transitive_le … Hfve Hle)
        ]
        #Hfve
        cut (fvb_e (νx) e1 = false)
        [ lapply (transitive_le … (le_maxr … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He @(transitive_le … Hfve Hle)
        ]
        #Hfve1
        >Hfvb >Hfvb1 >Hfve >Hfve1 normalize #abs destruct
      | cut (x < m)
        [ @(not_le_to_lt … (leb_false_to_not_le … Hleb)) ]
        #Hlt #_ #_ #_ @le_S @le_S @lt_to_le @Hlt
      ]
    ]
  ]
] qed.


lemma disjoint_dom:
 (∀t, s, x. fresh_var_t t ≤ s →
   (fvb_t x t = fvb x (fst ? ?(underline_pTerm t s))) ∧
   (fvb_e x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e]=true →
   domb_e x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e]=false)(* ∧
   (fvb_e x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e]=true →
   fvb_b x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ c]=true)*)) ∧
  (∀v.∀s.∀x. (s ≥ fresh_var_tv v) → fvb_tv x v = fvb_v x (fst ? ?(overline v s))).

@pValueTerm_ind
[ #v normalize #H #s #x lapply (H s x) cases overline #v #n normalize #HI #Ht
  lapply(HI Ht) -HI #HI >HI >if_then_true_else_false >if_then_true_else_false
  % [ // |#abs destruct ]
| 3: #y #s #x #H normalize cases veqb normalize //
| 4: #t * #x #HI #s * #y
  change with (max (S x) (fresh_var_t t)≤s) in match (s≥fresh_var_tv ?);
  #H
  lapply (HI s (νy) (le_maxr … H))
  normalize cases underline_pTerm * #b #e #n normalize
  -HI #HI >neq_simm cases neqb normalize // lapply HI * * #_ //
| lapply (line_monotone_names) * #Hmono1 #Hmono2
  lapply (line_names) * #Hline1 #Hline2
  lapply (line_dom) #Hldom
  lapply (env_bound_lemma) #Hbound
  lapply (free_var_bound) * #Hfvbd1 #Hfvbd2 #t1 #t2 cases t2
  [ #v2 cases t1
    [ #v1 normalize #H1 #H2 #s #x
      change with (max (fresh_var_tv ?) (fresh_var_tv ?))
        in match (if ? then ? else ?); #H
      lapply (H1 s x)
      lapply (Hmono2 v1 s)
      cases (overline v1 s) #vv #n normalize #Hsn #H1'
      lapply (H2 n x)
      lapply (Hmono2 v2 s)
      cases (overline v2 n) #ww #m normalize #Hnm #H2'
      lapply (H1' (le_maxl … H)) -H1'
      >if_then_true_else_false >if_then_true_else_false
      * #H1a #H1b
      >if_then_true_else_false >if_then_true_else_false
      lapply (H2' (transitive_le … (le_maxr … H) Hsn)) -H2'
      >if_then_true_else_false >if_then_true_else_false
      * #H2a #H2b
       %
       [ lapply H1a lapply H2a
         cases free_occ_v cases free_occ_v normalize
         [ #a #b <a <b //
         | #n #a #b <a <b //
         | #m #a #b <a <b //
         | #n #m #a #b <a <b //
         ]
       | #abs destruct
       ]
    | #u1 #u2 normalize #H1 #H2 #s * #x
      change with (max (max (fresh_var_t ?) (fresh_var_t ?)) (fresh_var_tv ?))
        in match (if ? then ? else ?); #H
      lapply (H1 s νx)
      lapply (Hfvbd1 (appl u1 u2) s)
      lapply (Hbound (appl u1 u2) s)
      lapply (Hldom (appl u1 u2) s)
      lapply (Hmono1 (appl u1 u2) s)
      lapply (Hline1 (appl u1 u2) s)
      change with (underline_pTerm (appl u1 u2) s)
        in match ( match u2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n
      normalize
      change with (max (fresh_var_t ?) (fresh_var_t ?))
        in match (if ? then ? else ?);
      change with (max ? ?)
        in match (if ? then ? else (fresh_var_b ?));
      #Hline1 #Hsn #Hldom1 #Hbound1 #Hfb1 #H1'
      lapply (H2 n νx)
      lapply (Hfvbd2 v2 n)
      lapply (Hbound (val_to_term v2) n)
      lapply (Hldom (val_to_term v2) n) normalize
      lapply (Hmono2 v2 n)
      lapply (Hline2 v2 n)
      cases (overline v2 n) #vv #m normalize
      change with (fresh_var_tv ?)
        in match (pi1 nat ? ?);
      #Hline2 #Hnm #Hldom2 #Hbound2 #Hfb2 #H2'


      >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (veqb ? ?);
      lapply (H1' (le_maxl … H)) -H1' * #H1a #H1b
      lapply (H2' (transitive_le … (le_maxr … H) Hsn)) -H2'
      * >if_then_true_else_false >if_then_true_else_false #H2a #_
      cut (neqb x m=true ∨ neqb x m=false) // * #Htf
      [ lapply (neqb_iff_eq x m) * #Heq #_
        lapply (Heq Htf) -Heq #Heq destruct
        >Htf >if_t
        cut (fvb_b (νm) b = false)
        [ lapply (le_maxl … (transitive_le … (Hline1 (le_maxl … H)) Hnm))
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb assumption
        ]
        #Hfvb >Hfvb normalize
        cut (domb_e (νm) e = false)
        [ lapply (le_maxr … (transitive_le … (Hline1 (le_maxl … H)) Hnm))
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply dom_to_in #He1
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → domb_e x e0=false)
          [#e #x lapply (He1 e x) cases domb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He assumption
        ] #Hdom >Hdom normalize
        cut (fvb_e (νm) e = false)
        [ lapply (le_maxr … (transitive_le … (Hline1 (le_maxl … H)) Hnm))
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He assumption
        ]
        #Hfve >Hfve normalize
        lapply H
        change with (fresh_var_t (appl (appl u1 u2) (val_to_term v2))≤s) in H;
        lapply H #H' -H #H
        lapply fresh_var_to_in * #Hfvtoin #_
        lapply (Hfvtoin … (appl (appl u1 u2) (val_to_term v2)) m (transitive_le … (transitive_le … H' Hsn) Hnm))
        lapply (fv_to_in_term) * #fvtoin #_
        cut (∀t:pTerm.∀x:Variable.inb_t x t=false → fvb_t x t=false)
        [#t #x lapply (fvtoin t x) cases fvb_t cases inb_t // #H >H //]
        -fvtoin #fvtoin #Hin lapply (fvtoin … Hin)
        change with (fvb_t (νm) (appl (appl u1 u2) (val_to_term v2)))
          in match (gtb ? 0);
        #H >H % //
        | >Htf >if_f normalize
        cut (fvb_e (νx) e=true ∨ fvb_e (νx) e=false) // * #Hfve
        [ lapply H1a >Hfve normalize >H1b // >if_monotone >if_monotone
          cases (free_occ_t (νx) u1+free_occ_t (νx) u2) normalize
          [ #abs destruct
          | #n #_ % //
          ]
        | normalize lapply H1a >Hfve normalize >if_then_true_else_false
          #H1a'
          lapply H1a' lapply H2a
          cut (domb_e (νx) e=true ∨ domb_e (νx) e=false) // * #Hde
          [ >Hde normalize >if_then_false_else_false >if_monotone >if_f
           (* se x è nel dominio di e è piò grande di s dunqe per ipotesi induttiva,
              ma siccome è più grande di fresh_var v2 non è libera in v2 che equivale
              a dire che free_occ_c νx v2=0
           *)
            cut (s ≤ x) [ @Hldom1 //]
            #Hsx
            cut (fresh_var_tv v2 ≤ x)
            [ @(transitive_le … (le_maxr … H) Hsx)]
            -Hsx #Hfvv2
            lapply (fresh_var_to_in) * #_ #Hfin
            lapply (Hfin … Hfvv2) -Hfin
            lapply (fv_to_in_term) * #_ #Hfin
            cut (∀v:pValue.∀x0:Variable.inb_tv x0 v=false → fvb_tv x0 v=false)
            [ #v #x lapply (Hfin v x) cases inb_tv cases fvb_tv // #H >H // ]
            -Hfin #Hfin #Yee lapply (Hfin … Yee) -Yee
            change with (gtb ? 0) in match (fvb_tv ? v2);
            #Yee lapply (gtb_O … Yee) #Uee >Uee
            cut (∀n. n+0=n) [ elim n //] #Hno >Hno -Hno
            #_ #bi >bi % //
          | >Hde normalize cases (free_occ_v (νx) v2)
            [ normalize #Hf <Hf >if_f
              >if_then_true_else_false
              cut (∀n. n+0=n) [elim n //]
              #Hno >Hno -Hno
              #H >H % //
            | #n normalize #Ht <Ht >if_t
              cut ((free_occ_t (νx) u1+free_occ_t (νx) u2)+S n =
                   S (free_occ_t (νx) u1+free_occ_t (νx) u2+n))
              [ cases (free_occ_t (νx) u1+free_occ_t (νx) u2) //]
              #Hpn >Hpn whd in match (gtb (S ?) 0); #_ % //
            ]
          ]
        ]
      ]
    ]
  | #u1 #u2 normalize #H1 #H2 #s * #x
    lapply (H2 s νx)
    change with (underline_pTerm (appl u1 u2) s)
      in match ( match u2 in pTerm with [_⇒ ?]);
    lapply (Hfvbd1 (appl u1 u2) s)
    lapply (Hbound (appl u1 u2) s)
    lapply (Hldom (appl u1 u2) s)
    lapply (Hmono1 (appl u1 u2) s)
    lapply (Hline1 (appl u1 u2) s)
    cases (underline_pTerm (appl u1 u2) s) * #b1 #e1 #n
    lapply H1 -H1
    cases t1
    [ #v1 #H1 normalize
      lapply (H1 n νx) normalize
      lapply (Hfvbd2 v1 n)
      lapply (Hbound (val_to_term v1) n)
      lapply (Hldom (val_to_term v1) n) normalize
      lapply (Hmono2 v1 n)
      lapply (Hline2 v1 n)
      cases (overline v1 n) #vv #m
      normalize
      change with (fresh_var_tv ?)
        in match (pi1 ? ? (fresh_var_tv_Sig ?));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u2));
      change with (max ? ?)
        in match (if ? then fresh_var_t ? else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e ? else ?);
      change with (max ? ?)
        in match (if ? then max ? ? else ?);
      #Hline1 #Hnm #Hldom1 #Hbound1 #Hfb1
      #H1
      #Hline2 #Hsn #Hldom2 #Hbound2 #Hfb2
      #H2 #Hm
      lapply (H2 (le_maxr … Hm)) -H2 #H2'
      lapply (H1 (transitive_le … (le_maxl … Hm) Hsn)) -H1 #H1'


      >concat_epsilon_e
      >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (veqb ? ?);
      lapply H1' >if_then_true_else_false >if_then_true_else_false -H1' #H1'
      cut (neqb x m=true ∨ neqb x m=false) // * #Htf
      [ lapply (neqb_iff_eq (x) (m)) * #Heq #_
        lapply (Heq Htf) -Heq #Heq destruct
        >Htf >if_t
        cut (fvb_e (νm) e1 = false)
        [ lapply (transitive_le … (le_maxr … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He assumption
        ]
        #Hfve
        cut (fvb_b (νm) b1 = false)
        [ lapply (transitive_le … (le_maxl … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb assumption
        ] #Hfvb
        cut (domb_e (νm) e1 = false)
        [ lapply (transitive_le … (le_maxr … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply dom_to_in #He1
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → domb_e x e0=false)
          [#e #x lapply (He1 e x) cases domb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He assumption
        ] #Hdom
        lapply H2' >Hfve >Hdom >Hfve >Hfvb
        normalize >if_then_true_else_false >if_monotone
        * #Hf lapply (gtb_O … Hf) -Hf #Ho >Ho
        cut (∀n. n+0=n) [ elim n //] #Hno >Hno -Hno #_ % //
        change with (fvb_tv ? ?) in match (gtb ? O);
        cut (fresh_var_tv v1 ≤ m)
        [ @(transitive_le … (transitive_le … (le_maxl … Hm) Hsn) Hnm)]
         #Hfvv1
         lapply (fresh_var_to_in) * #_ #Hfin
         lapply (Hfin … Hfvv1) -Hfin
         lapply (fv_to_in_term) * #_ #Hfin
         cut (∀v:pValue.∀x0:Variable.inb_tv x0 v=false → fvb_tv x0 v=false)
         [ #v #x lapply (Hfin v x) cases inb_tv cases fvb_tv // #H >H // ]
         -Hfin #Hfin #Yee  @(Hfin … Yee)
      | >Htf >if_f >if_then_true_else_false
        lapply H1' * -H1' #H1a #_
        lapply H2' * -H2' #H2a #H2b
        cut (domb_e (νx) e1=true ∨ domb_e (νx) e1=false) // * #Hde
        [ lapply H2a >Hde normalize >if_then_false_else_false >if_f
          >if_then_true_else_false
          cut (domb_e (νx) e1=true→fvb_e (νx) e1=false)
          [ lapply H2b cases domb_e cases fvb_e // #H >H //]
          #H2b' >H2b' // -H2a #H2a % // >if_monotone >if_f
          lapply (gtb_O … H2a) -H2a #H2a >H2a
          cut (∀n. n+0=n) [ elim n //] #Hno >Hno -Hno
          change with (fvb_tv ? ?) in match (gtb ? O);
          (* se x è nel dominio di e è piò grande di s dunqe per ipotesi induttiva,
              ma siccome è più grande di fresh_var v2 non è libera in v2 che equivale
              a dire che free_occ_c νx v2=0
           *)
          cut (s ≤ x) [ @Hldom2 //]
          #Hsx
          cut (fresh_var_tv v1 ≤ x)
          [ @(transitive_le … (le_maxl … Hm) Hsx)]
          -Hsx #Hfvv1
          lapply (fresh_var_to_in) * #_ #Hfin
          lapply (Hfin … Hfvv1) -Hfin
          lapply (fv_to_in_term) * #_ #Hfin
          cut (∀v:pValue.∀x0:Variable.inb_tv x0 v=false → fvb_tv x0 v=false)
          [ #v #x lapply (Hfin v x) cases inb_tv cases fvb_tv // #H >H // ]
          -Hfin #Hfin #Yee @(Hfin … Yee)
        | lapply H2a >Hde normalize >if_then_true_else_false #H2a
          >if_then_true_else_false lapply H1a
          cases (free_occ_v (νx) v1)
          [ normalize #Hf <Hf >if_f >H2a
            cases fvb_b cases fvb_e normalize % //
          | #n normalize #Ht <Ht >if_t % //
          ]
        ]
      ]
    | #r1 #r2 #H1 normalize
      lapply (H1 n νx) normalize
      lapply (Hfvbd1 (appl r1 r2) n)
      lapply (Hbound (appl r1 r2) n)
      lapply (Hldom (appl r1 r2) n)
      lapply (Hmono1 (appl r1 r2) n)
      lapply (Hline1 (appl r1 r2) n)
      change with (underline_pTerm (appl r1 r2) n)
        in match ( match r2 in pTerm with [_⇒ ?]);
      cases (underline_pTerm (appl r1 r2) n ) * #b #e #m
      normalize
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig u2));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig r1));
      change with (fresh_var_t ?)
        in match (pi1 ? ? (fresh_var_t_Sig r2));
      change with (max ? ?)
        in match (if ? then fresh_var_t r2 else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_t u2 else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e e else ?);
      change with (max ? ?)
        in match (if ? then fresh_var_e e1 else ?);
      change with (max ? ?)
        in match (if ? then max ? ? else ?);
      #Hline1 #Hnm #Hldom1 #Hbound1 #Hfb1
      #H1
      #Hline2 #Hsn #Hldom2 #Hbound2 #Hfb2
      #H2 #Hm
      lapply (H2 (le_maxr … Hm)) -H2 #H2
      lapply (H1 (transitive_le … (le_maxl … Hm) Hsn)) -H1 #H1


      lapply H1 -H1 * #H1a #H1b
      lapply H2 -H2 * #H2a #H2b
      >domb_concat_distr >dom_push >dom_push
      >fv_concat >fv_push >fv_push >dom_push
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (domb_e ? (Snoc ? ?));
      whd in match (veqb ? ?);
      whd in match (veqb ? ?);
      cut (∀x0:ℕ.m ≤ x0→ domb_e (νx0) e=false)
      [ #x lapply (Hbound1 x) cases domb_e // #H1 #H2 @False_ind
        lapply (transitive_le … (H1 (refl …)) H2) /2/
      ]
      cut (∀x0:ℕ.n ≤ x0→ domb_e (νx0) e1=false)
      [ #x lapply (Hbound2 x) cases domb_e // #H1 #H2 @False_ind
        lapply (transitive_le … (H1 (refl …)) H2) /2/
      ]
      #Hbound2' #Hbound1'
      cut (leb m x =true ∨ leb m x =false) // * #Hleb
      [ lapply(leb_true_to_le … Hleb) #Hle
        >Hbound1' //
(*        [ 2:  @(le_S_S_to_le … (le_S … Hle)) ] *)
        >Hbound2'
(*        [ 2: @(transitive_le … Hnm (le_S_S_to_le … (le_S … Hle))) ]*)
      [ 2: @(transitive_le … Hnm  Hle) ]
      cut (fvb_b (νx) b1 = false)
        [ lapply (transitive_le … (le_maxl … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb @(transitive_le … Hfvb Hle)
        ] #Hfvb1
        cut (fvb_b (νx) b = false)
        [ lapply (le_maxl … (Hline1 (transitive_le … (le_maxl … Hm) Hsn)))
          #Hfvb
          lapply fresh_var_to_in_crumble * * * * #_ #Hb #_ #_ #_
          lapply fv_to_in_crumble * * * * #_ #Hb1 #_ #_ #_
          cut (∀b:Bite.∀x:Variable.inb_b x b=false → fvb_b x b=false)
          [#e #x lapply (Hb1 e x) cases fvb_b cases inb_b // #H >H //]
          -Hb1 #Hb1 @Hb1 @Hb @(transitive_le … Hfvb Hle)
        ] #Hfvb
        cut (fvb_e (νx) e = false)
        [ lapply (le_maxr … (Hline1 (transitive_le … (le_maxl … Hm) Hsn)))
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He @(transitive_le … Hfve Hle)
        ] #Hfve
        cut (fvb_e (νx) e1 = false)
        [ lapply (transitive_le … (le_maxr … (Hline2 (le_maxr … Hm))) Hnm)
          #Hfve
          lapply fresh_var_to_in_crumble * * * * #_ #_ #He #_ #_
          lapply fv_to_in_crumble * * * * #_ #_ #He1 #_ #_
          cut (∀e0:Environment.∀x:Variable.inb_e x e0=false → fvb_e x e0=false)
          [#e #x lapply (He1 e x) cases fvb_e cases inb_e // #H >H //]
          -He1 #He1 @He1 @He @(transitive_le … Hfve Hle)
        ] #Hfve1
        lapply H1a lapply H2a
        >Hfvb >Hfvb1 >Hfve >Hfve1 normalize
        >if_then_true_else_false -H2a -H1a #H2a #H1a %
        [ 2: #abs destruct ]
        >if_then_true_else_false
        >if_then_true_else_false
        cut (neqb x (m)=true ∨ neqb x (m)=false) // * #Htf
        [ >Htf normalize >if_monotone
          lapply (gtb_O … H2a) -H2a #H2a
          lapply (gtb_O … H1a) -H1a #H1a
          >H1a >H2a //
        | >Htf normalize >if_then_true_else_false cases neqb normalize
          >(gtb_O … H2a) >(gtb_O … H1a) //
        ]

      | cut (x < m)
        [ @(not_le_to_lt … (leb_false_to_not_le … Hleb)) ]
        #Hlt
        cut (neqb x m=false ∧ neqb x (S m)=false)
        [ normalize %
          [ cut (neqb x m = true ∨ neqb x m = false) // * #Htf //
            @False_ind
            lapply (neqb_iff_eq x m) * #Heq #_
            lapply (Heq Htf) -Heq #Heq destruct /2/
          | cut (neqb x (S m) = true ∨ neqb x (S m) = false) // * #Htf //
            @False_ind
            lapply (neqb_iff_eq x (S m)) * #Heq #_
            lapply (Heq Htf) -Heq #Heq destruct /2/
          ]
        ]
        * #Hf1 #Hf2 >Hf1 >Hf2 normalize
        cut (fvb_e (νx) e1 =true ∨ fvb_e (νx) e1 =false) // * #Htf
        [ >Htf normalize >H2b // normalize
          cut (fvb_e (νx) e =true ∨ fvb_e (νx) e =false) // * #Htf1
          [ >Htf1 normalize >H1b // normalize
            lapply H2a >Htf >if_monotone -H2a #H2a
            lapply (gtb_O_true … H2a) -H2a * #n #H2a >H2a % //
            cases (free_occ_t (νx) r1+free_occ_t (νx) r2) //
          | >Htf1 normalize >if_monotone %
            [ lapply H2a >Htf >if_monotone #H2a lapply (gtb_O_true … H2a)
              * #k #Hk >Hk cases (plus (free_occ_t ? ?) ?) //
            ]
            cut (domb_e (νx) e=true ∨ domb_e (νx) e=false) // * #Hdome >Hdome //
            normalize lapply H1a lapply H2a >Hdome >Htf >Htf1 normalize
            >if_monotone >if_monotone >if_f
              change with (fvb_t ? (appl ??))
                in match (gtb ? O);
              lapply (Hldom1 … Hdome) #Hnx
              cut (fresh_var_t (appl u1 u2) ≤ x)
              [ @(transitive_le … (transitive_le … (le_maxr … Hm) Hsn) Hnx)]
              #Hfvu
              lapply (fresh_var_to_in) * #Hfin #_
              lapply (Hfin … Hfvu)
              lapply (fv_to_in_term) * #Hfin2 #_
              cut (∀v:pTerm.∀x0:Variable.inb_t x0 v=false → fvb_t x0 v=false)
              [ #v #x lapply (Hfin2 v x) cases inb_t cases fvb_t // #H >H // ]
              -Hfin2 #Hfin2 #Yee
              cut (fresh_var_t (appl u1 u2) ≤ x)
              [ @(transitive_le … (transitive_le … (le_maxr … Hm) Hsn) Hnx)]
              -Hnx #Hfvr
              lapply (Hfin … Hfvr) #Yee2
              >(Hfin2 … Yee) >(Hfin2 … Yee2) #abs destruct
            ]
        | >Htf normalize
          cut (domb_e (νx) e1=true ∨ domb_e (νx) e1=false) // * #Hde1
          [ >Hde1 normalize lapply H1a
            cut (domb_e (νx) e=false)
            [ cut (domb_e (νx) e=true∨domb_e (νx) e=false) // * #Hde //
              lapply (Hldom1 … Hde)
              lapply (Hbound2 … Hde1)
              #Hj #Hk lapply (transitive_le … Hj Hk) -Hj -Hk #HH
              @False_ind lapply HH elim x /2/
            ]
            #Hdome >Hdome normalize
            change with (fvb_t ? (appl ??))
                in match (gtb ? O);
            change with  (fvb_t ? (appl (appl ??)(appl ??)))
                in match (gtb (plus (plus ??) (plus ??)) 0);
            #H2a >fvb_t_distr lapply H2a -H2a
            lapply (Hldom2 … Hde1) #Hsx
            cut (fresh_var_t (appl r1 r2) ≤ x)
            [ @(transitive_le … (le_maxl … Hm) Hsx)]
            #Hfvu
            lapply (fresh_var_to_in) * #Hfin #_
            lapply (Hfin … Hfvu)
            lapply (fv_to_in_term) * #Hfin2 #_
            cut (∀v:pTerm.∀x0:Variable.inb_t x0 v=false → fvb_t x0 v=false)
            [ #v #x lapply (Hfin2 v x) cases inb_t cases fvb_t // #H >H // ]
            -Hfin2 #Hfin2 #Yee
            cut (fresh_var_t (appl u1 u2) ≤ x)
            [ @(transitive_le … (le_maxr … Hm) Hsx)]
            -Hsx #Hfvr
            lapply (Hfin … Hfvr) #Yee2
            >(Hfin2 … Yee) >(Hfin2 … Yee2) whd in match (false ∨ false);
            >if_then_true_else_false >if_then_true_else_false
            >if_monotone #_ % //
          | >Hde1 normalize
            >Htf
            cut (domb_e (νx) e= true ∨ domb_e (νx) e= false) // * #Hde
            [ >Hde normalize
              cut (domb_e (νx) e=true → fvb_e (νx) e=false)
              [ lapply H1b cases domb_e cases fvb_e normalize // #H >H // ]
              #H1b' >H1b' // normalize
              change with  (fvb_t ? (appl (appl ??)(appl ??)))
                  in match (gtb (plus (plus ??) (plus ??)) 0);
              lapply (Hldom1 … Hde) #Hnx
              cut (fresh_var_t (appl r1 r2) ≤ x)
              [ @(transitive_le … (transitive_le … (le_maxl … Hm) Hsn) Hnx)]
              #Hfvu
              lapply (fresh_var_to_in) * #Hfin #_
              lapply (Hfin … Hfvu)
              lapply (fv_to_in_term) * #Hfin2 #_
              cut (∀v:pTerm.∀x0:Variable.inb_t x0 v=false → fvb_t x0 v=false)
              [ #v #x lapply (Hfin2 v x) cases inb_t cases fvb_t // #H >H // ]
              -Hfin2 #Hfin2 #Yee
              cut (fresh_var_t (appl u1 u2) ≤ x)
              [ @(transitive_le … (transitive_le … (le_maxr … Hm) Hsn) Hnx)]
              -Hnx #Hfvr
              lapply (Hfin … Hfvr) #Yee2 >fvb_t_distr
              lapply (H2a)
              change with (fvb_t ? (appl ? ?)) in match (gtb ? 0);
              >Hde1 >Htf >if_then_true_else_false >if_f >if_then_true_else_false
              >(Hfin2 … Yee) >(Hfin2 … Yee2) #HH <HH % //
            | lapply H2a lapply H1a >Hde >Hde1 normalize >Htf
              >if_then_true_else_false >if_then_true_else_false
              >if_then_true_else_false
              cases (free_occ_t (νx) r1+free_occ_t (νx) r2)
              cases (free_occ_t (νx) u1+free_occ_t (νx) u2)
              normalize
              [ #a #b <b >if_then_true_else_false >if_then_true_else_false
                lapply a cases fvb_b cases fvb_e
                normalize [ 1,2,3: #a destruct ] #_ % //
              | #n #a #b <b normalize % // >if_monotone @refl
              | #m #a #b <b normalize % // lapply a cases fvb_b cases fvb_e
                normalize //
              | #n #m #a #b <b normalize % // >if_monotone @refl
              ]
            ]
          ]
        ]
      ]
    ]
  ]
] qed.

corollary four_dot_one_dot_one:
 (∀t, s, x. fresh_var_t t ≤ s →
   (fvb_t x t = fvb x (fst ? ?(underline_pTerm t s)))) ∧
  (∀v.∀s.∀x. (s ≥ fresh_var_tv v) → fvb_tv x v = fvb_v x (fst ? ?(overline v s))).

lapply disjoint_dom * #Ht #Hv % [2: @Hv] #t #s #x #h lapply (Ht t s x h) * #H #_ @H
qed.

corollary dis_dom:
 (∀t, s, x. fresh_var_t t ≤ s →
   fvb_e x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e]=true →
   domb_e x match (fst … (underline_pTerm t s)) with [CCrumble c e ⇒ e]=false).
lapply disjoint_dom * #Ht #Hv #t #s #x #h lapply (Ht t s x h) * #_ #H @H qed.


lemma closure_lemma:
 (∀t,s. fresh_var_t t ≤ s →
  closed_t t →
   closed_c (fst … (underline_pTerm t s))) ∧
 (∀v,s. fresh_var_tv v ≤ s →
  closed_tv v →
   closed_v (fst … (overline v s))).


@pValueTerm_ind
[ #v #H #s normalize #Ha #Hb #x lapply(H s Ha Hb x) cases overline #v #n normalize
  #H >H normalize //
| #t1 #t2 #H1 #H2 #s #H whd in match (closed_t ?); whd in match (closed_c ?);
  #Hct #x lapply (Hct x)
  lapply (four_dot_one_dot_one) * #H411 #_
    cut ((∀t0:pTerm.∀s0:ℕ.fresh_var_t t0≤s0 →
     ∀x:Variable.fvb_t x t0=fvb x (\fst  (underline_pTerm t0 s0))))
    [ #t #s #H #x @H411 @H]
    -H411 #H411 >(H411 … s H) //
| #y #s #Ha #Hb #x lapply (Hb x) normalize cases veqb normalize //
| #t #x #HI #s #Hm
  lapply (four_dot_one_dot_one) * #_ #H411 #H #z lapply (H z)
  >(H411 (abstr x t) s z Hm) //
] qed.


let rec c_len_e e on e ≝ match e with [Epsilon ⇒ O | Snoc e s ⇒ 1 + c_len_e e].

let rec c_len c on c ≝
 match c with
 [ CCrumble b e ⇒ c_len_e e].

let rec e_pop e on e ≝
 match e with
 [ Epsilon ⇒ e
 | Snoc e s ⇒ e
 ]
 .

let rec fv_pt x t on t≝
 match t with
 [ val_to_term v ⇒ fv_pv x v
 | appl t1 t2 ⇒  orb (fv_pt x t1) (fv_pt x t2)
 ]

and fv_pv x v on v ≝
 match v with
 [ pvar y ⇒ veqb x y
 | abstr y t ⇒ if veqb x y then false else fv_pt x t
 ]
 .

lemma env_len: ∀e: Environment. (e = Epsilon → False ) →  S (c_len_e (e_pop e))=(c_len_e e).
#e cases e [ normalize #Abs cut False [ cut (Epsilon=Epsilon) [ //| @Abs] | #Abs
@False_ind] @Abs | #e1 #s #H1 normalize //] qed.

(* Definizione 1: naïve, restituisce il clasico errore: *)
(* NTypeChecker failure: Recursive call (read_back_b b), b is not smaller.

let rec read_back x on x ≝
 match x with
 [ CCrumble b e ⇒ match e with
                  [ Epsilon ⇒ read_back_b b
                  | Snoc e1 s ⇒ match s with [ subst x' b1 ⇒ p_subst (read_back 〈b, e1〉) (psubst x' (read_back_b b1))]
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
(* purtroppo però, la chiamata ricorsiva sul bite non mi assicura che la dimensione diminuisca*)
(* suppongo che questo sia dovuto al fatto che un bite può a sua volta contenere un  *)
(* crumble la cui dimensione è arbitraria *)


let rec aux_read_back rbb e on e ≝
 match e with
 [ Epsilon ⇒ rbb
 | Snoc e1 s ⇒ match s with [ subst x' b1 ⇒ p_subst (aux_read_back rbb e1) (psubst x' (read_back_b b1))]
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
let rec read_back (n: nat) : Πc: Crumble. c_len c = n → pTerm ≝
 match n return λn.Πc: Crumble. c_len c = n → pTerm with
 [ O ⇒ λc. match c return λc.c_len c = O → pTerm with
          [ CCrumble b e ⇒ λp.(read_back_b b)]
 | S m ⇒ λc. match c return λc.c_len c = S m → pTerm with
    [ CCrumble b e ⇒ match e with
        [ Epsilon ⇒  λabs.(read_back_b b)
        | Snoc e1 s ⇒ λp.match s with [ subst x' b1 ⇒ p_subst (read_back m 〈b, e_pop e〉 ?) (psubst x' (read_back_b b1))]
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
(* annidati ney bite al primo membro. In questo modo dovrei riuscire ad evitare l'errore perché *)
(* la suddetta definizione mi garantirebbe la diminuzione della taglia del *)
(* termine ad ogni chiamata ricorsiva. Ma quando vado a fornire la dimostrazione *)
(* mi si solleva un altro problema: come faccio ad esprimere il fatto che e = Snoc e1 s ?
*)
(*

let rec read_back (n: nat) : Πc: Crumble. c_size c = n → pTerm ≝
 match n return λn.Πc: Crumble. c_size c = n → pTerm with
 [ O ⇒ λc.λabs. ?
 | S m ⇒ λc. match c return λc.c_size c = S m → pTerm with
    [ CCrumble b e ⇒ match e return λe. c_size (CCrumble b e) = S m → pTerm with

        [ Epsilon ⇒  λp.(read_back_b (m) b (?))
        | Snoc e1 s ⇒ match s return λs. c_size (CCrumble b (Snoc e1 s)) = S m → pTerm with [ subst x' b1 ⇒ λp. p_subst (read_back ((S m) - (c_size_s [x'← b1])) 〈b, e1〉 ?) (psubst x' (read_back_b (m - c_size 〈b, e1〉) b1 ?))]
        ]
    ]
 ]


and

read_back_b (n: nat): Πb: Bite. c_size_b b = n → pTerm ≝
 match n return λn.Πb: Bite. c_size_b b = n → pTerm with
 [ O ⇒ λb. match b return λb. c_size_b b = O → pTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λabs. ?
    ]
 | S m ⇒ λb. match b return λb. c_size_b b = S m → pTerm with
    [ CValue v ⇒ λp. read_back_v (c_size_v v) v (refl …)
    | AppValue v w ⇒ λp. appl (read_back_v (c_size_v v) v (refl …)) (read_back_v (c_size_v w) w (refl …))
    ]
 ]

and

read_back_v (n: nat): Πv: Value. c_size_v v = n → pTerm≝
 match n return λn.Πv: Value. c_size_v v = n → pTerm with
 [ O ⇒ λv. match v return λv. c_size_v v = O → pTerm with
     [ var x ⇒ λp.val_to_term (pvar x)
     | lambda x c ⇒ λp.val_to_term (abstr x (read_back (c_size c) c (refl …)))
     ]
 | S m ⇒ λv. match v return λv. c_size_v v = S m → pTerm with
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

definition ol ≝ λv. fst Value nat (overline v (fresh_var_tv v)).
definition ul ≝ λt. fst Crumble nat (underline_pTerm t (fresh_var_t t)).

lemma size_lemma:
 (∀t.∀n. c_size (fst  … (underline_pTerm t n)) ≤ 5 * (t_size t)) ∧
   (∀v.∀n. c_size_v (fst … (overline v n)) ≤ 5 * (v_size v)).

@pValueTerm_ind
[ #v #H #s normalize lapply (H s) cases (overline v s) #w #n normalize //
| #t1 #t2 cases t2
  [ #v2 cases t1
    [ #v1 normalize #H1 #H2 #s lapply (H1 s) cases (overline v1 s) #vv #n normalize
      #H1' lapply (H2 n) cases (overline v2 n) #ww #m normalize #H2'
      lapply (le_plus … H1' H2') -H1' -H2' #H
      normalize in H1'; <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      cut ((c_size_v vv+c_size_v ww+O)≤(S (S (S (S
       (v_size v1+v_size v2
        +(v_size v1+v_size v2
          +(v_size v1+v_size v2+(v_size v1+v_size v2+(v_size v1+v_size v2+O))))))))))
      [ @le_S @le_S @le_S @le_S //
      | -H #H @le_S_S @H
      ]
    | #u1 #u2 normalize #H1 #H2 #s lapply (H1 s) normalize
      change with (underline_pTerm (appl u1 u2) s)
       in match (match u2 in pTerm with [_⇒ ?]);
     cases (underline_pTerm (appl u1 u2) s)
      * #b #e #n normalize lapply (H2 n) cases (overline v2 n) #vv #mm
      normalize #H2' #H1' <(size_env_push e ?)
      whd in match (c_size_e ?);
      whd in match (c_size_s ?);
      lapply (le_plus … H1' H2') -H1' -H2'
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      cut ((((((t_size u1+t_size u2
        +(t_size u1+t_size u2
          +(t_size u1+t_size u2+(t_size u1+t_size u2+(t_size u1+t_size u2+O)))))))))
   +(v_size v2+(v_size v2+(v_size v2+(v_size v2+(v_size v2+O))))) = (t_size u1+t_size u2+v_size v2
              +(t_size u1+t_size u2+v_size v2
                +(t_size u1+t_size u2+v_size v2
                  +(t_size u1+t_size u2+v_size v2
                    +(t_size u1+t_size u2+v_size v2+O))))))[ //] #HH <HH
       #H @le_S_S @le_S_S @le_S_S @le_S @le_S
       cut (c_size_v vv+(c_size_e e+c_size_b b)=c_size_b b+c_size_e e+(c_size_v vv+O)) [//]
       #HHH >HHH @H
       ]
  | #u1 #u2 normalize #H1 #H2 #s lapply (H2 s)
    change with (underline_pTerm (appl u1 u2) ?)
      in match ( match u2 in pTerm with [_⇒ ?]);
    cases (underline_pTerm (appl u1 u2) s) * #b #e #n normalize
    lapply (H1 n) cases t1
    [ #v1 normalize cases (overline v1 n) #vv #m normalize
      >concat_epsilon_e <(size_env_push e  [νm←b])
      whd in match (c_size_e (Snoc e ?));
      whd in match (c_size_s ?);
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
      #H1' #H2'
      @le_S_S @le_S_S @le_S_S @le_S @le_S
      lapply (le_plus …H1' H2') -H1' -H2' #H
      cut (v_size v1+(v_size v1+(v_size v1+(v_size v1+(v_size v1+O))))
    +S
     (S
      (S
       (S
        (S
         (t_size u1+t_size u2
          +(t_size u1+t_size u2
            +(t_size u1+t_size u2+(t_size u1+t_size u2+(t_size u1+t_size u2+O)))))))))=
   (S
    (S
     (S
      (S
       (S (v_size v1+(t_size u1+t_size u2))
        +(v_size v1+(t_size u1+t_size u2)
          +(v_size v1+(t_size u1+t_size u2)
            +(v_size v1+(t_size u1+t_size u2)
              +(v_size v1+(t_size u1+t_size u2)+O))))))))))
   [ <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
     @eq_f @eq_f @eq_f @eq_f @eq_f //
   | #HH <HH >commutative_plus in match (c_size_e e+c_size_b b); @H
   ]
  | #r1 #r2 cases (underline_pTerm (appl r1 r2) (n)) * #b1 #e1 #n1 normalize
    >(size_env_concat …)
    <(size_env_push e  [νn1←b])
    <(size_env_push e1 [ν(S n1)←b1])
    whd in match (c_size_e (Snoc e ?));
    whd in match (c_size_e (Snoc e1 ?));
    whd in match (c_size_s ?);
    whd in match (c_size_s ?);
    #H1' #H2'
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    @le_S_S @le_S_S @le_S_S @le_S_S @le_S_S
    lapply (le_plus … H1' H2')
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    cut  (S
   (S
    (S
     (S
      (S
       (S
        (S
         (S
          (S
           (S
            (t_size r1+t_size r2
             +(t_size r1+t_size r2
               +(t_size r1+t_size r2
                 +(t_size r1+t_size r2+(t_size r1+t_size r2+O)))))))))
        +(t_size u1+t_size u2
          +(t_size u1+t_size u2
            +(t_size u1+t_size u2+(t_size u1+t_size u2+(t_size u1+t_size u2+O))))))))))=
  S
    (S
     (S
      (S
       (S
        (S
         (S
          (S
           (S
            (S (t_size r1+t_size r2+(t_size u1+t_size u2))
             +(t_size r1+t_size r2+(t_size u1+t_size u2)
               +(t_size r1+t_size r2+(t_size u1+t_size u2)
                 +(t_size r1+t_size r2+(t_size u1+t_size u2)
                   +(t_size r1+t_size r2+(t_size u1+t_size u2)+O))))))))))))))
   [@eq_f @eq_f @eq_f @eq_f @eq_f normalize //]
   #HH >HH #H
   cut (c_size_e e1+c_size_b b1+(c_size_e e+c_size_b b)=c_size_b b1+c_size_e e1+(c_size_b b+c_size_e e))
   [ // ] #Yee >Yee @H
   ]
 ]
| #x normalize //
| #p #v whd in match (overline ? ?);
  #H cut (t_size p+(t_size p+(t_size p+(t_size p+(t_size p+O))))≤
     (t_size p+S (t_size p+S (t_size p+S (t_size p+S (t_size p+O))))))
  [ <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm <plus_n_Sm
    <plus_n_Sm <plus_n_Sm <plus_n_Sm @le_S @le_S @le_S @le_S  //
  | #H2 #n normalize lapply (H n) cases (underline_pTerm p n) #c #n normalize -H #H @le_S_S  @(transitive_le … H H2)
] qed.
(*
lemma strong_fv_lemma:
 (∀c.∀x. free_occ_t x (read_back c) ≤ free_occ x c ) ∧
  (∀b.∀x. free_occ_t x (read_back_b b) ≤ free_occ_b x b ) ∧
   (∀e.∀b.∀x. (free_occ_t x (read_back_b b) ≤ free_occ_b x b) → free_occ_t x (read_back 〈b, e〉) ≤ free_occ x 〈b, e〉) ∧
    (∀v.∀x. free_occ_t x (read_back_v v) ≤ free_occ_val x v) ∧
     (∀s.∀b.∀e.∀x. (free_occ_t x (read_back 〈b, e〉) ≤ free_occ x 〈b, e〉) →  free_occ_t x (read_back 〈b, (Snoc e s)〉) ≤ free_occ x 〈b, (Snoc e s)〉).

@Crumble_mutual_ind
[ #b #e #H1 #H2 #x lapply (H1 x) lapply (H2 b x) #H @H
| #v #H assumption
| #v #w #H1 #H2 #x whd in match (read_back_b ?);
  whd in match (free_occ_t ? ?);
  whd in match (free_occ_b ? ?); /2/
| #z #x //
| #z #c #H #x whd in match (read_back_v ?);
  whd in match (free_occ_val ? ?);
  lapply (H x) cases c #b #e
  whd in match (match ?  in Crumble with [_⇒ ?]);
  whd in match (free_occ_t x (val_to_term ?));
  cases veqb //
| #b #x
 whd in match (read_back 〈b, Epsilon〉);
 whd in match (free_occ x 〈b, Epsilon〉);
 whd in match (free_occ_e x Epsilon);
 whd in match (domb_e x Epsilon); >if_f //
| #e #s #H1 #H2 #b #x #H @(H2 … (H1 … H))
| #y #b' #H1 #b #e #x #H2
  change with (p_subst (aux_read_back (read_back_b b) e) (psubst y (read_back_b b')))
    in match (read_back 〈b, Snoc e [y←b']〉);
  change with (pi1 pTerm ? (p_subst_sig ? ? ? ? ?))
    in match (p_subst ? ?);
  whd in match (match ? in pSubst  with [_⇒ ?]);
  whd in match (match ? in pSubst  with [_⇒ ?]);
  cut (veqb x y = true ∨ veqb x y = false) // * #Hxy
  [ elim (veqb_true_to_eq x y) #Heq #_ lapply (Heq Hxy) -Heq #Heq destruct
    @sigma_prop_gen #z #z_def * #_ #z_prop >z_prop
    >veqb_true >if_t
    whd in match (free_occ y ?);
    whd in match (domb_e ? ?);
    whd in match (free_occ_e ??);
    whd in match (match ?  in Substitution with [_⇒ ?]);
    whd in match (free_occ_s ??);
    >veqb_true >if_t >if_t
*)
lemma fv_lemma:
 (∀c.∀x. fvb_t x (read_back c) = true → fvb x c = true) ∧
  (∀b.∀x. fvb_t x (read_back_b b) = true → fvb_b x b = true ) ∧
   (∀e.∀b.∀x. (fvb_t x (read_back_b b)  = true → fvb_b x b = true) → fvb_t x (read_back 〈b, e〉) = true → fvb x 〈b, e〉  = true ) ∧
    (∀v.∀x. fvb_t x (read_back_v v) = true → fvb_v x v = true) ∧
     (∀s.∀b.∀e.∀x. (fvb_t x (read_back 〈b, e〉) = true → fvb x 〈b, e〉 = true ) →  fvb_t x (read_back 〈b, (Snoc e s)〉)=true → fvb x 〈b, (Snoc e s)〉=true).

@Crumble_mutual_ind
[ #b #e #H1 #H2 #x lapply (H1 x) lapply (H2 b x) #H @H
| #v #H assumption
| #v #w #H1 #H2 #x #H normalize in H;
  change with (appl (read_back_v v) (read_back_v w)) in match (read_back_b ?);
  change with (orb ? ?) in match (if ? then ? else ?) in H;
  whd in match (fvb_t ? ?);
  whd in match (free_occ_t ? ?);
  cut (fvb_t x (read_back_v v)=true ∨ fvb_t x (read_back_v w)=true)
   [ normalize lapply (gtb_O_true … H) #He elim He #j -He
     cases (free_occ_t x (read_back_v v))
     cases (free_occ_t x (read_back_v w))
     [ normalize #abs destruct
     | 2,3,4:  normalize /2/
     ]
   | * #Hrb  change with (fvb_v x v ∨ ?) in match (fvb_b ? ?);
     [ >(H1 x Hrb) //
     | >(H2 x Hrb) /2/
     ]
   ]
| #x #y normalize cases (veqb y x) normalize /2/
| #x #c cases c #b #e normalize #H #y lapply (H y) >(veqb_comm y x) elim (veqb x y) normalize
 [ #Hinutile  // | #Hutile @Hutile]
| #b #x normalize #H #H1 lapply (H H1) #H2 >H2 normalize //
| #e #s cases s #y #b' #H1 #H2 #b #x #H3 lapply (H1 b x) lapply (H2 b e x) #H1' #H2'
  lapply (H2' H3) #H4 lapply(H1' H4) -H1' normalize @sigma_prop_gen #z #_ * #_ #z_prop >z_prop
  <veqb_simm cut (veqb x y=true ∨ veqb x y = false) // * #Htf >Htf normalize
  #Hue #Hyee @(Hue Hyee)
| #y #b #H #b' #e #x
   cases y #ny lapply (H x) #Hx #H1
  whd in match (fvb ? ?); change with (orb ? ?) in match ( if ? then ? else ?);
  change with (aux_read_back ? ?) in match (read_back 〈b',Snoc e [νny←b]〉);
  change with (p_subst (aux_read_back (read_back_b b') e) ?)
    in match (aux_read_back (read_back_b b') (Snoc e [νny←b]));
  change with (pi1 … (p_subst_sig ? ? ? ? ?))
    in match (p_subst (aux_read_back (read_back_b b') e) (psubst (νny) (read_back_b b)));
  @sigma_prop_gen #z #_ * #_ #z_prop
  change with (gtb ? ?) in match (fvb_t ? ?);
  change with (gtb ? ?) in match (fvb_t x z);
  normalize in match (fvb ? ?);
  >(z_prop x)
   whd in match (match ? in pSubst with [ _ ⇒ ? ]);
    whd in match (match ? in pSubst with [ _ ⇒ ? ]);
   change with (read_back 〈b', e〉) in match (aux_read_back (read_back_b b') e);
   change with (gtb (free_occ_t y (read_back_b b)) 0) in match (fvb_t y (read_back_b b)) in Hx;
   change with (gtb (free_occ_t y (read_back 〈b',e〉)) 0) in match (fvb_t y (read_back 〈b',e〉)) in H1;
   whd in match (domb_e ? ?); whd in match (fvb_e ? ?);
   lapply (H x) lapply H1;
   change with (gtb ? ?) in match (fvb_t ? ?);
   change with (gtb ? ?) in match (fvb_t x (read_back_b b));
   cases (free_occ_t x (read_back_b b)) cases (free_occ_t x (read_back 〈b',e〉))
   [ normalize cut ( free_occ_t (νny) (aux_read_back (read_back_b b') e)*O+O=0)
     [ cases  (free_occ_t (νny) (aux_read_back (read_back_b b') e)) //
     | #H0 >H0 >if_monotone whd in match (gtb 0 0); #abs #_ #abs destruct
     ]
   |  #n #Hyess normalize in Hyess; <veqb_simm cut (veqb x (νny)=true ∨ veqb x (νny)=false) // * #Htf
     [ >Htf normalize >if_then_false_else_false >if_then_false_else_false
       normalize >times_O normalize #_ #abs destruct
     | change with (orb ? ?) in match (if veqb x (νny) then true else domb_e x e);
       change with (orb ? ?) in match (if (fvb_e (νny) e∧¬veqb x (νny)) then true else fvb_b x b);
       >Htf change with (domb_e x e) in match (false∨domb_e x e);
       change with true in match (¬false);
       normalize >times_O normalize #_
       change with (notb ?) in match (if domb_e x e then false else true);
       change with (andb ? ?) in match (if fvb_b x b' then (¬domb_e x e) else false);
       >if_then_true_else_false
       change with (orb ? ?) in match (if fvb_e (νny) e then true else fvb_b x b);
       change with (orb ? ?) in match (if ? then ? else ?); #_
       change with (notb ?) in match (if domb_e x e then false else true) in Hyess;
       change with (andb ? ?) in match (if fvb_b x b' then (¬domb_e x e) else false) in Hyess;
       change with (orb ? ?) in match (if ?then ? else ?)in Hyess;
       cut ((fvb_b x b'∧¬domb_e x e∨fvb_e x e)=true)
       [ @Hyess //
       | -Hyess #H4
         cut ((fvb_b x b'∧¬domb_e x e)=true∨fvb_e x e=true)
         [ lapply H4 cases fvb_b cases fvb_e cases domb_e
           normalize /2/
         | * -H4 #H4 >H4 normalize //
         ]
       ]
     ]
   | normalize #H3 #H_ #H5 >H5 // >if_monotone >if_monotone #_ //
   | #n #m normalize #_ #H5 >H5 // >if_monotone >if_monotone #_ //
   ]
] qed.


(*
lemma p_subst_distro:
 (∀t.∀x, t'. fresh_var_t (p_subst t (psubst (νx) t')) ≤
  max (fresh_var_t t) (fresh_var_t t')) ∧
 ∀v. (∀x, t'. fresh_var_t (p_subst (val_to_term v) (psubst (νx) t')) ≤
  max (fresh_var_tv v) (fresh_var_t t')).

@pValueTerm_ind
[ #v #H cut (∀v. fresh_var_tv v=fresh_var_t (val_to_term v)) //
| #t1 #t2 #H1 #H2 #x #t' >p_subst_distro
  change with (max (fresh_var_t (p_subst t1 (psubst (νx) t'))) (fresh_var_t (p_subst t2 (psubst (νx) t'))))
    in match (fresh_var_t ?);
  cut (max (fresh_var_t (p_subst t1 (psubst (νx) t')))
           (fresh_var_t (p_subst t2 (psubst (νx) t')))
       ≤ max (max (fresh_var_t t1) (fresh_var_t t'))
             (max (fresh_var_t t2) (fresh_var_t t')))
  [ @(to_max)
    [ @(le_le_max …) @H1
    | >max_comm @(le_le_max …) @H2
    ]
  |#H change with (max (fresh_var_t t1) (fresh_var_t t2)) in match (fresh_var_t (appl t1 t2));
  <max_fact @H
  ]
| #x #ny #t' cases x #nx cut (veqb (νnx) (νny)=true ∨ veqb (νnx) (νny)=false) // *
  #Htf
  [ lapply (veqb_true_to_eq (νnx) (νny)) * #Heq #_ lapply (Heq Htf) destruct
    -Htf -Heq #Heq destruct >atomic_subst >max_comm
    cut (fresh_var_t t'≤ max ny (fresh_var_t t'))
    [ >max_comm @le_n_max_n
    | #H @(le_le_max …) //
    ]
  | >no_subst //
  ]
| #t #x #H #y #t' lapply (H y t') -H #H
  change with (pi1 … (p_subst_sig ? ? ? ?)) in match ( p_subst ? ?);
*)
(*
lemma fresh_var_lemma:
 (∀c. fresh_var_t (read_back c) ≤ fresh_var c) ∧
  (∀b. fresh_var_t (read_back_b b) ≤ fresh_var_b b ) ∧
   (∀e.∀b. (fresh_var_t (read_back_b b) ≤ fresh_var_b b) → fresh_var_t (read_back 〈b, e〉) ≤ fresh_var 〈b, e〉) ∧
    (∀v. fresh_var_t (read_back_v v) ≤ fresh_var_v v) ∧
     (∀s.∀b.∀e. (fresh_var_t (read_back 〈b, e〉) ≤ fresh_var 〈b, e〉) →  fresh_var_t (read_back 〈b, (Snoc e s)〉) ≤ fresh_var 〈b, (Snoc e s)〉).

@Crumble_mutual_ind
[ #b #e #H #H1 @(H1 b H)
| #v #H whd in match (fresh_var_b (CValue v)); whd in match (read_back_b ?); @H
| #v #w #H1 #H2 whd in match (fresh_var_b (AppValue ? ?));
  change with (max (fresh_var_v ?) (fresh_var_v ?))
   in match (if leb (fresh_var_v v) (fresh_var_v w) then fresh_var_v w else fresh_var_v v);
  whd in match (read_back_b ?);
  change with (max (fresh_var_t (read_back_v v)) (fresh_var_t (read_back_v w))) in match (fresh_var_t ?);
  @(to_max … )
  [ whd in match (max ? ?);
    cut (leb (fresh_var_v v) (fresh_var_v w)=true ∨ leb (fresh_var_v v) (fresh_var_v w)=false) //
    * #Htf >Htf
    [ change with (fresh_var_v w) in match (if true then (fresh_var_v w) else ?);
      lapply (leb_true_to_le … Htf) -Htf #H @(transitive_le … H1 H)
    | change with (fresh_var_v v) in match (if false then ? else (fresh_var_v v));
      @H1
    ]
  | whd in match (max ? ?);
    cut (leb (fresh_var_v v) (fresh_var_v w)=true ∨ leb (fresh_var_v v) (fresh_var_v w)=false) //
    * #Htf >Htf
    [ change with (fresh_var_v w) in match (if true then (fresh_var_v w) else ?);
      @H2
    | change with (fresh_var_v v) in match (if false then ? else (fresh_var_v v));
      lapply (leb_false_to_not_le … Htf) -Htf #H lapply (not_le_to_lt … H) -H #H
      lapply (lt_to_le … H) -H #H @(transitive_le … H2 H)
    ]
  ]
| #x cases x #nx normalize //
| #x cases x #nx #c cases c #b #e normalize
  cases (pi1 ℕ (λn:ℕ.∀x0:ℕ.1≤free_occ_t (νx0) (aux_read_back (read_back_b b) e)→S x0≤n)
  (fresh_var_t_Sig (aux_read_back (read_back_b b) e)))
  change with (fresh_var 〈b, e〉) in match ((if leb (fresh_var_b b) (fresh_var_e e) 
         then fresh_var_e e 
         else fresh_var_b b));
  [ #H whd in match (match ? in nat with [ _ ⇒ ? ]);
    change with (S nx) in match (if false then O else S nx );
    change with (leb (S nx) ?) in match (match fresh_var 〈b,e〉 in nat return λ_:ℕ.bool with 
        [O⇒false|S (q:ℕ)⇒leb nx q]);
    cut (leb (S nx) (fresh_var 〈b, e〉)=true ∨ leb (S nx) (fresh_var 〈b, e〉)=false) //
    | #k #H change with (leb (S nx) ?) in match (match fresh_var 〈b,e〉 in nat with 
    [O⇒false|S (q:ℕ)⇒leb nx q]);
    change with (leb (S nx) (S k)) in match (match (S k) in nat with 
    [O⇒false|S (q:ℕ)⇒leb nx q]);
    change with (max ? ?) in match (if ? then ? else ?);
    change with (max (S nx) (fresh_var 〈b, e〉)) in match (if (leb (S nx) (fresh_var ?)) then ? else ?);
    @(to_max …)
    change with (if (leb (S nx) (fresh_var 〈b, e〉)) then (fresh_var 〈b, e〉) else (S nx)) in match (max (S nx) ?);
    cut (leb (S nx) (fresh_var 〈b,e〉)=true ∨ leb (S nx) (fresh_var 〈b,e〉)=false) // * #Htf >Htf
    [ lapply (leb_true_to_le … Htf) -Htf #Hle
      change with (fresh_var 〈b,e〉) in match (if true then fresh_var 〈b,e〉 else S nx ); //
    | 3: normalize
    | lapply(leb_false_to_not_le … Htf) -Htf #Hnle
      lapply (not_le_to_lt … Hnle) -Hnle #Hlt
      lapply (lt_to_le … Hlt) -Hlt #Hle
      change with (S nx) in match (if ? then ? else ?);
      @(transitive_le … H Hle)
    ]
  ]
| #b #H whd in match (read_back ?); whd in match (fresh_var ?);
  whd in match (fresh_var_e Epsilon); lapply H cases (fresh_var_b …)
  normalize //
| #e #s #H1 #H2 #b #H @(H2 … (H1 … H))
| * #x #b' #H #b #e #H1 lapply H1
  change with (max ? ?) in match (fresh_var 〈b, e〉);
  change with (max ? ?) in match (fresh_var 〈b, Snoc ? ?〉);
  change with (max ? ?) in match (fresh_var_e (Snoc e ?));
  change with (max ? ?) in match (fresh_var_s ?);
  whd in match (read_back ?);
  change with (aux_read_back ? ?) in match (read_back ?);
  change with (p_subst ? ?) in match (aux_read_back ? (Snoc ? ?));
  normalize
  @sigma_prop_gen #z #z_def #z_prop
  change with (max ? ?) in match (if ? then ? else ?);
  @sigma_prop_gen #k #k_def #k_prop #Hz
  change with (max ? (max (fresh_var_e e) (max (S x) (fresh_var_b b'))))
    in match (if ? then ? else ?);


  cut (k ≤ z)
  [ 2:  cut (max (fresh_var_b b) (fresh_var_e e) ≤
        max (fresh_var_b b) (max (fresh_var_e e) (max (S x) (fresh_var_b b'))))
    [ //]
    #H1 #H2 @(transitive_le … H2 (transitive_le … Hz H1))
  ]
  lapply ((z_prop k))

            #Hf @(transitive_le …
  whd in match (read_back_v ?); lapply H cases c #b #e
  -H #H whd in match (match ? in Crumble with [ _ ⇒ ? ]);
*)


lemma interval_lemma2: ∀e. ∀ (y:Variable).∀ b, n. (interval_dom (Snoc e [y←b]) n) → n ≤ match y with [variable ny ⇒ ny].
#e #y #b #n cases y #ny normalize #H @(H ny) lapply (neqb_iff_eq … ny ny) * #_
#Hscontata >Hscontata // qed.

lemma fresh_var_occ:
 (∀t. ∀x. x ≥ (fresh_var_t t) → free_occ_t (νx) t = 0) ∧
  (∀v. ∀x. x ≥(fresh_var_tv v) →  free_occ_v (νx) v = 0).

@pValueTerm_ind
[ #v #H #x @H
| #t1 #t2 #H1 #H2 #x #H change with (max ? ?) in match (fresh_var_t ?) in H;
  cut (max (pi1 ℕ (λn:ℕ.∀x0:ℕ.free_occ_t (νx0) t1≥1→n>x0) (fresh_var_t_Sig t1))
    (pi1 ℕ (λn:ℕ.∀x0:ℕ.free_occ_t (νx0) t2≥1→n>x0) (fresh_var_t_Sig t2))≤x) //
  -H #H lapply(le_maxl … H) #H11 lapply(le_maxr … H) #H22 -H
  cut (x ≥pi1 ℕ (λn:ℕ.∀x0:ℕ.free_occ_t (νx0) t1≥1→n>x0) (fresh_var_t_Sig t1)) // -H11 #H11
  cut (x ≥pi1 ℕ (λn:ℕ.∀x0:ℕ.free_occ_t (νx0) t2≥1→n>x0) (fresh_var_t_Sig t2)) // -H22 #H22
  lapply (H1 … H11) lapply (H2 x H22) -H1 -H11 -H2 -H22 #H2 #H1
  change with (plus ? ?) in match (free_occ_t ? ?); //
| #x cases x #nx normalize #y #H cut (neqb y nx = true ∨ neqb y nx = false) // *
  #Htf [2: >Htf // | @False_ind lapply (neqb_iff_eq y nx) * #Heq #_ lapply (Heq Htf)
  -Htf -Heq #Heq destruct @(leq_Sx_x_false nx H)]
| #t #x #HI #y whd in match (fresh_var_tv ?); whd in match (fresh_var_tv_Sig ?);
  cases x #nx normalize
  change with (leb (S nx) ?) in match (match pi1 ℕ (λn:ℕ.∀x00:ℕ.1≤free_occ_t (νx00) t→S x00≤n) (fresh_var_t_Sig t)
        in nat
        return λ_:ℕ.bool
        with 
       [O⇒false|S (q:ℕ)⇒leb nx q]);
  change with (max ? ?) in match (if ? then ? else ?);
  #H lapply(le_maxl … H) #H1 lapply(le_maxr … H) #H2 -H
  cut (y≥(pi1 ℕ (λn:ℕ.∀x00:ℕ.1≤free_occ_t (νx00) t→S x00≤n) (fresh_var_t_Sig t))) //
  -H2 #H2 >(HI y H2) cases (neqb y nx) //
] qed.
(*
lemma p_subst_lemma: ∀t, t', ny. fresh_var_t t ≤ ny → p_subst t (psubst (νny) t')=t.
#t #t' #ny #H
change with (pi1 … (p_subst_sig (t_size t) ? t ?)) in match (p_subst ??);
@(nat_ind … (t_size t));
normalize () t @sigma_prop_gen cases (t_size t) #z #z_def * #_ #z_prop
*)

lemma fresh_var_abstr: ∀x,t,ny. fresh_var_t (val_to_term (abstr x t)) ≤ ny → veqb x (νny) =false.
#x #t #ny cut (veqb x (νny)=true ∨ veqb x (νny)=false) // * #Hveqb [2: //]
lapply (veqb_true_to_eq x (νny)) * #Heq #_ lapply (Heq Hveqb) -Hveqb -Heq #Heq
destruct >veqb_true normalize  change with (leb (S ny) ?) in match (match pi1 ℕ (λn:ℕ.∀x0:ℕ.1≤free_occ_t (νx0) t→S x0≤n) (fresh_var_t_Sig t)
         in nat
         return λ_:ℕ.bool
         with 
        [O⇒false|S (q:ℕ)⇒leb ny q])  ;
        change with (max ? ?) in match (if ? then ? else ?);
#H lapply(le_maxl … H) #abs -H @False_ind /2/ qed.

lemma aux_read_back1: ∀t1, t2, e. aux_read_back (appl t1 t2) e = appl (aux_read_back t1 e) (aux_read_back t2 e).
#t1 #t2 #e @(Environment_simple_ind2 … e)
[ normalize //
| #e' #s cases s #x #b
  change with (p_subst (aux_read_back (appl t1 t2) e') (psubst x (read_back_b b)))
  in match (aux_read_back (appl t1 t2) (Snoc e' [x←b]));
  change with (p_subst (aux_read_back t1 e') (psubst x (read_back_b b)))
  in match (aux_read_back t1 (Snoc e' [x←b]));
  change with (p_subst (aux_read_back t2 e') (psubst x (read_back_b b)))
  in match (aux_read_back t2 (Snoc e' [x←b]));
  #HI >HI @p_subst_distro
] qed.

lemma push_lemma_aux: ∀t, e, s. aux_read_back t (Snoc e s) = aux_read_back (aux_read_back t e) (Snoc Epsilon s).
#t #e @(Environment_simple_ind2 … e)
[ #s normalize in match ((aux_read_back t Epsilon)); //
| #e' #s' #H #s lapply (H s')
 cases s' #y #b #H' >H' /2/
]. qed.


lemma push_lemma:
 ∀t, e, s. aux_read_back t (push e s) = aux_read_back (p_subst t match s with [subst x b ⇒ psubst x (read_back_b b) ]) e.
 #t #e @(Environment_simple_ind2 … e)

[ normalize #s cases s #x #b normalize //
| #e' #s' #H #s lapply (H s)
  normalize in match (push ? ?) in ⊢ (? → %);
  cases s #y #t
  normalize in match (match [y←t]  with 
    [subst (x:Variable)   (b:Bite)⇒psubst x (read_back_b b)]);
  #H' >(push_lemma_aux …) /2/
] qed.

lemma fresh_dom_e: ∀x, e. domb_e (νx) e =true → x ≤ fresh_var_e e.
#x #e @(Environment_simple_ind2 … e)
[ normalize #abs destruct
| #e' * * #ny #b normalize change with (leb (S ny) ?) in match (match fresh_var_b b in nat with 
                [O⇒false|S (q:ℕ)⇒leb ny q]);
  change with (max ? ?) in match (if leb ? ? then ? else ? );
  change with (max ? ?) in match (if leb (S ny) ? then ? else ? );
  cut (neqb x ny=true ∨ neqb x ny=false) // * #Htf >Htf
  [ >if_t lapply (neqb_iff_eq … x ny) * #Heq #_ lapply (Heq Htf) -Heq
    #Heq destruct #_ #_ >max_comm cut (ny ≤S ny) // #Hw
    cut (S ny≤max (max (S ny) (fresh_var_b b)) (fresh_var_e e'))
    [ /2/
    | #H @le_le_max cut (S ny ≤max (S ny) (fresh_var_b b))[ @le_n_max_n | #HH @le_le_max assumption]
    ]
  | >if_f #H #HH lapply (H HH) -H -HH #H @le_le_max assumption
  ]
qed.

corollary no_subst_corollary1: ∀ny.
 (∀t. fresh_var_t t ≤ ny → ∀t'. p_subst t (psubst (νny) t')=t).

lapply no_subst30 #Ht #ny #t #H #t' @Ht
whd in match (match ? in  pSubst with [_⇒?]);
lapply fresh_var_to_in *
#Ht1 #_ @Ht1 @H qed.

(*
il lemma seguente non è dimostrabile in questa formulazione perché la p_subst
effettua α-conversioni anche senza che avvenga la sostituzione,
l'uguaglianza fra un termine ed il suo sostituito è dunque vera se intesa come
equivalenza a meno di α-conversioni
*)

(*
lemma p_subst_lemma: ∀ny.
 (∀t. fresh_var_t t ≤ ny → ∀t'. p_subst t (psubst (νny) t')=t) ∧
  ∀v. fresh_var_tv v ≤ ny →∀t'. p_subst (val_to_term v) (psubst (νny) t')=(val_to_term v).

#ny @pValueTerm_ind
[ 3: #x #H #t' whd in match (p_subst_sig  ? ? ? ? );
  cut (∀gg.∀ tt. (pi1 pTerm
  (λu:pTerm
   .t_size u
    =(t_size (val_to_term (pvar x)))
     +((free_occ_t (νny) (val_to_term (pvar x)))*(t_size t'-1))
    ∧(∀z:Variable
      .free_occ_t z u
       =if match z in Variable return λ_:Variable.bool with 
             [variable (m1:ℕ)⇒neqb ny m1] 
        then (free_occ_t z (val_to_term (pvar x)))*(free_occ_t z t') 
        else (free_occ_t (νny) (val_to_term (pvar x)))*(free_occ_t z t')
                 +free_occ_t z (val_to_term (pvar x)) ))
 (match veqb (νny) x
 return λb. veqb (νny) x = b → 1 ≤ 1 →
    Σu: pTerm. ?
    with
     [ true ⇒ λH: veqb (νny) x = true.
        λp: 1 ≤ 1.
         «t', gg H p»
     | false ⇒ λH: veqb (νny) x = false.
        λp: 1 ≤ 1.
         «val_to_term (pvar x), tt H p»
     ] (refl bool (veqb (νny) x )) (le_n 1))) = val_to_term (pvar x))
     [2: #UU @UU]  #gg #tt
     lapply (fresh_var_occ) * #fv_occ #_
     cut (free_occ_t (νny) (val_to_term (pvar x))=0)
     [ @fv_occ //
     | cut (veqb (νny) x=true ∨ veqb (νny) x=false ) // *
     #Hveqb
     [ lapply (veqb_true_to_eq (νny) x) * #Heq #_
       lapply (Heq Hveqb) -Heq #Heq destruct #abs
       normalize in abs; normalize in Hveqb;>Hveqb in abs;
       #abs normalize in abs; destruct
     | >Hveqb in gg tt ⊢ %; normalize #_ #_ #_ //
     ]
   ]
| 4: #r #x #HI #H #t' whd in match (p_subst_sig  ? ? ? ? );
  whd in match (match ? in pSubst with [_ ⇒ ?]);
  whd in match (match ? in pSubst with [_ ⇒ ?]);
  cut (∀K.∀K1.∀K2. (pi1 pTerm   (λu:pTerm
   .t_size u
    =(t_size (val_to_term (abstr x r)))
     +(free_occ_t (νny) (val_to_term (abstr x r)))*(t_size t'-1)
    ∧(∀z:Variable
      .free_occ_t z u
       =if match z in Variable return λ_:Variable.bool with 
             [variable (m1:ℕ)⇒neqb ny m1] 
        then (free_occ_t z (val_to_term (abstr x r)))*(free_occ_t z t' )
        else (free_occ_t (νny) (val_to_term (abstr x r)))*(free_occ_t z t')
                 +(free_occ_t z (val_to_term (abstr x r))) ))
  (match veqb (νny) x return λb. veqb (νny) x = b → t_size (val_to_term (abstr x r)) ≤ S (t_size r) → Σu: pTerm. ?
      with
       [ true ⇒ λH:veqb (νny) x = true.λp:t_size (val_to_term (abstr x r)) ≤ S (t_size r). «(val_to_term (abstr x r)), K H p »
       | false ⇒ λH:veqb (νny) x = false. match fvb_t x t'return λb. fvb_t x  t' = b → t_size (val_to_term (abstr x r)) ≤ S (t_size r) → Σu: pTerm. ?
        with
         [ true ⇒ λHH:fvb_t x  t' = true. λp:t_size (val_to_term (abstr x r)) ≤ S (t_size r). let z ≝ (max (S ny) (max (S match x with [variable nx⇒ nx]) (max (fresh_var_t r) (fresh_var_t t'))))
                  in match (p_subst_sig (t_size r) (psubst x (val_to_term (pvar ν(z)))) r (le_n ?)) with
           [ mk_Sig a h ⇒ «(val_to_term (abstr (ν(z)) (pi1 … (p_subst_sig (t_size r) (psubst (νny) t') a (subst_aux_5 r x z a (t_size r) h p))))), K1 H HH p a h »]
         | false ⇒ λHH:fvb_t x  t' = false. λp. «(val_to_term (abstr x (pi1 … (p_subst_sig (t_size r) (psubst (νny) t') r (le_n ?))))), K2 H HH p»
         ] (refl …)
       ] (refl bool (veqb (νny) x)) (le_n (t_size (val_to_term (abstr x r)))))=val_to_term (abstr x r)))
       [2: #UU @UU] #K #K1 #K2
       lapply (fresh_var_occ) * #fv_occ #_
     cut (free_occ_t (νny) (val_to_term (abstr x r))=0)
     [@fv_occ //
     | lapply(fresh_var_abstr …H) #Hveqb  check veqb_comm lapply (veqb_comm x (νny)) #Hcomm <Hcomm in K K1 K2 ⊢ %;
        #K #K1 #K2 >Hveqb in K K1 K2 ⊢ %; lapply (fresh_var_abstr_decr x r) #Hm
        lapply (HI (transitive_le … Hm H)) -HI #HI  #K #K1 #K2
        cut (fvb_t x t'=true ∨ fvb_t x t'=false) // * #Hfvb_t >Hfvb_t in K K1 K2 ⊢ %;
        [ 2:  #K #K1 #K2 #FreeOcc normalize in HI; normalize @eq_f @eq_f @HI
        | #K #K1 #K2 #Hfo whd in match (pi1 …); normalize >HI
        change with (p_subst r (psubst (νny) t')) in match (p_subst_sig (t_size r) (psubst (νny) t') r
                                 (le_n (t_size r))); normalize in HI;
        cut (∀K. (pi1 pTerm
   (λu:pTerm
    .t_size u=t_size r+(free_occ_t (νny) r)*(t_size t'-1)
     ∧(∀z:Variable
       .free_occ_t z u
        =if match z in Variable return λ_:Variable.bool with 
              [variable (m1:ℕ)⇒neqb ny m1] 
         then (free_occ_t z r)*(free_occ_t z t') 
         else (free_occ_t (νny) r)*((free_occ_t z t')+(free_occ_t z r)) ))
   (p_subst_sig (t_size r) (psubst (νny) t') r (K (t_size r)))
   =r));


         >HI in K K1 K2 ⊢ %; normalize // check veqb_comm normalize #_ #_ #_ //
     ]




      >Hfv_occ in K K1 K2 ⊢ %;
*)


lemma stronger_aux_read_back3: ∀e, t.
  (∀x. (domb_e x e = true → fvb_t x t = false)) →
     aux_read_back t e = t.
@Environment_simple_ind2
[ #t #_ //
| #e * * #y #b #H #t lapply (H t) -H #HI #H
  change with (p_subst (aux_read_back t e) ?)
    in match (aux_read_back ? ?);
  >no_subst5
  [ 2: >HI
    [ >H // normalize >neqb_refl >if_t @refl ]
    #z #HH @H normalize >HH >if_monotone @refl
  ]
  @HI #z #HH @H normalize >HH >if_monotone @refl
] qed.

lemma aux_read_back3: ∀t, e, b.
  (fresh_var_t t ≤ b) →
   (interval_dom e b) → (*interval_dom ≝  λe, b. ∀x. domb_e (νx) e =true → b ≤ x.*)
     aux_read_back t e = t.

#t #e #b #H1 #H2 @stronger_aux_read_back3 * #x #H normalize in H2; lapply (H2 … H)
#HH cut (inb_t (νx) t=false)
[ lapply (transitive_le … H1 HH)
  lapply (fresh_var_to_in) * #Ht #_ @Ht ]
@bool_impl_inv2 lapply (fv_to_in_term) * #Ht #_ @Ht qed.

lemma aux_read_back4: ∀m,e.
 fresh_var_e e ≤ m →
  (aux_read_back (val_to_term (pvar νm)) e=val_to_term (pvar νm)).

#m #e @(Environment_simple_ind2 … e)
[ normalize //
| #e' * * #y #b #HI
  change with (max ? ?) in match (fresh_var_e ?); #Hm
  lapply (HI (le_maxl … Hm)) -HI #HI
  change with (p_subst ? ?)
    in match (aux_read_back ? ?);
  >HI @no_subst
  lapply (le_maxr … Hm)
  change with (max ? ?) in match (fresh_var_s ?);
  #Hm1 normalize
  cut (neqb y m=true ∨ neqb y m=false) // * // #Htf
  lapply (neqb_iff_eq y m) * #Heq #_
  lapply (Heq Htf) -Heq #Heq destruct
  lapply (le_maxl … Hm1) /2/
] qed.


(*
lemma basic_subst: ∀x, t. (p_subst (val_to_term (pvar x)) (psubst x t)) = t.
#x #t change with (pi1 … (p_subst_sig (t_size ?) ? ? ?)) in match (p_subst ??);
change with (1) in match (t_size (val_to_term (pvar x)));
whd in match (match ? in pSubst with [ _ ⇒ ? ]);
whd in match (match ? in pSubst with [ _ ⇒ ? ]);
whd in match (p_subst_sig 1 (psubst x t) (val_to_term (pvar x)) (le_n 1));
lapply(veqb_true x) #Ht cases (veqb x x)


lemma definetly_simple_concat_lemma:
 ∀e, s. (concat e (Snoc Epsilon s) = Snoc e s).

@Environment_simple_ind2
[ #s normalize //
| #e' #s' #H #s normalize >H //
] qed.

lemma abba_difficult_concat_lemma:
 ∀f, e, x, s. match s with [subst y b ⇒ match y with [variable nx ⇒ nx] ] ≥ S x → interval_dom e (S x) →
  aux_read_back (val_to_term (pvar νx)) (concat e (push f s)) =
   aux_read_back (val_to_term (pvar νx)) (concat e f).

#f

@(Environment_simple_ind2 … f)
[ #e #x * * #y #b #H #H1
  whd in match (concat ? ?);
  >banal_concat_lemma
  change with (p_subst ? ? )
    in match (aux_read_back ? (Snoc ? ?));
  >(aux_read_back3 … (S x))
  [ >(no_subst …  (νx) (νy) (read_back_b b)) //
    normalize cut (neqb y x = true ∨ neqb y x = false) // * #Htf
    [ lapply (neqb_iff_eq y x) * #Heq #_ lapply (Heq Htf) -Heq #Heq
      destruct @False_ind /2/
    | @Htf
    ]
  | @H1
  | //
  ]
| #e #s #H #f' #x * * #y #b
  whd in match (match ? in Substitution with [_ ⇒ ?]);
  whd in match (push ? ?);
  @(Environment_simple_ind2 … e)
  [ normalize #H1 #H2
    whd in match ((concat f' (Snoc (Snoc Epsilon [νy←b]) s)));

whd in match (concat e (Snoc Epsilon ?));
*)
lemma ultimate_concat_lemma:
  (∀x, f, e. interval_dom e (S x) →  (aux_read_back (val_to_term (pvar (νx)))
  (concat e f)
  =aux_read_back (val_to_term (pvar νx)) f)).

#x #f @(Environment_simple_ind2 … f)
[ #f #H whd in match (concat ? ?); >(aux_read_back3 … (S x)) //
| #e' * * #y #b #HI #e
  whd in match (concat e (Snoc e' ?));
  #Hdom (*fattibile*)
  change with (p_subst  ? ?) in match (aux_read_back (val_to_term (pvar (νx))) (Snoc (concat e e') ?));
  >HI //
] qed.

lemma ultra_concat_lemma:
  (∀f, x, e. domb_e x f = false →
    (∀z. domb_e z f = true → fvb_e z e = false) →
     (aux_read_back (val_to_term (pvar x)) (concat e f)
  =aux_read_back (val_to_term (pvar x)) e)).

@(Environment_simple_ind2)
[ #x #e #H #H1 >concat_e_epsilon
  whd in match (aux_read_back (val_to_term (pvar x)) Epsilon);
  lapply H
  @(Environment_simple_ind2 … e)
  [ //
  | #e' *
   * #y #b #HI #H'
    normalize in H'; //
  ]
| #f' * * #y #b  #HIe #x #e #H #H1
  whd in match (concat ? ?);
  change with (p_subst ? ?)
    in match (aux_read_back ? ?);
  >HIe
  [ 2: #w #Hw lapply (H1 w) normalize >Hw >if_monotone #HH >HH @refl
  | 3: lapply H normalize cases domb_e // >if_monotone #H @H
  ] >no_subst5 // lapply fv_lemma * * * * #_ #_ #He #_ #_
    cut (fvb (νy) 〈CValue (var x), e〉= false)
    [ lapply H lapply (H1 νy) normalize >neqb_refl >if_t #H' >H' //
      >if_then_true_else_false cases x #nx normalize >neq_simm cases neqb
      normalize [ #abs destruct ] //
    ]
    @bool_impl_inv2
    change with (read_back 〈CValue (var x), e〉)
      in match (aux_read_back ? ?);
      @He normalize cases x #n normalize cases neqb normalize //
] qed.

lemma pre_iper_concat_lemma: ∀e, t.
 (∀x. fvb_t x t = true → domb_e x e = false) →
 aux_read_back t e = t.

@Environment_simple_ind2
[ #t #H //
| #e * * #y #b #HI #t #H change with (p_subst ? ?) in match (aux_read_back ? ?);
  >HI [ 2: #z #Hz lapply (H z Hz) normalize cases domb_e // >if_monotone #abs
  destruct ] @no_subst5 lapply (H νy) cases fvb_t // normalize >neqb_refl
  >if_t #H @H @refl
] qed.

lemma iper_concat_lemma: ∀f, e, x.
  domb_e x e = false →
  (aux_read_back (val_to_term (pvar x)) (concat e f)
  =aux_read_back (val_to_term (pvar x)) f).
@Environment_simple_ind2
[ #e #x #H >concat_e_epsilon normalize >pre_iper_concat_lemma //
  #z normalize cut (veqb z x = true ∨ veqb z x = false) // * #Hzx >Hzx normalize
  [ #_ elim (veqb_true_to_eq … z x) #Heq #_ lapply (Heq Hzx) -Heq #Heq destruct
    @H ] #abs destruct
| #f * #y #b #HI #e #x #H
  whd in match (concat ? ?);
  change with (p_subst ? ?) in match (aux_read_back ? ?);
  change with (p_subst ? ?) in match (aux_read_back ? (Snoc ? ?)); >HI //
] qed.

include "environments.ma".
(*
lemma iper_concat_lemma:
 ∀f, m, n, e, b, b1.
  fresh_var_e e ≤ m → fresh_var_b b ≤ m →
   fresh_var_e f ≤ n → fresh_var_b b1 ≤ n →
    interval_dom e n →  n≤m →
   ((aux_read_back (val_to_term (pvar νm))
    (concat (push e [ν(S m)←b])(push f [(νm)←b1]))
    =aux_read_back (val_to_term (pvar νm)) (push f [(νm)←b1]))).

@(Environment_simple_ind2)

[ #m #n #e #b #b1
  whd in match (push Epsilon ?);
  whd in match (concat ? ?);
  >concat_e_epsilon
  #Hfve #Hfvb #Hfvf #Hfvb1 #Hie #Hnm
  change with (p_subst ? ?) in match (aux_read_back ? (Snoc (push e ?) ?));
  change with (read_back 〈 CValue (var ?), push e ?〉)
    in match ((aux_read_back (val_to_term (pvar νm)) (push e ?)));
  lapply fv_lemma * * * * #Hc #Hb #He #Hv #_
  lapply (Hc 〈CValue (var νm),(push e [νm←b1])〉 ν(S m)) #Hfv
  whd in match (read_back ?) in Hfv ⊢ %;
  whd in match (read_back_b ?);
  cut (fvb (ν(S m)) 〈CValue (var (νm)),(push e [νm←b1])〉=false → fvb_t (ν(S m)) (aux_read_back (read_back_b (CValue (var νm))) (push e [νm←b1]))=false)
  [ lapply Hfv cases fvb_t cases fvb // #Ht #_ >Ht //
  | -Hfv #Hfv
    cut (fvb (ν(S m)) 〈CValue (var νm),(push e [νm←b1])〉=false)
    [ change with (((fvb_b ? ?) ∧ ¬(domb_e ? ?)) ∨ fvb_e ? ?)
       in match (fvb ? ?);
      change with (neqb ? ?) in match (fvb_b (ν (S m)) (CValue (var (νm))));
      cut (neqb (S m) m =false) [//] #Hf >Hf
      change with (fvb_e (ν(S m)) (push e [νm←b1])=false) -Hf
      cut (inb_e (ν (S m)) (push e [νm←b1]) = false)
      [ lapply (fresh_var_to_in_crumble) * * * * #_ #_ #Hfvtoin #_ #_
      | #Hin lapply fv_to_in_crumble * * * * #_ #_ #Hine #_ #_
        lapply (Hine (push e [νm←b1]) ν(S m)) -Hine #Hinf
        cut (inb_e (ν(S m)) (push e [νm←b1])=false → fvb_e (ν(S m)) (push e [νm←b1])=false)
        [ lapply Hinf cases fvb_e cases inb_e // #Ht >Ht //
        | -Hinf #Hinf >Hinf //
        ]
      ] @Hfvtoin <fresh_var_push
      change with (max ? (max ? ?)) in match (fresh_var_e ?);
      @to_max
      [ @(le_S … Hfve)
      | @to_max // @(le_S … (transitive_le … Hfvb1 Hnm))
      ]
    | #HH whd in match (read_back_b ?) in Hfv; lapply Hfv
      letin t ≝ ((val_to_term (pvar νm)))
      letin z ≝ (aux_read_back t (push e [νm←b1])) -Hfv #Hfv
      lapply (Hfv HH) -Hfv #Hfv
      lapply no_subst5 #Hnos1 >Hnos1 @Hfv
    ]
  ]
| #e' * * #y #b' #HI #f #b #b1
  change with (max ? (max ? ?)) in match (fresh_var_e (Snoc ? ?));
  #H1 #H2 #H3 #H4 #H5 #H6
  whd in match (push (Snoc ? ?) ?);
  whd in match (concat ? ?);
  change with (p_subst ? ?) in match (aux_read_back ? (Snoc (concat ? ?) ?));
  >(HI … (le_maxl … H1) H2 H3 H4 (interval_lemma … H5) H6)
  lapply no_subst5 #Hns1 @Hns1
  cut  (fvb_t (νy) (aux_read_back (val_to_term (pvar νm)) (push f [νm←b1]))
        =true ∨
        fvb_t (νy) (aux_read_back (val_to_term (pvar νm)) (push f [νm←b1]))
        =false) // * #Htf //
  @False_ind lapply fv_lemma * * * * #Hc #Hb #He #Hv #Hs
  lapply Htf
  change with (read_back 〈CValue (var νm), (push f [νm←b1])〉)
  in match (aux_read_back ? ?);
  #Htf' lapply (Hc … Htf') normalize
  cut ((neqb y m=false) ∧ (fvb_b (νy) b1=false) ∧ (inb_e (νy) f=false))
  [ %
    [ %
      [ lapply (le_maxl … (le_maxr … H1))
        cut (neqb y m = true ∨ neqb y m = false) // * #Htf //
        lapply (neqb_iff_eq y m) * #Heq #_ lapply (Heq Htf) -Heq #Heq
        >Heq /2/
      | lapply (H5 y) normalize >neqb_refl >if_t lapply H4
        lapply fresh_var_to_in_crumble * * * * #_ #Hfvb #_ #_ #_
        #Ht1 #Ht2
        lapply fv_to_in_crumble * * * * #_ #Hb' #_ #_ #_
        lapply (Hb' b1 (νy)) -Hb' #Hb'
        cut (inb_b (νy) b1=false → fvb_b (νy) b1=false)
        [ lapply Hb' cases fvb_b cases inb_b // #H #_ >H //
        | -Hb' #Hb' >Hb' // @Hfvb cut (n≤y) [@Ht2 //] -Ht2 #Ht2
          @(transitive_le … Ht1 Ht2)
        ]
      ]
    | lapply (H5 y) normalize >neqb_refl >if_t
      #Hny cut (n≤y) [ @Hny //] -Hny #Hny
      cut (fresh_var_e f≤ y)
      [ @(transitive_le … H3 Hny)
      | lapply fv_to_in_crumble * * * * #_ #_ #He' #_ #_
        lapply (He' f (νy)) -He' #He'
        lapply fresh_var_to_in_crumble * * * * #_ #_ #He'' #_ #_
        @He'' @Hfve
      ]
    ]
  ] * * #Hneqb >Hneqb >if_f #Hfvb1
    @(Environment_simple_ind2 … f)
    [ normalize >Hfvb1 #_ #abs destruct
    | #f' * #g #t #HI' whd in match (push ? ?);
      change with (((fvb_e (νy) ?) ∧ (¬ veqb (νy) g)) ∨ fvb_b (νy) t)
        in match (fvb_e (νy) (Snoc (push ? [νm ← b1]) [g←t]));
      change with (((fvb_e (νy) f') ∧ (¬ veqb (νy) g)) ∨ fvb_b (νy) t)
        in match (fvb_e (νy) (Snoc f' [g←t]));
      #Hnonso
      cut (inb_b (νy) t =false)
      [ cut (inb_b (νy) t =true ∨ inb_b (νy) t =false) // * #Ht //
        @False_ind lapply Hnonso normalize >Ht
        lapply fv_to_in_crumble * * * * #_ #Hbb #_ #_ #_
        normalize >if_monotone >if_monotone #abs destruct
      ]
      #Hinyt
      cut (fvb_b (νy) t =false)
      [ lapply fv_to_in_crumble * * * * #_ #Hb' #_ #_ #_
        lapply (Hb' t (νy)) -Hb' #Hb'
        cut (inb_b (νy) t=false → fvb_b (νy) t=false)
        [ lapply Hb' cases inb_b cases fvb_b // #H >H // ]
        -Hb'#Hb' @Hb' assumption
      ]
      #Hfvt lapply Hnonso -Hnonso >Hfvt
      #Hdino #Hsauri @HI'
      [ lapply Hdino normalize cases inb_b
        [ >if_monotone >if_monotone #abs destruct
        | cases inb_e normalize //
        ]
      | cut (veqb (νy) g=false)
        [ lapply Hdino cases g normalize #ng cases neqb // >if_monotone //]
        #Hyg lapply Hsauri >Hyg normalize
        >if_then_true_else_false >if_then_true_else_false //
        ]
      ]
    ] qed.
*)
lemma four_dot_two:
    (∀t.∀s. (s ≥ fresh_var_t t) → read_back (fst ?? (underline_pTerm t s)) = t ) ∧
    (∀v.∀s. (s ≥ fresh_var_tv v) →read_back_v (fst ?? (overline v s)) = val_to_term v).

@(pValueTerm_ind (λt.∀s. (s ≥ fresh_var_t t) → read_back (fst ?? (underline_pTerm t s)) = t)
      (λv.∀ s. (s ≥ fresh_var_tv v) →read_back_v (fst ?? (overline v s)) = val_to_term v ))
[ #v normalize in match (fresh_var_tv ?); #HI #s #Hsz lapply (HI s Hsz)
 -HI -Hsz normalize cases (overline v s) #vv #nn normalize //
| lapply line_monotone_names * #Hmono1 #Hmono2
  lapply (line_names) * #Hline1 #Hline2
  lapply (four_dot_one_dot_one) * #H411t #H411v
  lapply (env_bound_lemma) #Hbound #t1 #t2 cases t2
  [ #v2
    cases t1
    [ #v1 normalize #H1 #H2
      #s lapply (H1 s) lapply (Hmono2 v1 s) cases (overline v1 s) #vv #n normalize
      #Hsn -H1 #H1 lapply (H2 n) lapply (Hmono2 v1 n) cases (overline v2 (n))
      #ww #m normalize #Hnm -H2 #H2 change with (max ? ?) in match (if ? then ? else ?);
      #Hmax lapply (le_maxl … Hmax) lapply (le_maxr … Hmax) -Hmax #H2' #H1'
      lapply (H1 H1') lapply (H2 (transitive_le … H2' Hsn )) -H2 -H2' -H1 -H1'
      #H1 #H2 >H1 >H2 //
    | #u1 #u2 normalize #Hu1u2 #Hv2 #s lapply (Hu1u2 s)
      change with (underline_pTerm (appl u1 u2) s) in match
      (match u2 in pTerm with [_ ⇒ ?]);
      lapply (Hmono1 (appl u1 u2) s)
      lapply (line_dom (appl u1 u2) s)
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n normalize #Hdome #Hsn
      lapply (Hv2 n) lapply (Hmono2 v2 n)
      cases (overline v2 n) #vv #m normalize #Hnm
      change with (max ? ?) in match (if leb ? ? then ?  else ?);
      change with (fresh_var_tv ?) in match (pi1 nat ? ?);
      change with (fresh_var_t ?) in match (pi1 nat ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?) in match (pi1 nat ? (fresh_var_t_Sig u2));
      change with (max ? ?) in match (if leb (max ? ?) ? then ? else ?);
      #H2 #H1 #H lapply (H1 (le_maxl … H)) -H1 #H1
      lapply (H2 (transitive_le … (le_maxr … H) Hsn)) -H2 #H2 >H2
      >(aux_read_back1 (val_to_term (pvar ν(m))) (val_to_term v2) (push e [ν(m)←b]))
      >(push_lemma …)
      change with (psubst ? (read_back_b ?)) in match (match [ν(m)←b] return λ_:Substitution.pSubst with 
        [subst (x:Variable)   (b0:Bite)⇒psubst x (read_back_b b0)]);
      >(atomic_subst …)  >H1 @eq_f >(aux_read_back3 … (s))
      [ //
      | normalize #x lapply (Hdome x) -Hdome #Hdome >dom_push normalize
        cut (neqb x (m)=true ∨ neqb x (m)=false) // * #Htf
        [ lapply (neqb_iff_eq x (m)) * #Heq #_ lapply (Heq Htf)
          -Heq #Heq destruct >neqb_refl >if_t #_ @(transitive_le … Hsn Hnm)
        | >Htf >if_f #H @(Hdome H)
        ]
      | normalize @(le_maxr … H)
      ]
    ]
  | #u1 #u2 #H1 #H2 #s lapply (H2 s)
    lapply (Hline1 (appl u1 u2) s)
    lapply (line_dom (appl u1 u2) s)
    lapply (Hbound … (appl u1 u2) s)
    lapply (H411t … (appl u1 u2) s)
    lapply (Hmono1 (appl u1 u2) s) normalize
    change with (underline_pTerm (appl u1 u2) s)
      in match (match u2 in pTerm with [_ ⇒ ?]);
    cases ((underline_pTerm (appl u1 u2) s)) * #b1 #e1 #n normalize
    change with (fresh_var_t ?)
      in match (pi1 … (fresh_var_t_Sig u1));
    change with (fresh_var_t ?)
      in match (pi1 … (fresh_var_t_Sig u2));
    change with (max ? ?) in match (if ? then ? else ?);
    #Hsn #H4111 #Hbound1 #Hdome1
    lapply (H1 (n)) cases t1
    [ #v1 normalize
      lapply (Hline2 v1 n)
      lapply (Hmono2 v1 n)
      cases (overline v1 n) #vv #m normalize #Hnm
      change with (fresh_var_tv ?)
        in match (pi1 … (fresh_var_tv_Sig v1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u2));
      #Hline2
      change with (max ? ?) in match (if leb ? ? then ? else ?); #H1'
      change with (max (fresh_var_b b1) ?)
        in match (if leb (fresh_var_b b1) ? then ? else ?); #Hline1 #H2'
      change with (max ? ?) in match (if leb (fresh_var_tv v1) (max (fresh_var_t u1) (fresh_var_t u2)) 
                                      then max (fresh_var_t u1) (fresh_var_t u2) 
                                      else fresh_var_tv v1); #H
      lapply (H1' (transitive_le … (le_maxl … H) Hsn)) -H1' #H1'
      lapply (H2' (le_maxr … H)) -H2' #H2'
      >aux_read_back1 >concat_epsilon_e >push_lemma >push_lemma
      change with (psubst ? (read_back_b ?)) in match (match [ν(m)←b1] return λ_:Substitution.pSubst with 
        [subst (x:Variable)   (b0:Bite)⇒psubst x (read_back_b b0)]);
      >atomic_subst >H2' @eq_f2 // >H1'
      >(aux_read_back3 … (s))
      [ cut (inb_t (νm) (val_to_term v1) = false)
        [ lapply (transitive_le … (transitive_le … (le_maxl … H) Hsn) Hnm)
          normalize lapply fresh_var_to_in * #_ #Hin #Htmp
          @(Hin … Htmp)
        | lapply no_subst3 #Hnsbst #Hy > (Hnsbst … Hy ) //
        ]
      | @Hdome1
      | cut (inb_t (νm) (val_to_term v1) = false)
        [ lapply (transitive_le … (transitive_le … (le_maxl … H) Hsn) Hnm)
          normalize lapply fresh_var_to_in * #_ #Hin #Htmp
          @(Hin … Htmp)
        | lapply no_subst3 #Hnsbst #Hy > (Hnsbst … Hy) @(le_maxl …H)
        ]
      ]
    | #r1 #r2
      lapply (Hline1 … (appl r1 r2) n)
      lapply (line_dom (appl r1 r2) n)
      lapply (Hmono1 … (appl r1 r2) n)
      lapply (Hbound … (appl r1 r2) n)
      lapply (H411t  … (appl r1 r2) n)
      cases (underline_pTerm (appl r1 r2) n)
      * #b #e #m normalize #H4112 #Hbound2 #Hnm #Hdome
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig r1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig r2));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u2));
      change with (max ? ?) in match ((if leb (fresh_var_t r1) (fresh_var_t r2) 
          then fresh_var_t r2 
          else fresh_var_t r1 ));
      change with (max ? ?) in match ((if leb (fresh_var_t u1) (fresh_var_t u2) 
          then fresh_var_t u2 
          else fresh_var_t u1 ));
      change with (max ? ?) in match (if leb (fresh_var_b b) (fresh_var_e e) 
          then fresh_var_e e 
          else fresh_var_b b);
      change with (max ? ?) in match (if leb (fresh_var_b b1) (fresh_var_e e1) 
          then fresh_var_e e1 
          else fresh_var_b b1);
      change with (max ? ?) in match (if leb (max (fresh_var_t r1) (fresh_var_t r2))
         (max (fresh_var_t u1) (fresh_var_t u2)) 
         then max (fresh_var_t u1) (fresh_var_t u2) 
         else max (fresh_var_t r1) (fresh_var_t r2)
         );
      #Hline1 #H1 #Hline2 #H2 #H
      >aux_read_back1 @eq_f2
      [ cut (aux_read_back (val_to_term (pvar ν(S m)))
             (concat (push e [ν(S m)←b]) (push e1 [νm←b1])) =
             aux_read_back (val_to_term (pvar ν(S m)))
              (push e [ν(S m)←b]))
        [2: #UU >UU >push_lemma
            whd in match (match [ν?←b] in Substitution
              return λ_:Substitution.pSubst with[_⇒ ?]);
            >atomic_subst >H1 //
            @(transitive_le … (le_maxl … H) Hsn)
        | @ultra_concat_lemma
          [ >dom_push normalize
            change with (neqb (S m) (m)) in match (match ? in nat with [_⇒?]);
            >neq_simm >neqb_false >if_f lapply (Hbound1 (S m)) cases domb_e //
            #abs @False_ind lapply (le_S … (transitive_le … (abs (refl …)) Hnm))
            @le_Sn_n
          | * #k >dom_push >fv_push normalize
            cut (neqb k m = true ∨ neqb k m = false) // * #Hkm
            [ elim (neqb_iff_eq k m) #Heq #_ lapply (Heq Hkm) -Heq #Heq
              destruct >neqb_refl normalize #_ lapply (Hbound2 m)
              lapply (H4112 (νm) (transitive_le … (le_maxl  … H) Hsn))
              cases domb_e normalize
              [ #_ #abs @False_ind lapply (abs (refl …)) @le_Sn_n
              | >if_then_true_else_false
                change with (fvb_t (νm) (appl r1 r2))
                  in match (gtb ? 0);
                cut (fvb_t (νm) (appl r1 r2) = false)
                [ cut (inb_t (νm) (appl r1 r2) = false)
                  [ cut (fresh_var_t (appl r1 r2)≤m)
                    [ normalize
                      @(transitive_le … (transitive_le … (le_maxl … H) Hsn) Hnm)
                    ]
                    lapply (fresh_var_to_in) * #Ht #_ @Ht ]
                  @bool_impl_inv2 lapply (fv_to_in_term) * #Ht #_ @Ht ]
                #HH >HH cases fvb_e normalize
                [ >if_monotone #abs destruct
                | cases fvb_b //
                ]
              ]
            | >Hkm normalize #HH lapply (Hdome1 … HH) #Hsk
              cut (fvb_t (νk) (appl r1 r2) = false)
              [ cut (inb_t (νk) (appl r1 r2) = false)
                [ cut (fresh_var_t (appl r1 r2) ≤ k)
                  [ @(transitive_le … (le_maxl … H) Hsk) ]
                lapply (fresh_var_to_in) * #Ht #_ @Ht ]
              @bool_impl_inv2 lapply (fv_to_in_term) * #Ht #_ @Ht ]
              -HH -Hsk #HH lapply (H4112 (νk) (transitive_le … (le_maxl … H) Hsn))
              change with (fvb_t (?) (appl ??))
                in match (gtb ? 0);
              >HH cases fvb_e
              [ >if_monotone #abs destruct
              | >if_then_true_else_false >if_f cases fvb_b normalize //
                cases domb_e normalize //
              ]
            ]
          ]
        ]
      | >iper_concat_lemma
        [ 2: >dom_push normalize >neqb_false >if_f lapply (Hbound2 m)
          cases domb_e // #abs @False_ind lapply (abs (refl …)) @le_Sn_n ]
        >push_lemma
        whd in match (match ?  in Substitution with [_⇒?]);
        >atomic_subst @H2 @(le_maxr … H)
      ]
    ]
  ]
| * #x #s //
| #t * #x #HI #s #H cut (fresh_var_t t ≤ s)
  [ lapply H normalize
    change with (fresh_var_t t)
      in match (pi1 nat ? ?);
    change with (max (S x) (fresh_var_t t)) in match (if ? then ? else ?);
    #Htop @(le_maxr … Htop)
  | #H' lapply (HI … H') normalize
    cases ((underline_pTerm t s)) * #b #e #n normalize
    #Hue >Hue //
  ]
] qed.

lemma unerline_var_hole:
 (∀t, s, x. fresh_var_t t ≤ s →
  fresh_var_t t ≤ x → x < s →
   inb (νx) (fst … (underline_pTerm t s)) = false) ∧
 (∀v, s, x. fresh_var_tv v ≤ s →
  fresh_var_tv v ≤ x → x < s →
   inb_v (νx) (fst … (overline v s)) = false) .

@pValueTerm_ind
[ #v #H #s #x normalize #H1 #H2 #H3 lapply (H s x H1 H2 H3)
  cases overline #v #n normalize cases inb_v // >if_t //
| lapply line_monotone_names * #Hmono1 #Hmono2
  lapply (line_names) * #Hline1 #Hline2
  lapply (four_dot_one_dot_one) * #H411t #H411v
  lapply (env_bound_lemma) #Hbound #t1 #t2 cases t2
  [ #v2
    cases t1
    [ #v1 normalize #H1 #H2
      #s #x lapply (H1 s x) lapply (Hmono2 v1 s) cases (overline v1 s) #vv #n normalize
      #Hsn -H1 #H1 lapply (H2 n x) lapply (Hmono2 v1 n) cases (overline v2 (n))
      #ww #m normalize #Hnm -H2 #H2 change with (max ? ?) in match (if ? then ? else ?);

      #Ha #Hb #Hc >if_then_true_else_false in H1; >if_then_true_else_false in H2;
      #H2 #H1
      >(H1 (le_maxl … Ha) (le_maxl … Hb) Hc)
      >(H2 (transitive_le … (le_maxr … Ha) Hsn) (le_maxr … Hb) (transitive_le … Hc Hsn))
      //
    | #u1 #u2 normalize #Hu1u2 #Hv2 #s #x lapply (Hu1u2 s x)
      change with (underline_pTerm (appl u1 u2) s) in match
      (match u2 in pTerm with [_ ⇒ ?]);
      lapply (Hmono1 (appl u1 u2) s)
      lapply (line_dom (appl u1 u2) s)
      cases (underline_pTerm (appl u1 u2) s) * #b #e #n normalize #Hdome #Hsn
      lapply (Hv2 n x) lapply (Hmono2 v2 n)
      cases (overline v2 n) #vv #m normalize #Hnm
      change with (max ? ?) in match (if leb ? ? then ?  else ?);
      change with (fresh_var_tv ?) in match (pi1 nat ? ?);
      change with (fresh_var_t ?) in match (pi1 nat ? (fresh_var_t_Sig u1));
      change with (fresh_var_t ?) in match (pi1 nat ? (fresh_var_t_Sig u2));
      change with (max ? ?) in match (if leb (max ? ?) ? then ? else ?);
      #H2 #H1 #Ha #Hb #Hc

      lapply (H1 (le_maxl … Ha) (le_maxl … Hb) Hc) -H1 #H1
      lapply (H2 (transitive_le … (le_maxr … Ha) Hsn) (le_maxr … Hb) (transitive_le … Hc Hsn))
      -H2 #H2
      >if_then_true_else_false in H2; #H2 >H2
      >if_then_true_else_false >inb_push whd in match (inb_e ? ?);
      whd in match (inb_s ? ?); whd in match (veqb ? ?);
      change with (orb ? ? = false) in H1;
      lapply (orb_false … H1) -H1 * #H1a #H1b >H1a >H1b normalize
      cut (neqb x m = true ∨ neqb x m = false) // * #Hxm >Hxm //
      elim (neqb_iff_eq x m) #Heq #_ lapply (Heq Hxm) #Heq destruct @False_ind
      lapply (transitive_le … (transitive_le … Hc Hsn) Hnm) @le_Sn_n
    ]
  | #u1 #u2 #H1 #H2 #s #x lapply (H2 s x)
    lapply (Hline1 (appl u1 u2) s)
    lapply (Hmono1 (appl u1 u2) s) normalize
    change with (underline_pTerm (appl u1 u2) s)
      in match (match u2 in pTerm with [_ ⇒ ?]);
    cases ((underline_pTerm (appl u1 u2) s)) * #b1 #e1 #n normalize
    change with (fresh_var_t ?)
      in match (pi1 … (fresh_var_t_Sig u1));
    change with (fresh_var_t ?)
      in match (pi1 … (fresh_var_t_Sig u2));
    change with (max ? ?) in match (if ? then ? else ?);
    #Hsn
    lapply (H1 n x) cases t1
    [ #v1 normalize
      lapply (Hline2 v1 n)
      lapply (Hmono2 v1 n)
      cases (overline v1 n) #vv #m normalize #Hnm
      change with (fresh_var_tv ?)
        in match (pi1 … (fresh_var_tv_Sig v1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u2));
      #Hline2
      change with (max ? ?) in match (if leb ? ? then ? else ?); #H1'
      change with (max (fresh_var_b b1) ?)
        in match (if leb (fresh_var_b b1) ? then ? else ?); #Hline1 #H2'
      change with (max ? ?) in match (if leb (fresh_var_tv v1) (max (fresh_var_t u1) (fresh_var_t u2)) 
                                      then max (fresh_var_t u1) (fresh_var_t u2) 
                                      else fresh_var_tv v1);
      #Ha #Hb #Hc >if_then_true_else_false in H1'; #H1'
      lapply (H1' (transitive_le … (le_maxl … Ha) Hsn) (le_maxl … Hb) (transitive_le … Hc Hsn))
      -H1' #H1'
      lapply (H2' (le_maxr … Ha) (le_maxr … Hb) Hc) -H2' #H2'
      >H1' >concat_epsilon_e >inb_push whd in match (inb_e ? ?);
      whd in match (inb_s ? ?); whd in match (veqb ? ?);
      change with (orb ? ? = false) in H2';
      lapply (orb_false … H2') * #Ha #Hb >Ha >Hb -Ha -Hb normalize
      cut (neqb x m = true ∨ neqb x m = false) // * #Hxm >Hxm //
      elim (neqb_iff_eq x m) #Heq #_ lapply (Heq Hxm) -Heq #Heq destruct @False_ind
      lapply (transitive_le … (transitive_le … Hc Hsn) Hnm) @le_Sn_n
    | #r1 #r2
      lapply (Hline1 … (appl r1 r2) n)
      lapply (Hmono1 … (appl r1 r2) n)
      cases (underline_pTerm (appl r1 r2) n)
      * #b #e #m normalize #Hnm
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig r1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig r2));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u1));
      change with (fresh_var_t ?)
        in match (pi1 … (fresh_var_t_Sig u2));
      change with (max ? ?) in match ((if leb (fresh_var_t r1) (fresh_var_t r2) 
          then fresh_var_t r2 
          else fresh_var_t r1 ));
      change with (max ? ?) in match ((if leb (fresh_var_t u1) (fresh_var_t u2) 
          then fresh_var_t u2 
          else fresh_var_t u1 ));
      change with (max ? ?) in match (if leb (fresh_var_b b) (fresh_var_e e) 
          then fresh_var_e e 
          else fresh_var_b b);
      change with (max ? ?) in match (if leb (fresh_var_b b1) (fresh_var_e e1) 
          then fresh_var_e e1 
          else fresh_var_b b1);
      change with (max ? ?) in match (if leb (max (fresh_var_t r1) (fresh_var_t r2))
         (max (fresh_var_t u1) (fresh_var_t u2)) 
         then max (fresh_var_t u1) (fresh_var_t u2) 
         else max (fresh_var_t r1) (fresh_var_t r2)
         ); #Hline2 #H2 #Hline1 #H1
      #Ha #Hb #Hc
      lapply (H2 (transitive_le … (le_maxl … Ha) Hsn) (le_maxl … Hb) (transitive_le … Hc Hsn))
      -H2 -H2 #H2
      lapply (H1 (le_maxr … Ha) (le_maxr … Hb) Hc) -H1 -H1 #H1
      change with (orb ? ? = false) in H1;
      change with (orb ? ? = false) in H2;
      lapply (orb_false … H1) lapply (orb_false … H2) * #Ha1 #Ha2 * #Ha3 #Ha4
      >inb_concat >inb_push >inb_push
      whd in match (inb_e ? ?);
      whd in match (inb_s ? ?);
      whd in match (inb_e ? (Snoc ? ?));
      whd in match (inb_s ? ?);
      whd in match (veqb ? ?); whd in match (veqb ? ?);
      >Ha1 >Ha2 >Ha3 >Ha4 normalize
      cut (neqb x m = true ∨ neqb x m = false) // * #Hxm >Hxm
      [ elim (neqb_iff_eq x m) #Heq #_ lapply (Heq Hxm) -Heq #Heq destruct @False_ind
        lapply (transitive_le … (transitive_le … Hc Hsn) Hnm) @le_Sn_n
      | normalize cut (neqb x (S m) = true ∨ neqb x (S m) = false) // * #HxSm >HxSm //
        elim (neqb_iff_eq x (S m)) #Heq #_ lapply (Heq HxSm) -Heq #Heq destruct @False_ind
        lapply (le_S … (transitive_le … (transitive_le … Hc Hsn) Hnm)) @le_Sn_n
      ]
    ]
  ]
| * #z #s #x normalize cut (neqb x z = true ∨ neqb x z = false) // * #Hxz >Hxz //
  elim (neqb_iff_eq x z) #Heq #_ lapply (Heq Hxz) -Heq #Heq destruct #_ #abs
  #_ @False_ind lapply abs @le_Sn_n
| #t * #z #H #s #x #H1 #H2 #H3 whd in match (overline ? ?);
  change with (max ? ? ≤ s) in H1;
  change with (max ? ? ≤ x) in H2;
  lapply (H s x (le_maxr … H1) (le_maxr … H2) H3)
  cases underline_pTerm #cc #n normalize
  #HH >HH >if_then_true_else_false
  cut (neqb x z = true ∨ neqb x z = false) // * #Hxz >Hxz //
  elim (neqb_iff_eq x z) #Heq #_ lapply (Heq Hxz) -Heq #Heq destruct
  @False_ind lapply (le_maxl … H2) @le_Sn_n
] qed.
