# Item A — sample points that are algebraic, without Q(alpha)

> **Superseded** by FINISH_PLAN.md (2026-09-21), whose "what next" replaced this item's; the
> algebraic samples were built later (alg_* theories, cad/PROGRESS.md). Kept for the record.

## The gap, stated exactly

`svs_pt` is the polynomial-time lifting. It is TYPED on `list[rat]`, so it
cannot represent an algebraic coordinate at all. Every Bath problem has an
algebraic coordinate at the OUTERMOST level (`cad-bench` reports
`outer-level-rational = FALSE` on 01 and 03), so `rsv` falls back to 0 and the
decision reports `ok = FALSE` — it declines to vouch. The route that CAN
handle an algebraic coordinate, `svs_sg`, costs 3^|F| and times out past 280 s
on every Bath problem. Fast-but-silent or sound-but-too-slow: that is the gap.

## The old plan assumed an extension field. It does not need one.

PHASE6_PLAN.md item E proposed arithmetic in Q(alpha) — add, multiply and
compare algebraic numbers, Sturm chains over them — and flagged a
resultant shortcut as "measure first", with the objection that the resultant
gives a SUPERSET of the candidate roots and filtering the superset is the same
hard problem again.

**The superset never needs filtering.** What the lifting computes is the SET
of realized sign vectors over the fibre. Extra candidate points that are not
roots of anything simply subdivide a sector into two sectors carrying the same
sign vector. That is a refinement of the decomposition, not a wrong one: every
genuine root is still a section, every open interval still has constant sign,
and the SET of realized vectors is unchanged. So the objection dissolves and
the whole of Q(alpha) goes with it.

Three facts make the rest go through, all using machinery that already exists:

1. **Candidate roots stay over Q.** For `alpha` a root of `p(x)` and a member
   `f(y, x)`, `Res_x(p, f)` is a polynomial in y with RATIONAL coefficients
   whose roots include every y with `f(y, alpha) = 0`. Isolating its real
   roots is `alg_isolate` on a rational polynomial — existing.

2. **Signs at rational y are already solved.** For rational `y0`,
   `f(y0, x)` is a rational polynomial in x, and `alg_sign2(a, .)` gives its
   sign at `alpha` — existing, and `alg_sign2_sign` already proves it.

3. **Vanishing at a candidate is a SIGN CHANGE, not a zero test.** If
   `disc_y(f)(alpha) /= 0` and `lc_y(f)(alpha) /= 0`, then `f(., alpha)` has
   only SIMPLE roots, so it changes sign at each one. Testing `f = 0` at an
   algebraic candidate — the two-algebraic-coordinate zero test that forces
   Q(alpha) — is replaced by comparing the signs at the two rational points
   either side, which fact 2 already gives. Both `disc` and `lc` are
   PROJECTION polynomials, already computed, and their nonvanishing at
   `alpha` is again just `alg_sign2`.

The one primitive genuinely missing is the variable swap, because mpoly's
`res` eliminates the MAIN variable and we need to eliminate the second one.

## CORRECTION, found while building A1

Fact 2 above -- "signs at rational y are already solved by alg_sign2" -- holds
only when there is ONE algebraic coordinate.  At three variables the level-3
lifting happens over a level-2 SECTION, whose y-coordinate is algebraic, so
the sign test has TWO algebraic coordinates and alg_sign2 does not apply.  The
plan as first written understated the job.  What survives the correction:

  - CANDIDATE ROOTS at any level are still computable over Q, by ITERATED
    resultants.  For a level-1 coordinate alpha (root of p) and a level-2
    curve q, the level-3 candidates in z are the roots of
    `Res_y(Res_x(p, q), Res_x(p, f))`, a rational polynomial.  Supersets all
    the way down, and supersets are harmless for the same reason as before.
  - So the SECTORS are fine at every level.  Only the SIGN at a point with
    more than one algebraic coordinate is missing.

and there is a way to do that without an extension field either:

  **A-II.  sign(g(beta, alpha)) by interval refinement with a resultant
  certificate.**  Evaluate g over the box of the two isolating intervals and
  refine.  This terminates as soon as the box excludes 0, i.e. whenever
  g(beta, alpha) /= 0; the only obstruction is the zero test.  And
  NONVANISHING has a certificate: put `Z(y) = Res_x(p(x), g(y, x))`, a
  rational polynomial.  If `g(beta, alpha) = 0` then `Z(beta) = 0`, so

      alg_sign2(beta, Z) /= 0  IMPLIES  g(beta, alpha) /= 0

  and `alg_sign2` decides the left side.  When the certificate fires,
  refinement is guaranteed to terminate and gives the sign.  When it does not
  -- `Z(beta) = 0`, meaning SOME root of p makes g vanish at beta, possibly
  not alpha -- the honest answer is `ok = FALSE`, exactly as today.  Sound
  always, complete in the common case, and no separation bound and no Q(alpha).

So item A is two stages.  **A-I is 2-variable-complete on its own** and is a
prerequisite for A-II, so it goes first and gets measured first.

## Steps

**A1. `mpoly_swap` — the missing primitive.** Represent a bivariate member as
its coefficient MATRIX over the rationals and transpose it:

    prow(u)  = partial_eval(u, null[rat])          % Polylist of a univariate
    pmat(f)  = map(prow)(f)             : list[Polylist]   m[i][j] = coef y^i x^j
    transp(m): list[Polylist]                       % zero-padded transpose
    mswap(f) = map(LAMBDA l: mpol(map(mconst)(l)))(transp(pmat(f)))

    mswap_eval: THEOREM meval(mpol(mswap(f)))((: x, y :))
                      = meval(mpol(f))((: y, x :))

Keeping the transpose at the level of `list[Polylist]` — a matrix of RATIONALS
— turns the correctness proof into an interchange of two finite sums, instead
of an induction over the mpoly datatype. This is the one hard step.

**A2. `alg_lift_def` — the executable pieces.** No proofs yet.

    cand(a, f)  = the Polylist of Res_x(a`p, f), via mswap
    acands(a, F)= sortu of the isolated real roots over all members
    asgn(a, f, y0: rat) = alg_sign2(a, partial_list(mswap(f), (: y0 :)))
    aok?(a, f)  = f not nullified at alpha, lc /= 0, and disc /= 0 or deg <= 1

**A3. `alg_lift` — `svs_alg(F, a)`,** the realized sign-vector set over the
fibre above an algebraic coordinate: sections at the candidates, rational
points between them (`sects`/`svec_between`, already proved to give RATIONAL
points), open-sector vectors by `asgn`, section vectors by the sign-change
rule of fact 3.

**A4. MEASURE BEFORE PROVING.** Run `cad-bench` on the Bath bank and on
2-variable problems. With A-I alone the Bath entries are 3-variable, so the
expectation is `ok = TRUE` wherever the level-2 section coordinates happen to
come out rational and `ok = FALSE` otherwise -- the measurement is exactly
what says how much of A-II is needed. On 2-variable problems A-I should be
complete: `ok = TRUE` always.
Standing rule from the user: get something working that is right, then prove
it. If the measurement refuses this design the proofs are not wasted work,
because they will not have been written.

**A5. `alg_lift_ok` — correctness.**

    svs_alg_fib: aok?(a, F) IMPLIES
      (FORALL v: member(v, svs_alg(F, a)) IFF fib(F, (: value(a) :))(v))

  sub-lemmas: every root of `f(., alpha)` is a root of `cand(a, f)`
  (resultant vanishing); `aok?` makes those roots simple, hence sign-changing;
  no member vanishes strictly between consecutive candidates.

**A6. Wire it in.** `svs_pt` keeps the rational samples, `svs_alg` takes the
algebraic ones, and `dec`/`decok?`/`pdecide` dispatch on the sector's sample.
`decn_sem` is stated over `decok?` and should carry through unchanged.

**A7. Fallback, so correctness never degrades.** When `aok?` fails — alpha
sitting on a discriminant root — fall back for THAT CELL ONLY to the proved
`svs_sg` route. 3^|F| is then confined to the rare cells instead of being
entered at the outermost level, which is what makes the Bath problems
exponential today.

## What this does not fix

Delineability in general (blocker B) is untouched: this is about the decision
being able to RUN at an algebraic sample, not about it emitting a proof.
A CAD that answers Bath problems in seconds with `ok = TRUE` is the
deliverable here.

## OUTCOME (2026-09-19): A-I built, measured, gated — and it is partial

A1 `mpoly_swap` (29/29), A2-A3 `alg_lift` (10/10), A4 `alg_meas` (14/14),
A6 `alg_dec` (1/1) and `alg_dec_ex` (8/8) are all done and gated. The design
works: the lifting runs at an algebraic sample point with no Q(alpha), and the
superset claim held up under measurement exactly as argued.

**But A-I stops at a discriminant root**, and the measurement is unambiguous:
on `x^2 + y^2 - 2` the per-sector check reads
`(: TRUE, FALSE, TRUE, FALSE, TRUE :)` — the three open sectors pass, the two
sections fail. Those sections are roots of the discriminant, so the fibre has
a repeated root, no member changes sign there, and the sign-change rule that
replaces the zero test is invalid. A discriminant root is a section of every
CAD; this is the generic critical point.

**So the plan's staging was right but its accounting was wrong.** A-II is not
an optional extension for three-variable problems: it is needed for two
variables as well, at every vertical tangent.

And A-II's own design needs revisiting. The interval-refinement-with-
resultant-certificate sketch above decides NONVANISHING; at a discriminant
root the interesting case is precisely vanishing. The route that does decide
it without an extension field is the SUBRESULTANT CHAIN: division-free, its
specialization is already `subres2`'s `sresc_eval`, and the signs of its
entries at alpha are `alg_sign2` calls on rational polynomials. Turning those
signs into a root count is `sh_count`.

**`sh_count` is also exactly what delineability needs.** The two blockers this
plan treated as independent are one theorem. That is the finding that should
drive what comes next, and it makes `sh_count` the single remaining piece of
mathematics for the project rather than one of two.

NASALib's `Tarski` already has Sturm-Tarski over REAL coefficient arrays, so
the counting half exists; what is missing is the subresultant/PRS
correspondence that makes it executable at an algebraic point.
