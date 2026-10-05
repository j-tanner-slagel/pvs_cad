# PERF_PLAN — making the n-level decision fast (2026-09-27)

> **Finished 2026-09-27/28** (the status sections below). Later speed work: QE_PLAN.md section 12,
> COLLINS_PLAN.md (the Collins run) and PROJ_PLAN.md (P1-P3, P5).

## Are the timings normal?

No.  Mature CAD systems (QEPCAD B, Mathematica, Maple, Redlog) decide most of
the Bath bank's closed problems in well under a second.  A verified procedure
running in PVS's ground evaluator pays a constant factor (exact rationals in a
functional setting, certificates checked at run time), but the gap here is
orders of magnitude, and it is not the doubly exponential cell count: bath_01
(two quadrics, three variables) starts with 11 outer sectors.

## What the profiles show (SBCL sb-sprof + sb-profile on the evaluator)

The time goes to the SAME pure computations, repeated:

| problem | where the time goes |
|---|---|
| e4_above (16 s) | ~50 %: the section oracle is REBUILT at every sign query -- `osent` calls `osg(od)`, and `osg(sec(..))` is `sg_sec`, which picks the member (`secp`: root counts through the oracle below) and builds its Sturm chain again, with `bprod` twice |
| bath_08 (256 s) | 250 s in `alg_sign2` (sign at the algebraic sample): 66,890 calls, **302 distinct**; 42 % of them from the rebuilt section oracles, the rest the walks and certificates asking again |
| bath_01, one sector's tower closure (123 s) | 62 s `i_rd` + 46 s `schain`: a table entry (`mkce`) builds its chain once and its reads twice, and `rchain2_rd` recomputes every step twice -- about SEVEN chain steps where one does; 13.5 s `bprod` (4,668 times, for the degree bound `bk`) |
| bath_02 (first 200 s) | 88 s `inv_chk` (the Sturm chain of the same read rebuilt for every sector), 79 s chains, 25 s `proj` (the projection recomputed inside every sector's tower, 8.4 s each) |

Also: each sector's closed tower is computed in every round of the outer
closure and twice more (certificate, value); tables are rebuilt in every round
of the tower closure.

**Experiment** (scratch caches in front of `osg` and `alg_sign2` at the Lisp
level, NOT kept): e4_above 16 -> 4 s, bath_08 256 -> 2 s, same answers.
bath_02/03 still > 300 s -- their time is in the chains, inv_chk, proj.

## Principle

The evaluator stays as it is: no Lisp-level caching (it would put unverified
code on the path (cad) trusts).  Every speedup is a change to the PVS
executable:
- parts OUTSIDE the trusted argument (proj, tw0, nclos_o, tclos_o, the
  separator and end searches) may change freely -- the certificates check
  whatever they produce (foldn_sem holds for any outer family; claim A for any
  tower that passes okn_o); only the tower's shape (k levels ending with F) is
  used;
- parts INSIDE it (chains, oracles, certificates, alg_sign2) change only with
  a proof that the new function equals the old one, or is correct directly.

## Stages (measure before and after each on bench_n; gate what changes)

- P1 chains once: `chrd` computes a chain and its reads in one pass; `mkce`
  and `i_rd` go through it (equality lemmas, no new mathematics).
- P2 the initial tower once: `decn_o` computes `tw0(k, F)` once and every
  sector's tower starts from it; the projection drops constant and duplicate
  members (untrusted; decn_ok's shape lemmas take the tower as a parameter).
- P3 the section oracle once per cell: the `sec` descriptor carries its member
  and chain, built by `osec`; `osg` of it only wraps them (well-formedness
  says they are `secp`/`schain` below; oddef, walk_od, qsec lemmas re-proved).
- P4 cheap signs at an algebraic sample: the sample's isolating interval is
  refined once per sector (`refine`, proved); `alg_sign2` first tries an
  interval-Horner enclosure of the query over the interval and falls back to
  the Sturm count (new lemma: the enclosure contains every value).
- P5 one tower per sector: the certificate and the value share it; the outer
  closure reuses the towers of sectors it has already closed.
- P6 `inv_chk` with shared chains: the Sturm chain of each distinct top read
  once, reused across sectors (`between_free` & co. already take the chain).
- P7 `bk` without the product.
- P8 re-measure the Bath bank, profile again, iterate; benchmark table.

## Status (2026-09-27, evening)

Done, proved, gated, whole-library replays clean:
- P1 chains once (chain_rd), P2 + P5 the initial tower and each sector's tower
  once (decn_o, decn_ok re-proved), P4 interval-Horner signs at algebraic
  samples (alg_isign, NASALib interval_arith), P7 cheap bk,
- P6b zero_at through a verified gcd (poly_gcd),
- R3 Sturm counts with each chain element evaluated once by Horner
  (sturm_fast; rcf_eq, nrh_eq -- equal to NASALib's counts).

| (cad-mn), decision only | before | now |
|---|---|---|
| e4_above (ALL ALL ALL EX) | 16 s | 3 s |
| e4_between | 13 s | 1 s |
| bath_08 | 256-280 s | 1 s |
| bath_01, one sector's tower | 123 s | 20 s |
| bath_02, 03, 04, 05, 07 | > 300 s | > 600 s (measured before R3) |

Tried and dropped: refining each sector's end roots once for inv_chk (fewer
Sturm counts, each dearer -- no gain).

What stops the rest (measured on bath_02): the certificate itself.  At one
sector the top family's walk reads 239 polynomials, degrees up to 102 (median
18) -- the coefficients of the Sturm chains of member PAIR PRODUCTS, the
walk's coincidence test -- and each must be shown sign-invariant on every
sector; their Sturm chains and the chain tables (symbolic chains in the outer
variables) are most of the remaining time.  This is not repeated work; making
it small means certifying less: coincidences by resultants instead of
product chains, squarefree reads, or a McCallum/Brown projection with
delineability -- each a change to the walk's certificate and its proofs.
Smaller items still open: P3 (the section oracle built once per cell: about
100,000 chain rebuilds on e4_above), a faster determinant for the n-level
projection (untrusted), shared read chains across sectors.


## Status (2026-09-27, night): fail fast, degree drops, witness first

The long Bath runs showed that most "slow" problems were FAILING: a
certificate that did not pass sent (cad) into decide2's 3^|F| read closure,
which never returns.  The main cause was degree drops (a leading coefficient
vanishing at a cell while its member does not), which the walk's
leading-coefficient conditions refused.  Done, proved and gated:

1. fail fast -- no exponential fallback above one quantifier; two
   quantifiers try decw, then decn_o (cad_decide5_def);
2. degree drops -- every member truncated at the cell (ztrunc's tz) in both
   effective families (feff, zf); the proofs of the zero-member case carried
   over (zfam, oddef, odreads, innern_sem, decn_ok);
3. witness first -- (cad) looks for a witness before the full decision:
   model search for existential goals, one existential position fixed to a
   small constant otherwise; (cad-direct) is the decision alone.

Bath closed problems now (whole proofs, quiet machine): 01, 03, 04 in under
a second (model search), 02, 05, 07 in about 12 s (a constant witness, then
a two-variable decision), 08 in 5 s; the library examples in 0.8-3.9 s.
Open: the Joukowsky family (09, 10) and Upper Half Plane (12), universal
sentences with no witness to find; every published tool times out on them
without a hand reformulation.  [2026-09-29: overstated -- a RegularChains CAD
result on a Joukowski instance after mechanical negation and splitting is
reported (Chen and Moreno Maza, ICMS 2014); check before citing.]  The certificate-size items above (resultant
coincidences, squarefree reads, a smaller projection) are what they need.
