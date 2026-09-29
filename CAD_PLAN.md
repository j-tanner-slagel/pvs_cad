# A formally verified computer algebra core for PVS, centered on CAD

Status: plan approved by the user on 2026-09-09; decisions recorded in section 10. Nothing in the library has been built yet.

## 1. Bottom line

The Narkawicz–Muñoz–Dutle paper (J. Automated Reasoning 54, 2015, doi 10.1007/s10817-015-9320-x) gives the template:
a decision procedure written as an executable PVS function, a correctness theorem about
that function, a deep embedding of PVS real expressions into the function's input type,
and a strategy that instantiates the theorem, ground-evaluates the function, and closes
the sequent. Soundness rests on the PVS logic plus the ground evaluator, never on an
oracle. The same template scales to several variables, but the mathematics that
justifies the multivariate procedure (cylindrical algebraic decomposition, CAD) is an
order of magnitude larger than Sturm/Tarski, and NASALib has none of its algebraic core
(no resultants, no subresultants, no real algebraic numbers, no polynomial gcd).

The recommended route is staged so that every stage ships a usable, verified strategy:

1. A verified multivariate polynomial kernel and a reflective `ring`-style normalizer
   (`mpoly-norm`, `mpoly-eq`). Immediately useful across NASALib and your matrix work.
2. A verified univariate real-algebraic-number layer (isolating intervals, sign of a
   polynomial at an algebraic number) on top of Sturm/Tarski.
3. A verified, complete multivariate decision procedure by sign-case branching over
   pseudo-remainder sequences ("branching QE"), reusing Tarski's engine. Correct by a
   homomorphism argument, no resultant theory needed. First end-to-end `qe` strategy.
4. Subresultants: the algebraic core of Collins projection (specialization theorem and
   gcd-degree theorem).
5. CAD proper: delineability over connected cells, projection, lifting with sample points,
   and the `cad` strategy. This is the research contribution.
6. Partial CAD and practical optimizations; then CAS extras (Gröbner bases, square-free
   factorization, sum-of-squares certificate checking).

Novelty, as of September 2026: Collins's CAD has a correctness proof in Rocq (Cohen,
Djalal, Vermande; paper: Q. Vermande, CPP 2026) but it is stated over an abstract real closed field with a
classical root function and is not executable and has no tactic. Isabelle/HOL has a
complete multivariate quantifier elimination procedure (Kosaian, Tan, Platzer; CPP 2023)
that is executable through code export but, in the authors' words, "hangs on all but the
simplest univariate examples". No prover has an executable, proof-producing CAD. PVS has
the strongest executable univariate engine (Sturm, Tarski, hutch), so it is the natural
place to build one.

## 2. The template, from the paper

Pieces the paper uses, all present in NASALib and all reusable:

| Piece | Where | Role |
|---|---|---|
| Polynomials as coefficient lists/arrays | `reals@polynomials`, `Sturm@polylist` | target representation |
| Pseudo-division, adjusted remainders, remainder sequences | `Sturm@polynomial_pseudo_divide`, `Sturm@remainder_sequence` | integer arithmetic only, content stripping |
| Sign changes, Sturm's theorem | `Sturm@number_sign_changes`, `Sturm@sturm` | root counting on intervals |
| Root-radius perturbation, Knuth bound, interval subdivision | `Sturm@compute_sturm` | `roots_cl_int`, `nonneg_int`, `always_nonneg` |
| Tarski queries and the 6x6 tensor matrix | `Tarski@tarski_query`, `Tarski@tarski_query_matrix` | counts roots under sign conditions |
| `compute_solvable`, `tarski` | `Tarski@poly_system_strategy` | satisfiability of conjunctions |
| `hutch` | `Tarski@hutch` | Boolean combinations via a sign-invariant interval decomposition (a one-dimensional CAD) |
| Deep embedding `pconst/pmonom/psum/pneg/pminus/pprod/pscal/pdiv/ppow` | `Sturm@polylist` | strategy builds this term syntactically; rewriting with `polylist_*` proves `p(x) = p<x>` |
| Ground evaluation | `eval-expr` (extrategies) | evaluates the decision function on ground input |
| Strategies | `Sturm/pvs-strategies`, `Tarski/pvs-strategies` | `sturm`, `mono-poly`, `tarski`, `hutch` |

Two design lessons from Section 6 of the paper carry over unchanged. First, keep the
strategy's Lisp dumb: it is a pretty-printer from the PVS expression to the embedding
term, and the embedding's correctness theorem does the work. Second, never expand
recursive definitions in the prover; ground-evaluate them.

## 3. What NASALib already has, and what is missing

Counts are from the shipped summaries (proofs) or a grep for LEMMA/THEOREM lines.

| Library | Size | Relevant content |
|---|---|---|
| `Sturm` | 349 proofs | everything univariate needed for root counting; `sturm`, `mono-poly` |
| `Tarski` | 515 proofs | Tarski queries, BKR-style sign determination, `tarski`, `hutch`, DNF handling |
| `mult_poly` (Slagel, White, Dutle) | ~470 lemmas | multivariate polynomials as monomial lists `[# C: real, alpha: list[nat] #]`, standard form, uniqueness of standard form (`sf(p) = sf(q) IFF FORALL x: p(x) = q(x)`), add/mult/power, evaluation, partial evaluation, `dimension_induction` (a polynomial as univariate in one variable with polynomial coefficients), semi-algebraic sets as DNF of atoms |
| `Bernstein` | 310 proofs | `multi_polylist`: `MultiPolyList = list[[real, list[nat]]]` with constructors `mpconst`, `mpmonom`, `mpvar`, `mpsum`, `mpprod`, `mpscal`, `mpminus`, `mppow`, `mpneg` whose types carry `meval` correctness, and a simplifier `mp_simp`; this is already a multivariate deep embedding in the paper's style. Also a Lisp parser `get-multivar-polynomial` from PVS expressions to monomial lists, and the `bernstein` strategy (numeric, incomplete) |
| `reals` | 1778 proofs | `polynomials` (`[nat->real]` with degree, `polynomial_prod`, `poly_shift`, `poly_scal`), `more_polynomial_props` (`square_free?`, root multiplicity `max_linear_div_power?`, root separation `min_poly_root_dist`, `poly_root_bound`, Knuth bounds); derivatives of polynomials are in `analysis@polynomial_deriv` |
| `algebra` | 1306 proofs | abstract rings, ideals, Euclidean domains, PIDs, UFDs, gcd in rings; no instance for a polynomial ring |
| `interval_arith`, `affine_arith` | 886, 835 | numeric semi-decision strategies |
| `analysis`, `mv_analysis` | 1644, 1015 proofs | continuity, IVT (`interm_value_thm`), compactness, Bolzano–Weierstrass, `polynomial_deriv`; a table-driven `deriv` strategy that is a good model for symbolic differentiation |
| `Tarski@PolyRelExpr` | — | a datatype of Boolean formulas over polynomial relations (`PREL`, `PAND`, `POR`, `PNOT`, `PIMPLIES`, `PIFF`, `PITE`) with DNF conversion in `dnf_polynomials`; the formula layer for Phases 3 and 5 |
| `PVS0` | 671 proofs | the reference pattern for proving a deep-embedded evaluator equivalent to a shallow PVS function |
| `extrategies` (`src/Field/extrategies.lisp`) | — | `eval-expr`, `eval-formula`, `extra-add-evalexpr`, `with-fresh-labels`, `with-fresh-names`, `mapstep`; the strategy toolkit |

Missing entirely (grep over all of NASALib): resultants, subresultants, discriminants,
polynomial gcd over Q, square-free decomposition, real algebraic numbers with exact
arithmetic, Thom encodings, Descartes' rule, Gröbner bases, sum-of-squares certificates,
any polynomial ring instance of `algebra`, a derivative on multivariate polynomials, a
computable determinant over a ring (`matrices@matrix_det` is about elementary matrices;
Tarski's `A66_inv` is a fixed numeric matrix).

Two maintenance facts about the installed snapshot (NASALib 8.0 layout, `proveit 7.1.0`):
`summaries/mult_poly.summary` records a typecheck error (`= does not uniquely resolve`),
and `mult_poly/simplified.prlite` records the lemma `simplified` in
`standard_form_mult_poly` as unfinished. Phase 0 has to replay `mult_poly` here and
repair both before anything is built on it.

NASALib has four polynomial representations that do not talk to each other:
`reals` arrays with degree, Sturm `Polylist`, Bernstein `MultiPolyList`, and
`mult_poly` monomial lists (`array2list` bridges the first two). The plan adds one more
(recursive, D1) and pays for it with conversion theorems; the alternative of forcing
CAD onto a distributed representation costs more in every projection lemma.

## 4. Prior art and where the contribution sits

- Rocq `coq-mathcomp-cad` (Cohen, Djalal, Vermande; paper: Q. Vermande, CPP 2026): correctness proof of
  Collins's CAD over an abstract `rcfType`. Projection = subresultants of `p` with `p'`,
  of `p` with `q`, plus leading coefficients, with degree truncations. Lifting uses
  `rootsR`, which is classical. Files: `subresultant.v`, `continuity_roots.v`,
  `topology.v`, `semialgebraic.v`, `cylinder.v` (about 540 KB of Rocq). Not executable,
  no tactic. It is the right reference for the proof architecture of Phase 5.
- Isabelle/HOL (Kosaian, Tan, Platzer; CPP 2023): complete multivariate QE by
  sign-case branching on leading coefficients of remainder sequences, plus BKR sign
  determination. Executable via code export, impractically slow. This is the
  algorithmic shape of Phase 3, and their branch-assumption bookkeeping is worth reading.
- Isabelle/HOL (Li, Passmore, Paulson 2019): univariate CAD with untrusted certificates.
- Isabelle/HOL (Cordwell, Tan, Platzer 2021): univariate BKR, executable.
- Coq (Mahboubi 2007): a CAD implementation without a completed correctness proof.
- Coq (Cohen, Mahboubi 2012): QE for real closed fields via Tarski/Hörmander style, "totally ineffective".
- HOL Light (Harrison): Positivstellensatz/SOS certificates with an untrusted SDP solver, verified certificate checking. Complementary to CAD, cheap for universal claims.
- PVS: the paper's Sturm/Tarski strategies; Bernstein and interval strategies; `metit` (MetiTarski/Z3 as oracle).

Contribution statement the plan aims at: the first executable, proof-producing,
formally verified multivariate real decision procedure integrated as a prover strategy,
with CAD as the algorithm and PVS's univariate engine as the base case.

## 5. Design decisions

D1. Polynomial representation for the algorithms: recursive.
`R[x_1..x_n] = R[x_1..x_{n-1}][x_n]`, as a PVS datatype

```
mpoly: DATATYPE BEGIN
  mconst(c: rat): mconst?
  mpoly(coeffs: list[mpoly]): mpoly?      % coefficient i is the coefficient of x_k^i at level k
END mpoly
```

with `level(p)` the number of variables and `meval(p)(xs: list[real])`. Projection,
lifting, leading coefficient, degree in the main variable, derivative in the main
variable, pseudo-division with polynomial coefficients are all structural on this shape.
This is what BPR (Basu, Pollack, Roy, ch. 11) and the Rocq file `cylinder.v`
(`{poly {mpoly R[n]}}`) use. Your `mult_poly` monomial-list form stays as the canonical
form for equality; a verified conversion both ways gives `meval(to_rec(p)) = eval(p)`.
Decision: recursive for algorithms, monomial lists for normal forms and for the
existing semi-algebraic-set theory.

D2. Coefficients are `rat` in the executable functions and the statements are about
`real`-valued evaluation. Integer coefficients with content stripping where remainder
sequences are computed, as Sturm does. Where a coefficient is a polynomial in lower
variables, its "sign" is a case in a branch, never a number.

D3. Deep embedding of multivariate expressions. Reuse `Bernstein@multi_polylist`: its
constructors `mpconst`, `mpvar`, `mpsum`, `mpprod`, `mpscal`, `mpminus`, `mppow`,
`mpneg` already have dependent types stating `meval` correctness, so the strategy can
print a PVS expression as an `mp*` term exactly as `sturm-poly-expr-rec` prints
`pconst/psum/...`, and one rewrite per constructor proves `meval(term)(xs) = p<xs>`.
What is missing is (a) a canonical form with a uniqueness theorem (`mp_simp` sorts and
merges, but nothing states that equal evaluations give equal simplified lists; that
theorem exists in `mult_poly@standard_form_unique` for the other representation, and a
conversion carries it over) and (b) a proven conversion from `MultiPolyList` to the
recursive form of D1. If reuse turns out awkward (real coefficients where `rat` is wanted,
or evaluation through `[nat->real]` valuations rather than lists), define a fresh
`PolyExpr` datatype with `pnorm` instead; either way it is one theorem per constructor.

D4. Algorithm track. Phase 3 first (branching QE, complete, cheap to verify), Phase 5
second (CAD proper). Phase 3 is not a throwaway: its branch bookkeeping becomes the
lifting step's sign-determination in Phase 5, and it gives a fallback for problems where
the CAD projection is too large.

D5. Real algebraic numbers. Two options for CAD sample points in section cells: explicit
algebraic numbers (defining polynomial plus isolating rational interval, arithmetic via
resultants) or Thom encodings (sign vectors of derivatives, BPR style, computed by Tarski
queries, no arithmetic on numbers at all). Recommendation: Thom encodings, because the
Tarski library already computes exactly the sign-condition counts they need and because
it removes the need for algebraic-number addition and multiplication, which are the
most expensive things to verify. Explicit isolating intervals stay as the user-facing
output for existential witnesses.

D6. Where the analytic core lives. CAD correctness needs: the roots of a real univariate
polynomial vary continuously with the coefficients on a connected parameter set where
the number of distinct roots and the leading coefficient are invariant. The classical
route (Collins; BPR; the Rocq proof) goes through the complex roots: the number of
distinct complex roots is what subresultant invariance controls, complex roots move
continuously, and real roots stay real because a root can only leave the real line by
colliding with its conjugate, which is a multiple root. NASALib has the ingredients:
`complex@fundamental_algebra` (existence of a root, linear-factor splitting,
`fundamental_algebra_roots`), `complex@cpolynomial_real` (conjugate roots of real
polynomials), continuity of complex polynomial functions. Decision (user, 2026-09-09):
the complex route, because it is the complete classical theory and yields reusable
theorems (continuity of complex roots, factorization over C). Cost accepted: the
subresultant/gcd theory of Phase 4 is stated over a commutative ring and instantiated
at both `rat` (for computation) and `complex` (for the proof), so Phase 4 must be
written generically from the start.

D7. Standing workflow rules from `CLAUDE.md` apply: small topic-scoped theories, raw
`pvs -raw` sessions, no skipped lemmas, three clean `proveit -f` runs plus a traces run
per file, `top.pvs` description blocks, commit after each verified file.

## 6. Phases

Sizes are calibrated against Sturm (349 proofs), Tarski (515), and the Rocq CAD.
"Gate" is what must be true before the phase is called done.

### Phase 0. Baseline and harness (days)

- Replay `Sturm`, `Tarski`, `mult_poly`, `Bernstein` on this machine with the installed
  PVS; record timings for the shipped examples (`Sturm/examples`, `Tarski/examples`
  including `hutch_examples`), so later phases have a performance baseline.
- Repair `mult_poly` on this PVS: the typecheck error in the shipped summary and the
  unfinished lemma `simplified`. Prove it, do not skip it.
- Confirm `eval-expr` behavior on datatypes with `list[rat]` fields and on recursive
  functions with `MEASURE` over datatypes; a small probe theory.
- Create the library skeleton `cad/` next to `linear_algebra_new/` with its own
  `pvs-strategies`, `top.pvs`, `PROGRESS.md`, `tools/` symlinks.
- Gate: all four libraries replay; probe theory ground-evaluates.

### Phase 1. Multivariate polynomial kernel and the `mpoly-norm` strategy (Sturm-sized)

Theories (one concern each):
- `mpoly_def`: datatype, `level`, `meval`, well-formedness (uniform level).
- `mpoly_arith`: `madd`, `mneg`, `msub`, `mmul`, `mscal`, `mpow`, evaluation
  homomorphism lemmas (`meval(madd(p,q)) = meval(p) + meval(q)`, etc.).
- `mpoly_norm`: recursive normal form (strip trailing zeros at every level, collapse
  singleton levels), `mnorm_eval`, and uniqueness: `meval(p) = meval(q)` pointwise
  implies `mnorm(p) = mnorm(q)`. Proof by induction on level using the univariate
  "zero function implies zero polynomial" fact from `reals@polynomials` at each level;
  `mult_poly@standard_form_unique` and `dimension_induction` give an alternative
  route by conversion.
- `mpoly_mono`: conversion to and from `mult_poly@MultPoly`, evaluation preserved.
- `mpoly_univ`: view at the top level as a univariate polynomial with `mpoly`
  coefficients: `deg`, `lc`, `coef(i)`, `deriv`, `pseudo_div`, `pseudo_rem`, with the
  identity `lc(g)^k * f = q*g + r` (in `mpoly` arithmetic, so evaluation carries it to
  reals), and `partial_eval(p)(xs)` to a `Sturm@Polylist` when all but the main
  variable are given rationals.
- `mpoly_embed`: the deep embedding per D3 (Bernstein `mp*` terms or a fresh
  `PolyExpr`), the evaluation rewrites, and the conversion to the recursive form.
- Strategies: `mpoly-norm` (rewrite a real-valued polynomial expression to normal
  form), `mpoly-eq` (prove `p<x> = q<x>` by `pnorm(p) = pnorm(q)` under `eval-expr`),
  `mpoly-simp` (replace a subexpression by its normal form in a sequent).
- Shared front end (`cad-frontend` in `pvs-strategies`), used by every strategy in
  this plan: (a) unfold user definitions whose bodies are polynomial expressions,
  transitively, including `LAMBDA`-defined function handles and parametrized
  definitions, before translating, so that sequents written in terms of
  `f(x:real): real = x^5 + 50*x - 2` or `g: [real -> real] = LAMBDA ...` are accepted
  as they are. Verified on 2026-09-09: the shipped `sturm`, `tarski`, `mono-poly` reject
  `f(x)` ("doesn't appear to be a polynomial") and prove every test after
  `(expand "f")`; the front end automates that `expand`, with an option to list the
  names to leave folded. (b) Rational expressions: a division by a polynomial
  denominator is cleared by a case split on the denominator's sign (the well-clear
  predicates use `tau_mod` and `tcpa`, which are quotients). (c) Variables of subtypes
  of `real` contribute their type predicates as constraints, as `preds?` does in
  `tarski`. These are
  PVS's first verified reflective ring tactics; they subsume most `grind`-with-arithmetic
  uses on polynomial identities and are directly useful in the matrix library.
- Gate: strategies close the Legendre identities from the paper and a set of matrix
  identities from `linear_algebra_new` faster than `grind`; three clean `proveit -f`
  runs per file.

### Phase 2. Univariate real algebraic numbers on top of Sturm/Tarski (half Sturm-sized)

- `alg_num_def`: `alg = [# p: Polylist, lb, ub: rat #]` with `p` nonzero, exactly one
  root in `[lb, ub]` (decided by `roots_cl_int`), `value(a)` the unique root.
- `alg_sign`: sign of a rational polynomial `q` at `value(a)` computed by a Tarski query
  on `[lb, ub]`; theorem `alg_sign(a,q) = sign(q(value(a)))`.
- `alg_isolate`: from `p` produce the list of isolating intervals of all real roots
  (bisection driven by `roots_cl_int`, bounded by the Knuth bound; termination by the
  root-separation bound `min_poly_root_dist` in `reals@more_polynomial_props`),
  theorem: the intervals are disjoint, each contains exactly one root, every root is in
  one. `Tarski@hutch` already computes a sign-invariant interval decomposition with a
  sign vector per interval; this phase mostly repackages it with explicit intervals.
- `alg_refine`, `alg_compare`: order two algebraic numbers by refinement.
- Thom encodings: `thom(p, a)` as the sign vector of `p, p', p'', ...` at `a`;
  theorem that Thom encodings of distinct roots differ (BPR Prop. 2.28), computed via
  Tarski queries.
- Strategy `poly-roots` (isolate all roots of a univariate polynomial expression and
  add the interval facts to the sequent) and `alg-sign`.
- Gate: `Sturm/examples` and `Tarski/examples` polynomials isolate in under a second
  each; three clean runs per file.

### Phase 3. Branching quantifier elimination: the first complete multivariate procedure (Tarski-sized)

Idea: to decide `EXISTS x: phi(x, ys)` where `phi` is a Boolean combination of
`p_i(x, ys) R 0`, run Tarski's univariate algorithm symbolically in `x`. Every place
the algorithm tests the sign of a coefficient (leading coefficients in pseudo-division,
degrees, the `greatify` step, the endpoint signs) it instead branches on
`c < 0`, `c = 0`, `c > 0` where `c` is an `mpoly` in `ys`, recording the assumption. The
result is a finite disjunction of `(sign assumptions on ys) AND (univariate verdict)`,
a quantifier-free formula in `ys`. Iterate to eliminate all quantifiers; a closed
formula reduces to `TRUE`/`FALSE`.

- `branch_tree`: a datatype of sign-condition trees over `mpoly` with semantics; the
  key lemma is that evaluation at any `ys` selects exactly one consistent branch.
- `branch_prs`: the pseudo-remainder sequence as a branch tree whose leaves are lists
  of univariate `Polylist`s together with the sign of each leading coefficient. Theorem:
  on every branch, evaluating the leaf at `ys` equals the Sturm chain of the evaluated
  polynomials. This is the evaluation-homomorphism lemma from Phase 1 applied step by
  step; no new mathematics.
- `branch_tarski`: `compute_solvable` lifted to branch trees; correctness by the
  Tarski theorem on each leaf.
- `qe_formula`: formulas as a datatype (`Tarski@PolyRelExpr` has the Boolean
  structure and DNF conversion for univariate atoms; `mult_poly@semi_algebraic` has
  multivariate atoms, meets and joins; extend with `mpoly` atoms and quantifiers),
  `qe_exists`, `qe`, and the theorem `FORALL ys: feval(qe(F))(ys) IFF feval(F)(ys)`.
- Strategy `qe`: handles the sequent forms of `tarski` in Section 6.5 of the paper but
  with several real variables and nested quantifiers; free variables of the sequent are
  universally closed. Same reflection skeleton as `tarski__`.
- Gate: decides the paper's Example 6 (conflict detection) with `D`, `H`, `T` as
  variables rather than numbers; decides two-variable Turan-type inequalities; three
  clean runs per file. Expect this to be slow beyond three variables or degree four;
  that is the motivation for Phases 4 and 5, and the numbers go into the paper.

### Phase 4. Subresultants (Tarski-sized, hardest algebra)

The Collins projection needs the principal subresultant coefficients
`sres_j(f, g)` for `f, g` in `R[ys][x]`, and two theorems:
- Specialization: if `lc(f)(ys) /= 0` and `lc(g)(ys) /= 0` then
  `sres_j(f,g)(ys) = sres_j(f(ys), g(ys))`.
- Gcd degree: `deg gcd(f, g) = min {j | sres_j(f,g) /= 0}`, and the `j`-th subresultant
  polynomial is that gcd up to a unit.

Route: define subresultants as determinants of Sylvester-type matrices over the
commutative ring `mpoly` (the paper's `Tarski@tarski_query_matrix` has computable
determinants only over `real`; a determinant over a commutative ring is needed here;
`algebra@commutative_ring` supplies the ring, not the determinant). Then prove the
subresultant PRS theorem relating them to the pseudo-remainder sequence
(BPR Thm 4.29 / Mishra Ch. 7). Alternative that avoids determinants: define the
subresultant chain by the Ducos or Brown–Traub recursion directly and prove the
gcd-degree theorem from the recursion; the Rocq `subresultant.v` (37 KB) uses the
determinant route and is the model to follow.

Theories: `ring_det` (determinant over a commutative ring, Leibniz or Laplace, with
multilinearity), `sylvester`, `subresultant_def`, `subresultant_prs`,
`subresultant_spec`, `subresultant_gcd`, plus the univariate specializations
`resultant`, `discriminant` and their root-theoretic readings
(`discriminant(p) = 0 IFF p has a multiple root`, proved through the gcd theorem).

- Gate: `resultant` and `discriminant` ground-evaluate; the gcd-degree theorem is
  proved; three clean runs per file. Also gives the CAS features `poly-gcd`,
  `poly-sqfree` (square-free part `p / gcd(p, p')`) for free.

### Phase 5. Cylindrical algebraic decomposition (larger than Sturm and Tarski together)

Mathematics, following BPR Ch. 11 in the real-only form of D6:
- `cell_def`: cells as sign conditions on projection polynomials; connectedness for the
  cells we produce (sectors are intervals over a cell, sections are graphs of continuous
  root functions), by induction on the level.
- `complex_roots`: factorization of a complex polynomial into linear factors (induction
  on `polynomial_zero_factor`), the multiset of roots, number of distinct roots equals
  degree minus degree of `gcd(p, p')` (Phase 4 at `complex`), continuity of the root
  multiset in the coefficients (bounded roots plus the factorization bound
  `|p(z)| = |lc| * prod |z - r_i|`), and conjugate-closure of the roots of a real
  polynomial (`cpolynomial_real`).
- `root_continuity`: for `p` in `R[ys][x]` and a connected `S` on which `lc(p)`, all
  `sres_j(p, p')` and `sres_j(p, q)` are sign-invariant: the distinct real roots of
  `p(ys, .)` are given by finitely many continuous functions on `S`, ordered, and each
  `q` in the family is sign-invariant on each graph and each band. This is the
  delineability theorem and the bulk of the work; it follows the classical proof with
  `complex_roots` supplying "distinct complex roots stay distinct and move
  continuously", so a real root cannot become complex (it would have to meet its
  conjugate) and two real roots cannot merge.
- `projection`: `proj(P)` = leading coefficients, `sres_j(p, p')`, `sres_j(p, q)` for
  `p, q` in `P`, plus the truncations needed when leading coefficients vanish
  (`elimp_subdef1` in the Rocq file), all as `mpoly` at level `n-1`, with
  the lemma that sign invariance of `proj(P)` on a connected cell implies
  delineability of `P` over it.
- `lifting`: from a sample of a level `n-1` cell (Thom encoding or rational point),
  compute the roots of the product of the evaluated polynomials (Phase 2), the sample
  points of the sections and sectors, and the sign of every `p` in `P` at each sample.
- `cad_main`: `cad(P)` returns a list of cells with samples; theorems: the cells cover
  `R^n`, are pairwise disjoint, each `p` in `P` is sign-invariant on each cell, and
  each cell's sample lies in it. Decision `decide(F)` for a closed prenex formula by
  evaluating at samples, with `decide(F) IFF feval(F)`.
- Strategy `cad`: same front end as `qe`; back end instantiates `decide_correct`.
- Gate: the same benchmark set as Phase 3, plus the standard CAD textbook examples
  (circle and line, `x^2 + y^2 < 1 AND y > x` style, Collins's cubic example), with
  time and cell counts recorded; three clean runs per file; a whole-library
  `proveit` run of `cad/top.pvs`.

### Phase 6. Making it practical, then the rest of the CAS (open-ended)

- Partial CAD (Collins–Hong): propagate truth values, stop lifting cells whose truth is
  determined; equational-constraint projection restriction; variable-order heuristics
  in the strategy (Lisp side, no proof impact).
- Verified square-free and content/primitive-part preprocessing of the projection set,
  which is where real CAD implementations get most of their savings.
- Sum-of-squares certificate checking: `sos-check` takes a certificate found by an
  untrusted search (Lisp or external) and verifies `p = sum q_i^2 + ...` with
  `mpoly-eq`. Cheap universal proofs for problems where CAD is too big.
- Gröbner bases (Buchberger with a verified termination measure, or a certificate
  checker for ideal membership: `p = sum c_i g_i` checked by `mpoly-eq`), for equational
  hypotheses.
- Univariate factorization over Q is not needed for any of the above and is best left
  out.

## 7. PVS-specific engineering notes

- Ground evaluation constraints, learned from Sturm/Tarski: functions must be total,
  first-order-ish, with structural or measured recursion; no `choose`, no unbounded
  quantifiers in executable code; `list` and datatypes evaluate well; `[nat->int]`
  arrays are converted to lists with `structures@array2list` at the boundary. Keep the
  executable functions in their own theories, separate from the correctness theories.
- TCC load: subtype-heavy signatures such as `(n | FORALL (j:upto(k)): p(j)(n(j)) /= 0)`
  in Tarski are what make the strategies need `preds?` handling; prefer datatypes with
  well-formedness predicates proven once.
- The branch-tree and cell representations should be `list`-based datatypes so that
  `eval-expr` output is readable in transcripts and the hand-built `.prf` workflow
  stays viable.
- Strategy code: reuse `sturm-poly-expr-rec` (Sturm) for the univariate case and
  Bernstein's monomial parser for the multivariate grammar; share `extra-add-evalexpr`
  for numeric subexpressions; follow `tarski__`'s label discipline
  (`with-fresh-labels`, `hide *` early, `eval-expr` on one labeled formula).
- Machine limits: 8 GB, `proveit` hangs below ~5000 free pages; the subresultant
  determinant lemmas will be the heaviest typechecking; keep files small.

## 8. Rough size and order

| Phase | New proofs (estimate) | Depends on |
|---|---|---|
| 0 | 0 | — |
| 1 | 250–350 | — |
| 2 | 150–200 | 1 |
| 3 | 400–500 | 1, 2 |
| 4 | 400–600 | 1 |
| 5 | 800–1200 | 2, 4 |
| 6 | open | 5 |

Phases 3 and 4 are independent and can be interleaved. A paper is possible after
Phase 3 (executable verified multivariate QE in a prover strategy) and a stronger one
after Phase 5.

## 9. Questions

1. Primary use case: closed sequents over real variables (decision), or do you also
   want the QE output as a PVS formula the user can keep (quantifier-free equivalent)?
   The second needs a formula pretty-printer back into PVS syntax and changes Phase 3's
   strategy design.
2. Do you want `mult_poly`'s monomial-list representation to be the primary one (with
   the recursive view derived), or the recursive one primary as in D1? D1 is my
   recommendation for CAD; the cost is a conversion theory.
3. Thom encodings versus explicit algebraic numbers for sample points (D5)?
4. Real-only root continuity (D6) versus going through `complex` and building
   continuity of complex roots?
5. Target problem sizes for the benchmark set: ACCoRD-style conflict-detection
   formulas with 3–4 variables, or something else? This decides whether Phase 6's
   partial CAD is needed before the work is usable to you.
6. Location and naming: a new `cad/` directory in this repository, or a separate
   repository intended for NASALib contribution?
7. PVS version: the strategies will be developed against the installed PVS
   (`$PVS_DIR`, `proveit 7.1.0`). Is targeting PVS 8 for release a
   requirement?

## 10. Decisions taken (2026-09-09)

1. Both: a decision procedure for closed sequents, and QE returning a quantifier-free
   PVS formula. The `qe` strategy therefore needs a printer from the formula datatype
   back to PVS syntax; the decision path is the special case where the output is
   `TRUE`/`FALSE`.
2. D1 (recursive representation for the algorithms, monomial lists for canonical
   forms), with conversion theorems both ways. The difference: a monomial list is a
   set of (coefficient, exponent vector) pairs, symmetric in the variables, natural for
   normal forms, equality, total degree and Gröbner bases, but "degree in x_n",
   "leading coefficient in x_n", "derivative in x_n" and pseudo-division each need a
   pass that groups monomials by the x_n exponent, and every lemma about them is a
   multiset argument. The recursive form fixes a variable order (which CAD also fixes)
   and makes those operations structural recursion, so univariate lemmas lift through
   one evaluation homomorphism. Changing the variable order costs a conversion.
3. Thom encodings for sample points (confirmed by the user), explicit isolating
   intervals only for user-facing witnesses (D5).
4. The complex route for root continuity (user's choice, superseding the earlier
   real-only recommendation); see D6. Phase 4 is written over a generic commutative
   ring so it instantiates at `rat` and `complex`.
5. Benchmarks: ACCoRD-style conflict detection and the DAIDALUS well-clear volume. The
   well-clear definitions are not in NASALib; they are in NASA's public `WellClear`
   repository under `PVS/WellClear/` (`horizontal_WCV_taumod.pvs`,
   `WCV_taumod.pvs`, and the `_interval` lemmas), a Boolean combination of quadratics in
   `s`, `v`, `t` with parameters `DTHR`, `TAUMOD`, `ZTHR`, `TCOA`. Phase 0 imports a copy
   of those theories as the benchmark set.
6. This directory is the CAD repository: private GitHub `j-tanner-slagel/pvs_cad`.
8. Benchmarks for the decision procedure (agreed 2026-09-09): the WCV_inclusion and
   ACCoRD universal lemmas with symbolic parameters, and the literature CAD problems,
   in addition to the executable and symbolic bands (section 11.4).
9. Reporting: `cad/PROGRESS.md` is the running log (one entry per session or verified
   item); `paper/main.tex` is the report of the entire formalization, intended for a
   conference submission, with a methods section on LLM-assisted formalization whose
   usage table (tokens, wall-clock, turns, tool calls per session) is generated from
   the Claude Code transcripts by `tools/llm_usage.py`, never estimated.
7. PVS was updated to 8.1 (built from `SRI-CSL/PVS` master of 2026-08-06) and NASALib
   to 8.1 (master of 2026-07-23) on 2026-09-09; all work targets that pair. Sturm
   (81/81), Tarski (39/39) and hutch (35/35) examples replay on it.

## 10a. Decisions taken (2026-09-14, after Phase 3)

10. Phase 3 closed with the parametric layer as context-aware branch trees and a
    hutch-based sign oracle; the conflict question with the radius symbolic is
    decided (closest approach), the version with the lookahead window is beyond
    branching QE (25-47 min unfinished) and is reported as the phase's limit.
11. Phase 4 delivers the executable resultant and discriminant with the
    specialization theorem (`ring_det`, `sylvester`). The subresultant gcd-degree
    theorem is **deferred**: it is not on the critical path to an executable CAD,
    because the projection operator of Phase 5 will be the leading coefficients of
    the symbolic Sturm chains of the projection polynomials (and of their products
    for sign conditions), which Phase 3 already proves determine the number of
    distinct real roots at every valuation. Subresultants are the content-controlled
    refinement of the same chains and return as the size optimization of Phase 6.
    NASALib's `matrices@matrix_det` has no expansion, adjugate or kernel theory, so
    the resultant-common-factor theorem would need that built from scratch first.
12. **Phase 5 route revised (2026-09-14, after croot_near).** The justification
    written into decision 11 is wrong: a constant number of distinct *real* roots
    with a nonvanishing leading coefficient does not give delineability. The
    polynomial `(y^2 - x) ((y - 1)^2 + x)` has exactly two distinct real roots for
    every `x` in `(-1, 1)` and leading coefficient 1, yet its smaller root jumps
    from near 1 (for `x < 0`) to 0 (at `x = 0`) to near 0 (for `x > 0`): a real
    double root and a complex pair trade places at `x = 0`. Delineability needs the
    number of distinct *complex* roots, i.e. the degree of `gcd(p, p')`, and that is
    exactly the deferred gcd theorem (plus a multiplicity theory over C).
    The decision procedure does not need delineability at all. What it needs, at
    every parameter point `ys`, is the finite set of sign vectors that the family
    `F_k` realizes along the top variable, and that set is: the sign vectors at the
    real roots of `G = prod F_k` (the sections), the sign vectors at the real roots
    of `G'` (one in every bounded sector, by Rolle; the sign vector is constant on a
    sector), and the sign vectors at `+oo` and `-oo` (the two unbounded sectors,
    from the leading coefficients). Each of the three is a parametric branch tree
    that Phase 3 already computes symbolically in `ys` (`cjtreec` decides
    `EXISTS x: g = 0 AND E = 0 AND Q > 0` for any conjunction; `snormc` gives the
    normalized leading coefficients), so the realized-sign-vector list is a branch
    tree over `ys` whose branch conditions are the projection set `F_{k-1}`, and its
    leaf is constant wherever `F_{k-1}` is sign-invariant: that is the cylindrical
    structure, obtained algebraically instead of analytically. Correctness of the
    quantifier evaluation is pointwise in `ys` (soundness: every `x` realizes a
    listed vector; completeness: every listed vector is realized), by downward
    induction on the level, for an arbitrary prefix of quantifiers. This is BPR's
    cylindrical decision method with Thom-style sign determination, with the
    projection operator being the branch conditions of the parametric Tarski
    trees. Cell connectedness and root continuity are not proved; `croot_near`
    (root proximity, both directions available) is kept as the analytic input for
    a later geometric cell theory. The subresultant/gcd theorem stays deferred.

13. **Phase 5 measured (2026-09-14).** The decision procedure of decision 12 is
    proved (`decide_correct`, any prefix) and the `cad` strategy works, but the
    executable trees are exponential in practice: linear two-variable examples
    take 2 s, the circle and line (`EXISTS x, y: x^2 + y^2 < 1 AND y > x`),
    `y^2 = x` and the three-variable `a x + b = 0 OR a = 0` do not finish in 15
    minutes. Measured: one parametric existence query on `x^2 + y^2 - 1` with a
    side condition takes 5 s, the same query on the product `(x^2+y^2-1)(y-x)`
    more than 500 s; `svs` nests 26 such queries with `bbindc`, and every node
    of the joint tree calls the hutch oracle on the whole context. The cure is
    the architecture of a real CAD, without giving up pointwise correctness:
    (a) evaluate the queries per cell instead of building a joint tree — the
    context-free tree builders of Phase 3 get deforested versions
    `X_sel(args, sg)` that compute `select` of the tree for a sign function `sg`
    (proved equal to `select` by induction, with generic `selsg_bbind`/`selsg_bmap`),
    and condition collectors `X_cs(args)` with the read-set property (the value
    depends on `sg` only on `X_cs`), so the level below is the collected set
    and each cell evaluates the queries with its own sign vector, no oracle;
    (b) level 1 by Phase 2 root isolation: the realized vectors of a univariate
    family are the vectors at its isolated roots (`roots`, `alg_sign`) and at
    rational samples between consecutive roots (`sector_cases`, `svec_same`),
    replacing the univariate Tarski trees whose product polynomial would have
    degree in the hundreds; (c) roots factor by factor and sector
    representatives from pairwise products `(f_i f_j)'` instead of the full
    product and its derivative. Levels 2 and up stay symbolic per cell, which
    is what makes correctness pointwise and delineability unnecessary. This is
    the first item of Phase 6; the three-variable case inherits it (a cell of
    level 2 is a sign vector, not a sample point).
14. **Phase 6 built and measured (2026-09-15).** Items (a) and (b) of decision
    13 are proved (`sg_*`, `cell1`, `cad_lift`, `decide2_correct` relative to
    the completion flag of the closure). What the measurements then showed,
    and what was done, each without touching the correctness argument since
    the closure `closed?` remains the specification and is checked on the
    result: (i) the ground evaluator cannot compare lists of different
    lengths through `=` on a non-primitive type, so executable membership
    uses the structural equalities of `mpoly_eqd`; (ii) answering 0 for a
    polynomial not yet in the family makes the Tarski chains read garbage
    (degree-8 products for the circle), so at level 1 the reads are taken
    exactly at the sample points (`asg`: rational samples by `meval`, roots
    by `alg_sign`) and only genuine projection polynomials enter the family;
    (iii) `alg_sign` at a rational sample is a Sturm chain on a sum of
    squares per read and was the whole cost of a cell - direct evaluation
    instead; (iv) the sum of squares `sqsum(E)` doubles the degree of every
    equation before normalization: `sg_conj2` refutes on a nonzero constant,
    drops identically zero equations and decides a single equation on
    itself, which took the largest polynomial of the circle's level-1 family
    from degree 90 to 38; (v) `iso` recomputes the Sturm chain at every
    bisection, `alg_fast` computes it once (`isoc_iso`); (vi) roots are
    compared by interval separation before any algebraic comparison
    (`cmpf` in `cell1`). Item (c) of decision 13 (factor by factor, pairwise
    products) remains the next lever if the closure is still slow.
15. **Root cause found (2026-09-15, evening).** With every fix of decision 14
    the circle still does not finish, and the reason is now measured and
    structural: the reads of the per-cell procedure are the leading
    coefficients of the sign remainder chains of Phase 3, and those chains
    are plain pseudo-remainder sequences (`sturm_step`, `branch_prs`), whose
    coefficients grow exponentially in the number of steps. For the circle
    the first family already holds a polynomial of degree 36 in x with
    coefficients near 10^8, and 34 distinct such reads, each with real roots,
    so every one of them legitimately splits the line. Checking sign
    invariance per sector instead of adding the reads to the family
    (`sect_inv`, proved except `inv_chk_sound`; `cad_lift` restructured for
    it) does not help, because the reads themselves have the roots. Two ways
    out, both real work: (a) replace the pseudo-remainder chain of Phase 3 by
    a subresultant chain (the same sign-variation semantics, coefficients of
    polynomial size, the reads then the classical projection polynomials:
    discriminants and resultants) - this touches `sturm_step`/`branch_prs`
    and everything above them in Phase 3; (b) the classical projection with a
    delineability proof, which decision 12 avoided. Both are multi-week.
    Without one of them the verified procedure decides linear two-variable
    formulas in seconds and the circle in more than 15 minutes.
16. **Subresultant chain, approved (2026-09-15).** The user chose option (a).
    Design, minimal in proof surface, refined in the evening: nothing of
    Phase 3 changes. New theories: `mpoly_div` (`mdiv`, a fuel-bounded
    exact-division attempt at the coefficient level, `ldivl`, and the check
    `lexact(d, q, r)`: `d * q = r` coefficient by coefficient after
    `mnorm`, by `meq`; no lemma about `mdiv` is needed), `earr_ops`
    (`prop(l1, l2, c, ys)`: lists of the same length whose coefficients at
    `ys` are in the ratio `c`; it passes through `pstep`, `prem` (ratio
    `c1 c2^pk`), `sstep` (`c1 c2^(2 pk)`) and, for `c > 0`, through
    normalization at `ys` and the leading sign), `sturm_step2`
    (`sstep2(l1, l2, cc, e, sg)`: the pseudo-remainder divided by `cc^e`
    when `lexact` confirms it, with the sign `-sgn(b^k) sgn(cc^e)` read
    from the sign function, otherwise `sstep`; `sstep2_prop`: at `msg(ys)` a
    positive multiple of `sstep`), `sg_chain2` (`rchain2_sg` carries the
    divisor of Collins's reduced sequence: `cc` = the leading coefficient of
    the element before the pair, `e` = one more than the degree drop before
    it, `nexp`; `rchain2_prop`: element by element a positive multiple of
    `rchain`; `chprop_tqf`: the Tarski query reads only lengths and leading
    signs, so `tq2_sg_at`, `mts2_sg_at`, and the `_det` lemmas). Then
    `sg_conj`'s `mcount_sg` calls `mts2_sg`. The Sturm-sequence property is
    never re-proved: the new chain is compared with the old one at every
    valuation, which is a syntactic induction over `pquo_rem`. Expected
    effect on the circle: reads of classical projection size (degree at
    most 4 in x), a level-1 family of a handful of polynomials, and a
    decision in tens of seconds.

## 11. Application: exact kinematic bands (the maneuver moment as a variable)

### 11.1 What DAIDALUS computes (read from `nasa/WellClear`, `PVS/DAIDALUS/`)

- A maneuver is a trajectory `traj: [nnreal -> [Vect3, Vect3]]` (`int_bands.pvs`) that keeps
  maneuvering forever: for track bands `traj(t) = turnOmega(so, vo, t, +-omega)`
  (`aviation@kinematics_turn`), a turn at constant rate `omega` and ground speed `g`,
  with position `so + (g/omega) * (cos th0 - cos(omega t + th0), sin(omega t + th0) - sin th0)`
  and velocity `g * (sin(th0 + omega t), cos(th0 + omega t))`, altitude linear.
  Ground-speed, vertical-speed and altitude bands use the analogous constant-acceleration
  trajectories (`kinematic_gs_bands`, `kinematic_vs_bands`, `alt_bands`).
- A resolution is the moment `tj` at which the ownship stops maneuvering and flies
  straight ("jump off"): state `traj(tj)`, then `traj(tj)`1 + (t - tj) * traj(tj)`2`.
  DAIDALUS only considers `tj = k * ts` with `ts = trk_step / omega` (default
  `trk_step` = 1 degree), `k <= MaxN`.
- Resolution `k` is in conflict (`conflict_step`, `int_bands.pvs`) iff any of:
  (a) loss of separation with some intruder at a sample time `j * ts <= k * ts` during the
  maneuver itself (`first_los_step`), only at the samples `B <= j*ts <= T`;
  (b) the straight segment after `tj` is in conflict with some intruder within the
  lookahead (`CD_future_traj`: `CD(max(B - tj, 0), T - tj, traj(tj), intruder at tj)`,
  where `CD` is an exact straight-line detector such as `ACCoRD@cd2d`/`cd3d` or the
  well-clear interval detector);
  (c) optionally, a coordination criterion (`repulsive_at`) fails at some sample.
- `bands_search_index` is the first `k` whose maneuver phase already hits (a) or (c);
  every later `k` is conflicting because reaching it passes through that moment.
  `kinematic_bands` returns the conflict-free `IntBand`s of `k` below that index
  (`nat_bands`), scaled by `trk_step`, then merged left/right and reduced mod 2 pi
  (`combine_bands`, `mod_bands`). Soundness is `bands_sound?`, stated for the sampled
  predicate only.

Two discretizations therefore limit the result: resolutions are examined only at
multiples of `trk_step`, and separation during the maneuver is checked only at multiples
of `ts`. Both are exactly the holes you remember.

### 11.2 The exact formulation

Fix one intruder (multiple intruders are a union) and one maneuver family. Let `tj >= 0`
be the jump-off moment, the free variable. Define

```
conflict(tj)  IFF  turn_los(tj) OR straight_conflict(tj)
turn_los(tj)         IFF  EXISTS (t): B <= t AND t <= T AND t <= tj AND LOS(traj(t), intruder(t))
straight_conflict(tj) IFF  EXISTS (t): max(B, tj) <= t AND t <= T AND
                                       LOS(traj(tj)`1 + (t - tj) * traj(tj)`2, intruder(t))
```

with `LOS(p, q)` the separation predicate (cylinder: `sqv(hor(p - q)) < D^2 AND
|alt(p - q)| < H`; well-clear: `horizontal_WCV_taumod` and its vertical part).
`intruder(t) = si + t * vi`. The exact band is `{tj : NOT conflict(tj)}`, and the
discretized DAIDALUS band is its restriction to `tj = k * ts` with `turn_los` sampled.

Algebraization. For the turn, substitute `u = tan(omega t / 2)` and `w = tan(omega tj / 2)`
(`t = (2/omega) atan u`, monotone on `[0, pi/omega)`; a full half-turn is one chart, the
other half is the other sign of `omega` or a second chart). Then `cos(omega t)`,
`sin(omega t)` are rational in `u` with denominator `1 + u^2 > 0`, so `traj(t)` is
rational in `u`, `traj(tj)` rational in `w`, and every atom of `conflict` becomes a
polynomial inequality after multiplying through by the positive denominators:
- `turn_los`: the ownship is on a circle (trigonometric in `t`) while the intruder moves
  linearly in `t`, so the relative squared distance is
  `A(t) + Bc(t) cos(omega t) + Bs(t) sin(omega t)` with `A` quadratic and `Bc`, `Bs`
  linear in `t`. This atom is not algebraic in one variable: the substitution
  `u = tan(omega t/2)` makes the trigonometric part rational but leaves the linear `t`,
  and `t = (2/omega) atan u` is transcendental. Exact treatment: replace `cos`, `sin`
  by the polynomial upper and lower bounds in NASALib `trig@trig_approx` (`sin_bounds`, `cos_bounds` with `sin_lb`, `sin_ub`, `cos_lb`, `cos_ub` of any order `n`)
  on subintervals of `[B, min(T, tj)]`, which gives
  polynomial over- and under-approximations of the atom, and apply QE/CAD to those.
  The result is sound and can be tightened to any precision by subdivision; it is a
  strictly better treatment than DAIDALUS's sampling at multiples of `ts`, which is
  neither sound nor complete between samples.
- `straight_conflict`: polynomial in `(w, t)`: `traj(tj)` is rational in `w` and the
  segment is linear in `t`. For the cylinder this is a quadratic in `t` with coefficients
  polynomial in `w`; for well-clear it is the Boolean combination in
  `horizontal_WCV_taumod_rew` with the `tau_mod`, `tcpa` quotients cleared by sign cases.

Quantifier elimination in `t` (Phase 3 or 5) turns `straight_conflict(w)` into a
quantifier-free formula in `w`, a finite union of intervals with real algebraic
endpoints; mapping through `tj = (2/omega) atan w` gives the exact set of jump-off
moments, hence the exact track band. Combined with the bounded treatment of
`turn_los`, the band is exact on the straight-segment side and conservative to a
chosen precision on the turn side. For the constant-acceleration families
(`gs`, `vs`, `alt`) both parts are polynomial in `(tj, t)` and the band is exact.

### 11.3 What the CAD library delivers for this

1. `exact_bands(family, LOS, so, vo, intruders, B, T, params): list[AlgBand]`: verified,
   executable; `AlgBand` has real-algebraic endpoints with rational isolating intervals.
   Theorem: `tj` is in some returned band iff `NOT conflict(tj)` (for the `gs`, `vs`,
   `alt` families and for the straight-segment part of track bands) and the returned
   bands are contained in the conflict-free set (for the turn-phase part).
2. A refinement to rational bands at a requested precision, inner (safe) and outer.
3. The lemma that DAIDALUS's sampled bands lie inside the exact conflict-free set, and
   a computable bound on what the sampling misses.
4. The same machinery answers the safety question directly: "is there any conflict-free
   resolution?" is `EXISTS (tj): NOT conflict(tj)`, a closed formula for the `qe`/`cad`
   strategy, giving formally proved recovery/existence results rather than sampled ones.

### 11.4 Symbolic parameters: deriving the analytic bands (user's request, 2026-09-09)

Notation: `D` is the horizontal separation threshold (radius of the protected cylinder,
`DTHR` for well-clear), `H` the vertical threshold, `[B, T]` the lookahead window,
`g` the ownship ground speed, `(sx, sy)` the relative horizontal position, `(vix, viy)`
the intruder velocity.

Instantaneous maneuvers make everything polynomial. With the new ownship velocity
`nvo = g * (c, s)`, `c^2 + s^2 = 1`, the cylinder conflict predicate is

```
conflict(c, s) IFF EXISTS (t): B <= t AND t <= T AND
                   (sx + t*(g*c - vix))^2 + (sy + t*(g*s - viy))^2 < D^2
```

(vertical part: `|sz + t*(nvz - viz)| < H`, also polynomial). Eliminating `t` with all
parameters symbolic is a one-quantifier QE problem with eight to ten free variables;
its output is a case formula in the parameters whose cases are ACCoRD's analytic band
solutions: tangency of the relative velocity to the protected zone (`trk_line`,
`tangent_line`, discriminant `Delta = D^2 * (v.v) - det(s, v)^2`) and the intruder being
at distance exactly `D` at time `T` or `B` (`trk_circle`, `circle_solutions`). So the CAD
derives the theorems of `ACCoRD@trk_bands_2D`, `horizontal_criterion` and
`cd2d` rather than only checking instances, and the same run with the well-clear atoms
derives the well-clear bands, for which no hand-derived analytic form exists.

This is the multi-variable, purely polynomial target for the decision procedure:
- Phase 3 (branching QE) can already eliminate `t` with symbolic parameters, since the
  branching is on signs of coefficient polynomials in the parameters; the output size
  is the risk, and it is the reason to build the partial-CAD simplifications of
  Phase 6 (equational constraint `c^2 + s^2 = 1`, sign-condition pruning).
- Phase 5 (CAD) with `t` and `(c, s)` as the highest levels and the parameters below
  gives the full decomposition, i.e., bands as functions of the parameters, and the
  universally quantified correctness lemmas of ACCoRD (`trk_bands_2D` and the
  criteria theories) become `cad` targets with their parameters free.
- Kinematic maneuvers reduce to this after the tangent-half-angle substitution for the
  straight part (11.2) and the trigonometric bounds for the turn part.

Benchmark set for the decision procedure, to complement the executable bands:
1. `WellClear/PVS/WellClear/WCV_inclusion.pvs`: `tcpa <= safe_tau`, `taumod <= tcpa`,
   `tep <= taumod`, and the `WCV_inclusion?` theorems, universal over `s`, `v` and the
   thresholds, with quotients cleared by sign cases (five to eight variables).
2. ACCoRD `cd2d`, `horizontal_criterion`, `trk_bands_2D` lemmas with parameters free.
3. Literature problems for comparison with QEPCAD and Redlog: Kahan's ellipse in a
   circle, the Collins–Johnson examples, `x^2 + y^2 < 1 AND y > x` and its relatives.

Order of work: the cylinder detector with the straight-segment part (pure QE in `(w, t)`),
then the constant-acceleration families (polynomial, no trig), then the turn-phase
part with trigonometric bounds, then well-clear with `taumod`. Coordination criteria
(`repulsive_at`) are polynomial as well and can be added as extra atoms.
