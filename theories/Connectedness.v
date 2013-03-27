(* -*- mode: coq; mode: visual-line -*-  *)
(** * Connectedness *)

Require Import Overture PathGroupoids Fibrations Equivalences Trunc types.Forall types.Sigma types.Paths.
Local Open Scope equiv_scope.
Local Open Scope path_scope.

(** There is a slight controversy of indexing for connectedness — in particular, how the indexing for maps shoud relate to the indexing for types.  One may reasonably take the connectedness of a map to correspond either to that of its *fibers*, or of its *cofiber*; these differ by 1.  The traditional topological indexing uses the cofiber.  We use the fiber, as does Lurie in [HTT]; but we choose to agree with the traditional indexing on types, while Lurie agrees with it on maps.

Currently, the translation is therefore as follows:

       HoTT              Traditional       Lurie

Map    (n-1)-connected   n-connected       n-connective
Type   n-connected       n-connected       (n+1)-connective

A handy benchmark: under our indexing, the map [S1 -> 1] is 0-connected but not 1-connected, while the map [1 -> S1] is (–1)–connected but not 0-connected.

There is also a technical choice to be made in the definition.  Connectedness can either be defined as contractibility of the truncation, or by elimination into truncated types.  The former requires HIT’s, but keeps the type [IsConnected] small; the latter, which we use for now, requires only core Coq, but blows up the size (universe leve) of [IsConnected], since it quantifies over types. 

Q: is there a definition of connectedness that neither blows up the universe level, nor requires HIT’s? *)

Class IsConnected (n : trunc_index) (A : Type)
 := isconnected_elim :> 
      forall (C : Type) `{IsTrunc n C} (f : A -> C),
        { c:C & forall a:A, f a = c }.

(* TODO: probably remove — with type classes, one is supposed to avoid using this sort of type, right?
Record ConnectedType (n : trunc_index) := BuildConnectedType {
  Type_of_ConnectedType :> Type ; 
  isconnected_ConnectedType :> IsTrunc n Type_of_ConnectedType
}.

Existing Instance isconnected_ConnectedType.
*)

Class IsConnMap (n : trunc_index) {A B : Type} (f : A -> B)
  := isconnected_hfiber_conn_map :>
       forall b:B, IsConnected n (hfiber f b).
(* TODO: question — why do the implicit arguments of this not seem to work, i.e. seem to need to be given explicitly? *)

(** n-connected maps are orthogonal to n-truncated maps (i.e. familes of n-truncated types). *)
Definition conn_map_elim {n : trunc_index}
  {A B : Type} (f : A -> B) `{IsConnMap n _ _ f}
  (P : B -> Type) {HP : forall b:B, IsTrunc n (P b)}
  (d : forall a:A, P (f a))
: forall b:B, P b.
Proof.
  intros b. 
  apply isconnected_elim.
    apply HP.
    instantiate (1 := b). intros [a p]. 
    exact (transport P p (d a)).
Defined.

Definition conn_map_comp {n : trunc_index}
  {A B : Type} (f : A -> B) `{IsConnMap n _ _ f}
  (P : B -> Type) {HP : forall b:B, IsTrunc n (P b)}
  (d : forall a:A, P (f a))
: forall a:A, conn_map_elim f P d (f a) = d a.
Proof.
  intros a. unfold conn_map_elim.
  set (fibermap := (fun a0p : hfiber f (f a)
    => let (a0, p) := a0p in transport P p (d a0))).
  destruct (isconnected_elim (P (f a)) fibermap) as [x e].
  change (d a) with (fibermap (a;1)).
  apply inverse, e.
Defined.

(* TODO: converse of these two lemmas — if a map has such an elim/comp, then it is connected. *)

Section Extensions.

Context `{Funext}.

(* TODO: consider naming for [ExtensionAlong] and subsequent lemmas.  As a name for the type itself, [Extension] or [ExtensionAlong] seems great; but resultant lemma names such as [path_extension] (following existing naming conventions) are rather misleading. *)

(** This elimination rule (and others) can be seen as saying that, given a fibration over the codomain and a section of it over the domain, there is some *extension* of this to a section over the whole domain. *)
Definition ExtensionAlong {A B : Type} (f : A -> B)
  (P : B -> Type) (d : forall x:A, P (f x))
:= { s : forall y:B, P y & forall x:A, s (f x) = d x }.

Definition path_extension {A B : Type} {f : A -> B}
  {P : B -> Type} {d : forall x:A, P (f x)}
  (ext ext' : ExtensionAlong f P d)
: (ExtensionAlong f
    (fun y => projT1 ext y = projT1 ext' y)
    (fun x => projT2 ext x @ (projT2 ext' x)^))
-> ext = ext'.
Proof.
(* Note: written with liberal use of [compose], to facilitate later proving that it’s an equivalance. *)
  apply (compose (path_sigma_uncurried _ _ _)).
  apply (functor_sigma (path_forall (ext .1) (ext' .1))). intros p.
  apply (compose (path_forall _ _)). unfold pointwise_paths.
  apply (functor_forall idmap). intros x.
  apply (compose (B := (p (f x))^ @ (ext .2 x) = (ext' .2 x))).
    apply concat.
    path_via ((apD10 (path_forall _ _ p) (f x))^ @ ext .2 x).
    assert (transp_extension : forall p : ext .1 = ext' .1,
      (transport (fun (s : forall y : B, P y) => forall x : A, s (f x) = d x)
        p (ext .2) x
      = ((apD10 p (f x))^ @ ext .2 x))).
      destruct ext as [g gd], ext' as [g' gd']; simpl.
      intros q; destruct q; simpl.
      apply inverse, concat_1p.
    apply transp_extension.
    apply whiskerR, ap, apD10_path_forall.
  apply (compose (moveR_Vp _ _ _)).
  apply (compose (moveL_pM _ _ _)).
  exact inverse.
Defined.

Instance isequiv_path_extension {A B : Type} {f : A -> B}
  {P : B -> Type} {d : forall x:A, P (f x)}
  (ext ext' : ExtensionAlong f P d)
: IsEquiv (path_extension ext ext').
Proof.
  apply @isequiv_compose.
    Focus 2. apply @isequiv_path_sigma.
  apply @isequiv_functor_sigma.
    apply @isequiv_path_forall.
  intros a. apply @isequiv_compose.
    Focus 2. apply @isequiv_path_forall.
  apply (@isequiv_functor_forall _).
    apply isequiv_idmap.
  intros x. apply @isequiv_compose.
  apply @isequiv_compose.
    apply @isequiv_compose.
      apply isequiv_path_inverse.
      apply isequiv_moveL_pM.
    apply isequiv_moveR_Vp.
  apply isequiv_concat_l.
Qed.
(** Note: opaque, since this term is big enough that using its computational content will probably be pretty intractable. *)

Lemma extension_conn_map_elim {n : trunc_index}
  {A B : Type} (f : A -> B) `{IsConnMap n _ _ f}
  (P : B -> Type) `{forall b:B, IsTrunc n (P b)}
  (d : forall a:A, P (f a))
: ExtensionAlong f P d.
Proof.
  exists (conn_map_elim f P d).
  apply conn_map_comp.
Defined.

Lemma extension_conn_map_all_eq {n : trunc_index}
  {A B : Type} (f : A -> B) `{IsConnMap n _ _ f}
  (P : B -> Type) `{forall b:B, IsTrunc n (P b)}
  (d : forall a:A, P (f a))
  (e e' : ExtensionAlong f P d)
: e = e'.
Proof.
  apply path_extension.
  apply (extension_conn_map_elim (n := n)); try assumption.
  intros b. apply trunc_succ.
Defined.

(** A key lemma on the interaction between connectedness and truncatedness: suppose one is trying to extend along an n-connected map, into a k-truncated family of types (k ≥ n).  Then the space of possible extensions is (k–n–2)-truncated.

(Mnemonic for the indexing: think of the base case, where k=n; then we know we can eliminate, so the space of extensions is contractible.) 

This lemma is most useful via corollaries like the wedge-inclusion, the wiggly wedge, and their n-ary generalizations. *)
Lemma istrunc_extension_along_conn {m n : trunc_index}
  {A B : Type} (f : A -> B) `{IsConnMap n _ _ f}
  (P : B -> Type) {HP : forall b:B, IsTrunc (m -2+ n) (P b)}
  (d : forall a:A, P (f a))
: IsTrunc m (ExtensionAlong f P d).
Proof.
  revert P HP d. induction m as [ | m' IH]; intros P HP d; simpl in *.
  (* m = –2 *)
  exists (extension_conn_map_elim f P d).
  intros y. apply (extension_conn_map_all_eq (n := n)); assumption.
  (* m = S m' *)
  intros e e'. refine (trunc_equiv (path_extension e e')).
  (* magically infers: paths in extensions = extensions into paths,
                       which by induction is m'-truncated. *)
Defined.

(** A very useful form of the key lemma: the connectivity of the wedge into the product, for a pair of pointed spaces.  In fact this can be formulated without mentioning the wedge per se, since the statement only needs to talk about maps out of the wedge. *)
Corollary isconn_wedge_incl {m n : trunc_index}
  (A : Type) (a0 : A) `{IsConnected (trunc_S m) A} 
  (B : Type) (b0 : B) `{IsConnected (trunc_S n) B} 
  (P : A -> B -> Type) `{forall a b, IsTrunc (m -2+ n) (P a b)}
  (f_a0 : forall b:B, P a0 b)
  (f_b0 : forall a:A, P a b0)
  (f_a0b0 : f_a0 b0 = f_b0 a0)
: { f : forall a b, P a b
  & { e_a0 : forall b, f a0 b = f_a0 b
  & { e_b0 : forall a, f a b0 = f_b0 a
  & (e_a0 b0) @ f_a0b0 = (e_b0 a0) }}}.
Proof.
Admitted.

End Extensions.