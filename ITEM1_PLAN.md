# Item 1: proving psc_det?, the last correctness obligation

## The target

    psc_det?(F):  svec(projc(F), (: x :)) = svec(projc(F), (: y :))
                  IMPLIES  fib(F, (: x :)) = fib(F, (: y :))

With `delin_from_psc` (this file's Stage A) and `dec2_sem` (proved, gated),
this alone makes the two-quantifier projection decision correct.

## Two shortcuts, both closed by measurement

1. **Read-closure.** `svs_det` is already proved: sign functions agreeing on
   `svs_srd` give the same `svs_sg`, and `svs_sg_sound/complete` say that IS
   the fibre set. So if the projection made the reads sign-invariant, item 1
   would be free. Measured: `inv1?(F, proj(F))` FALSE, and
   **`inv1?(F, projc(F))` FALSE as well** (74 distinct reads against 10
   members). Worse than unproven -- `inv1? = FALSE` says some read genuinely
   CHANGES SIGN inside a sector, so "the reads are determined by the
   projection" is false, not merely unproved. `svs_det` is sufficient, not
   necessary: the reads may move while the answer does not.

2. **A cheap runtime certificate.** `inv1?` is the only check the existing
   architecture offers, and it is both expensive (3^|F|) and false here.
   Sampling more points is not a proof.

So the classical theorem is required.

## The scope reduction that makes it tractable

The expensive and risky part of subresultant sign determination is the GAP
(defective) structure: what happens when the remainder sequence drops degree
by more than one. That is where an estimate doubles.

It can be avoided. The decision already carries an `ok` flag and already
reports FALSE rather than guessing. So prove delineability for the
NON-DEFECTIVE case and have the decision VERIFY the side conditions at
runtime -- and those conditions are themselves members of `projc`, hence
automatically sign-invariant on a sector by `sect_svec`:

    lc(f)     /= 0  on the sector   -- constant degree
    disc(f)   /= 0                  -- f squarefree, no repeated roots
    res(f, g) /= 0                  -- distinct members share no root

When they hold the Sturm-Habicht chain is generic, its entries' leading
coefficients ARE the psc, and the root count follows from sign data alone --
no gap analysis, and no continuity argument either, because the count comes
from Sturm's V(-inf) - V(+inf) rather than from roots moving continuously.
When they fail the decision reports `ok = FALSE`: sound, incomplete, and
honest, exactly as it already does for inexact samples.

Estimated 8-15 sessions rather than 15-30, with the research risk removed
rather than merely deferred. The defective case can be added later without
invalidating anything proved here.

## Stages

**A. Isolate the gap.** `delin_bridge`: `sval_in` and `delin_from_psc`, so
that `psc_det?` is the only open statement, with no CAD machinery around it.
Chains to `dec2_sem`. SMALL -- in progress.

**B. Degree and leading coefficient.** All coefficients of each member are in
`projc` (`cofs`), so equal signs give the same leading nonzero coefficient and
the same specialized degree. Small.

**C. The chain from psc signs (the core).** In the non-defective case the
subresultant chain entries' leading coefficients are the psc. Prove the sign
of each chain entry at +-infinity is determined by psc signs. `subres` already
builds psc as determinants with `psc_eval` free from `det_eval`.

**D. Root count.** Sturm: the number of distinct real roots is
V(-inf) - V(+inf) of the chain, so C gives the same count at x and y.

**E. Interleaving and the sign-vector set.** `res(f,g)` sign decides whether
two members share a root; with C and D the ordered root structure is
combinatorially identical, hence the same realizable sign vectors -- which is
`psc_det?`.

## Discipline

Measure before building at every stage -- this session alone, six hypotheses
that looked sound died on measurement, including both shortcuts above. Each
stage lands as its own gated file, wired into top.pvs, committed.
