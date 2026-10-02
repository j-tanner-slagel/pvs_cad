# FORMS_PLAN: (cad) and (cad-qe) on formulas as people write them

> **Status (2026-10-01).** Plan written; user: "we gotta fix that for real. Make a plan to fix all
> of this and do it."  Stages F0-F6 below; progress in cad/PROGRESS.md and in these lines.
> - F0 done (labels: flatten gives every piece the label; relabel :pairing? t names them; plain
>   flatten / split go several levels deep -- the walk uses flatten-disjunct .. 1 and split .. 1).
> - F1 done: gform_def (17 TCCs), gform_ok (qfval_ok, g2f_ok, decide_g_ok, qe_g_qf, qe_g_ok).
> - F2, F3 done: NOT goals (cad-default-fnum), grouped prenex (cad-nest__, then decide8), any other
>   shape (cadg__: decide_g + the mirror walk), subtype binders (guards).
> - F4 done: (cad-qe) grouped (nested form) and any shape (cadg-qe__ with qe_g_ok).
> - F5 done: (cad *) keeps non-prenex formulas whole (cadg-seq__).
> - F6: pvs_cad.pvs (everything (cad) and (cad-qe) need in one import), cad_showcase.pvs (38 lemmas,
>   43 after the review fixes), cad_forms_ex.pvs (35 regression lemmas, 64 after them), README.  TRUE / FALSE beside quantified parts:
>   rewritten away by the walk where the node is at the top (gb_* lemmas); PVS's rewrite does not
>   rewrite an instance that would contain a bound variable.  Gates: gform_def, gform_ok,
>   cad_showcase passed; whole library 5075/5075 before the constants fix, 5142/5142 after it
>   (355 theories, 2086 s, 2026-10-01).
> - 2026-10-01: review fixes (NOT over compound formulas, connective synonyms, typed unknowns,
>   grouped-binder failures, messages, comparisons of a term with itself) -- done: cad_forms_ex 64
>   lemmas, cad_showcase 43, both gated; whole library 5183/5183 (355 theories,
>   2209 s, 2026-10-02).

## 0. What is wrong

`(cad FNUM)`, `(cad-direct)`, `(cad :cad-only? t)` and `(cad-qe FNUM)` accept only a *prenex*
formula with *one variable per quantifier* over `real`:

- `FORALL (x, y: real): ...` is refused ("not a closed prenex formula"); one has to write
  `FORALL (x: real): FORALL (y: real): ...`.  (`(cad *)` already accepts grouped binders.)
- `NOT (FORALL x: ...)` as the goal is refused with the default formula number; one has to use
  `(cad -1)` (PVS shows the goal `NOT A` as the hypothesis `A`).
- Quantifiers inside connectives are refused: `(EXISTS t: t^2 = a) IFF a >= 0` under `FORALL a`,
  the epsilon-delta form `FORALL e: e > 0 IMPLIES EXISTS d: d > 0 AND FORALL x: ...`, or
  `(FORALL x: P) AND (EXISTS y: Q)`.
- Binders over subtypes of the reals (`posreal`, `nnreal`, ...) are refused.  [Corrected
  2026-10-01: a grouped one was; a single binder of any type was read as a binder over all reals,
  so `(cad)` could call a true sentence FALSE (cad/PROGRESS.md, 2026-10-01; the kernel never
  accepted a wrong proof).]

## 1. Design

Three routes, cheapest first; `(cad)` picks the first that applies.

1. **Leading NOT** (F2): PVS itself shows a goal `NOT A` as the hypothesis `A`, so `(cad)` with
   no consequent decides hypothesis -1 (`cad-default-fnum`) with the existing machinery.
2. **Grouped binders in a prenex formula** (F2): the formula is proved from its nested form (one
   variable per quantifier) when it is a goal, or the nested form from it when it is a hypothesis,
   and the nested form is decided by the existing fast path (witness search, `decide8`).  The step
   between the two is the *mirror walk* of section 2 with identical matrices.
3. **Any closed first-order formula over the reals** (F1, F3): quantifiers anywhere, all
   connectives, grouped binders, binders over `posreal` / `nnreal` / `negreal` / `npreal` /
   `nzreal`; other real terms that mention no bound variable are generalized first, so that the
   formula is closed (FORALL for a goal, EXISTS for a hypothesis, each with the bounds its type
   gives).  A
   verified decision for a formula language that mirrors PVS's own connectives:
   - `gform_def`: `Gm` (`gtrue`, `gfalse`, the six comparisons of two polynomials, `gnot`, `gand`,
     `gor`, `gimp`, `giff`, `gall`, `gex`), its meaning `gsem(g)(pt)` written with PVS's own
     connectives and quantifiers, the translation `g2f` into `rcf_fol`'s `Fm`, and
     `decide_g(g) = qfval(qelim(g2f(g), 0))(null)` (executable: `qelim` from `qelim_def`, proved
     in `qelim_ok`), `qe_g(g, m) = qelim(g2f(g), m)`.
   - `gform_ok`: `g2f_ok` (`fsem(g2f(g))(pt) IFF gsem(g)(pt)`), `decide_g_ok`
     (`decide_g(g) IFF gsem(g)(null)`), and for `(cad-qe)` `qe_g_qf` (`qf?(qe_g(g, m))`) and
     `qe_g_ok` (`length(pt) = m IMPLIES (fsem(qe_g(g, m))(pt) IFF gsem(g)(pt))`).
   The strategy encodes the goal as a `Gm` term (each atom's two sides as polynomials over the
   variables in scope), evaluates `decide_g`, instantiates `decide_g_ok`, expands `gsem` (which
   then has the goal's own shape) and closes the goal by the mirror walk.

`(cad-qe)` (F4) uses route 3 with the free real terms as the outer coordinates and `qelim` with
that many free variables (`qe_g`).  `(cad *)` (F5), when a selected formula is not prenex (or binds
a subtype of the reals), builds ONE sentence, FORALL (unknowns): (type facts AND hypotheses)
IMPLIES (goals), with every formula kept whole (`cadg-seq__`), has `(cad)` decide it by the routes
above, and closes the sequent from it by instantiation and propositional reasoning (`inst`,
`typepred`, `prop`).

## 2. The mirror walk (F2, F3)

Two formulas of the same shape, one in the antecedent and one in the consequent, each named by a
fresh label (`with-fresh-labels`, never a formula number).  The walk proves the consequent from
the antecedent, connective by connective:

| shape | consequent R | antecedent L | then |
|---|---|---|---|
| FORALL | skolemize (all names of a grouped binder at once; one per layer on the nested side) | instantiate with the same constants | body |
| EXISTS | instantiate | skolemize | body |
| NOT | nothing: PVS has already moved it (a goal NOT X is shown as the hypothesis X; inst, skolem, split and flatten strip a NOT as they make a piece) | flattened (`cadg-unnot__`) only if it still reads NOT X, e.g. after expand or rewrite | roles swap |
| AND | split | flatten, `relabel :pairing? t` | each branch |
| OR | flatten, relabel | split | each branch |
| IMPLIES | flatten, relabel | split | one branch swaps roles |
| IFF | split (two implications) | flatten (two implications), relabel | IMPLIES |
| quantifier-free | | | reflection equations, `bddsimp` |

Skolem constants get fresh names.  Subtype binders add their guard (`x > 0` for `posreal`, ...): a
`typepred` or a TCC branch closes it (`cadg-strong-layers`, `cadg-weak-layers`).  At a
quantifier-free leaf (`cadg-leaf__`) the atoms of the unfolded `gsem` compare terms
`meval(pnorm(E))(VS)`; for each, the equation `meval(pnorm(E))(VS) = side`, with `side` the
matching term of the formula, is proved at run time (`peval_pnorm`, then `mpoly-eq-side__`) and
replaced, after which the two sides are the same Boolean combination of the same atoms and close by
`propax` (or `bddsimp` and `assert`).

## 3. Stages

- **F0** probe PVS: labels through flatten / split / skolem / inst, `relabel`, `substit`.  (Done:
  flatten gives every piece the label; split keeps it; relabel with pairing names the pieces.)
- **F1** `gform_def`, `gform_ok`: Gm, gsem, g2f, qfval, decide_g, qe_g; proofs; gates.
- **F2** strategies: leading NOT; grouped binders by the walk with identical matrices, for `(cad)`,
  `(cad-direct)`, `(cad :cad-only? t)`, `(cad-qe)`.
- **F3** strategies: the Gm encoder and the full walk; `(cad)` / `(cad-direct)` / `:cad-only?` on any
  closed formula, consequent or antecedent; messages when FALSE or not decidable.
- **F4** `(cad-qe)` on any formula with free real terms (route 3 with `qe_g_ok`).
- **F5** `(cad *)` with formulas that are not prenex.
- **F6** tests (every shape, both sides of the sequent, both engines), the showcase theory
  `cad_showcase`, README and docs, gates, whole-library replay, commit.

## 4. Rules

Strategies name formulas by fresh labels only (`with-fresh-labels`, never formula numbers); every strategy edit is
followed by a diff against HEAD and a replay of the strategy demos; the whole library is replayed
before the commit.
