# Completeness plan — a (cad) that always answers

> **Finished 2026-09-28** (section "Done -- THE GOAL IS REACHED"): decide5 is proved sound and
> complete (`complete_all`). Later goals: GAP_PLAN.md, then NEXT_PLAN.md.

Written 2026-09-27, after the user set the goal: make (cad) verified
COMPLETE, not only sound.  It rests on a review of the executable decision
(decide5 and everything it calls) and of the proved library; the review's
findings are in section 2 and are checked by the canaries of stage C0.

## 1. The goal

Today (cad) is verified SOUND.  `decide5_correct` (cad_decide5.pvs) says

    decide5(reverse(os), F, phi)`ok IMPLIES
      (decide5(reverse(os), F, phi)`val IFF fsem(os, F, phi, null))

for any number of quantifiers, and every (cad) proof goes through it.
Nothing says `ok` is ever TRUE; when it is FALSE, (cad) reports "the
certificate did not pass" and proves nothing.  The goal is a decision
without that escape:

    decide_u_correct: THEOREM wf?(os, F, phi) IMPLIES
      (decide_u(reverse(os), F, phi) IFF fsem(os, F, phi, null))

where `decide_u` is the fast decision itself (not a slower replacement), and
`wf?` says what the strategy's translation already guarantees (atom indices
in range, every polynomial in the prefix variables only, list shapes).
Equivalently: for every well-formed input some fuel makes decide5's
certificate pass (`decide5_complete`, stage C8), and decide_u is decide5
with that fuel.  Then (cad) proves every true closed prenex sentence and
refutes every false one, at the fast decision's speed, given time.

The strategy layer (Lisp) stays outside the theorem: it only chooses steps,
and when the decision answers, its proof (the correctness theorem, ground
evaluation, the reflection equations, the quantifier walk) closes.  The
library gates check that; no theorem can.

## 2. What is true today

The review traced every way the executable decision can return `ok = FALSE`.

**Every one of them is a fixed fuel constant running out.**

| constant | where | what it bounds | example predicted to fail (C0 checks it) |
|---|---|---|---|
| `sfuel2 = 24` | walk_def.pvs:178 (seps), walk_od.pvs:275 (seps_t) | `swide` doubles the search radius at most 24 times; `sint` bisects at most 24 deep; `spick` retries | a fibre root beyond 2^24, e.g. FORALL y: EXISTS x: x > 10^8; two roots closer than about b/2^23, e.g. (x - 1/3)(x - 1/3 - 10^-8) |
| `gfuel = 64` | cell1.pvs:128 | `gapf` refines two root intervals until they are disjoint (`gaps_ok`) | roots 0 and 10^-25 (one quantifier); outer roots 1/3 and 1/3 + 10^-30 |
| `ifuel = 64` | sect_inv.pvs:77 | `sepf`, `clr` in `inv_chk` | a read root within about width/2^64 of a sector end |
| `tfuel = 12` | tower_def.pvs:76 | `tlo`/`thi`: 12 probes for Tarski-query ends where no chain entry vanishes | a derivative root at the gap's end with the root very close (three or more quantifiers) |
| `cfuel = 64` | cad_lift.pvs:238 | rounds of the closures `nclos_o`, `tclos_o`, `iclos` | no bound on the rounds is proved |

**No check needs more than fuel.**  With unlimited fuel every check passes:
`memok?`/`slc?` (leading coefficients nonzero) hold by construction since
ztrunc truncates the members at each cell; `clok?` and `inv_chk` hold exactly
at the fixpoints of the two closures (the closure adds precisely the reads
that fail them); the searches succeed because at any cell the members have
finitely many roots, all distinct roots are a positive distance apart, and
`wok_exist` (walk_transfer.pvs:175) already proves that good separators
exist.  Nothing needs delineability: the soundness design never assumed it,
and completeness does not either.

**Two quantifiers.**  decq5 tries decw and then decn_o, so ok is
decw`ok OR decn_o`ok.  decw is structurally incomplete (no degree-drop
truncation: x*y - 1 fails at x = 0), decn_o is not, so completeness is proved
for decn_o and decw stays a fast path.

**One quantifier.**  decq2's only flag is `svs1ok = gaps_ok(...)`, i.e.
`gfuel`.  Root isolation (`iso`, `rootsc`) is already total and proved,
by well-founded recursion on the minimum root distance (`mrd`), and so is all
algebraic-number arithmetic (`alg_sign`, `alg_cmp`, `sepr`, `zero_at`).

**A complete decision already exists.**  Phase 5's `decide` (cad_decide.pvs)
has no flag: `decq_correct: decq(qs, F, Psi) IFF sem(reverse(qs), F, Psi,
null)` for any prefix.  It is exponential (unreduced pseudo-remainder
chains, 3^|F| branching; the circle-and-line example did not finish in 15
minutes in Phase 5), so it is a safety net, not the answer.

**The soundness proofs look fuel-generic.**  `walk_fib`, `gapf_between`,
`sepf_apart`, `clr_free` hold for any separators or fuel; the searches are
untrusted.  The .prf files unfold the constants in about 90 places.

## 3. The approach

Keep the fast decision and remove its fuel ceilings, in two ways:

1. **Where the data are exact, make the search total** (no fuel) by
   well-founded recursion on a non-computable measure, as `iso` and `sepr`
   already do with `mrd`: `gapf`, `sepf`, `clr` at the outer level.
2. **Where the search runs on a sign oracle** (the walk at every level, the
   closures), make the fuel a parameter `u` of the decision, prove that for
   every well-formed input SOME `u` makes the certificate pass, and wrap the
   decision in an escalation `decide_u` that tries larger `u` until it passes.
   Its termination measure is the non-computable least sufficient `u`
   (precedent: `iso`/`shrinkw`, alg_isolate.pvs), so it is still an
   executable total function.

The hard part is the existence of a sufficient `u`.  Two facts carry it:

- **Stability.** Every search stops at its first success (`swide` returns the
  first radius that passes, `sint` stops splitting a gap once it holds at
  most one root, `spick` the first non-root, the closures at their
  fixpoints).  So once `u` is large enough for a search, a larger `u` gives
  the same result, the cell tree stops changing, and one `u` (a maximum over
  finitely many cells) serves the whole tree.
- **A finite universe of reads.**  The closures add normalized intrinsic
  reads; at a cell these depend on the oracle only through finitely many
  sign branches, and the families only through finitely many subsets, so all
  reads that can ever be added lie in a finite set built level by level from
  F.  Each round adds a new one, so the rounds are bounded.

## 4. Stages

Each stage ends gated (tools/gate.sh on every changed theory), with
PROGRESS.md, top.pvs, memory and a commit, per CLAUDE.md.

**C0. Canaries (evidence first).**  The inputs of section 2, as TRUE
sentences decided by (cad-direct) in a scratch theory; they must fail today
and pass at the end.  Also the 100-sentence robustness set (98 proved within
300 s after the root-candidate fix; no certificate failure).  DONE
2026-09-27: all four predicted failures confirmed, each ok = FALSE within
2 s, while the same shapes at moderate scale prove —

| canary | sentence | fuel it exhausts |
|---|---|---|
| k1 | EXISTS x: x > 0 AND x < 10^-25 | gfuel (outer roots 0 and 10^-25) |
| k2 | FORALL y: EXISTS x: x > 10^8 | sfuel2 (radius 2^24) |
| k3 | FORALL y: EXISTS x: (x - 1/3)(x - 1/3 - 10^-8) < 0 | sfuel2 (bisection depth 24) |
| k4 | FORALL x, y: EXISTS z: z > 10^8 | sfuel2 at the innermost level |

(Constants must be written as literals: the translator does not evaluate
10^25 in a denominator, a small gap to close in the strategy.)

**C1. A complete decision now, as a safety net.**  `decide6(qs, F, phi) =
IF decide5`ok THEN decide5`val ELSE decide(qs, F, phi)` with
`decide6_correct` (from decide5_correct and decide_correct_os; no flag, no
hypothesis), and `(cad :complete? t)` to use it.  (cad) itself stays fail-fast:
`decide` can take hours, so it runs only when asked.  This makes the formal
statement true at once, for any number of quantifiers; C2-C8 make it true at
the fast decision's speed.  DONE 2026-09-27 (cad_decide6_def, cad_decide6):
the four canaries, all ok = FALSE on the fast path, are proved by
(cad-direct :complete? t) in 2-9 s each.

**C2. Fuel as a parameter.**  Thread one `u: nat` from decide5 down to every
fuelled call: `sfuel2`, `tfuel`, `cfuel` become `24 + u`, `12 + u`,
`64 + u` (and `gfuel`, `ifuel` until C3 removes them).  Re-prove soundness for
every `u` (the proofs are fuel-generic; the ~90 .prf places that unfold a
constant get re-run).  The strategy retries with larger `u` when ok is FALSE,
which already fixes the canaries in practice before any completeness proof.
DONE 2026-09-28: u threaded through walk_od's seps_t (fuel sfuel2 + u,
seps_t_eq against walk_fuel's seps_n) and all of towern_od (closure fuels
cfuel + u); decn_correct for every u; decide5 = the u = 0 instance, so the
strategy and the examples are unchanged.

**C3. Total refinement at the outer level.**  `gapf`, `sepf`, `clr`
recurse on a root-separation measure (as `sepr`, `iso`) instead of fuel.
Theorems: `gaps_ok(sortu(allroots(F)))` is always TRUE (consecutive roots are
distinct, `sortu_incr`); the free tests of `inv_chk` always decide; hence
**`decq2_complete`: the one-quantifier decision is complete** — the first
completeness theorem, and the model for the rest.  DONE 2026-09-28:
cell1's `gapw` and sect_inv's `sepw`, `clr1`/`clrw` (well-founded on
`dist`, `qdist`, `mrd`, with no fuel) back the fuelled searches, which still
run first, so the fast path is unchanged; `gaps_ok_incr`; the four free
tests are sound and now also complete (`between_free_complete`, ...,
`inv_chk_complete`: a polynomial without roots inside a sector passes);
`nroots_two_sect_inv` (exactly two roots are counted twice; named `nroots_two` until 2026-10-05).  complete1:
`decide5_complete1`, the fast decision answers every closed formula with at
most one quantifier.  Canary k1 proves on the fast path.

**C4. Tarski queries without end searches.**  `qsecl` searches for ends
where NO entry of the Tarski chain vanishes only because the NASALib
`sturm_tarski` theorem assumes that.  Prove the standard stronger form
(Sylvester's theorem on Tarski queries, as in Basu, Pollack, Roy): the query
needs only l0(a) and l0(b) nonzero.  Then
a = lo, b = hi (the separators, where the walk already checked that no member
vanishes), `tfuel` and `tlo`/`thi` disappear, and `qsec`ok` holds by
construction under the parent's `wok_t`.

Design (2026-09-28).  `sturm_tarski_ends`: x < y, constructed_sturm_sequence?
(NASALib's), p(0)(x) /= 0, p(0)(y) /= 0 imply nsc(x) - nsc(y) = NSol(>) -
NSol(<) on [x, y].  Proof by perturbation: take x' just right of x and y' just
left of y so that no chain entry vanishes on (x, x'] or [y', y) and p(0) has no
root on [x, x'] or [y', y] (finitely many roots); NASALib's `sturm_tarski` on
[x', y']; the root sets agree (`NSol_union_top`); the counts agree by
NASALib's `nsc_edge_diff` (a zero entry at an end has opposite-signed
neighbours by the remainder relation, no two consecutive entries vanish by
`constructed_sturm_seq_repeated_root` since p(0) does not, and the first entry
is nonzero, so the count is unchanged).  Then qsecl with a = lo, b = hi;
tower_ok's `tq_nsol` and `tower` restated without nzall?; qsec_rd's reads
lose the search probes (tlo_rd, thi_rd).  Only tower_def, tower_ok and
qsec_rd change (qe_tree's tfuel is a different function).  PART 1 DONE 2026-09-28: sturm_tarski_ends proved
(ends_inward, tsig_near, tss_opposite, tss_no_two_zeros, sign_keep,
nsol_none).  PART 2 DONE 2026-09-28: tower_ok's `tower` needs no nzall? at
all, since one? (one root, strictly inside, none other in the closed gap)
already makes l0 nonzero at lo and hi (`tq_nsol` from sturm_tarski_ends,
`tchain_first`); `qsecl` reads its chain at lo and hi and asks only lo < hi,
l0 nonzero at lo and hi and a count of one; `tlo`, `thi`, `nzall?` and
`tfuel` are gone, and so are the search probes in qsec_rd's reads
(`sent_det`: the ends' reads are chain-entry reads).  cell_ok:
`qsec_ok_complete` -- at a gap the walk certified (`lvl?`) every query is
sound -- and `allok_complete`, from `secp_gap` (the chosen member is nonzero
at the ends, vanishes at beta, and counts exactly one root: `secp_or`,
`cnt_unique`).

**C5. Leading coefficients.**  `memok?` and `slc?` hold at every cell with a
correct oracle (`tz_top`, `lmul_lc`, `strip` of structurally zero terms).  Small.
DONE 2026-09-28 (cert_all): `certz_all`, certz?(F, ws) at EVERY point ws --
the effective members' tops are nonzero there (tz_top) so strip keeps them
(strip_top); the product's coefficients above the degree sum vanish
everywhere (prodl_above), hence are structurally zero (zc_iff, through
mpoly_unique) and stripped (strip_at); at the degree sum it is the product of
the leading coefficients (prodl_top).  With walk_transfer's `wok_exist`,
separators passing wok? exist at every point.  And (od_exact, finishing C4)
every well-formed descriptor's oracle IS its point's: `okqs_complete`
(okqs(od, R) for every R at a wf? od, from allok_complete and qs_det) and
`wf_exact` (osg(od) = msg(den(od))).  So every walk in the tree below a
certified level runs at an exact oracle: C6 needs to be proved at exact
oracles only.

**C6. The walk's searches succeed.**  At a cell whose oracle is correct (it
answers the true signs at the point the descriptor denotes), for all
`u >= N` (N depending on the root bound and the minimum root separation of
the live members there — existence only), `seps_t` returns separators with
`wok_t` TRUE, and the same separators for every larger `u` (stability).
Oracles are correct at exact descriptors by construction, and below a section
by C4 and the certificates of the level above: induction on the levels.
This is the largest new argument.  DONE 2026-09-28 at the walk level
(walk_fuel, walk_count, walk_search): `seps_ok` -- at an exact oracle with a
certified family some fuel N makes wok? hold and every n >= N gives the same
separators; the bisection's termination by a nested induction on the
product's count and a shrink budget (sint_inner), without a global root
separation bound.  What remains for the tree: C2 (thread the fuel), then
the same statement through walk_od's tables (seps_t_eq) at every wf? cell.

**C7. The closures reach their fixpoints.**  Define the read universe
U_k(F) level by level (every rd_norm'd intrinsic read of every subset of the
level's universe, over every branch of the sign-dependent chain computations;
an enumerator in the style of the Phase 3 trees, whose `tconds` covers only
the old chains).  Prove every read at any oracle lies in it, so `nclos_o` and
`tclos_o` stop within |U| + 1 rounds; at the fixpoint `inv_chk` and `clok?`
hold (they are exactly the closures' stopping conditions).

**C8. Assembly.**  `decn_complete`: for every well-formed input there is a
`u` with `decn_o(u, ...)`ok` (induction over levels and cells with C3-C7 and
stability); `decide5_complete`; `decide_u` by escalation with the
non-computable measure; `decide_u_correct` (section 1); (cad) switches to
decide_u.  C1's fallback can then be retired or kept as an option.  DONE 2026-09-28: decn_complete (decn_ev), decide_u (decn_u,
decn_u_correct, decn_u_complete), decide5 switched to decn_u, and
complete_all's decide5_decides -- decide5 answers every closed formula
with its truth.  C1's fallback (decide6, (cad :complete? t)) is kept; it is
now never taken.

**Order and size.**  C0, C1 first (small; C1 gives the formal statement).
Then C3, C4, C5, which need no fuel parameter: C3 and C4 remove `gfuel`,
`ifuel` and `tfuel` outright, C3 gives the first completeness theorem (one
quantifier), and C4 adds real mathematics (a stronger Sturm-Tarski
theorem).  C2 then parameterizes only `sfuel2` and `cfuel`, a smaller
refactor of the soundness proofs, before C6-C8.  C6 and C7 are the core and are new kinds of
argument (stability across a cell tree; a finite universe of reads); together
they are comparable to the N1-N9 soundness work.  C8 is bookkeeping.  Risks:
C6 at non-exact cells (the probes of the search are answered by queries that
the certificate never checks: they must be shown correct, not just checked),
and C7's enumerator, which must follow the sign branches of every chain
construction exactly.

## 5. Literature

- Vermande, "Cylindrical Algebraic Decomposition in Coq/Rocq", CPP 2026: the
  first formal correctness proof of (Collins') CAD, with Mathematical
  Components; Sturm theory, Thom's lemma, root continuity with
  multiplicities, delineability of Collins' projection.
- Kosaian, Tan, Platzer, "A First Complete Algorithm for Real Quantifier
  Elimination in Isabelle/HOL", CPP 2023: complete multivariate QE (a hybrid
  of Tarski's algorithm and Ben-Or-Kozen-Reif, about 8500 lines); they call
  CAD "tremendously difficult to verify" and trade efficiency for a
  tractable proof.
- Cohen and Mahboubi (Coq): Tarski's algorithm, verified and complete,
  non-elementary.  McLaughlin and Harrison (HOL Light): Cohen-Hormander,
  proof-producing, small problems only.
- Basu, Pollack, Roy, Algorithms in Real Algebraic Geometry: Tarski queries
  by signed remainder sequences, with only the first polynomial nonzero at the
  ends (Sylvester's theorem), for C4.
- Narkawicz, Munoz, Dutle (JAR; the reference paper of this repository):
  Sturm and Tarski decision procedures for one variable in PVS.

This project's route differs from all of them: a certificate-checked
decision whose soundness needs no delineability, made complete by proving
that its certificates can always be found.

## 6. Rules

Unchanged from CLAUDE.md: proofs with pvs-cli; .prf files are written only by
PVS; prove everything, decompose when stuck; small theories wired into
top.pvs; a gate per changed file; PROGRESS.md, memory and a commit after each
verified item.  No unproved lemma enters the library: the goal theorems live
in this plan until their proofs are complete.

## 7. Handoff state (updated 2026-09-28, read this first)

A new session picks up here.  (A previous session could not run Bash in auto
mode -- the auto-mode safety check returned errors on every command late in
a very long conversation; run outside auto mode if that recurs.)

### Done -- THE GOAL IS REACHED (2026-09-28)
C0-C8 all proved.  Committed: C0, C1, C3, C4, C5 (555c2f8); C6 + C2
(ecee5fc); C7 (list_flat, read_univ, read_fam, tower_univ, clos_ok,
nclos_ok -- gated, whole library replayed); C8 (ev_pred, ev_nat, lev_ev,
tower_ev, clos_ev, decn_complete, decide_u_def, decide_u, complete_all;
cad_decide5_def/cad_decide5 switched to decn_u).

The headline theorem is complete_all's
  decide5_decides: decide5(reverse(os), F, phi)`val IFF fsem(os, F, phi, null)
for every closed formula (quantifier list os, polynomials F, sign-condition
formula phi), with no hypothesis: the decision (cad) evaluates always
answers, and its answer is the truth.  Soundness is decide5_correct as
before; completeness is decide5_complete.

### Possible follow-ups (not part of the goal)
- (cad)'s messages still mention a failing certificate (now unreachable).
- The escalation starts at u = 0; a strategy option could start higher.
