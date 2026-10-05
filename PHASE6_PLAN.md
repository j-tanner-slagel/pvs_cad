# Phase 6 completion plan — from a validated projection route to a proved one

> **Corrected and superseded (2026-09-29, GAP_PLAN.md Tier 0; note added 2026-10-03).**
> `cad_projc` has no reducta, so it is Collins-like, not Collins' operator. The reduction below
> ("equivalently, two univariate families with the same psc signs realize the same sign
> vectors") is false: `psc_det_ce.psc_det_false` proves it fails. `delin_projc` is sector-local
> and needs connectedness. This plan was superseded by FINISH_PLAN.md (2026-09-21) and, for
> Collins' projection, by COLLINS_PLAN.md (finished 2026-10-01). It is kept as written, for the
> record.

Status as of 2026-09-16: the projection route decides ex_line, ex_circle,
ex_disc and ex_three correctly (negative controls pass) at 0.39–1.25 s, versus
1.59–68.89 s for the read closure and "does not finish" for ex_three. Measured
and banked as proved lemmas in `cad/cad_meas.pvs`. What is missing is a
correctness argument that covers an arbitrary input, plus the engineering to
put the route on the critical path.

## The fork: how to make the fast route PROVED

The current soundness chain is finite and algebraic, with no real analysis:

    inv1?(F,P)  =  every polynomial in reads1(F,s) is sign-invariant on s
    svs_det     =  two sign functions agreeing on svs_srd give the same answer
    qfoldS_sem  =  therefore the sample speaks for the whole sector, for ANY P

`qfoldS_sem` is already stated for an arbitrary family P. The projection fails
`inv1?` only because `reads1 = dedup1(svs_srd(...))` is the 3^|F| enumeration,
and the projection is not closed under *that* operator.

Two ways to finish. They are NOT equally expensive.

### Route 1 (REFUTED by measurement, see item B): make the read set cheap

`svs_srd` costs 3^|F| because `rsc_sg` branches on the sign of each leading
coefficient, and each branch continues the pseudo-remainder sequence
differently. But the *set of polynomials that can ever appear* is the
subresultant chain, which is sign-independent and polynomial-sized. So define

    rds(F) = the subresultant / Sturm chain polynomials of the family,
             computed directly (prem_arr, sturm_step, sg_chain machinery
             already in this repo), together with their principal coefficients

and prove the containment

    srd_sub: LEMMA member(c, svs_srd(k, F, sg)) IMPLIES memb(as_list(c), rds(F))

Then `sect_inv?` may use `rds(F)` in place of `reads1(F,s)`. Enlarging the read
set only makes the check STRONGER, so soundness is preserved and every existing
lemma above keeps its shape — `svs_det` is untouched. The check becomes
|rds| cheap `inv_chk`s instead of a 3^|F| walk, and `clos1` seeded with the
projection should reach its fixpoint immediately.

Crucially `srd_sub` is a finite algebraic statement provable by induction on
the chain construction. **No continuity, no IVT, no delineability.**

Note this converges with Collins: the principal subresultant coefficients ARE
the projection, so `rds(F)` and `proj(F)` are close relatives.

### Route 2 (CHOSEN): formalize delineability

**The reduction is DONE and gated (`cad_delin`).** `delin?` is a defined
predicate and `dec2_sem` proves the two-quantifier projection decision agrees
with the semantics for any family satisfying it. `subres` builds the psc as
determinants (`psc_eval` free from `det_eval`; `psc(f,g,0) = res(f,g)`, so
`cad_proj` is the j = 0 slice of Collins), `cad_projc` is Collins' operator,
and `collins_cost` measures that the correct operator adds NO roots below, so
the sector count and the speed advantage survive it. What remains is exactly
one statement:

    delin_projc: every sector of projc(F) satisfies delin?(F, -)

equivalently, two univariate families with the same psc signs realize the same
sign vectors -- sign determination, algebraic, no continuity and no
connectedness. Its remaining decomposition: (1) on a sector of `rts(P)` every
member of P has constant sign (`svec_between` of cell1 gives this once "no
root strictly inside a sector" is proved -- `gsects` has no inverse-structure
lemma yet, so that needs an induction); (2) same psc signs imply the same
realizable sign-vector set. (2) is the mathematical core.

McCallum's theorem: over a cell where `proj(F)` is sign-invariant (and no
member is nullified), the roots of F do not collide, appear or vanish, so one
sample point speaks for the cell. This needs root-continuity arguments — real
analysis, plus the nullification caveat, or Collins' larger operator with full
subresultant theory. This is a genuine formalization project and is the
fallback only if Route 1's containment turns out to be false or its `rds` too
large.

## Work items

**A. Housekeeping (in flight).** Gate `cad_meas`, commit, push.

**B. Decide the fork — DONE, 2026-09-16. Route 1 is dead; Route 2 it is.**

Measured (`cad_meas2`, proved as `read_set_small` and `root_sectors`):

| family | members | distinct reads | raw reads |
|--------|---------|----------------|-----------|
| f_line | 2       | 74             | 760       |
| q3     | 7       | 79             | 20132     |

The read SET is small and barely grows with the family while DISCOVERY is
3^|F| — which looks like a case for Route 1. It is not. The root-sector counts
are why:

    projection:   1 root  ->  3 sectors,  1 root sector
    read closure: 21 roots -> 43 sectors, 21 root sectors

`svsec` lifts a rational sector with `svs_pt` (polynomial) but a ROOT sector
with `svs_sg` (3^|F|), so **cost = #root_sectors x 3^|F|**. That reproduces
both timings: 21 x expensive ~ 63 s is cv_line's 68.89 s, 1 x expensive
~ 1.25 s is pv_line's.

Route 1 cannot fix this at any price, because a read-CLOSED family must
contain the ~74 read polynomials, and their roots are exactly what creates the
21 root sectors. Making the read set cheaper to compute leaves the sectors
where they are. **Delineability is required: it is what licenses the small
projection family.**

A second consequence, and it raises item E's priority sharply: exact algebraic
samples at root sectors would replace the last `svs_sg` with `svs_pt` and
remove the final 3^|F| from the fast path — benefiting the route whether or
not delineability lands.

**D. General n-level route. DONE (cad_pdec, gated).** `route3` in `cad_meas` is hand-built for exactly
three levels. Generalize to a recursive projection + lifting decision carrying
SAMPLE POINTS (not sign vectors) up the levels. Mostly mechanical.

**E. Algebraic sample points. NOW THE BLOCKING GAP, and bigger than first
written.** Two dodges were tried and both were refused by measurement:

  - *exact rational extraction* (`lin?`, then bisection for a midpoint that
    evaluates to zero). Works on the four examples, whose section coordinates
    are linear. On the Bath problems `cad-bench` reports
    `outer-level-rational = FALSE`: the coordinate is algebraic at the
    OUTERMOST level, so there is no rational to extract and `rsv` silently
    fell back to 0, making the answers untrustworthy (`ok = FALSE` caught it).
  - *the hybrid* `pdecq`: use `svs_pt` where a sample is exactly rational and
    the proved `svs_sg`/`alg_sign2` route where it is algebraic. Correct and
    fast on the four examples (0.24-0.85 s, `hybrid_examples`), and it needs
    no rational samples at all -- but it TIMES OUT past 280 s on every Bath
    problem, because those enter the 3^|F| branch immediately.

The obstruction is structural: **`svs_pt` is polynomial but TYPED on
`list[rat]` and cannot represent an algebraic coordinate**, while `svs_sg`
handles algebraic coordinates at 3^|F|. So the real item E is what every
serious CAD implementation does: exact arithmetic in an algebraic extension,
so that ROOT ISOLATION ITSELF works at an algebraic sample point. `alg_sign2`
solves the univariate sign problem; what is missing is arithmetic in Q(alpha)
-- add, multiply and compare algebraic numbers, and Sturm chains over them --
and then a specialization of the family at an algebraic point.

**Candidate that may avoid Q(alpha) entirely, TO BE MEASURED FIRST.** For a
member f(x, y) and a sample coordinate alpha that is a root of a rational
p(x), the resultant `Res_x(p, f)` is a polynomial in y with RATIONAL
coefficients whose roots include every y with f(x0, y) = 0 for some root x0
of p. So the candidate y-values stay algebraic over Q and representable as
`Alg`, every polynomial stays over Q, and `res` (sylvester) and `alg_sign2`
already exist. That would reuse the machinery instead of building an
extension field.

The honest caveat, which is why this is "measure first" and not "do this":
the candidate set is a SUPERSET -- it mixes in the y-values belonging to the
other roots of p -- so the candidates must be filtered by testing
f(alpha, y0) = 0, a zero test of a bivariate polynomial at a point with TWO
algebraic coordinates, which is the same hard problem again. It is only a
genuine saving if that filter can itself be done by resultants. Cheap to
test: build `Res_x(p, f)`, count its roots, and see whether the filter can be
expressed with existing pieces, BEFORE committing to either route.

**F. Rewire and re-prove.** Put the route on `decq2`'s critical path, re-found
its `ok`, re-prove `decq2_correct` and `decide2_correct`, rewire the `(cad)`
strategy. Re-gate every file touched. **Until F lands, `(cad)` is still the old
slow path — today's timings are harness timings, not strategy timings.**

**G. Benchmarks. RUN, and they are what redefined item E.** `cad-bench`
reports the projection decision's answer without touching the sequent.
Sanity: the four examples agree with `pdec_examples` using the STRATEGY's own
families, confirming the hand-written ones. Bath: `ok = FALSE` everywhere on
the rational route, timeouts everywhere on the hybrid. Two entries excluded
for defects in the SOURCE bank (06 has a conjunct with no relation operator,
11 unbalanced brackets), verified against the source rather than blamed on the
translator. `bench_pdec.pvs` holds the translations and is NOT in top.pvs;
vendoring the CC-BY-SA text remains the user's call.

**H. Gate the remaining Phase 6 files**: `mpoly_div`, `alg_fast`, `earr_deriv`,
`sturm_step`, `prem_arr`, `sturm_step2`, `cad_examples`, `sg_norm`, `sg_chain`,
`sg_chain2`, `sg_conj`, `sg_conj2`, `earr_ops`, `cell1`.

## Standing rules that constrain all of the above

Prove everything, never weaken a lemma. One PVS process at a time (8 GB).
Small topic-scoped files wired into `top.pvs`. Per-file gate = three fresh
`proveit -f` runs plus `--traces` with zero "fewer subproofs". After each
verified item: PROGRESS.md, top.pvs, memory, commit, push.
