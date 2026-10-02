# Progress notes — pvs_cad

Newest first. One entry per working session or verified item. Every entry records what
was proved or built, what was verified and how, what was learned, and what is next.
The LLM usage table is regenerated with `tools/llm_usage.py` (writes `paper/llm_usage.*`).

## 2026-09-16 (end) - the real benchmark set, fetched and parsed

- THE standard CAD benchmark is the Bath CAD example bank: Bradford, Davenport
  and Wilson, "A repository for CAD examples", ACM Communications in Computer
  Algebra 46(3) 67-69, doi 10.1145/2429135.2429137; dataset maintained by
  David Wilson, University of Bath Research Data Archive v4 (2013),
  doi 10.15125/BATH-00069, CC-BY-SA 4.0. Three files: examplebank_v4.pdf
  (properties and sources), examplebank_v4.txt (Maple), and
  QEPCADexamplebank_v4.txt (QEPCAD input). Fetched both .txt to
  /tmp/cad_scratch; NOT vendored into this repo (share-alike licence - decide
  with the user before adding it).
- Entry format: [Name], the variable order, the NUMBER OF FREE VARIABLES, then
  a Tarski formula, e.g.
      [Parametric Parabola] / (a,b,c,x) / 3 / (E x)[a x^2 + b x + c = 0].
  The PDF additionally carries, per example, the MINIMAL NUMBER OF CELLS of a
  full CAD with reproduction details - a hardware- and
  implementation-independent measure, which is the right yardstick for a
  verified implementation that will never match a C library on wall-clock.
- PARSED (parser + bath_bank_parsed.json in /tmp/cad_scratch): 78 entries, 30
  with zero free variables, of which 12 are genuinely CLOSED PRENEX, i.e. the
  shape (cad) decides:
      3 quantifiers: Ball and Circular Cylinder, Collision of Circle and
        Square, McCallum Trivariate Random Polynomial, Term Rewrite, and the
        four Buchberger-Hong randoms (A, B, A-Grobner, B-Grobner)
      4 quantifiers: Joukowsky Transformation (x2), Separate Clauses,
        Upper Half Plane
  The MINIMUM quantifier count among them is THREE. The other 48 entries are
  parametric (2, 3, 4, 5, 6, 8 and 11 variables) and need QE, not a decision.
- CALIBRATION, and it is unflattering: the field's entry-level decision
  problems all need >= 3 quantifiers, and ex_three (3 quantifiers, trivially
  true, linear) times out. So we cannot currently attempt a single problem
  from the standard set. The 3^|family| wall is the gap between this
  implementation and the benchmark suite - not a tuning issue.
- Named classics present in the bank, for later reference: Davenport and
  Heintz, Hong-90, Solotareff-3, X-axis Ellipse, Ellipse Problem, Arnon-84
  (and -2), Whitney Umbrella, Collins and Johnson, Kahan, ArcSin, Termination
  of Term Rewrite System, Range of Lower Bounds, Parametric Parabola.
- No external tool is installed here to cross-check (no qepcad, redlog,
  reduce, z3, cvc5, Mathematica), and no WellClear checkout, so the
  independent-oracle comparison the plan wants needs those obtained first.

## 2026-09-16 (end) - calibration: the plan targets 5-8 variables, 3 fails today

- CAD_PLAN.md's benchmark set (plan lines 372-375, 477-479, 765-768) is the
  DAIDALUS well-clear volume (`WellClear/PVS/WellClear/WCV_inclusion.pvs`,
  "five to eight variables") and the ACCoRD universal lemmas, plus the
  literature problems (Collins's cubic, the circle/line textbook examples).
  So the 3^|family| wall is not an academic curiosity: the target is 5-8
  variables and THREE currently times out. It blocks the stated goal.
- For calibration against the field: quantifier elimination over the reals is
  doubly exponential in the variable count (a proved lower bound), so hard
  problems are genuinely hard - but these examples are not hard. ex_line is
  linear and ex_three (FORALL x, y: EXISTS z: z > x AND z > y) is trivially
  true. Unverified tools built for this (QEPCAD B, Mathematica's
  CylindricalDecomposition, Redlog, the nonlinear arithmetic in Z3 / SMT-RAT)
  dispatch this shape in milliseconds. 48 s for ex_line is ~4 orders of
  magnitude off a production tool.
- Against VERIFIED CAD there is no practical competitor to compare with: the
  Rocq mathcomp CAD (CPP 2026) is proved correct but not executable, and the
  Isabelle multivariate QE (CPP 2023) is executable but impractical (see the
  prior-art survey). That gap is this project's point - and it means there is
  no external number making 48 s look acceptable.

## 2026-09-16 (end) - why ex_three cannot work: the walk is 3^|family|

- MEASURED the scaling of `svs_srd` in the SIZE OF THE FAMILY passed to it,
  on prefixes of ex_three's round-1 level-2 family (one sector, ~0.8 s base):
      |F|:      1     2      4      5       6
      sfuel:   10    16     42     48      61
      reads:   19    45   1305   4567   12701
  Each added member multiplies the read list by about three - exactly the
  three-way recursion of `rsc_srd`/`rsc_sg` over L (sg_svs.pvs:27-43), which
  is 3^|F| nodes before pruning. Extrapolated: |F| = 10 is ~10^6 reads FOR ONE
  SECTOR, and round 2's family of 40 is out of reach entirely. `sfuel` grows
  with |F| too (rfuel includes lsum(L)), so the chains lengthen at the same
  time.
- THIS is the two-vs-three quantifier split, and it is not a local
  inefficiency. For two quantifiers `decq2` walks
  `svs_sg(sfuel(F), F, asgS(s))` with F the FORMULA's atoms - 2 for every
  example here, so 3^2 = 9 nodes, trivial. For three or more it recurses as
  `decq2(r, Q, ..)` with Q = `clos(cfuel, m, lv(m), F, null)`, the ACCUMULATED
  PROJECTION FAMILY, so the next level down walks a family of 10, then 40.
- Consistent with the earlier numbers that looked anomalous: ex_three's
  round-1 family is TINY (10 polynomials, only 3 of positive degree, 3 raw
  roots, 1 distinct root, 3 sectors) yet its level-1 closure costs 98.79 s and
  `lv(2)` of it 130 s, while ex_line's 47-polynomial/43-sector closure costs
  5.5 s. Cost tracks 3^|F|, not polynomial count or sector count.
- CORRECTION (2026-09-16, later): an earlier version of this entry called this
  an "architectural limit" and I used the phrase "three-quantifier wall". That
  OVERSTATED it and conflated a defect of OUR design with a property of CAD.
  There is no such wall in the literature. What IS real: Davenport and Heintz
  (Real quantifier elimination is doubly exponential, JSC 1988) prove QE is
  INTRINSICALLY doubly exponential in the number of variables/quantifiers -
  formulas linear in the quantifier count whose quantifier-free equivalent is
  doubly exponential, double-exponent lower bound n/5 + O(1), later n/3 + O(1).
  That bound bites on ADVERSARIAL families (their own construction is entry
  "Davenport and Heintz" in the Bath bank, 4 variables). In practice 3- and
  4-variable problems are routine for real tools; feasibility tracks degrees,
  structure and variable ordering, not a quantifier threshold (one 12-variable
  economics QE exhausted memory only after eliminating 5).
  ex_three is FORALL x, y: EXISTS z: z > x AND z > y - linear, trivially true,
  3 variables, no intrinsic hardness at all. Failing it is OUR 3^|family|
  enumeration, i.e. a consequence of decision 12 (realized sign vectors, no
  delineability) that we can change - not a limit we must respect.
- So ex_three is a limit of THIS DESIGN: the projection family grows each round
  and the enumeration is exponential in it. Reaching it needs one of
    (a) far stronger pruning than ctree2_sg's false-prefix cut,
    (b) a level>=2 representation that does not enumerate sign vectors over
        the whole family (i.e. delineability-based lifting, which decision 12
        deliberately avoided), or
    (c) aggressive family shrinking - note there is NO content/primitive-part
        normalization anywhere in the library (`addnew` admits a read unless
        `memb`, i.e. structural `leq`, already has it), so c*p and p are both
        kept and each contributes its own roots and sectors.
  Micro-optimization cannot close the gap between 3^2 and 3^40 - but the
  ENUMERATION ITSELF is the thing to replace, and that is tractable: where the
  sign function is a concrete point (which is the case in the branch that
  blows up), the realized sign vectors can be read off by root isolation in
  time polynomial in the family, exactly as cell1/svs1 already does at level 1.
- Still worth doing for the two-quantifier path: `inv1?` re-sweeps every
  sector although `clos1`'s last round already established no read is bad
  (~5 s of ex_line's 48 s), provable as
  `bads(F, ss) = null IMPLIES all_inv?(F, ss)`, but it touches gated files.

## 2026-09-16 (later still) - (cad) evaluated the decision twice; two-stage split

- The 90 s of ex_line was ~58 s of DUPLICATED evaluation. `cad` computed the
  decision record twice: once in Lisp while elaborating (`recv (evalexpr
  recstr ..)`, to learn `ok`/`val` and hence whether to assert the formula or
  its negation) and once inside the proof (`(eval-expr recstr)`, which is what
  makes the answer checkable). One evaluation is ~29 s.
- FIX: split the strategy. `cad` now evaluates the record ONCE, in the proof,
  labels it `ev`, and calls a new helper `cad-finish__`, which reads `ok` and
  `val` off that labelled formula (`extra-get-formula "ev"`, then `search "ok
  := TRUE"`), rebuilds the cheap strings (cad-prefix, cad-bf, two
  `as_list(pnorm(..))` calls - all cheap; the globals `*mpoly-atoms*` and
  `*cad-polys*` are reset first) and emits the old script. `cad-strategy` drops
  its own `(eval-expr ..)` and keeps `ev` alive through the hide with
  `(hide-all-but (1 "ev"))` - `hide-all-but` takes a keep-LIST resolved by
  `gather-fnums`, so a label works (prover/strategies.lisp:4521).
- MEASURED, all three examples still Q.E.D.:
      ex_line    89.59 s -> 48.28 s
      ex_circle  24.51 s -> 13.76 s
      ex_disc     6.46 s ->  4.83 s
  Library files are untouched, so no re-proof and no re-gate.
- TRAP, cost me four wrong hypotheses: a `defstep`/`defhelper` whose body PVS
  cannot read fails SILENTLY - it prints "Error: Ill-formed rule or strategy,
  substituting (skip)" once and the step becomes a no-op, so the proof simply
  does not progress and no `cad:` message appears. The cause here was a
  top-level `let*` as the helper's binding form; plain `let` (which is already
  sequential - see `mpoly-eq__`, whose bindings depend on each other) works.
  `let*` NESTED inside a body is fine (alg-roots:275, poly-pos:382).
  Also: `*rulebase*`/`*steps*` are NOT where these register - the known-good
  `mpoly-eq__` and even `cad` itself report NIL there, so that probe proves
  nothing. Invoke the helper by hand on a prepared sequent and read the error.
- Why ex_line costs more than the circle although it is the trivial statement:
  the projection gives 47 polynomials / 21 roots / 43 sectors against the
  circle's ~29 and 11, and the value walk is linear in sectors; and
  `y*y >= 0` is two sign conditions, so the matrix is
  `band(batom(0,0), bor(batom(1,1), batom(1,0)))`, a three-leaf combination
  needing the bounded lift-if rounds, where the circle's is a plain
  disjunction.
- NEXT: `inv1?` re-sweeps every sector although `clos1`'s last round already
  established no read is bad (~5 s per evaluation); provable as
  `bads(F, ss) = null IMPLIES all_inv?(F, ss)` but it touches gated files.
  Then ex_three, still the only unproved example.

## 2026-09-16 (later) - Phase 6 performance: the at-root sign reads, found by measurement

- `ex_line` (FORALL x: EXISTS y: x + 2y = 1 AND y*y >= 0) never finished inside
  `(cad)`. Localized it by measuring, not reading: closure alone 0.60 s, plus
  sectors 1.46 s, plus the reads of ONE sector 37.19 s. Of 43 sectors, 21 are
  `at` (root) sectors; a rational sector's reads cost 2.61 s and an at-root
  sector's 35.76 s, a 13x penalty.
- THREE WRONG DIAGNOSES, each refuted by measurement and recorded here so they
  are not tried again:
  (a) "hoist `chain` out of `inv_chk`" - refuted: all 74 `inv_chk` calls of a
      sector are essentially free; the cost is computing `reads1`.
  (b) "`sep` rebuilds the Sturm chain per bisection round" - refuted: `sep`
      performed ZERO rounds on the measured read (width 198199/327680 before
      and after), so chain-passing into `sep` buys nothing.
  (c) "the reads are high-degree derived polynomials" - refuted: zero reads of
      degree > 20, and all 74 `alg_sign` calls on the real read set cost 1.09 s
      (~15 ms each). `alg_sign` per call was never the problem.
- The real cost is the NUMBER of sign queries. A walk with the sign function
  doing its work twice cost 67.88 s against a 34.94 s baseline, so the whole
  35 s of a sector is sign-function work: ~2200 queries per sector. The reads
  repeat: `snorm_sg` and `snorm_rd` walk the same list separately, `sl_sg`
  computes `snorm_sg` twice, and `ctree2_sg`/`ctree2_rd` each recompute
  `cst?`, `live` and `live_rd` over the same lists.
- FIX 1, `alg_sign2` (new theory, gated 8/8): `alg_sign` decides q(value(a))=0
  first with `zero_at`, which counts the roots of p^2+q^2, of twice the degree.
  `alg_sign2` counts the roots of q alone in the isolating interval first: with
  none, q cannot vanish at value(a) and keeps one sign there (`sturm_sign`), so
  the sign is q at the midpoint, one rational evaluation - no sum of squares
  and no `sturm` call. Falls back to `alg_sign` when q does have a root there.
  `alg_sign2_sign` is the semantics, `alg_sign2_def` the agreement. 50 of 74
  reads take the fast path.
- FIX 2, skip the root sectors: `inv_chk` is unconditionally TRUE at an `at`
  sector (the `at` arm of its CASES), so `badl` discarded every read it had
  just computed and `sect_inv?` held whatever they were. `sect_inv?` now
  short-circuits on `at?(s)` (same truth value, so `all_inv_mem` and the
  lemmas above it are untouched) and `bads` skips those sectors. Justified by
  `inv_chk_at`, `sample_at`, `badl_at`, `sect_inv_at`.
- Measured after: one at-root sector's reads 34.94 s -> 2.67 s, the same 74
  reads, matching the 2.61 s rational sector. The at-root penalty is gone.
- Proof repair: only `asgS_msg` and `reads_agree` broke. `asgS_msg` needed one
  citation swapped (`alg_sign_def` -> `alg_sign2_sign`) and replayed.
  `reads_agree` needed a case split on `at?(s)`: at a root sector `in?(s,x)`
  forces x = value(sample(s)), so `asgS_msg` makes the two sign functions
  equal and `agree` is immediate - the invariance check is not needed there.
  `sample_at` was required because the `CASES` from `sample` sits inside a
  LAMBDA body, where `assert` will not simplify it.
- TACTICS learned: `lift-if` before `ground` whenever the goal is a term-level
  IF (closed `alg_sign2_sign`); `skeep` takes the WHOLE implicit prefix, so a
  lemma needing list induction must be written `at?(s) IMPLIES FORALL R: ...`
  or `induct` reports "No change"; expanding a recursive function everywhere
  also unfolds the induction hypothesis, so expand in the consequent only.
- GATE PASSED, both files: alg_sign2 8/8 on three fresh runs plus a clean
  traces pass; cad_lift 80/80 on three fresh runs plus a clean traces pass,
  every log checked for zero "fewer subproofs", zero "proved - incomplete"
  and zero rerun-abort errors. The first cad_lift traces attempt had to be
  redone because I killed the running proveit with my own `pkill` (task exit
  144); that killed run left 68 of 80 formulas marked "proved - incomplete"
  plus "*** Error occurred while rerunning" - a KILL ARTIFACT, not proof
  damage, confirmed by the clean re-run and by the fact that a traces run
  which completes prints no per-formula lines at all (alg_sign2's log is 347
  bytes) and no other gate log of ~240 contains either marker.
- MEASURED: the ground evaluator DOES share a LET binding. Three inline
  copies of clos1(1,..) cost 3.98 s; `LET c = clos1(1,..) IN` used three
  times cost 0.54 s against a 0.47 s single-evaluation reference. So a
  repeated subterm is fully re-evaluated and LET collapses it to one - the
  basis for the next optimization.
- PROFILE of the remaining 90 s: the closure is NOT the problem. The full
  clos1(cfuel,..) returns 47 polynomials in 5.49 s and its 43 sectors take
  6.36 s, so ~6 s of the 90 s is closure work and ~84 s is the inv1? check
  plus the qfoldS value walk.
- TOOLING BUG FOUND: `tools/gate.sh` greps only for "fewer subproofs" and
  "unfinished|unproved|missing", so "proved - incomplete" and "*** Error
  occurred while rerunning" were invisible to it and a killed run could still
  report GATE PASSED. gate.sh now fails on all four signals.
- HAZARD (my own error, recorded so it is not repeated): running `(cad)` on an
  example through the server SAVES the result, so a measurement run can
  overwrite a committed proof. Use `--fail-proof` to quit without saving. I
  also misread a 117-insertion/450-deletion diffstat on cad_examples.prf as
  proof loss; per-formula comparison showed ex_circle/ex_disc/ex_three
  byte-identical to HEAD and ex_line GROWN from 144 to 5793 chars (PVS had
  merely reflowed the whole s-expression). Restoring the file to HEAD then
  discarded a legitimate new ex_line proof, which has to be regenerated.
- EXAMPLES. The baseline matters: at HEAD NONE of the four is proved. ex_line,
  ex_disc and ex_three are bare `(POSTPONE)` stubs; ex_circle's best stored
  slot runs `(CAD)`, closes branch 1 with a hand-written `(LIFT-IF -1)
  (ASSERT)` and postpones branch 2. So nothing here is a regression.
    committed strategy (rejected patch reverted): ex_line 90.17 s Q.E.D.;
      ex_circle and ex_disc return fast but do NOT close; ex_three > 300 s.
    with the rejected `lift-if` patch:            ex_line 90.95 s, ex_circle
      24.51 s, ex_disc 6.46 s all Q.E.D.; ex_three still > 300 s.
  So ex_line is newly proved either way, and ex_circle and ex_disc are newly
  provable only with the patch - which automates precisely the manual LIFT-IF
  that ex_circle's stored script already does by hand. The patch STAYS IN: the
  user confirmed they want it (2026-09-16), and it is what makes `(cad)` alone
  discharge these goals instead of leaving a hand-finished branch. (An earlier
  session note had recorded it as rejected; that note was wrong and I briefly
  reverted the patch on the strength of it.)
- PROFILE of ex_line's 90 s, by slope measurement (1x vs 3x/5x of the same
  expression, so the ~6.7 s closure baseline cancels instead of dominating a
  difference of two large numbers):
    closure clos1(cfuel,..)      5.5 s   (47 polys, all deg > 0)
    sects(rts(..))               0.9 s   (62 raw roots -> 21 distinct -> 43 sectors)
    inv1? sweep                  5.0 s   (22 non-at sectors x ~0.22 s; the
                                          at-sector skip is what makes this
                                          cheap - forcing reads1 at ALL 43
                                          sectors costs 110 s)
    gaps_ok                      0.9 s
    value walk qfoldS           ~18 s    (43 sectors x ~0.42 s; each sector is
                                          2 x rsc_sg over 3^2 nodes = 18
                                          ctree2_sg evaluations, ~23 ms each)
    => one decision evaluation  ~29 s
  The strategy evaluates the decision record TWICE: once in Lisp at
  elaboration (`recv (evalexpr recstr ..)`, to choose `truth`/`okay` and hence
  which formula to assert) and once inside the proof (`(eval-expr recstr)`,
  which is what makes the answer checkable). 2 x 29 s + ~30 s of proof steps
  accounts for the 90 s. The double is INHERENT to decide-by-evaluation then
  prove-by-re-evaluation; it cannot be removed without making the answer
  untrusted, so the only lever is making one evaluation cheaper.
  Note the value walk is no longer root-dominated: after alg_sign2 a rational
  sector's svs_sg (0.84 s) costs MORE than a root sector's (0.54 s).
- NULL RESULT, recorded so it is not retried: the ground evaluator DOES share
  a LET binding (3 inline copies of clos1(1,..) 3.98 s vs 0.54 s LET-bound,
  0.47 s single), and `mts2_rd`/`mts_rd` textually re-evaluate
  `lmn_sg(car(Q), g, sg)` three times and its double twice. Binding them with
  LET changed NOTHING measurable: root-sector svs_sg 0.41 s vs 0.445 s, inv1?
  5.00 s vs 5.08 s, both inside noise on an A/B against the unmodified files.
  Reason: those calls only fire for non-empty Q, |F| = 2 here so |Q| <= 2, and
  each call is a cheap meval sign query at a rational sample, not a Sturm
  chain. Reverted rather than re-gate sg_chain, sg_chain2 and their four
  dependents for no gain.
- Sector count is NOT reducible: all 47 closure members have deg > 0 and every
  one of the 21 distinct roots must be a sector boundary for the decomposition
  to be correct. rts itself is only 0.83 s.
- NEXT: ex_line at 90 s is still too slow (user). Profile the decision into
  clos1 / inv1? / qfoldS plus the strategy reconstruction and cut the largest
  part. Two known targets: the ~2.6 s per rational sector, where the `_sg` and
  `_rd` variants each rebuild the same chains (`snorm_sg`/`snorm_rd` walk the
  list separately, `sl_sg` computes `snorm_sg` twice, `ctree2_sg`/`ctree2_rd`
  recompute `cst?`/`live`/`live_rd`), and `dedup1`, which is quadratic over
  412 raw reads per sector. Then `ex_three`, on the three-quantifier
  `clos`/`lv(3)`/`sgv` path that neither fix touches.

## 2026-09-16 - Phase 6 performance: the stalled closure, found and fixed

- Instrumented the level-1 closure of the circle instead of timing it whole.
  Round 1 took 0.7 s for 28 polynomials, round 2 took 58 s for 29, round 3
  returned 29 again (a fixed point in content), yet `clos1(cfuel, ...)` never
  returned: the loop tests `inv1?` while progress is made by `addnew`, so once
  `bads` returned only polynomials already present the recursion spun through
  all 64 rounds and the strategy reported `ok = FALSE`. That was the 1000 s.
- Root cause of the permanent `inv1?` failure: `nroots_c` counts the CLOSED
  interval (Sturm's `roots_closed_int_def_truetrue`) and `between_free`
  counted the gap [ca`ub, cb`lb], so a family polynomial vanishing exactly at
  a sector endpoint was counted as an interior root. Measured: the failing
  sector was `mid(root0, root1)` with gap [-1, -3/4], closed count 1, the
  polynomial vanishing exactly at -1 (`polylist(ql)(-1) = 0`) and 0 roots
  strictly inside. Because the sector boundaries are the family's own roots,
  essentially every member failed, all 34 distinct reads, every round, for
  ever. Fix: `bdry(ql, r)` subtracts a root sitting exactly on a gap endpoint,
  in `between_free`, `below_free` and `above_free`.
- Two further inefficiencies fixed: `clos1` called `inv1?` and then `bads`,
  evaluating every read of every sector twice, and never stopped on no
  progress (it now computes `bads` once and stops when a round adds nothing);
  and `reads1` returned the raw read list with heavy repetition (412 reads, 35
  distinct at a rational sample; 188 and 12 at a root), so it is now
  deduplicated (`memb1`, `dedup1`).
- Measured after the fixes: failing reads at round 1 34 -> 0; `inv1?` on the
  round-1 family FALSE -> TRUE; the closure terminates with 28 polynomials;
  closure round 2 58 s -> 10 s; and the circle's decision record evaluates to
  `(# ok := TRUE, val := TRUE #)` in 20.9 s, the first time that computation
  has completed at all.
- Strategy: the two impossible branches of `cad` (`ok` false, `val` false) ran
  `(then (hide-all-but "ev") (assert))`, which hides the case formula that
  `ev` is meant to contradict, leaving nothing to prove. Removed the hide;
  `ex_above`, `ex_zero`, `ex_sos` close with `(cad)` again. The break was
  verified present at commit 94430b1, before tonight's edits, so it came with
  the decision-16 switch and not with the performance work.
- Open: `ex_circle` now decides correctly and fast, but its proof
  reconstruction still leaves two branches. It is the first example whose
  formula is a disjunction (`bor`), and on those branches both the semantic
  side (`fs`) and the original formula (`gl`) sit in the consequent, so there
  is nothing to reason from; the `con`/`ant` orientation of the walk needs
  revisiting.
- Measured with `proveit -f cad_lift.pvs` rather than guessed: 63 of the 72
  `cad_lift` proofs still replay, and exactly nine are broken - the TCCs
  `all_inv?_TCC2`, `badl_TCC1`, `lv_TCC2`, `decq2_TCC2` and the lemmas
  `closed_sub`, `cell2_eq`, `qfold_msg`, `qfold_cell`, `qfold_svs1`.
  `lv_sound`, `lv_complete`, `decq2_correct`, `decide2_correct` and
  `reads_agree` survived the edits, so the earlier note here overstated the
  damage. The five list lemmas behind the dedup (`memb1_member`,
  `dedup1_member`, `dedup1_every`, `every_cons_m`, `every_mem`) are proved.
  Still to do: those nine, plus the three sector soundness proofs in
  `sect_inv` (statements unchanged, since the corrected test accepts strictly
  more sectors), and then the gates.
- All nine are now repaired. Three of them (`qfold_msg`, `qfold_cell`,
  `qfold_svs1`) were never really broken by the performance work: `cad_decide`
  already declares `every_mem` over sign vectors, my duplicate over `mpoly`
  made that one unresolvable ("Found 0 resolutions relative to the
  substitution"), and renaming mine to `every_mem_m` restored all three
  untouched. Two were genuine consequences of the read deduplication and
  needed new membership facts, both proved: `agree_dedup1` (agree is
  membership-based, so it passes through `dedup1`) for `cell2_eq`, and
  `addnew_member` for `closed_sub`. The rest were length/termination
  obligations. Remaining: the three sector soundness proofs in `sect_inv`, the
  reconstruction of compound boolean forms, `ex_three`, and the gates.
- Verified, not asserted: `proveit -f cad_lift.pvs` reports 74 of 74 proofs
  attempted and succeeded, zero unfinished, so `cad_lift` is clean including
  the deduplication helpers and all nine repairs. `sect_inv` is being checked
  the same way.
- `proveit -f sect_inv.pvs` reports 37 of 51 succeeded and 14 unfinished:
  `between_free_sound`, `below_free_sound`, `above_free_sound` (the three the
  `bdry` correction affects, and `between_free_sound` stalls exactly on the
  endpoint case it introduces), plus eleven subtype obligations -
  `nroots_c_TCC1`, `nroots_c_TCC2`, `clr_TCC2`, `clr_TCC3`, `sepf_TCC2`,
  `sepf_TCC3`, `between_free_TCC1`, `sample_TCC1` to `sample_TCC4`. Ten of
  those eleven are about `refine`, `rat_alg` and the rational-to-integer
  conversion, which the `bdry` edit does not touch, and `sect_inv` had never
  been gated, so the question of blame was settled by measurement: `proveit` on a
  pre-edit checkout of 94430b1 (no `bdry`) gives 40 of 51 with 11
  unfinished, and they are exactly those same eleven TCCs. So the eleven
  are older debt from the earlier Phase 6 work, which was never gated, and
  the `bdry` correction broke precisely the three soundness lemmas and
  nothing else.
- What those three proofs need, established by reading the counting theory:
  `alg_count` proves `nroots_pos_intro` (a root in the closed interval forces
  a count of at least one) and `nroots_one_unique` (count one forces the roots
  to coincide), but it has no forward bound for two or more distinct roots.
  With the `bdry` correction the hard case is a root at each gap endpoint plus
  one strictly inside: the hypothesis then reads count = 2 while three
  distinct roots exist, which the present lemmas cannot contradict. The two
  easy cases do go through (no boundary root, via `nroots_pos_intro`; one
  boundary root, via `nroots_one_unique`), and the first branch of
  `between_free_sound` is already closed this way. So the missing piece is a
  pigeonhole lemma, derivable from `nroots_a_bij`: an injection of k distinct
  roots into `below(nroots)` forces `nroots >= k`. It should go in a new small
  theory rather than in `alg_count`, which is gated.
- That theory is `alg_count2`, and it is proved: `three_card` (three distinct
  elements of a finite set force a cardinality of three, from `card_subset`,
  `card_add` and `card_singleton`), `roots_finite` (the root set of a closed
  interval is finite, from the bijection via `is_finite_surj`), `nroots_ge2`
  (which needed no bijection at all - `nroots_zero_elim` and
  `nroots_one_unique` suffice) and `nroots_ge3` (the bound the corrected
  sector test needs). Wired into `top.pvs`. Next: cite it from `sect_inv` to
  finish `between_free_sound`, `below_free_sound` and `above_free_sound`.
- `between_free_sound` is proved for the corrected test. The argument: supply
  `nroots_pos_intro` at the interior root, `nroots_ge2` at *each* gap endpoint
  (both instances are needed - the case where only the upper endpoint is a
  root leaves the lower instance vacuous), and `nroots_ge3` at all three, then
  split on the two endpoint-root conditions. In each of the four cases the
  bound exceeds what the `bdry` subtraction allows, so an interior root is
  contradictory.
- `below_free_sound` and `above_free_sound` are still open, and their only
  remaining gap is one fact: a root at the gap endpoint must be the sector
  boundary itself (`value(b)`, resp. `value(a)`), which is `clr_free` applied
  at the endpoint instead of at the interior root. It is declared as
  `clr_free_lb` / `clr_free_ub` in `sect_inv` but not yet proved: every
  failure so far has been instantiating `clr_free`'s inner quantifier, not the
  mathematics. `below_free_sound` already shows the endpoint fact arriving in
  usable form once those helpers exist.
- `alg_count2` verified by `proveit`, not just interactively: 4 proofs, 4
  attempted, 4 succeeded, zero unfinished. So `three_card`, `roots_finite`,
  `nroots_ge2` and `nroots_ge3` are real, and `between_free_sound` rests on
  proved ground.
- `sect_inv` re-verified by `proveit` after the fix: 53 proofs, 51 attempted,
  39 succeeded. `between_free_sound` is absent from the unfinished list, so it
  is confirmed proved, and `sample_TCC4` stayed fixed. Note 53 declared vs 51
  attempted: the two new helper declarations `clr_free_lb` / `clr_free_ub` have
  no saved proof at all, so proveit skipped them. The precise outstanding set
  is therefore ten older TCCs (`nroots_c_TCC1`, `nroots_c_TCC2`, `clr_TCC2`,
  `clr_TCC3`, `sepf_TCC2`, `sepf_TCC3`, `between_free_TCC1`, `sample_TCC1` to
  `sample_TCC3`), the two soundness lemmas, and those two unattempted helpers -
  eleven was the count before `sample_TCC4` was recovered.
- The nine recoveries hold up under `proveit`: `sect_inv` now reports 53
  proofs, 51 attempted, **48 succeeded**, with only three unfinished -
  `between_free_TCC1`, `below_free_sound`, `above_free_sound`. That is up from
  39 succeeded and twelve unfinished. The 53-vs-51 gap is still the two helper
  declarations `clr_free_lb` / `clr_free_ub`, which have no saved proof and so
  are skipped rather than reported. `between_free_TCC1` resisted four attempts:
  every supporting fact is present and syntactically aligned after replacing
  the `ch`, `ca`, `cb` and `s` equations (the goal reduces to
  `clr(...)`a`ub <= sepf(...)`a`ub < sepf(...)`b`lb <= clr(...)`a`lb`), yet
  neither `assert`, `grind` nor a targeted `flatten` closes it; parked rather
  than guessed at again.
- Library state overall: `cad_lift` 74 of 74 verified, `alg_count2` 4 of 4
  verified, `sect_inv` 48 of 51 attempted.
- All three sector soundness lemmas are now proved, and so is
  `between_free_TCC1`: `sect_inv` should be complete (a confirming `proveit`
  run was launched). What unblocked it was mechanical, not mathematical. PVS's
  `inst` cannot see through a guard implication - `clr_free` reads
  `deg(ql) > 0 AND clr(...)`ok IMPLIES FORALL z: ...` - so after supplying the
  lemma the inner quantifier is not a top-level quantified formula and `inst`
  answers with a bare "No change". That defeated positional `inst`,
  label-addressed `inst`, a `name`-introduced term, and `use` with a
  substitution (a substitution walks only the contiguous quantifier prefix and
  stops at the guard, so `z` is unreachable that way at all). `(split "cf")`
  first makes it reachable; the leftover side condition `lb <= ub` comes from
  the `Alg` invariant via `typepred` plus `expand "alg?"`. The two one-sided
  lemmas then closed with `rbound_root` (every root satisfies
  `abs(x) < rbound`), `nroots_pos_intro`, `clr_free_lb` / `clr_free_ub` and
  `nroots_ge2`, instantiated on the interval each branch actually has - `min`
  and `max` resolve per branch, and instantiating on the wrong arm is why
  several earlier attempts had no visible effect.
- Two process lessons worth keeping: steps appended after `(rerun)` inside a
  single `then` fail silently, which is why five batch attempts returned
  byte-identical sequents - these proofs had to be driven step by step; and
  before assuming an old unfinished TCC needs real work, print its sequent and
  look for the one library fact it wants. Nine of ten were a single `use` away.
- Confirmed: `proveit -f sect_inv.pvs` reports **53 proofs, 53 attempted, 53
  succeeded, zero unfinished**. The theory is complete. Note the attempted
  count rose from 51 to 53: `clr_free_lb` and `clr_free_ub` now have saved
  proofs, so nothing is silently skipped any more - that was the hole flagged
  earlier, and it is closed. Library state, all by `proveit`: `cad_lift` 74 of
  74, `alg_count2` 4 of 4, `sect_inv` 53 of 53. The per-file gate (three fresh
  runs after clearing `pvsbin`, plus a `--traces` run requiring zero "fewer
  subproofs" warnings) is now running for all three.
- Correction, from a source-level analysis of the reconstruction gap: the
  diagnosis recorded here earlier was wrong. The residual
  `{1,fs} ((x^2+y^2)) - (1) = 0` on the consequent side is sign3's own first
  condition, negated - not a lost hypothesis - and the `con`/`ant` orientation
  of the walk is correct: `split-step` copies labels to its children, so the
  branch keeps `fs` and an `fs` antecedent carrying the remaining conditional
  is still present (the snippet quoted earlier omitted antecedents). The actual
  cause is that `lift-if` cannot see past the first disjunct: `collect-conds`
  recurses into `args1` only for AND, OR and IMPLIES
  (`proofrules.lisp:724-731`), so on a compound matrix only the leftmost atom's
  conditional is lifted and the rest survive as term-level conditionals, which
  `ground`'s `split` can never reach (it handles formula-level connectives
  only). Single-`batom` formulas close because one lift is enough. Candidate
  fix: append bounded rounds of `(then (lift-if) (ground))` after the core's
  `(ground)` - bounded rather than `repeat*`, to avoid branch multiplication -
  and it is not expected to extend past `ex_circle`.
- Also corrected: `ex_line` and `ex_three` are a different failure. Neither has
  a `(CAD)` node in `cad_examples.prf`, only bare `POSTPONE`s, so `(cad)` exits
  at one of its printf guards (unsupported matrix, or the closure not
  completing within fuel) and never reaches reconstruction at all. Grouping
  them with the compound-form gap was a mistake.
- First real gate pass of this stretch: **`alg_count2` GATE PASSED** - three
  fresh `proveit -f` runs after clearing `pvsbin`, each 4 of 4, plus
  `proveit -l --traces -f` with zero "fewer subproofs" warnings. **`sect_inv` GATE PASSED** as well -
  three fresh runs, each 53 of 53, and a traces pass with zero warnings. That
  is the theory that held every open formula at the start of this stretch.
  **`cad_lift` GATE PASSED** too - three fresh runs, each 74 of 74, traces
  clean. So all three theories touched by this work now clear the project
  gate: `alg_count2` 4/4, `sect_inv` 53/53, `cad_lift` 74/74, each three
  times from a cleared `pvsbin`, each with zero "fewer subproofs" warnings.
- Also still outstanding: the eleven older `sect_inv` TCCs (measured as
  pre-existing), the reconstruction of compound boolean forms, `ex_three`, and
  the gates. `sample_TCC4` re-proved with `grind`.

## 2026-09-15 — Phase 6: the per-cell procedure, proved; making it fast (in progress)

- Per-cell evaluation of the cylindrical decision (decision 13), proved on
  the pvs-cli server (gates pending): `sg_norm`, `sg_chain`, `sg_conj`,
  `sg_svs` (the Phase 3/5 tree builders written against a sign function
  `sg: [mpoly -> Sign3]`, with agreement `_at`, read lists `_rd` and
  determinism `_det`), `cell1` (the bottom level by root isolation:
  `svs1_sound`/`svs1_complete`, roots sorted without repetition, rational
  samples between consecutive roots by `gap`), `map_member`, `mpoly_eqd`
  (decidable equalities `meq`/`leq`/`posq`, because the ground evaluator
  cannot compare lists of different lengths through `=`), `cad_lift`
  (`clos` closes a level under the reads of the level above, `lv(m)` lists
  the cells of every level, `lv_sound`/`lv_complete` pointwise,
  `qfold_cell`, `sem_peel2`, `decq2_correct`, `decide2_correct` relative to
  the completion flag `ok`). Strategy `cad` switched to `decide2`; it
  evaluates the decision record once and reads the flag and the value off
  it in the proof.
- Performance work on the circle (`ex_circle`), all measured with
  `eval-expr` on the server: (1) unknown signs answered 0 made the Tarski
  chains read garbage (degree-8 products) - at level 1 the reads are now
  taken exactly at the sample points (`asg`, rational samples by `meval`,
  roots by `alg_sign`); (2) the sum of squares doubled every equation's
  degree - `sg_conj2` prunes the equations (a nonzero constant refutes,
  identically zero ones are dropped, a single equation is decided on
  itself), which took the first family of the circle from a degree-90
  polynomial to degree 38 and root isolation from 97 s to 1 s;
  (3) `alg_fast`: `isoc`/`rootsc` compute the Sturm chain once per
  polynomial (`isoc_iso`, `rootsc_roots` proved); `cell1` compares roots by
  interval separation first (`cmpf`), falling back to `alg_cmp`.
- Sector-based level 1 (`sect_inv`: sectors of a sorted root list with
  their samples, `clr`/`between_free`/`below_free`/`above_free`/`whole_free`
  numeric sign-invariance checks with their soundness, `sects_cover`,
  `sample_in`, `sects_ok`, `inv_free`; `cad_lift` restructured: `clos1`,
  `over1`, `qfoldS`, level 2 and the two-quantifier case of `decq2` by
  sectors). Measured: still over 10 minutes for the circle, because the
  reads are leading coefficients of pseudo-remainder chains (degree 36,
  34 distinct, all with real roots). Root cause recorded as decision 15 of
  the plan: only a subresultant chain in Phase 3 (or the classical
  projection with delineability) makes the circle fast.
- All of the above is now proved on the server. Gates passed so far:
  `map_member`, `mpoly_eqd`, `alg_fast`, `sg_norm`, `sg_chain`, `sg_conj`,
  `sg_conj2`; `sg_svs` needed two TCCs (`rsc_sg_TCC2`, `svs_sg_TCC1`),
  proved; the rest of the Phase 6 gates are queued behind the chain work.
- Decision 16 (the reduced chain), built and proved the same evening,
  with nothing of Phase 3 changed: `mpoly_div` (`mdiv`, `ldivl`, `lexact`;
  executable, no lemmas), `earr_ops` (coefficient arrays through `lscal`,
  `shiftl`, `lsub`, `lbut`, `pstep`; `prop(l1, l2, c, ys)` and
  `prop_prem`, `prop_sstep`, `prop_snorm`, `prop_sign`, `sign3_mult`),
  `sturm_step2` (`sstep2`, `sgp`; `sstep2_prop`: at `msg(ys)` a positive
  multiple of `sstep`; `sstep2_det`), `sg_chain2` (`rchain2_sg` with the
  divisor `cc^e` of Collins's reduced sequence, `chprop`, `rchain2_prop`,
  `chprop_tqf`: the Tarski query reads only lengths and leading signs,
  `tq2_sg_at`, `mts2_sg_at`, the `_det` lemmas). `sg_conj`'s `mcount_sg`
  now counts with `mts2_sg`; `mcount_sg_at`, `mcount_det` replayed. The
  Sturm-sequence property is never re-proved: the new chain is compared
  with the old one at every valuation (`earr`-wise proportionality, a
  syntactic induction over `pquo_rem`).
- Prover notes from this stretch: `then` is branch-blind (use `spread`);
  `undo n` counts steps along the current branch and can fall back to the
  root; `measure-induct+` generates a side goal per subtype in the formula
  (state `cons?(m2)` explicitly rather than derive it); `use` with a named
  substitution avoids the binder-order guessing of `inst`; `field` closes
  the monomial identities `assert` refuses when a negated product is
  involved; `expand "msg"` turns `msg(ys)` into a lambda that blocks
  `lcs_at` (expand `lcs` instead).

## 2026-09-14 — Phase 5: the cylindrical decision procedure, proved

- The route of decision 12, built and verified (three fresh `proveit` runs
  plus traces per file):
  `sign_vec` (6: sign vectors, positions), `tree_sel` (11: selecting a
  tree by a sign vector, `sel_by_sel`), `bbindc_ex` (1: the existential
  form of `select_bbindc`), `rsc_tree` (18: realized sign vectors at the
  roots of one polynomial with side conditions, the adaptive enumeration on
  `cjtreec`, `rsc_sound`/`rsc_complete`), `far_sign` (14: the vectors at
  ±oo from the normalized leading coefficients, via `far_right`/`far_left`
  of Phase 3 and `lneg`), `sector_rep` (13: IVT and Rolle for a polynomial
  in the top variable, the product `prodl` of a family, `svec_same`,
  `sector_cases` with the nearest-root machinery of `poly_rolle`),
  `svs_tree` (8: every vector a family realizes — roots of `G = prodl(F)`,
  roots of `G'`, the two ends — `svs_sound`/`svs_complete`), `bform` (1),
  `cad_decide` (17: `decq` peels the innermost quantifier, the family of
  the level below is `polys(svs(F))`, the truth function folds the
  quantifier over the leaf selected by the lower sign vector;
  `decq_correct`, `decide_correct`, `decide_correct_os`).
- The theorem: `decide(qs, F, phi) IFF fsem(reverse(qs), F, phi, null)` for
  any quantifier prefix, by induction on the prefix with `sem_peel`
  (`qfold_svs`: the fold over the listed vectors is the quantifier, from
  `svs_sound`/`svs_complete`; `sel_by_sel` replaces the valuation by its
  sign vector). No delineability, no connectedness.
- Strategy `cad` (pvs-strategies): reads the prefix and the matrix (any
  Boolean combination of polynomial sign conditions), evaluates
  `decide(reverse(os), F, phi)` on the ground, adds the formula or its
  negation labelled `cad`, proved from `decide_correct_os` by unfolding
  `fsem`, walking the quantifiers (a universal is skolemized in the
  consequent and instantiated in the antecedent with the same name, an
  existential the other way round), unfolding `bfeval`, and one reflection
  equation per polynomial (`peval_pnorm`, `mpoly-eq-side__`).
- Measured on `cad_examples`: `ex_above`, `ex_zero`, `ex_sos` (linear
  atoms, two variables, alternations) close in 2 s each; the circle and line,
  `y^2 = x` and the three-variable linear example do not finish in 15
  minutes. One parametric existence query on the circle alone takes 5 s, on
  the product of the two polynomials more than 500 s, and `svs` nests 26 of
  them with the hutch oracle at every node of the joint tree. Recorded as
  decision 13 in `CAD_PLAN.md`: the cure is per-cell evaluation with
  deforested tree builders and a numeric level-1 decomposition from Phase 2
  root isolation, the first item of Phase 6.
- Next: Phase 6 item (a)-(c) of decision 13, then the benchmark set with times
  and cell counts, the paper section, the whole-library replay.

- Lessons: `case` with several formulas gives n+1 subgoals (the last is the
  negation of the first alone); `inst` consumes a formula (use `inst-cp`
  or labels); expanding `member`/`length` everywhere desynchronizes CASES
  forms — rewrite with a cons lemma instead; `expand` on the induction
  hypothesis destroys it — restrict to the goal (`(expand "f" 1)`).

## 2026-09-14 — Phase 5 route revised: cylindrical decision without delineability

- Checking the next step exposed an error in the plan's decision 11: the
  number of distinct *real* roots being constant does not make the ordered
  real roots continuous. `(y^2 - x) ((y - 1)^2 + x)` has two distinct real
  roots for every `x` in `(-1, 1)` and leading coefficient 1, but the smaller
  root sits near 1 for `x < 0` and near 0 for `x > 0`. Delineability needs the
  number of distinct complex roots, hence `gcd(p, p')`, hence the deferred
  gcd theorem plus a multiplicity theory over ℂ.
- The decision procedure does not need it. At each parameter point the set of
  sign vectors realized by the family along the top variable is the union of
  the vectors at the roots of the product `G`, at the roots of `G'` (a root in
  every bounded sector, by Rolle) and at `+oo`, `-oo`. All three are parametric
  branch trees Phase 3 already computes (`cjtreec` for `EXISTS x: g = 0 AND
  E = 0 AND Q > 0`, `snormc` for normalized leading coefficients), so the
  realized-vector list is a branch tree over `ys` whose conditions are the
  projection set; its leaf is constant wherever the projection set is
  sign-invariant. Quantifier evaluation is then pointwise in `ys` by downward
  induction on the level, for any quantifier prefix. Recorded as decision 12
  in `CAD_PLAN.md` §10a; `croot_near` is kept for a later geometric cell theory.
- Plan of files: `sign_vec` (sign vectors, select-by-signs), `rsc_tree`
  (realized sign vectors at the roots of one polynomial, adaptive enumeration
  with pruning), `far_sign` (vectors at ±oo), `sector_rep` (Rolle: every
  sector has a root of `G'` or is unbounded), `svs_tree` (the three combined,
  sound and complete), `cad_formula` (prefix formulas, `decide`,
  `decide_correct`), strategy and examples.

## 2026-09-14 — Phase 5 opened: complex polynomials

- Route (D6): delineability through the complex roots. What Phase 5 needs
  from ℂ is only this: for a proper polynomial p, every root of a nearby
  polynomial is near a root of p and conversely, which follows from the
  factorization p(z) = lc ∏ (z - α_i) and a root bound. NASALib's
  `complex@fundamental_algebra` gives one root and one linear factor
  (`polynomial_zero_factor`) and nothing about the number of roots or the
  coefficients of a factor, so that is built first.
- `cpoly_unique` (10 formulas proved, gate running): `roots_bound` (a
  polynomial of degree at most n vanishing at n + 1 distinct points is the
  zero function; induction with one linear factor peeled per step),
  `coefs_unique` (the zero function has zero coefficients: a(0) = p(0), then
  the cofactor vanishes at the n + 1 nonzero naturals), `coefs_eq`,
  `shift_poly` (the coefficients of (x - y) q, with the degree carried:
  b(i-1) - y b(i) up to n, then b(n)), `factor_lc` (the cofactor of a linear
  factor has the same leading coefficient).
- Complex arithmetic in PVS: `grind` decomposes into Re/Im and gets lost in
  `csigma` terms; name the polynomial values (`name "PP" "cpolynomial(...)"`)
  before `grind`, and instantiate `cpolynomial_rec`/`cpolynomial_struct_rec`
  by hand. Complex equalities from component equalities close with
  `apply-extensionality`.
- `croots` (5 formulas, gate running): `cprod(r, n)(z)` the product of
  (z - r(i)) over i < n, `cprod_eq` (only the roots below n matter),
  `cfact`: a proper polynomial of degree n is a(n) times cprod of n roots,
  by induction on n with `fundamental_algebra`, `polynomial_zero_factor` and
  `factor_lc` (the cofactor is proper again).
- `croot_near` (11/11, gated): `abs_cprod`, `cprod_far` (all factors
  at least eps gives a product at least eps^n), `cpoly_bound` (|p(z)| <=
  (n+1) M B^n when the coefficients are at most M and |z| <= B, B > 1, via
  `csigma_real_triangle` and `sigma_le`/`sigma_const`), `cpoly_diff_bound`,
  `root_bound` (a root has modulus at most 1 + n M / |a(n)|: a root above
  modulus 1 satisfies |a(n)| |z|^n <= n M |z|^(n-1)), and `root_near`: for
  every eps > 0 there is a delta > 0 such that every root of a polynomial of
  the same degree with coefficients within delta lies within eps of a root of
  p. The delta is min(1, |a(n)|/2, |a(n)| eps^n / (2 (n+1) B^n)) with
  B = 2 + 2n(M+1)/|a(n)| and M the sum of the |a(i)|; the proof bounds the
  perturbed roots by `root_bound`, |p(z)| = |p(z) - q(z)| from above by
  `cpoly_diff_bound` and from below by `cprod_far`, and compares.
- The proof took an afternoon of `pvs-cli` rounds: `name` the fractions
  and products before `assert`, keep the two syntactic forms of a denominator
  aligned with a `case` (assert rewrites `2 (n+1) B^n` into
  `2 B^n + 2 (B^n n)`), and use the prelude's `both_sides_times_pos_le*_imp`,
  `le_div_le_pos`, `min_le`/`min_gt` and Field's `field` for the arithmetic
  that `assert` and `grind-reals` will not do.
- Next: delineability — on a connected set where the number of distinct real
  roots is constant and the leading coefficient does not vanish, the ordered
  real roots are continuous functions.

## 2026-09-14 — Phase 4: the determinant and the resultant

- `ring_det` (gate pending): `detl(n, M, j)` is the Laplace expansion of an
  n-matrix of mpolys along its first row from column j, one recursion with
  measure `n (n + 1) + (n - j)` (the first measure I wrote, `2n - j`, does
  not decrease on the minor call — the prover said so); `det = detl(_, _, 0)`;
  `rdetl`/`rdet` the same over the reals; `det_eval`: `meval(det(n, M))(ys)
  = rdet(n, ev(M, ys))`, by the same measure induction, since meval is a
  ring homomorphism (`meval_madd`, `meval_mmul`).
- `sylvester` (gate pending): `syl(f, g)` the (deg f + deg g)-square Sylvester
  matrix of two coefficient lists (rows of f shifted, then rows of g, both in
  descending order through `coef_at`), `res(f, g) = det(...)`, `disc(f) =
  res(f, lderiv(f))`; `rsyl`/`rres` over real arrays; `res_eval` and
  `disc_eval`: the resultant specializes, `meval(res(f, g))(ys) =
  rres(earr(f, ys), dg(f), earr(g, ys), dg(g))`. Both executable.

## 2026-09-14 — Phase 4 opened: the route

- NASALib's `matrices@matrix_det` defines `det` through elementary-matrix
  decompositions and proves no Laplace expansion, no adjugate, no kernel or
  rank fact, and `linear_algebra` has none either. So Phase 4 is
  self-contained: `ring_det` (Laplace determinant over `mpoly`, executable,
  with `det_eval`: evaluation at the parameters is the real determinant of
  the evaluated matrix), `sylvester` (the Sylvester matrix of two coefficient
  lists, the resultant and the discriminant), `resultant_spec`
  (specialization), then the real-level algebra --- multilinearity and the
  alternating property from the expansion, the adjugate identity, `det = 0`
  iff a nontrivial kernel, Euclid and Bezout for real polynomials --- giving
  `Res(f, g) = 0 IFF f and g have a nonconstant common factor`. Subresultants
  proper (the gcd-degree theorem) follow on the same base.

## 2026-09-14 — Parametric QE: trees that know their path

- The first parametric run did not return. Two causes, fixed in turn.
  (1) The trees were built unpruned and pruned afterwards, and building is
  exponential in the fuel: `snormp` (branch_sgn) now normalizes the leading
  coefficient (`mnorm`) and, when it is a constant, takes the child its sign
  selects instead of branching. `snormp_sel` keeps its statement; regated
  12/12; the whole library replays (1323 proofs) after renaming
  `mpoly_cst.len_cons` to `len_cons1` (it clashed with `prem_arr.len_cons`
  once branch_sgn imported both).
  (2) With that, `x - a` took 54 s and 25 branches, and the conflict question
  with `D` free did not finish in 80 minutes: the 2^m chains of the
  recursion are nested by `bbind`, so their branch counts multiply, and a
  leading coefficient in `D` is a three-way branch even when the conditions
  above it fix its sign. So the trees now carry their path.
- `sign_oracle` (22/22): `forced(c, cx)` decides the sign of a coefficient
  under the conditions of the path with the library's own one-variable QE
  (the parameter as the variable, `qe_exists` with no parameters left), or
  answers 2; `forced_sound`. One parameter only, by construction
  (`ulist?`).
- `branch_ctx[T, U]` (9/9): `bbindc` passes the leaf's path to the
  continuation; `select_bbindc` is the one fact needed (the value at the
  selected leaf under any context the valuation admits).
- `snorm_ctx` (9/9), `prsp_ctx` (6/6), `tarski_ctx` (13/13), `ineq_ctx`
  (6/6), `qe_ctx` (8/8): the whole QE layer rebuilt with contexts, each
  select theorem under `conds_hold(cx, ys)`; `qdecidec` from the empty path,
  `qe_branchc` for the strategy. Every proof mirrors the context-free one
  with `select_bbindc` in place of `select_bbind`, instantiated with the
  value the valuation selects.
- `qe-exists` now evaluates `qdecidec`: for `x - a` the tree has three
  branches — `4a > 0`, `4a = 0`, `4a < 0` — in 7 s, where `qdecide` had
  twenty-five in 54 s. Proved through it: `s1`, `s2`, `s4`.
- All proofs through NASALib's `pvs-cli` server (`tools/pvscli.sh`, patched
  for no keepalive timeout and no message-size limit): one command at a
  time, the sequent shown, the proof saved by the server. Lessons: `then`
  applies to every open subgoal; a skolem name from a lemma's bound
  variable is `cx2`, then `cx2_1`, `cx2_1!1`; instantiate lemmas in the
  order of their FORALL (uppercase first); `replace` will not rewrite under a
  lambda, so instantiate `select_bbindc` with the continuation printed by
  the prover.
- The oracle was the bottleneck after all: on a realistic path (three
  conditions of degrees 8–20 in `D` with large coefficients) the QE-based
  `forced` ran for ten minutes without answering while a `hutch`-based one
  answered in 7 s. `hutch_oracle` (18/18): `forced2(c, cx)` asks
  Tarski@hutch whether the conditions of the path admit a value at which c
  is not positive (then not negative, not zero) — `qarr` reads a univariate
  list as the rational array hutch takes, `plist`/`rels` build the system,
  `sat_sound` and `forced2_sound` are the soundness; `snormc` now calls it.
- With that: `cw1`, the closest-approach question with the radius free,
  `EXISTS t: (5 - t)^2 + (t/2)^2 < D^2`, is decided in 8 s into exactly three
  branches on `3125/32 D^2 - 15625/32`, i.e. the sign of `D^2 - 5`, and
  `D^2 > 5 IMPLIES EXISTS t: ...` is proved by `(qe-exists)` and `grind`.
  With the lookahead window as well (`cs0`, `cs1`, `cs3`: three or four
  conditions) the 2^m nested chains produce coefficients of degree thirty
  and more in `D`, and no variant finished in 25–47 minutes. That is the
  limit of branching QE the plan predicted, and it is reported as such.
- Whole-library replay after `rm -rf pvsbin`: **1426 proofs, 1426 attempted,
  1426 succeeded**, 79 theories, 644 s (09:19:44 → 09:30:28). Phase 3 is
  closed: one-variable QE with numeric coefficients in full, the parametric
  layer with path contexts, the conflict question with the radius free
  (closest approach) decided, and the windowed version measured as beyond
  branching QE.
- `qe_symbolic` (6/6): `s1`–`s4`, `cw1`, `cw2` all proved by
  `(skeep) (qe-exists) (grind)` in 1–12 s each; after `skeep` a negated
  existential sits in the antecedent, so the strategy takes its number
  (`(qe-exists -2)`).
- Strategy fix: in the branches where the decision says the existential
  holds, the witness of `qe_branchc` is skolemized by label with the goal's
  bound name (`skolem "qs" (x)`), since `skeep` keeps the lemma's own name
  `x`, which is not the goal's `t`.

## 2026-09-13 — Parametric QE: the whole layer on trees, and the pvs-cli server

- `ineq_ok` (25/25) and `ineq_tree` (7/7): the no-equation conjunction
  `EXISTS x: every q in Q: q(x, ys) > 0` decided on a tree. `itree`
  normalizes the conditions, answers TRUE when the recorded signs say the
  conjunction holds far right or far left (`posinfp_at`, `neginfp_at`),
  forms the product as a tree (`wtree`, one degree branching per factor,
  `select_wtree` = `sl_of(qprod)`), answers FALSE for a product of length at
  most two (constant: `const_posinf`; linear: `lin_nocrit`, no critical
  point), and asks `mcount` at the derivative of the product otherwise
  (`lderiv_big`, `ineq_big`). `itree_sound` needs `2 mlen(Q) + 1 <= k`
  alone; `dgs_le` bounds the degree of the product by the fuel.
- `conj_tree` (5/5): `ctree` decides one conjunct; the sum of squares of the
  equations gets a degree branching — zero polynomial → `itree`, nonzero
  constant → FALSE, positive degree → `mcore` — under
  `length(sqsum(E)) + 2 mlen(Q) + 1 <= k`.
- `qe_tree` (11/11): `qtree` decides `EXISTS x: feval(F, ys, x)` for a
  formula of `qe_formula` with symbolic parameters, `qtree_sound` under the
  computable fuel `tfuel(F)`; `qdecide = prune(qtree)`, and `qe_branch` is the
  branch theorem the strategy instantiates.
- Workflow change, at the user's suggestion: NASALib's `pvs-scripts/pvs-cli.sh`
  drives a PVS server (`pvs -raw -port 23456`) over websockets, one proof
  command at a time with the resulting sequent shown, and it **saves the proof
  itself** with the full tree and the TCCs it ran. Three things learned: the
  server dies when its stdin closes (start it as
  `sleep 100000000 | pvs -raw -port 23456` under nohup); a theory whose
  IMPORTING changed cannot be re-typechecked in a running server (assertion
  `(NULL (COMPARE OTHY NTHY))`, restart it); and it is one PVS process like
  any other, so it is stopped before a `proveit` gate. `itree_sound`,
  `ctree_sound` and `qtree_sound` were proved this way in minutes, where the
  scripted sessions had cost an unbalanced-parenthesis round trip each.
- Strategy: `qe-exists` now takes parameters. With parameters it evaluates
  `branches(qdecide(tfuel(F), F))` and adds one fact per branch,
  `<sign conditions on the parameters> IMPLIES <the formula or its negation>`,
  proved from `qe_branch`; with numeric coefficients it still goes through
  `qe_sound`. Examples in `qe_symbolic.pvs` (to be run): `x - a`, `x^2 - a`,
  a parametric discriminant, and the conflict question with `D` symbolic.

## 2026-09-13 — Parametric QE: a root with many conditions, on a tree

- `many_tree` (12/12, gated): `snormps(Q)` normalizes every condition as a
  degree branching and records the sign of each leading coefficient
  (`select_snormps` = `slofs`); `mcount(k, p0, ps)` asks whether the count
  of `tarski_tree` started from the multiplier one is positive, sound under
  `length(p) >= 2`, `lok(p)`, `allok` of the conditions and the fuel
  `length(p) + 1 + mlen(Q)` (`mcount_sound`, from `select_mtree`, `mok_at`
  and `many_exists`); `mcore` answers FALSE on a branch where a condition
  normalizes to nothing (`allgt_allcons`) and is `mcount` otherwise.
  `mcore_sound` needs nothing about the conditions.
- `mcount` is kept separate from `mcore` so the no-equation tree, which has
  already normalized the conditions, does not branch on them twice.
- Lesson: a goal `FALSE IFF EXISTS x: ...` has to be `split` before
  `skosimp*` can see the existential; the same shape defeated `mcore_sound`
  once.

## 2026-09-13 — Parametric QE: when the recursion is well formed

- `many_ok` (13/13, gated): `mok_at` — `mok(k, l0, Q, g, ys)` holds as soon as
  `l0` has degree at least one, `l0`, `g` and every condition have a
  nonvanishing leading coefficient, and `length(l0) + length(g) + mlen(Q) <= k`,
  where `mlen(Q)` is twice the total length of the conditions. The bound is
  crude on purpose: each condition enters a multiplier at most twice, and a
  crude bound avoids subtraction on `nat`.
- The normalized conditions `nlists(Q, ys)` keep their values (`allgt_nlists`),
  are no longer (`mlen_nlists`), have nonvanishing leading coefficients once
  none is empty (`allok_nlists`), and an empty one is the zero polynomial, so
  a conjunction that holds forces every condition to be nonempty
  (`allgt_allcons`).
- Lessons: `list_null_extensionality` needs the actual (`[mpoly]`) when several
  list types are imported; a `label` on `-1` after a `skeep` may land on the
  induction hypothesis and replace its label; and `multi.sh` reads
  `<session>_<formula>.cmds`, so a renamed session needs its scripts copied.

## 2026-09-13 — Parametric QE: the many-condition recursion as a tree

- `tarski_tree` (6/6, gated): `mtree(k, p0, Q, g)` is `mts` of `tarski_many`
  with each normalization at the valuation replaced by a degree branching
  (`snormp` of the product), so the whole 2^m recursion is one tree of sign
  conditions on the parameters with integer leaves. `select_mtree` says the
  selected leaf is `mts(k, l0, Q, g, ys)` with **no hypothesis**: whether the
  chains are well formed is a separate question, decided from leaf data next.
- The induction goes through four `select_bbind`/`select_bmap` rewrites, which
  remove every binder, then `snormp_lmul` (the branching picks `lmn`) and two
  instances of the hypothesis.
- Proofs written as single compound commands (`then`/`spread`), so a `.prf` is
  one node per formula and the traces run reports no missing subproofs.
- Next: `many_ok` (`mok` from leading coefficients and a syntactic fuel bound
  `length(p) + length(g) + mlen(Q)`), then `many_tree` (normalize the conditions
  as a tree, decide with `mtree`).

## 2026-09-13 — Phase 3 closed: paper section, whole-library replay, proof chains

- Paper (`paper/main.tex`): the QE layer written up, six paragraphs at the end
  of the Phase 3 subsection — the restricted Tarski query and the recursion
  `2 T(p, q::P, f) = T(p, P, qf) + T(p, P, q^2 f)` that gives the 2^m queries
  without exponent vectors (and why NASALib's `poly_families` could not be
  reused: integer coefficient arrays only); `mts`/`many_exists` on coefficient
  lists; the Rolle reduction for a conjunction with no equation; the sum of
  squares that collapses several equations; `qe_sound` and the fuel; the
  `qe-exists` strategy and what makes its emitted proof go through (skolemize
  with the goal's own variable name, `replace` the reflection equations); and
  the conflict question with numbers. 14 pages, builds clean.
- Whole-library replay after `rm -rf pvsbin`: **1242 proofs, 1242 attempted,
  1242 succeeded**, 64 theories, 636 s wall clock (20:39:27 → 20:50:03).
  Previous full run was 1076; Phase 3's QE layer added 166.
- Checked what PVS's `proved - incomplete` means here, since 838 of the 1242
  carry it. `pc-complete` marks a proof incomplete when its chain contains a
  formula that is not *proved in this context*; AXIOMs are counted separately,
  so the datatype axioms are not the cause. `proofchain-status` on `qe_sound`,
  `ineq_exists`, `many_exists` and `cd2` lists only NASALib formulas —
  `mean_value_aux`, `poly_sign_near_infinity`, `max_in_interval`, the
  `sigma`/`polynomials`/`number_sign_changes` TCCs, and so on. Nothing from
  `cad/` is ever listed. The reason is that a library theory restored from its
  `.bin` does not carry proof status: `sq.sq_TCC1` reports UNPROVED even inside
  NASALib's own `reals` directory, though `sq.prf` holds its proof. So the
  label records dependence on NASALib, not a gap. Said so in the Evaluation
  section rather than leaving the reader to wonder.
- Evaluation section updated: 1242/1242 in 64 theories, 636 s; the only AXIOMs
  are the generated datatype ones (`mpoly`, `btree`, `PolyExpr`); the only
  trusted oracle PVS reports is METIT, which nothing here calls.
- Memory updated: `project_cad_phase3_qe.md` rewritten for the finished phase,
  `reference_pvs_proof_tactics_phase3.md` extended with the tactics from the
  QE layer (replace-don't-add, `hide-all-but` vs `NOT` formulas, label the
  lemma instance, print empty lists with their actual).
- Next: Phase 4 (subresultants), and the parametric QE — the whole QE layer
  lifted to branch trees, as `gdec` lifts one sign condition, which is what
  `qe-exists` needs for symbolic coefficients.

## 2026-09-13 — Phase 3: the qe-exists strategy, and the conflict question

- `qe-exists` (in `cad/pvs-strategies`): reads a goal `EXISTS (x: real): PHI`
  or `FORALL (x: real): PHI` with PHI any Boolean combination of sign
  conditions on polynomials in x with numeric coefficients, puts PHI in
  disjunctive normal form **in Lisp**, evaluates `qe_exists` and `fok` of
  `qe_formula` with the ground evaluator, and adds the answer — the formula
  or its negation — to the sequent, proved from `qe_sound`, that evaluation,
  and one proved reflection equation per polynomial. The normal form is not
  trusted: if it were wrong the proof would not close.
- Four shapes, all handled: the goal is an EXISTS or a FORALL, and the
  decision says the existential holds or fails. The witness moves in opposite
  directions in the two cases — from `qe_sound` into the formula's own
  quantifier when it holds, from the formula into `qe_sound`'s universal when
  it fails — which is why the strategy labels the `qe_sound` instance and
  instantiates through the label rather than by position.
- `qe_run` (12/12): `EXISTS x: x^2 - 1 = 0 AND x > 0`;
  `NOT EXISTS x: x^2 + 1 = 0 AND x > 0`; a disjunction of an inequality and an
  equation-with-side-condition; `EXISTS x: x > 0 AND 1 - x > 0` and the
  unsatisfiable `x > 1 AND 1 - x > 0` (both with no equation, so through
  `ineq_exists`); `FORALL x: x^2 + 1 > 0`; and the paper's conflict-detection
  question with numbers — an aircraft at (5,0) with relative velocity
  (-1, 1/2), lookahead 10, protected radius 3 (a conflict) and 2 (none) —
  decided and proved on both sides.
- One lesson: the reflection equations have to be `replace`d into the sequent,
  not merely added. `assert` will not use `meval(mpol(l))(cons(x, ys)) = P` to
  rewrite a goal about the `meval` term when the sequent is large; with the
  substitution done the arithmetic closes at once.
- Verified: `qe_formula` (12/12, with the fuel function) and `qe_run` (12/12)
  gated; `pos_examples`, `sgn_examples` and `qe_examples` still replay against
  the extended strategy file.
- Next: the paper section for the QE layer, and the parametric case (a branch
  tree over the QE layer, as `gdec` is for one sign condition).

## 2026-09-13 — Phase 3: quantifier elimination for one variable

- `qe_conj` (12/12): one conjunct of a QE problem. Several equations collapse
  into one, because a sum of squares of reals vanishes exactly when every term
  does (`sqsum_zero`), so `sqsum(E) = 0` is the conjunction of the equations.
  `cdec` then decides the conjunct — `many_exists` when there is an equation,
  `ineq_exists` when there is none — and `cdec_sound` proves it. `ladd` (the
  sum of two coefficient lists) and three existential bridges
  (`ex_allgt`, `ex_crit`, `ceq_ex`) are the glue.
- `qe_formula` (8/8): a formula is a list of conjuncts, each a list of
  equations and a list of strict inequalities, and `qe_sound` says
  `qe_exists(k, F, ys)` decides `EXISTS x: feval(F, ys, x)` under `fok`. That
  is the plan's `qe_formula` item: quantifier elimination for one variable
  over an arbitrary Boolean combination of sign conditions, since every such
  combination has this normal form and the other relations reduce to it
  (`p < 0` is `-p > 0`, `p /= 0` is `p > 0 OR -p > 0`, `p >= 0` is
  `p > 0 OR p = 0`). The Boolean normalization itself is left to the strategy,
  outside the verified core, in the same way the polynomial printer is: every
  fact it produces is proved.
- Verified: both gates passed (three fresh runs each, traces clean).
- Next (paused here): the `qe` strategy on top of `qe_sound`, the examples,
  and the conflict-detection gate example.

## 2026-09-13 — Phase 3: any number of conditions, and the case with no equation

- `tarski_multi` (19/19) and `tarski_many` (21/21): `T(p, P, f)` is the Tarski
  query of f restricted to the roots of p at which every function of the list
  P is positive, and `T_step` says
  `2 T(p, cons(q,P), f) = T(p, P, q f) + T(p, P, q^2 f)` — at a root where q is
  positive the two terms agree and elsewhere they cancel. Unrolling it gives
  the 2^m queries of the m-condition identity without ever indexing the
  exponent vectors, which is how NASALib does it for integer arrays. The step
  is pure finite-set cardinality and holds for arbitrary functions; only the
  base case needs the polynomials.
- `mts(k, l0, Q, g, ys)` is that recursion on coefficient lists and is
  executable: 2^m Tarski queries of products built by `lmn`. `mts_val` proves
  `mts = 2^m T` by induction on Q, and `many_exists` decides
  `EXISTS x: p(x, ys) = 0 AND every q in Q: q(x, ys) > 0`.
- `poly_farinf` (10/10) and `poly_rolle` (30/30): the conjunction with **no**
  equation. `ineq_exists` says it holds somewhere exactly when it holds far to
  the right (all leading coefficients positive), far to the left (all positive
  after the sign `(-1)^deg`), or at a critical point of the product — the last
  is what `many_exists` decides, with the derivative of the product as the
  polynomial. So the last shape the phase needs is reduced to the shapes it
  already decides.
- The argument in `poly_rolle` is the interval one: with a root of the product
  on each side of the witness, the nearest ones are `sup` and `inf` of the two
  root sets (`sup_zero`, `inf_zero` prove they are roots, by continuity and
  the leastness of the bound), no root lies strictly between them, so every
  member of the list keeps its sign there (`keep_pos`, from the intermediate
  value theorem), and Rolle's theorem (`mean_value_aux`) gives the critical
  point. If a root set is empty the conjunction holds on a whole ray, and then
  `far_left_list_inv` / `far_right_list_inv` read off the leading
  coefficients.
- Verified: gates passed for all four files (three fresh runs each, traces
  clean).
- Next: the formula layer — DNF over sign atoms, several equations folded into
  one by a sum of squares, and the strategy.

## 2026-09-12 — Phase 3: the pair of conditions, symbolically

- `tarski_two` (18/18): `two_exists` decides
  `EXISTS x: p(x, ys) = 0 AND q1(x, ys) > 0 AND q2(x, ys) > 0` from four
  Tarski queries computed by the chains of `tarski_chain`, under `two_ok`
  (the four queries well formed). It is `tarski_pair`'s identity carried over
  to coefficient lists over `mpoly`.
- `lmn(l1, l2, ys)` is the normalized product of two lists, and its six
  lemmas (nonempty, degree `dg(l1) + dg(l2)`, nonvanishing leading
  coefficient, array equal to `polynomial_prod` of the factors, `lok` closed,
  length) are what makes the queries composable: the squares and the mixed
  products are `lmn` applied twice, so `Q12 = lmn(q1, lmn(q2, q2, ys), ys)`
  and so on, and `Q12_arr` identifies its array with `tarski_pair`'s `q12`.
  `gsq` of `tarski_dec` was the special case `lmn(q, q, ys)`.
- `ex_bridge` moves the existential between the array form NASALib's counting
  uses and the `meval` form the decision states, the same skolemize-both-ways
  pattern as `snorm_ex2`.
- Verified: gate passed (three fresh runs at 18/18, traces clean).
- Next: the tree for two conditions (the analogue of `gdec`), then the
  Boolean-combination layer and the strategy.

## 2026-09-12 — Phase 3: two sign conditions at the roots

- `tarski_pair` (32/32): `pair_exists` decides
  `EXISTS x: p(x) = 0 AND q1(x) > 0 AND q2(x) > 0` from four Tarski queries,
  those of `q1 q2`, `q1 q2^2`, `q1^2 q2` and `q1^2 q2^2`. Each query is a
  difference of counts over the four sign patterns of (q1, q2) at the roots of
  p, and the four combinations add to four times the all-positive count
  (`pair_count`): A+D−B−C, A+B−C−D, A+C−B−D and A+B+C+D sum to 4A.
- This is the first step past a single sign condition, and it is the shape a
  Boolean combination needs. NASALib has the general identity for a family of
  polynomials (`Tarski@poly_families.mult_tarski_query_simple`, with the
  matrix inversion in `tarski_query` and `poly_systems`), but only for
  **integer** coefficient arrays; the symbolic construction produces real ones
  at a valuation, so the two-polynomial case is proved here over the reals.
- The proof is finite-set cardinality: the four root sets `SS(..., s1, s2)` are
  finite (subsets of the root set, which NASALib types as a `finite_set`) and
  pairwise disjoint, each query's solution set is a union of them
  (`Sol_11p` ... `Sol_22n`, by extensionality and the product-sign lemmas of
  the prelude), and `card_disj_union` turns the unions into sums. `card_pos`
  (`nonempty_card` plus `nonempty_member`) turns the count into the
  existential.
- Two things to know for this kind of proof: a set equality needs
  `(apply-extensionality <fnum> :hide? t)` with the formula number, because
  the negated hypothesis is also an equality; and the resulting boolean
  equality needs `(iff)` before `ground` will split it. PVS also flattens
  products, so `x*x*y*y > 0` needs its own lemma (`sq2pos`, proved by
  rewriting it as `(x*y)*(x*y)`); `sqpos` does not match it.
- Verified: gate passed (three fresh runs at 32/32, traces clean).
- Next: the symbolic side of the pair (the four product lists, their arrays
  and degrees through `earr_lmul` and `snorm_arr`), then the tree and the
  strategy for two conditions.

## 2026-09-12 — Phase 3: pruning the tree, and the sign-condition strategies

- `mpoly_cst` (10/10) and `btree_prune[T]` (7/7): almost every node of a
  symbolic Sturm-Tarski tree asks for the sign of a coefficient that is a
  number, because that is what the construction produces. `mcst?` recognizes a
  term that denotes a constant, `cst_val` is that constant, and `prune`
  replaces every such node by the child its sign selects. `select_prune` says
  the branch the parameters take is unchanged, so soundness carries over.
- The measurement that made this necessary: `branches(gdec(9, x^2 - 1, x))`
  has **48827** entries, all but one with contradictory conditions, and the
  strategy that reads them ran the Lisp control stack out. After pruning
  (`sgn_prune`, 4/4) it has **one**. For the parametric `a*x - 1` the count
  falls from 20529 to 415, and for `x - a` and `x^2 - a` to 9 and 27, which
  is what makes the parametric examples run.
- `poly-sign` and `poly-nosign` (in `cad/pvs-strategies`): the formula
  `EXISTS (x: real): P = 0 AND Q > 0` is read off the sequent, the pruned tree
  is evaluated, and every TRUE branch contributes
  `<sign conditions> IMPLIES EXISTS x: P = 0 AND Q > 0` while every FALSE
  branch contributes `<sign conditions> IMPLIES FORALL x: NOT (P = 0 AND Q > 0)`.
  Each fact is proved from `psign_branch` / `pnosign_branch`, the ground
  evaluation of the tree and Phase 1's reflection.
- The trick that makes the strategy possible: the witness `psign_branch`
  provides is skolemized **with the name of the formula's own bound variable**
  (`(skolem "sb" ("x"))`), so the polynomials printed from the formula parse
  again as expressions in the proof. Nothing has to be substituted textually.
- `sgn_examples` (6/6): `EXISTS x: x^2 - 1 = 0 AND x > 0` in one call;
  `NOT (EXISTS x: x^2 + 1 = 0 AND x > 0)`; `a > 0 IMPLIES EXISTS x: x - a = 0
  AND x > 0` and its negative counterpart; and `a > 0 IMPLIES EXISTS x:
  x^2 - a = 0 AND x > 0` — every positive number has a positive square root,
  decided by the tree. The parametric ones need one nonlinear side step
  (`a > 0` gives `-16 a^5 < 0`) which `assert` cannot do; `mult-ineq` does it.
- Two strategy lessons, both recorded in the tactics memory: the branch facts
  have to be `case`d **after** the witness is introduced (the nesting of the
  generated `spread`s is the proof order), and each `case` whose term mentions
  a `SignCond` record generates a subtype TCC, so every `spread` needs a third
  `(grind)` branch.
- Verified: gates passed for `mpoly_cst` (10/10), `btree_prune` (7/7),
  `sgn_prune` (4/4) and `sgn_examples` (6/6); `pos_examples` (17/17) and
  `qe_examples` (21/21) still replay against the extended strategy file.
- Next: Boolean combinations and several quantifiers (`qe_formula`), and the
  paper's conflict-detection example.

## 2026-09-12 — Phase 3: the sign condition with nothing assumed

- `sgn_dec` (8/8): `gdec_sound` decides `EXISTS x: p(x, ys) = 0 AND q(x, ys) > 0`
  under a bound on the fuel alone (`length(p) + 3 * length(q) <= k`). That is
  the difference between `sdec` and `gdec`: `sdec_sound` assumes `tok2`, which
  is a condition on the valuation and so cannot be checked by a strategy, and
  `gdec` branches on the three cases `tok2` rules out and answers them —
  p vanishing identically (the question `exists_dec` decides), p a nonzero
  constant (no root), q vanishing identically (nowhere positive).
- `sign_branch` and `nosign_branch` are the strategy-facing forms: a branch of
  the tree whose sign conditions hold at the parameters carries the answer
  there, from `branch_sound` and `gdec_sound`.
- `sign_tree` was refactored so this costs nothing: `score(k, p0, pq)` is the
  two chains and the comparison for a polynomial and a query whose degrees are
  already decided, `sdec` is `score` under the two degree branchings, and
  `score_at` gives its answer. Without that split `gdec` would branch on both
  degrees twice and the branch count would multiply. `select_sdec` is now
  three lines through `score_at`, and `sign_tree` re-gated at 8/8.
- Verified: `sign_tree` and `sgn_dec` gates passed (three fresh runs each,
  traces clean); `exists_dec` replays at 17/17 against the refactored
  `sign_tree`.
- Next: the strategy that reads `branches(gdec(...))` and proves one fact per
  branch, mirroring `poly-pos`.

## 2026-09-12 — Phase 3: deciding a strict inequality

- `exists_dec` (17/17): `edec_sound` decides `EXISTS x: q(x, ys) > 0` on a
  tree of sign conditions, with `3 * length(q) <= k` as the only hypothesis —
  syntactic, so a strategy can check it. This is the question that closes the
  gap in the sign conditions: when the polynomial of an equation vanishes
  identically, `EXISTS x: p = 0 AND q > 0` is exactly this.
- Five leaves: a list that normalizes to nothing is the zero polynomial and
  has no positive value; a positive leading coefficient gives one far to the
  right (`big_pos`); a negative constant has none (`pval_one`); a negative
  leading coefficient with an odd degree gives one far to the left
  (`big_pos_left`); and even degree with a negative leading coefficient is
  `crit_pos`'s case, decided by `sdec` for the derivative and the polynomial
  (`e_even_iff`).
- `tok2_lderiv` is where the fuel is counted: the two queries need
  `length(p) + length(q)` and `length(p) + length(q^2)` terms, and with
  p = q' that is `3 * length(q) - 2`, which is why the bound is three times
  the length. `sdec_at` is `sdec_sound` with the normalizations removed by
  `snorm_fix` (a list whose leading coefficient does not vanish is its own
  normalization).
- Two things PVS will not do by arithmetic alone: `assert` does not tighten
  `2 * j >= 1` to `j >= 1` for an integer j, so `even_dg_three` (an even
  degree of at least one is at least two) goes through `odd_one` and
  `odd_iff_not_even` instead; and the list recognizers need `list_inclusive`
  and `length_cdr` to get from `NOT null?` to `cons?` and back.
- The proofs of the assembled lemmas are ten-lemma sequents closed by a
  single `ground`: propositional splitting turns each conditional lemma into a
  branch that proves its hypothesis, and `assert` closes those arithmetically.
  That is much shorter than discharging the hypotheses by hand, and it is why
  the helper lemmas are stated with the hypotheses the callers already have.
- Verified: gate passed (three fresh runs at 17/17, traces clean).
- Next: the guarded sign tree — `sdec` with the degenerate branches answered by
  `edec`, so its soundness needs only the syntactic fuel bound — and then the
  strategy for sign conditions.

## 2026-09-12 — Phase 3: a positive value at a critical point

- `crit_pos` (15/15): `crit_exists` says a polynomial of even degree with a
  negative leading coefficient is positive somewhere exactly when it is
  positive at one of its critical points. This is the one case the root
  counting does not reach on its own: such a polynomial tends to minus
  infinity in both directions, so it can be positive without being positive
  near infinity, and no count of roots sees that.
- The proof is the only analysis in the phase: `far_neg_left` and
  `far_neg_right` put a negative value on each side of the positive one
  (NASALib's `poly_sign_near_infinity` and its negative-infinity twin),
  `max_in_interval` attains the maximum over the closed interval between
  them, that maximum is at least the positive value so it is interior, and
  `deriv_maximum` makes the derivative vanish there. `deriv_max_le` is
  `deriv_maximum` restated over the closed interval the extreme value theorem
  gives, and `crit_between` is the whole argument for one interval.
- `pf_deriv`: the derivative of `LAMBDA x: meval(mpol(l))(cons(x, ys))` is the
  same function of `lderiv(l)`, which connects Phase 1's `mderiv` to the
  coefficient-list derivative the chains use. The one-argument `deriv` of
  `analysis@derivatives` is a function and the two-argument one is its value,
  so `pf_deriv_at` exists to move between them.
- With `crit_exists` the remaining question `EXISTS x: q(x, ys) > 0` becomes
  the question `sign_tree` already decides, with the derivative as the
  polynomial and the polynomial itself as the query.
- Verified: gate passed (three fresh runs at 15/15, traces clean).
- Next: `exists_dec`, the tree for `EXISTS x: q(x, ys) > 0`, and then the
  guarded sign tree whose soundness needs no semantic hypothesis.

## 2026-09-12 — Phase 3: the sign condition as a branch tree

- `sign_tree` (7/7): `sdec(k, l0, q)` is a tree of sign conditions on the
  parameters whose leaves are TRUE or FALSE, and `sdec_sound` says the leaf the
  parameters select answers `EXISTS x: p(x, ys) = 0 AND q(x, ys) > 0`. This is
  to `sign_exists` what `qdec` is to the root count: the decision no longer
  needs the valuation to build the chains, only to pick a branch.
- The tree normalizes p, q and q^2 (three degree branchings), builds the two
  Tarski chains through the helper `ctree`, and compares `tqf(cs1) + tqf(cs2)`
  with zero at the leaf. `tqf` is the query read off a sign-annotated chain,
  and `tq_tqf` identifies it with the `tq` of `tarski_count`; `slof_tchain`
  splits the sign-annotated chain into its head and the `rchain` tail, which is
  what lets `prsp` and `select_prsp` be reused for the Tarski chain as well.
- `select_ctree` needs its argument to be a pair of a list with the sign of its
  own leading coefficient. Stated that way it is not a rewrite rule, so
  `select_ctree_at` is the same fact with the hypothesis discharged
  (`p0 := sl_of(l0, ys)`), and that version is what `select_sdec` rewrites
  with. Two attempts at `select_sdec` failed before that: instantiating
  `select_ctree` leaves `sl_of(l, ys)`slist` under a `ctree`, and no amount of
  replacing reduces it in place.
- `snorm_ex2`: normalizing both the polynomial and the query does not change
  the question. `rewrite` cannot do this one, since the substitution has to
  happen under an `EXISTS` whose variable the rule would have to capture; the
  two directions are skolemized separately instead.
- Verified: gate passed (three fresh `proveit -f` runs at 7/7, traces run with
  no "fewer subproofs" warning).
- Next: the strategy for sign conditions on top of `sdec` (mirroring
  `poly-pos`), then Boolean combinations and several quantifiers.

## 2026-09-12 — Phase 3: Tarski queries, and sign conditions at the roots

- `tarski_dec` (9/9): `sign_exists` decides `EXISTS x: p(x) = 0 AND q(x) > 0`.
  Two Tarski queries determine the number of roots where q is positive:
  TQ(p, q) is the difference of the counts where q is positive and negative,
  TQ(p, q^2) is their sum (q^2 is positive exactly where q is nonzero), so
  twice the number is their sum. This is the step past equations to arbitrary
  sign conditions, which is what the rest of the phase needs.
- `tarski_count` (6/6): `tq_val` computes the query from the leaf of the
  symbolic chain, through `Tarski@sturmtarski`'s `sturm_tarski_unbounded`.
  `hi_eq_n` and `lo_eq_n` generalize the sign counting of `sgn_count` to any
  chain whose elements are nonempty up to an explicit index.
- `tarski_chain` (38/38): `tchain_sturm` says the chain whose second element
  is g times the derivative satisfies `Tarski@sturmtarski`'s
  `constructed_sturm_sequence?` at every valuation. The chain reuses `rchain`
  and every structure lemma already proved for it: `gchain` and the `gc_*`
  lemmas are the chain with an arbitrary second element, and the Sturm chain
  of `chain_sturm` and this one are the two instances.
- `mpoly_prod` (10/10): `earr_lmul`, the product of two coefficient lists
  denotes NASALib's `polynomial_prod` of the arrays of the factors. The proof
  does not compute the convolution: two arrays that denote the same polynomial
  at a degree at least as large as both, and vanish above it, agree
  coefficient by coefficient. That trick is what made the Tarski chain
  affordable.
- `snorm_arr` (5/5): normalizing a list leaves its array alone, not only the
  polynomial, so the degree of the normalized list is the top index at which
  the array is nonzero. The Tarski chain needs it because the predicate pins
  the degree of the second element to deg(g) + deg(p) - 1 while the product
  list may carry trailing zeros.
- `poly-nonzero` (in `cad/pvs-strategies`): the same tree read for the absence
  of roots, adding `<sign conditions> IMPLIES P /= 0` per FALSE branch.
- Examples: `x^2 + x*y + y^2 + 1 > 0` for all real x and y is proved in two
  rounds, the first eliminating x and leaving `-16 - 12*y^2 < 0`, the second
  eliminating y. A quartic with a parameter shows the cost of the squaring
  trick in `sturm_step`: branch conditions with coefficients around 10^43 and
  degree 14 in the parameter. A subresultant sequence is the fix, and is
  Phase 4.
- `tarski_examples` (9/9): for p = x^2 - 1 and q = x the evaluator computes
  TQ(p, q) = 0 and TQ(p, q^2) = 2, so a root with q > 0 exists, and
  `sign_exists` turns that into a proof of `EXISTS x: x^2 - 1 = 0 AND x > 0`;
  for q = -x^2 the sum is zero and the same decision proves there is none.
  The fuel has to cover both chains, so the second example runs at k = 10.
- Whole library: `proveit -a top.pvs` gives 1001/1001 in 491 s over 53 files.
- Next: the branch-tree and strategy layer for sign conditions (mirroring
  `prsp`, `qdec` and `poly-pos`), then formulas with several quantifiers.

## 2026-09-12 — Phase 3: positivity, and a strategy that uses it

- `pos_dec` (14/14): `pdec(k, l0)` decides `FORALL x: p(x, ys) > 0` on the same
  tree, with different leaves. A polynomial with no real root keeps one sign
  (`no_root_pos`, the intermediate value theorem applied through the
  derivability of `meval` from Phase 1), and at large x that sign is the sign
  of the leading coefficient (`big_pos` / `big_neg`, from NASALib's
  `poly_sign_near_infinity`), so positivity everywhere is exactly the absence
  of a root once the leading coefficient is known positive (`pos_iff`). The
  leaves are FALSE where the polynomial vanishes identically or its leading
  coefficient is negative, TRUE for a positive constant, and the absence of
  roots otherwise.
- `poly-pos "P" "x"` (in `cad/pvs-strategies`): evaluates the tree for the
  polynomial expression P and adds one proved fact per branch on which P is
  everywhere positive,
      <sign conditions on the other atoms> IMPLIES P > 0,
  labelled poly-pos. The conditions are the branch conditions printed as
  ordinary arithmetic; each fact is proved from `pos_branch` (branch_sound and
  pdec_sound), the ground evaluation of the tree and the Phase 1 reflection,
  so nothing the printer produces is trusted.
- `pos_examples` (12/12): `b^2 < 4c IMPLIES x^2 + b*x + c > 0` is proved by
  `(poly-pos "x^2 + b*x + c" "x")` followed by `assert` in about 18 s, and the
  fact the strategy adds is exactly the discriminant condition. Also
  `(x + y)^2 + 1 > 0`, `x^4 - b > 0` for b < 0, and with a symbolic leading
  coefficient `a > 0 AND b^2 < 4ac IMPLIES a*x^2 + b*x + c > 0`, where the
  tree returns two branches: a > 0 with the discriminant scaled by a^3 (the
  price of the squaring trick in `sturm_step`) and the degenerate
  a = 0, b = 0, c > 0.
- `poly-nonzero "P" "x"` reads the same tree for the absence of roots and adds
  `<sign conditions> IMPLIES P /= 0` per FALSE branch (`noroot_branch`);
  `b^2 < 4c IMPLIES x^2 + b*x + c /= 0` and `c > 0 IMPLIES x^2 + c /= 0`.
- Whole library: `proveit -a top.pvs` gives 921/921 in 449 s over 37 theories.
- Proof-engineering notes: `^` and `expt` are different definitions, so
  arithmetic that must compare `a^3 * a` with `a^4` needs `(expand "^")` and
  then `(expand "expt")` repeatedly; `every` over a literal list needs `grind`
  rather than one `expand`, since one expansion leaves the tail; and a lemma
  declared after the one being proved is invisible, which is worth checking
  first when a `lemma` step reports no resolution.
- Next: Tarski queries (sign conditions rather than equations), which lift the
  same construction with `Tarski@sturmtarski`'s real-coefficient generalized
  chain, and then formulas with several quantifiers.

## 2026-09-11 — Phase 3: branching quantifier elimination, running

- `root_dec` (12/12): `qdec(k, l0)` is a tree of sign conditions on the
  parameters whose leaves are TRUE or FALSE, and `qdec_sound` says the leaf
  the parameters select answers `EXISTS x: p(x, ys) = 0`. Read through
  `branches` the tree is a quantifier-free formula in the parameters, so this
  is quantifier elimination for one equation and one quantifier by branching
  Sturm. Three kinds of leaf: identically zero at ys, a nonzero constant, or
  degree at least one and then the verdict is the comparison of the two sign
  counts (`main_count`, from `Sturm@sturm`'s `sturm_unbounded`).
- `branch_sgn` (10/10) and `sgn_count` (12/12): the sign of every leading
  coefficient is already decided on a branch, so `snormp` records it in the
  leaf and both counts become functions of the leaf. `nsc_sign_eq` licenses
  the substitution: the number of sign changes depends only on the signs.
  `select_prsp` is one induction on the step count that reuses every structure
  lemma already proved for `rchain`, rather than redoing them for the
  sign-carrying sequence.
- `qe_examples` (12/12): the procedure runs. For `x^2 + y` the evaluator
  reports no root at y = 1 and a root at y = -1 and at y = 0; for `a*x + b` a
  root at (2, 3), none at (0, 3) and a root at (0, 0), which is the degree
  branching deciding and not the sign counting; for `x^2 + b*x + c` it
  reproduces the discriminant condition. Each takes well under a second.
  `e11` closes the loop: `NOT EXISTS x: x^2 + 1 = 0` proved by `qdec_sound`
  and one evaluation of the tree, the reflection skeleton the strategy needs.
- Whole library: `proveit -a top.pvs` gives 882/882 in 335 s.
- Proof-engineering notes: `eval-formula` does not close a goal of the shape
  `NOT select(...)`, but the prover command `eval-expr` computes the value and
  adds it as a hypothesis, which `assert` then uses; instantiating a lemma
  whose bound variable ranges over a subtype fails silently unless the
  existential it comes from has already been skolemized; and a lemma stated
  with an explicit `FORALL` inside is quantified *after* the theory's free
  variables, so the argument order of `inst` changes.
- Next: the `qe` strategy (the sequent front end for the tree), then Tarski
  queries, which lift the same construction to sign conditions rather than
  equations, using `Tarski@sturmtarski`'s real-coefficient generalization.

## 2026-09-11 — Phase 3: the symbolic sequence is a Sturm sequence

- `chain_sturm` (38/38): `fchain_sturm` is the theorem the whole phase was
  aiming at. Read the chain that `branch_prs` computes as the triple
  `Sturm@sturm` expects (a coefficient array per index, its degree, and a last
  index) and it satisfies `constructed_sturm_sequence?` at every valuation ys,
  provided the polynomial is not constant in the eliminated variable, its
  leading coefficient does not vanish at ys, and the step count is large
  enough. Every theorem of NASALib's Sturm development therefore applies to
  the symbolic construction, one branch at a time.
- The fifth condition is the crux and `step_cond` is where it is paid for. For
  a divisor of degree at least one it is `sstep_sturm` read through
  `snorm_poly` (normalizing changes neither the polynomial nor the value).
  For a divisor of degree zero, which can only be the last nonzero element,
  both sides are the zero polynomial: `poly_divide_struct` gives NASALib's
  remainder as zero and `step_zero` gives our chain element as the empty list.
- Condition 2 (degrees strictly decreasing across all pairs, not only
  consecutive ones) needed `strict_dec`, an induction turning a decreasing
  step into a decreasing sequence.
- `branch_prs` (34/34): `prs(k, l1, l2)` iterates the step and the degree
  branching; `rchain` is the same recursion at one valuation and `select_prs`
  identifies them, so every question about the symbolic sequence becomes a
  question about `rchain`. The structure lemmas (`rchain_last`,
  `rchain_nonnull`, `rchain_lc`, `rchain_dec`, `rchain_step`) are inductions
  on the step count that peel one step with `rchain_cons` / `rchain_len` /
  `rchain_nth`, so no proof ever unfolds the recursion twice.
- `sturm_step` (9/9): the step is `-b^k * prem(l1, l2)`. The Sturm condition
  asks for a NEGATIVE multiple of the remainder and pseudo-division gives
  `b^k` times it, whose sign is unknown when k is odd; multiplying once more
  by b makes the multiplier `(b^k)^2`, positive for every nonzero b. So no
  branch on the sign of b is needed, at the price of one extra factor of b in
  the coefficients per step. A subresultant sequence is the natural successor.
- `earr_deriv` (8/8): the formal derivative of a coefficient list, and the
  array it denotes is exactly NASALib's `poly_deriv` of the array of the list,
  which is what the third condition asks for (an equality of arrays, not only
  of the polynomials they denote).
- Proof-engineering notes from this stretch, all confirmed the hard way:
  `assert` does not apply modus ponens when the hypothesis of an implication
  is a disjunction or a conjunction sitting in the sequent, so a leaf step is
  `ground` and not `assert`; `expand "length"` on a term whose list is not a
  literal leaves an unevaluable CASES and poisons every arithmetic fact in the
  sequent, so peel with a lemma (`rchain_len1`) instead; a lemma may only be
  used by a proof of something declared later in the theory; and `split` on a
  conjunction of eight conjuncts yields eight subgoals at once, not two.
- Verified: three fresh `proveit -f` runs plus the `--traces` run on each of
  `earr_deriv`, `sturm_step`, `branch_prs`, `chain_sturm`, zero "fewer
  subproofs" warnings. `tools/gate.sh` runs the gate and now also fails on an
  "unfinished" line, which caught a TCC added late to `branch_prs`.
- Next: the sign of each leading coefficient carried in the tree, the number
  of sign changes at plus and minus infinity, and `sturm_unbounded` to decide
  whether a symbolic polynomial has a real root on each branch.

## 2026-09-11 — Phase 3: the pseudo-remainder is NASALib's remainder

- `prem_arr` (14/14): the identification the Sturm construction needs. For each
  valuation ys of the parameters, the Phase 1 pseudo-remainder of two
  coefficient lists is exactly `b^k` times the remainder `poly_divide`
  computes, where b is the value of the leading coefficient of the divisor:

      polynomial(earr(prem(l1, l2), ys), length(l2) - 2)(w)
        = blc(l2, ys)^pk(l1, l2) * polynomial(pr(...), prd(...))(w)

  `prem_eval` lifts `pquo_rem_eval` from `meval` to real coefficient arrays
  through `earr`, and `divide_unique_scal` identifies the two remainders.
- `poly_unique` grew `divide_unique_scal` (11/11): if `cc * G = Q H + R` with
  deg R below deg H and cc nonzero, then R is cc times `poly_divide`'s
  remainder. The plain `divide_unique` cannot be used directly here, because
  pseudo-division multiplies the dividend by a power of the leading
  coefficient instead of dividing by it, and the conclusion has to be about
  the remainder of the *unscaled* dividend, which is the one the Sturm
  condition names. Proved by the same argument as `divide_unique`: the two
  division equations are subtracted, and the difference of the remainders is a
  multiple of H of degree below that of H, hence zero.
- `mpoly_real` grew `earr_eval_d` (9/9), the evaluation homomorphism at any
  degree bound at or above the list length rather than exactly `length(l) - 1`.
  Every step of the remainder sequence names its degree bound from the *divisor*
  (`length(l2) - 2`), never from the list it is applied to, so the exact form is
  unusable in practice; `extend_polynomial` supplies the slack.
- The divisor is required to have length at least two, that is degree at least
  one. That is not a restriction for the sequence: a `constructed_sturm_sequence?`
  ends with the zero polynomial of degree zero and the degrees strictly
  decrease, so every divisor along the way has degree at least one.
- Verified: three fresh `proveit -f` runs plus the `--traces` run on each of
  `poly_unique`, `mpoly_real`, `prem_arr`, zero "fewer subproofs" warnings.
- Next: `branch_prs`, the pseudo-remainder sequence as a branch tree, with the
  theorem that each branch evaluates to a `constructed_sturm_sequence?`.

## 2026-09-11 — Phase 3: coefficient lists as real arrays

- `mpoly_real` (8/8): `earr(l, ys)` is the real coefficient array a list of
  mpoly coefficients denotes once the parameters take real values ys, and
  `earr_eval` is the evaluation homomorphism, `polynomial(earr(l, ys),
  length(l) - 1)(x) = meval(mpol(l))(cons(x, ys))`. Every theorem of NASALib's
  Sturm development is stated about real coefficient arrays, so this is what
  lets a symbolic construction be checked against the library one valuation at
  a time. With `earr_top` (the array's leading entry is the value of the last
  coefficient) the degree facts of `branch_norm` transfer as well.
- Proof note: the induction works only if the decomposition lemmas are applied
  before `earr` is expanded; expanding it first turns the array into an IF over
  `nth` and neither `polynomial_eq_a0_plus` nor the induction hypothesis
  matches any more.

## 2026-09-11 — Phase 3: uniqueness of polynomial division

- `poly_unique` (10/10): uniqueness of division with remainder over the reals.
  NASALib's `poly_divide` proves the defining equation and the degree bound
  but not that the pair is unique, and the branching elimination needs exactly
  that, because the symbolic algorithm produces a pseudo-remainder R with
  b^k G = Q H + R while the Sturm condition of `Sturm@sturm` is phrased in
  terms of `poly_divide`'s remainder. `divide_unique` identifies the two.
- The argument: `low_degree_zero` says a multiple of H whose degree is below
  that of H is the zero function, proved by taking the top nonzero
  coefficient of the multiplier (`polynomial_degree_existence`), forming the
  product (`prod_top`, the leading coefficient of a product, by the same
  sigma argument used for the sums of squares in Phase 2) and comparing
  coefficients (`polynomial_eq_coeff`) at a degree the remainder cannot
  reach. `diff` and `trunc` package the difference of two polynomials of
  different nominal degrees as one polynomial, which is what makes the
  subtraction of the two division equations expressible.
- This is the bridge the rest of Phase 3 rests on: a symbolic pseudo-remainder
  sequence can now be shown to satisfy `constructed_sturm_sequence?`, whose
  fifth condition asks each element to be a positive multiple of the negated
  `poly_divide` remainder. The sign of that multiple is b^k, so the symbolic
  algorithm branches on the sign of b and negates accordingly.

## 2026-09-11 — Phase 3: map/bind and the symbolic degree

- `branch_map[T, U]` (12/12): `bmap` applies a function to every leaf,
  `bbind` replaces every leaf by a tree, so one symbolic step followed by
  another is again a branch tree and the later step may branch further.
  `select_bmap` and `select_bbind` say both commute with evaluation, which is
  what reduces reasoning about the symbolic algorithm to reasoning about the
  ordinary one at each valuation.
- `branch_norm` (6/6): the first genuinely symbolic step. A polynomial in the
  eliminated variable is a list of `mpoly` coefficients in the parameters;
  its degree is not fixed by the syntax because the leading coefficient can
  vanish. `snorm` branches on the sign of the last coefficient, dropping it
  where it is zero, so on every branch the leading coefficient is known
  nonzero. `snorm_eval` (the polynomial is unchanged as a function of the
  point and the parameters) and `snorm_lc` (the leading coefficient of the
  result is nonzero) are the two facts every later step needs.
- Design check: NASALib's abstract Sturm theory (`Sturm@sturm`) is stated over
  real coefficient arrays `[nat -> real]`, not just the integer/rational
  executable layer. So the branching design works as the plan assumed: on each
  branch the evaluated polynomials have real coefficients and the library's
  Sturm and Sturm-Tarski theorems apply directly, with no new mathematics.
- Proof notes: `expand` with no target rewrites inside the induction
  hypothesis and destroys the shape it must match, so expansions are confined
  to the consequent with `+`, or done with the `select_leaf` / `select_node`
  lemmas as rewrites, which leave `select(snorm(...), ys)` intact;
  `auto-rewrite` did not fire on those lemmas where explicit `rewrite` did.

## 2026-09-11 — Phase 3 begins: sign-condition branch trees

- `btree[T]` datatype and `branch_tree[T]` (27/27, gated): the shape of a
  computation that is symbolic in the parameters. A node carries an `mpoly`
  and three subtrees, one per sign; a leaf carries a result.
- `select(t, ys)` follows the signs of the node polynomials at the valuation
  `ys` down to a leaf. `branches(t)` lists every leaf with the sign conditions
  on the path that reaches it, so it is the finite disjunction that the
  elimination will return as a quantifier-free formula.
- The two theorems that make this a case analysis: `branch_exists` (at any
  `ys` some listed branch has all its conditions satisfied and carries
  `select(t, ys)`) and `branch_sound` (every satisfied branch carries
  `select(t, ys)`). Corollary `branch_forall`: a property holding at every
  leaf holds at every valuation, which is how leaf-wise correctness of the
  symbolic algorithm will transfer to all parameters.
- Proof notes: `add_cond` is defined by recursion rather than with `map`,
  which makes the list inductions one `assert` each; the node cases of both
  theorems are factored into per-sign step lemmas (`step_neg/zer/pos`,
  `mem_branch_neg/zer/pos`, `branches_node_inv`) so the inductions have a
  uniform shape; `conds_hold_head`/`tail` keep `conds_hold` abstract, because
  expanding `every` in a hypothesis stops it matching the induction
  hypothesis.
- Next in Phase 3: `branch_map` (the map and bind that let the symbolic
  algorithm be written as a sequence of branching steps), then `branch_prs`
  (the pseudo-remainder sequence as a branch tree).

## 2026-09-11 — Model change: Fable 5.1 to Opus 5

- Phases 0, 1 and 2 were done by Claude Fable 5.1. From Phase 3 on the work is
  done by Claude Opus 5 (the change took effect mid-session, after the Phase 2
  close-out; Fable's last turn was 2026-09-11T18:53Z).
- `tools/llm_usage.py` now records the model that produced each phase's turns,
  so the per-phase table in the paper shows it; the methods section warns that
  counts are comparable only within a model and that proof style will differ.
- What does not change: the verification gate. Three fresh `proveit -f` runs
  plus `proveit -l --traces -f` per file, whatever wrote the proof.

## 2026-09-11 — Phase 2 closed: the alg-roots strategy

- `alg_strategy` (3/3): `upoly` (the Polylist of a univariate PolyExpr, via
  `partial_eval` of Phase 1), `root_interval` (every root of p lies in one of
  the isolating intervals of `roots(p)`), `sign_at_root` (the sign of q at the
  root isolated by a is `alg_sign(a, q)`).
- `cad/pvs-strategies`: `(alg-roots "P" ("Q1" ...) var split?)` isolates the
  real roots of the univariate polynomial expression P and adds the proved
  facts `P = 0 IMPLIES (lb_1 <= x AND x <= ub_1) OR ...` (labeled `alg-roots`)
  and, per root and per Q, `lb_i <= x AND x <= ub_i AND P = 0 IMPLIES Q > 0`
  (or `= 0`, or `< 0`). With `split?` the sequent is split into one case per
  root. All computation (upoly, deg, roots, alg_sign) happens in the strategy's
  `let` through the ground evaluator; every fact is then proved from the three
  lemmas above, `eval-formula` and the Phase 1 reflection.
- `alg_strategy_examples` (9/9): x^2-2 with 2x^2-3 > 0; x^3-x with x^2 <= 1;
  an unsatisfiable x^2+1 = 0; a quintic with roots 1..5 bounded by the signs of
  x-1/2 and x-11/2; a defined handle f(x) = x^4-5x^2+4; x^2-2 = 0 giving
  x^4-4 = 0. Each proof is a single `alg-roots` call, 4 to 40 seconds.
- Whole library: `proveit --importchain -f top.pvs` 668/668, 27 theories.
- Lessons: in a `defstep` body every computed argument must be bound in the
  `let` (strategy arguments are not evaluated), and a variable-length script is
  built as data there and run with `(mapstep #'(lambda (st) st) list)`; `prop`
  on a sequent carrying k interval facts and m sign facts is exponential, so
  the strategy splits on the labeled disjunction instead and follows with
  `flatten`; a TCC raised by `inst` prints rationals canonically (`-1/2`) which
  does not match a `case` text (`-1 / 2`), so lemmas that the strategy
  instantiates are stated over the base type with an explicit predicate
  hypothesis.
- Phase 2 gate met: every plan item verified (isolating-interval algebraic
  numbers, sign, isolation of all roots, comparison, Thom encodings, the
  strategy), each file with three fresh `proveit -f` runs plus traces.
  Phase 3 (branching quantifier elimination) opens.

## 2026-09-10 — Phase 2: isolation, order, Thom encodings

- `alg_isolate` (42/42): `roots(p)` isolates every real root of p as a list
  of algebraic numbers with strictly increasing values. Bisection with the
  half-open count `nroots_h` (Sturm's `number_roots_interval` on (lb, ub])
  so a root at a split point belongs to one half only; a single root sitting
  at the right endpoint is rational and `shrink` finds a symmetric isolating
  interval around it; termination of both loops by the root separation
  `mrd = min_poly_root_dist` in the epsilon order; the specification
  `iso_spec` (elements are algebraic numbers of p, their values are exactly
  the roots in (lb, ub], increasing) by `measure_induction` on pairs of
  endpoints with one lemma per case of the recursion; the initial interval
  is NASALib's Cauchy-type bound `poly_root_bound`, restated as a rational.
- `alg_order` (15/15): `alg_eq` (value(a) is a root of b's polynomial inside
  b's interval, decided by `alg_sign`), `sepr` (bisect both numbers until the
  intervals are disjoint; measure `max(width)` in the epsilon order of half
  the distance of the values), `alg_cmp_def: alg_cmp(a, b) = sign3(value(a) -
  value(b))`.
- `thom_lemma` (24/24): Thom's lemma on coefficient sequences. `dk` iterates
  `poly_deriv`; `sat(a, n, sc, i)(x)` says derivatives i..n have the signs
  `sc` at x; `sat_convex`: such sets are convex, by downward induction on i:
  on an interval where the (i+1)st derivative keeps a nonzero sign the i-th
  is strictly monotone (NASALib `poly_increasing_is_strict`), and a nonzero
  polynomial cannot vanish on an interval (root separation). `thom_distinct`:
  two roots with the same signs of p', ..., p^(n) are equal.
- `thom_enc` (27/27): Polylist derivatives `pderiv`/`nderiv` with
  `nderiv_eval` (bridge to `dk`), executable encodings `thom(p, a)`
  (signs of p^(d), ..., p' at value(a) by `alg_sign`), and
  `thom_encoding_distinct`. So a root of p is determined by its encoding.
- `alg_examples` (52/52): isolation of x^3 - x, x^2 - 2, x^2 + 1, a double
  root, a quintic with five integer roots; comparisons sqrt(2) vs sqrt(3) vs
  the golden ratio vs 3/2; Thom encodings of the roots of x^3 - x
  ((1,-1,1), (1,0,-1), (1,1,1)) and of x^2 - 2; derivatives.
- Whole library: `proveit --importchain -f top.pvs` 656/656, 25 theories.
- Lessons: `assert` does not identify alpha-equivalent quantified formulas
  coming from different sources (a `case` hypothesis and a lemma's
  antecedent), so discharge lemma hypotheses with `split` on the
  instantiated implication and `inst`; `inst` on a lemma whose statement has
  an explicit FORALL takes the theory-level free variables first (in
  alphabetical order) and then the bound ones; a nested-IF equation over
  `sign3` closes with repeated `lift-if`/`prop`/`assert` rounds; when a
  theorem's variables are all in one FORALL, `induct` on one of them
  generalizes the others (instantiate the hypothesis before use).

## 2026-09-10 — Phase 2: algebraic numbers, zero test, sign

- Representation decision: univariate polynomials are Sturm's `Polylist`
  (rational coefficients, lowest degree first), which is what
  `mpoly_univ.partial_eval` produces; the Sturm procedures get the integer
  form `ipoly` (NASALib's `rat_poly_to_int`) with a precomputed chain.
- `alg_count` (29/29): `nroots_a(A, n, lb, ub)` on integer arrays (Sturm's
  `roots_closed_int`) and `nroots(pl, lb, ub)` on Polylists, with the
  specifications `nroots = 0 IFF empty?`, `>= 1 IFF nonempty?`,
  `= 1 IFF exactly one root` derived from the library's bijection lemma
  through two small finite-set lemmas (`bij_empty`, `bij_single`).
- `alg_def` (32/32): `alg = [# p, lb, ub #]`, executable invariant `alg?`
  (`nroots = 1`), `value(a)` by `the` on the singleton root set with
  `value_root/in/unique/char`, rationals as algebraic numbers (`rat_alg`),
  bisection `refine` with `refine_alg` and `refine_value` (the half not
  containing the root has no root, by uniqueness), `refine_n` with width
  `width/2^n`.
- `alg_zero` (18/18): `zero_at(a, q)` decides `q(value(a)) = 0` by counting
  the roots of the sum of squares `p^2 + q^2` on the isolating interval
  (a common root there is the unique root of p). The squares are integer
  arrays (`isq`, `sos`) built with `polynomial_prod`'s coefficient formula,
  whose degree `2 max(deg p, deg q)` and positive leading coefficient come
  from two sigma facts (`sigma_eq_arg`, empty range); `polylist_deg0` and
  `ipoly_root_any` extend the Polylist/array bridge to degree 0.
- `alg_sign` (40/40): `alg_sign(a, q) = sign3(q(value(a)))`. The bisection
  loop `sep` refines until q has no root in the interval; it terminates
  because the width halves and `value(a)` is at distance more than `qdist`
  from every root of q, where `qdist = min_poly_root_dist(p*q)` (NASALib's
  root separation of the product, since the roots of q are roots of p*q
  distinct from value(a)); the measure is `real_ord_ep(qdist)`, and the
  loop invariants are proved with the prelude's `measure_induction` lemma
  (PVS's `measure-induct+` assumes a nat measure). Then Sturm's
  `compute_poly_sat` at the midpoint decides the constant sign.
- `alg_examples` (22/22): counts, `sqrt(2)` as `(x^2 - 2, [1, 2])`, five
  bisection rounds, six signs at `sqrt(2)` including a shared root
  (`x^4 - 4`) and a constant, all by `eval-formula` in well under a second.
- Lessons: `rewrite` matches the first instance in the sequent, often the
  wrong one in a hypothesis: use `lemma`+`inst`; `inst` on a lemma with
  `FORALL` inside its body takes the outer (free) variables alphabetically
  followed by the inner ones; TCC subgoals of `case`/`inst` come as extra
  branches, so `spread` needs closers for them; `measure-induct+` treats a
  real measure as nat (see `simple-measure-induct` in strategies.lisp).

## 2026-09-10 — Phase 1 closed: mult_poly bridge, mpoly-simp, showcase

- `mpoly_mono` (67/67): `tm` converts a recursive polynomial to a NASALib
  `mult_poly` monomial list (`shift0` prefixes exponent vectors with 0,
  `shift_up`/`bump` increments the head exponent, zero constants are dropped);
  `tm_eval: full_eval(tm(p))(xs) = meval(p)(xs)` whenever `xs` is long enough
  for `mult_poly`'s evaluation. On the way, the evaluation theory that
  `mult_poly` lacks: `full_eval_nil/cons/append/scale/nullp`, `full_eval_null_alpha`,
  the monomial shifts `full_eval_shift0_mono`/`full_eval_shift_up_mono` (via
  `eval_vals`), the list shifts, and `max_length` of every construction.
- `mpoly_mono_examples` (6/6): `tm_peval` (any `PolyExpr` reaches `mult_poly`
  with its value preserved) and ground conversions checked by `eval-formula`
  (`tm` is executable: `(x+y)^2` becomes three monomials).
- `mpoly-simp` strategy: normalizes a polynomial expression in place (normal
  form printed back as `coef*var^i` sums and substituted by a verified `case`).
- `mpoly_showcase` (43/43): identities up to 8 variables (Lagrange's four-square
  identity), Chebyshev/Legendre definitions, 2x2 Cayley–Hamilton, opaque atoms,
  inequalities via identities (AM–GM, Cauchy–Schwarz), `mpoly-simp` in
  hypotheses and goals.
- Whole library: `proveit --importchain -f top.pvs` 377/377, 18 theories.
- Lessons: PVS closes free theory variables in alphabetical order (so
  `inst` on a lemma with free vars `m, q, xs` takes terms in that order);
  `rewrite` with a lemma stated over `list[nat]` can match a `list[real]` term
  and leave unprovable subtype subgoals — instantiate such lemmas explicitly;
  a record field containing an `IF` blocks the decision procedures (they do
  not normalize `car(al)+1` against `1+car(al)` inside it), fixed by naming
  the field expression (`bump`); `fulleval0_fconst` lives in
  `poly_comp_analytic`, which drags in analysis, so the null-exponent case was
  reproved locally; TCCs are only allowed to cite lemmas declared before the
  declaration that raised them.
- Phase 1 gate met: kernel, canonical forms with uniqueness, reflection
  strategies `mpoly-eq`/`mpoly-simp` with definition unfolding, univariate
  view, pseudo-division, `mult_poly` bridge, examples. Phase 2 (real algebraic
  numbers, Thom encodings) opens.

## 2026-09-10 — Phase 1: univariate view and pseudo-division

- `PolyExpr` constructors renamed with a `pe_` prefix (they clashed with
  `Sturm@polylist.pconst` etc., which would have made the strategy's `case`
  strings ambiguous in any context importing Sturm); `mpoly_embed` and
  `mpoly_examples` re-gated.
- `mpoly_univ` (31/31): `coef`, `lc`, `cf`, `meval_coef`; `mderiv` with
  `deg_mderiv`, `cf_mderiv`, `meval_mderiv`, `mderiv_derivable`,
  `mderiv_is_deriv` (the analytic derivative of `x |-> meval(p)(x::ys)` is
  `meval(mderiv(p))`, via `analysis@polynomial_deriv`); rationality of
  evaluation at rational points; `partial_eval` to a Sturm `Polylist` with
  `partial_eval_polylist` (`polylist(partial_eval(p, rs))(x) = meval(p)(x::rs)`),
  the bridge that lets Sturm/Tarski run on a specialized polynomial.
- `mpoly_pdiv` (33/33): coefficient-list operations `lscal`, `shiftl`, `lbut`,
  `llast`, `lsub` with length and evaluation lemmas; the reduction step
  `pstep` (top coefficient dropped syntactically so the length decreases);
  `pquo_rem` by recursion on the length, with `pquo_rem_eval`
  (`b^pk(l1,l2) * f = quo * g + rem` as functions) and
  `pquo_rem_rem_length` (`length(rem) < length(g)`). This is Collins's
  pseudo-remainder over polynomial coefficients, the primitive of the
  remainder sequences of Phases 3 and 4.
- Lessons: `grind` diverges on these theories (it unfolds `length`/`madd`
  without end); `expand` targets must name the goal formula explicitly after
  a `case` (the case fact takes formula 1); `(assert)` right after
  `measure-induct+` closes its TCC subgoals before the main script runs;
  a lemma instance that is a conjunction must be `assert`ed (to discharge its
  hypothesis) before `flatten` splits it.

## 2026-09-10 — Phase 1: uniqueness of normal forms (completeness)

- `mpoly_coefs` (8/8): coefficient sequences `coefs(l, ys)`, `meval_mpol_poly`
  (meval of a list is NASALib's `polynomial` in the head variable),
  `poly_coefs_eq` via `reals@polynomials.diff_polynomial` and
  `poly_eq_0_le_degree`.
- `mpoly_unique` (20/20): `nth_msize`, normality of list elements and of the
  last element (`tail_normal_nth/last`, `normal_nth/last/single`),
  `eq_fun_coefs`, `eq_fun_const_coefs`, the theorem `unique` (measure induction
  on `msize(p) + msize(q)` with four constructor cases and a length argument),
  and `mnorm_eq_iff: mnorm(p) = mnorm(q) IFF eq_fun?(p, q)`. So `mpoly-eq` is
  complete: it proves every true polynomial identity over its atoms.
- Kernel status: Phase 1 files `mpoly`, `mpoly_def`, `mpoly_arith`,
  `mpoly_norm`, `PolyExpr`, `mpoly_embed`, `mpoly_coefs`, `mpoly_unique`, the
  strategy `mpoly-eq` with definition unfolding, `mpoly_examples`: all gated.
- Proof-engineering notes: instantiate NASALib lemmas with `inst?` and
  `:subst` by name (their variable order follows first occurrence, not
  declaration); after `inst?` add `(assert)` so the nat-subtype TCC subgoals
  close before the next `spread`; use list eta (`list_cons_eta`) and
  `replace :dir RL` to turn an abstract list into `cons(car, cdr)` before
  expanding `nth`/`length`.
- Still to do in Phase 1: `mpoly_mono` (conversion to `mult_poly`), `mpoly_univ`
  (degree, leading coefficient, derivative, pseudo-division in the main
  variable) needed by Phases 3–4, and strategy extras (`mpoly-simp`,
  antecedent equalities).

## 2026-09-09 (late) — Phase 1: first strategy, mpoly-eq, working

- `PolyExpr` datatype and `mpoly_embed` (23/23): `peval` with one rewrite lemma
  per constructor, `pto`/`pnorm`, `meval_pto`, `peval_pnorm`, `poly_eq_by_norm`.
- `cad/pvs-strategies`: `mpoly-eq` — Lisp printer from a PVS real expression to a
  PolyExpr term (maximal non-polynomial subterms become variables, numbered by
  first occurrence; `sq(a)` printed as `pmul(a,a)`; division by a literal as
  multiplication by its inverse), then two `case`s proved by rewriting with the
  `peval_*` lemmas, one `case` decided by `eval-formula`, and `poly_eq_by_norm`.
  Skolemizes a universally quantified goal first.
- `mpoly_examples` (23/23 incl. TCCs): ten identities, degree up to 6, up to
  four variables, a function atom `f(x)`, `sq`, `1/2` and `/3`; each closes in
  about 0.5 s. This is PVS's first verified reflective ring tactic.
- Not yet: unfolding user definitions (front end), antecedent equalities,
  `mpoly-simp`, uniqueness of normal forms (completeness of the strategy).

## 2026-09-09 (night) — Phase 1: mpoly_norm verified

- `mpoly_norm` (18/18): `mnorm` (strip trailing zeros per level, empty list to
  `mconst(0)`, one-element list around a constant collapsed), `meval_mnorm`,
  `normalx(tail?, p)`/`normal?`, `normal_as_list_cons/tail`, `mnorm_normal`,
  `normal_mnorm_x` (in tail mode `mnorm` returns the same list and is non-zero;
  in normal mode it is the identity), `normal_mnorm`.
- Lessons: state lemmas with `as_list` rather than `coeffs` to avoid TCC branches
  inside `measure-induct+`; expand the constant `zero` before `assert` needs
  constructor disjointness; keep `as_list(mnorm(..))` opaque and rewrite the
  other side with a `case`, since expanding it into `CASES` blocks congruence.
- Remaining for the kernel: uniqueness (`mpoly_unique`, via
  `reals@polynomials.poly_eq_0_le_degree`), the deep embedding and the
  `mpoly-eq` strategy.

## 2026-09-09 (evening) — Phase 1: mpoly_def and mpoly_arith verified

- `mpoly_def` (29/29): size measure and its car/cdr lemmas in list and selector
  form, `hd`/`tl`, `meval`, rewrite lemmas for evaluation (constant, empty,
  cons, and selector forms), `as_list`, `mvar(j)`/`nth0`, `deg`.
- `mpoly_arith` (43/43): `madd`, `mscal`, `mneg`, `msub`, `mmulx` (one function
  for same-level and coefficient mode), `mmul`, `mpow`; 18 defining-equation
  lemmas with recognizer hypotheses; `meval_madd`, `meval_mscal`, `meval_mneg`,
  `meval_msub`, `meval_mmulx`, `meval_mmul`, `meval_mpow`.
- Proof pattern that works for the recursion over `mpol(cdr(l))`: measure
  induction (`measure-induct+` on `msize`), case split on recognizers with
  `mpoly_inclusive` for the coeffs TCC branch, rewrite with the defining
  equation, `inst-cp` on the labeled hypothesis, `inst` on the label for the
  inner quantifier (this needs the outer and inner quantifier arities to
  differ; generalize an extra variable in the induction if they do not),
  then `assert`. The mode flag of `mmulx` is generalized in the induction and
  the lemma is one equation with an `IF` on the flag, so instantiated
  hypotheses are plain equalities (conjunction hypotheses were not split by
  `flatten`, and `repeat` aborts a `then` chain when its step makes no change).
- Proof commands are generated by small Python scripts to keep the parentheses
  balanced; an unbalanced command makes the raw session loop on EOF.
- `tools/prove_each.sh`: one formula per raw session, immediate
  `save-all-proofs`, status per formula.

## 2026-09-09 (later) — Phase 0: probe verified, baselines, benchmarks

- `cad/mpoly.pvs` (datatype) and `cad/eval_probe.pvs`: recursive multivariate
  polynomials (D1) with `meval`, `madd`, `mscal`, `mmulx` (one function, coefficient
  mode and same-level mode, since PVS has no mutual recursion), `mpow`, `deg`; size
  measure `msize` via the generated `reduce_nat`; lemmas `msize_car`, `msize_cdr`,
  `msize_pos` discharge every termination TCC. Ground evaluation works: `(x+y+1)^8`
  evaluates to the correct coefficient table in 0.24 ms; `eval-formula` closes the
  probe lemmas. Gate: 28/28 in three fresh `proveit -f` runs, traces run clean.
- Finding: `save-all-proofs` works on the rebuilt PVS 8.1 as
  `(save-all-proofs (get-theory "T") t)`; proofs replay. Hand-built `.prf` is now a
  fallback only.
- Finding: an unprovable subtype TCC (`coeffs` of a possibly-constant result) showed
  up first as a ground-evaluator type error; the fix was to the definition.
- Baselines recorded in `cad/benchmarks/baseline.md` (Sturm 81/81, Tarski 39/39,
  hutch 35/35, Bernstein 94/94 on PVS 8.1).
- WellClear PVS development (nasa/WellClear, last updated for PVS 7.1) sparse-cloned
  to a local checkout of `WellClear`; the `WellClear` library replays 209/209 on 8.1
  (`proveit -i -f WCV_inclusion.pvs`). Benchmark targets listed in
  `cad/benchmarks/README.md`.
- mult_poly on 8.1: the shipped summary's typecheck error is gone and `simplified`
  is proved, so no repair was needed; the only issue is a `grind` in
  `smooth_not_analytic.deriv_left_right_point` that does not terminate in 30 min
  (upstream, not imported by this work).
- Phase 0 gate met: skeleton, probe verified, benchmarks located and replaying,
  baselines recorded. Phase 0 closed; Phase 1 (multivariate kernel) opens.
- The T7 drive unmounted once mid-session; `diskutil mount disk6s1` restored it, no
  data lost.

## 2026-09-09 — Plan, survey, toolchain, repository

- Read Narkawicz–Muñoz–Dutle (JAR 2015 draft) and the Sturm/Tarski/mult_poly/Bernstein
  sources; inventoried NASALib (nothing above univariate root counting exists: no
  resultants, subresultants, algebraic numbers, gcd, Gröbner).
- Prior art: Rocq `coq-mathcomp-cad` (CPP 2026) proves Collins CAD correct but is not
  executable; Isabelle multivariate QE (CPP 2023) is executable but impractical. Gap:
  executable, proof-producing CAD in a prover.
- Wrote `CAD_PLAN.md` (phases 0–6, design decisions D1–D7, application section 11).
  Decisions: both decision and QE output; recursive representation (D1); Thom encodings;
  complex route for root continuity; benchmarks = executable exact bands, symbolic bands,
  WCV_inclusion theorems, ACCoRD lemmas, literature CAD problems.
- Repository: this directory became `j-tanner-slagel/pvs_cad` (fresh history); the
  matrix library was pushed to `matrix_suite` and removed here.
- Toolchain: PVS rebuilt at 8.1 (SRI master 2026-08-06), NASALib 8.1 (2026-07-23),
  all pvsbin caches cleared. Replays: Sturm examples 81/81, Tarski 39/39, hutch 35/35;
  mult_poly typechecks and its CAD-relevant theories replay (run killed inside a
  `grind` in `smooth_not_analytic`, not needed).
- Probe: `sturm`/`tarski`/`mono-poly` reject a defined `f(x)` until `(expand "f")`;
  after expansion all five probe lemmas prove. The new strategies get a
  definition-unfolding front end.
- Set up `tools/llm_usage.py` (per-session token/time/tool-call totals from the Claude
  Code transcripts) and the report skeleton in `paper/`.
- Next: Phase 0 — create `cad/top.pvs`, ground-evaluator probe theory, vendor the
  WellClear/ACCoRD benchmark theories into `cad/benchmarks/`.

## 2026-09-16 — cad_proj: the Collins/McCallum projection operator

`cad_proj` GATE PASSED (9/9 on three fresh runs, traces with zero
"fewer subproofs" warnings). The operator only:

    proj(A) = { coeffs(f), disc(f) : f in A, deg f > 0 }
            U { res(f, g)          : f, g in A distinct, both of degree > 0 }

over sylvester's `res`/`disc`. Taking only the leading coefficient is NOT
enough — a projection that is too small gives an INVALID decomposition, not
merely a coarse one. The delineability argument that makes projection +
lifting a correct CAD is NOT claimed in this theory.

Why it exists: `clos1` derives the level-below family by iterating "which
polynomials did the decision read" to a fixpoint, and answering that question
is `reads1 = dedup1(svs_srd(...))`, the 3^|F| enumeration. Measured on
ex_three's level-2 family (10 members): one sector costs 190411 reads / 39.8 s
and the closure 57.9 s. **The read closure is a substitute for CAD's
projection phase**, and it is the substitute that is exponential.

Note for the rewire: `qfoldS_sem` is stated for an arbitrary family `P` —
`inv1?(F,P) AND gaps_ok(rts(P)) IMPLIES (qfoldS(...) IFF sem(...))`. It never
requires `P` to be the closure. So at two quantifiers a projection-based
decision is covered by the correctness theorem already proved, provided
`inv1?(F, proj(F))` holds; the closure was only ever a way to FIND such a `P`.

## 2026-09-16 — the projection route WORKS, including ex_three

Measured by ground evaluation in `cad_meas` (scratch theory, families written
literally; `np`/`nc` reproduce the earlier projection counts exactly, so the
encoding matches what the strategy builds).

Same lifting (`svsec`), same formulas, only the level-below family differs:

| example   | projection route | closure route | speedup |
|-----------|------------------|---------------|---------|
| ex_line   | TRUE   1.25 s    | TRUE  68.89 s | 55x     |
| ex_circle | TRUE   0.50 s    | TRUE   7.46 s | 15x     |
| ex_disc   | TRUE   0.43 s    | TRUE   1.59 s | 3.7x    |
| ex_three  | TRUE   0.39 s    | out of reach  | --      |

All four answers are correct (all four are theorems). **ex_three is no longer
out of reach**: 0.39 s, and `ok_three = TRUE` says every sample point the
route used was exactly rational, so no approximation entered anywhere.

### Negative controls

A route that always answered TRUE would look identical on four true examples,
so each route was also run on FALSE formulas over the same families:
`FORALL x,y: EXISTS z: z > x AND z < y` and `FORALL x: EXISTS y: x^2+y^2 = 1`.
Both answer FALSE (`pv_three_f`, `pv_circle_f`), and the closure route agrees
(`cv_circle_f = FALSE`). Proved as `controls`.

### Two things had to be right

1. **`inv1?` is the wrong validity check for the projection.** The projection
   FAILS it (`okp(f_line) = FALSE`, proved as `proj_not_inv1`) while deciding
   every example correctly. `inv1?` demands that `reads1` -- what the Sturm
   sign-chain implementation consults -- be sign-invariant on each sector;
   the closure is read-closed by construction, the projection is closed under
   a different operator. Sufficient condition, not necessary.
   Seeding the closure with the projection restores it (`seeded_inv1`, proved)
   and halves the family, 47 -> 20, but leaves sectors at 43 and the cost
   unchanged -- it buys nothing. **A fast AND proved decision needs
   delineability, not `inv1?`.**

2. **Three quantifiers need sample POINTS, not sign vectors.** `svs_pt` lifts
   by specializing at a point, so level 3 needs the level-2 coordinates.
   `alg?` requires `lb < ub` STRICTLY, so an exact rational is never signalled
   by a collapsed isolating interval -- a first test on `lb = ub` can never
   fire and is meaningless. `rat_alg(r)` encodes r as the linear polynomial
   `x - r`, so a sample is exactly rational precisely when its defining
   polynomial is linear, and the root is then `-c0/c1` exactly. `ok3` checks
   that over every sector the route actually visits.

### What is NOT claimed

The projection's correctness (delineability) is still unproved -- `cad_proj`
says so in its header. `ok3` is a sufficient test for exact samples: a
genuinely irrational section coordinate (a root of an irreducible quadratic)
makes it FALSE, and that case still needs exact algebraic arithmetic. The four
examples above happen to have linear section coordinates.

Everything above is banked as proved lemmas in `cad_meas` (`proj_not_inv1`,
`seeded_inv1`, `routes_agree`, `three_works`, `controls`), each discharged by
ground evaluation, so the numbers are re-checked on every run of the file
rather than living only in this note.

## 2026-09-16 — B1/B2: the cost is #root_sectors x 3^|F|, so delineability is required

`cad_meas2` (GATE pending; 3/3 verified) measures the read set and the sector
structure, both banked as proved lemmas:

    read_set_small:  2 members -> 74 distinct reads of 760 raw
                     7 members -> 79 distinct reads of 20132 raw
    root_sectors:    projection 1 root sector, read closure 21

The read SET is small and barely grows with the family while DISCOVERY is
3^|F|. That looks like an argument for computing a superset of the read set
directly -- cheap `inv1?`, every existing soundness lemma untouched. **It is
wrong, and this is the second hypothesis in a row that measurement killed.**

`svsec` lifts a rational sector with `svs_pt` (polynomial) but a ROOT sector
with `svs_sg` (3^|F|). So the cost is **#root_sectors x 3^|F|**, which
reproduces both observed timings: 21 x expensive ~ 63 s against cv_line's
68.89 s, and 1 x expensive ~ 1.25 s against pv_line's. A read-closed family
must CONTAIN the ~74 read polynomials, and their roots are precisely what
creates the 21 root sectors -- so no cheaper read set helps.

Delineability is therefore required, not merely preferable: it is what
licenses the small projection family. Recorded in PHASE6_PLAN.md as the B2
decision. It also raises the priority of exact algebraic samples at root
sectors, which would remove the last 3^|F| from the fast path regardless.

## 2026-09-17 — item D: the projection decision at any number of levels

`cad_pdec` + `cad_pdec_ex` (21/21 and 2/2 verified; gate running). `route3` in
`cad_meas` was hand-built for exactly three quantifiers; this is the general
form:

    tower(m, F) = (: proj^m(F), ..., proj(F), F :)   -- each proj computed once
    dec(TW, qs, rs, Psi)  folds the outermost quantifier over the sectors of
      the outermost family specialized at the coordinates chosen so far,
      prepends each sector's sample to rs, and hands the innermost fibre to
      svs_pt (polynomial) rather than svs_sg (3^|F|).

Measured, and banked as `pdec_examples` / `pdec_controls`:

| example   | ok   | val  | time   |
|-----------|------|------|--------|
| ex_line   | TRUE | TRUE | 0.20 s |
| ex_circle | TRUE | TRUE | 0.22 s |
| ex_disc   | TRUE | TRUE | 0.22 s |
| ex_three  | TRUE | TRUE | 0.23 s |

with FALSE on false formulas over the same families. Faster than the
hand-built route (ex_line 1.25 s -> 0.20 s) because with exact rational
samples `svs_pt` covers the ROOT sectors too, so **no 3^|F| remains anywhere
on these examples** -- the cost model #root_sectors x 3^|F| collapses.

### The ok flag caught a real error, which is the point of it

First attempt used only `lin?` -- exactly rational iff the defining polynomial
is linear. That gave `d_line`ok = FALSE` while `d_line`val = TRUE, and **that
TRUE was luck**: `rsv` had silently fallen back to 0 for a sample it could not
render exactly, and ex_line is true at every x, so the wrong coordinate still
produced the right answer. The cause: ex_line's projection carries (x-1)^2, so
the root 1 IS rational while its defining polynomial is quadratic.

Fixed by also bisecting the isolating interval for a midpoint that evaluates
to zero -- which PROVES it is the root. The exactness chain is proved, not
assumed: `rroot_exact` (the midpoint is a root), `rroot_in` (it lies in the
isolating interval), `lin_root`, `rsamp_value` (so it is THE root, via
value_unique), `rsv_exact` (so `value(sample(sc)) = rsv(sc)`).

Still only sufficient: a rational like 1/3 is never a bisection midpoint, and
an irrational section coordinate never is. Those need item E.

## 2026-09-17 — subresultants, and Collins' operator costs nothing extra

`subres` (9/9) and `cad_projc` (8/8), gate running.

`psc(f, g, j)` is the determinant of a submatrix of the same Sylvester-style
matrix `res` already uses, so `ring_det`'s `det_eval` -- which commutes with
evaluation for ANY matrix -- hands over the specialization theorem for free
(`psc_eval`). `psc(f, g, 0) = res(f, g)` (`psc0_res`), so **cad_proj is
exactly the j = 0 slice of Collins' operator**.

One design correction worth recording: `sres0_syl` was first stated as full
extensional equality of the j = 0 subresultant matrix with `syl`, which is
FALSE -- outside the matrix the two disagree, and `det` reads only entries
below its size, but `ring_det` has no congruence lemma. Rather than prove one,
the column-degree formula now keeps the plain degree for every b when j = 0,
so the matrices agree everywhere and the equality is genuine.

### Why the psc, and what they cost

A polynomial remainder sequence branches on the signs of its leading
coefficients -- that branching IS the 3^|F| of `rsc_sg`. The psc are
determinants and branch on nothing, so "same psc signs" pins down the whole
chain structure with no case analysis. That is what makes the delineability
route algebraic: since `svs_pt` is already proved to compute the fibre set
exactly, delineability reduces to a statement about two UNIVARIATE families --
*same psc signs implies same realizable sign-vector set* -- with no continuity
of roots and no connectedness anywhere in it.

The obvious worry was cost: a bigger operator means more roots below, and the
route's advantage was 1 root sector against the closure's 21. Measured
(`collins_cost`, proved):

|          | members McC -> Collins | roots below McC -> Collins |
|----------|------------------------|----------------------------|
| ex_line  | 8 -> 10                | 1 -> 1                     |
| ex_three | 7 -> 8                 | 1 -> 1                     |

**No new roots.** The higher psc are constants or non-vanishing here, so the
sector count is unchanged and the correct operator is essentially free.

## 2026-09-17 — the correctness gap is now ONE named statement

`cad_delin` (7/7 verified, gate running). This is the reduction that turns
"correctness is unproved" into "exactly one statement is unproved". Nothing is
assumed: delineability is a **defined predicate**, and the theorem is a real
proof.

    fib(F, ys)(v)   = EXISTS z: v = svec(F, cons(z, ys))        -- the fibre set
    delin?(F, s)    = the fibre set does not vary along sector s

    dec2_sem: THEOREM  incr?(rts(P))
      AND (every sector of rts(P) satisfies delin?, has an exact rational
           sample in it, and svs_ptok at that sample)
      IMPLIES (qfoldS(q1, sects(rts(P)),
                      LAMBDA s: qfold(q2, svs_pt(F, (: rsv(s) :)), Psi))
               IFF sem((: q1, q2 :), F, Psi, null))

This is the projection analogue of `qfoldS_sem`, which needs `inv1?` -- the
read-closure condition that forces 21 root sectors where the projection leaves
1. Same conclusion, from `delin?` instead.

Why the reduction works: `svs_pt` is ALREADY proved to compute the fibre set
exactly, so the decision never reasons about root isolation. `svs_pt_fib`
turns `svs_pt` into the fibre set, `qfold_fib` says one quantifier's semantics
sees only that set, `sem1_fib` (via `fib_swap`) transports it between two
points with equal fibre sets, and `sect_sem` moves it from the sample to the
whole sector. `inner_sem` glues the inner fold to the inner quantifier.

### What is still open, stated so it cannot be mistaken for proved

    delin_projc:  every sector of projc(F) satisfies delin?(F, -)

Equivalently, by svs_pt_sound/complete: **two univariate families with the
same principal subresultant coefficient signs realize the same sign vectors.**
That is sign determination -- algebraic, no continuity of roots and no
connectedness. `subres` builds the psc as determinants, `cad_projc` puts them
in the operator, and `collins_cost` measures that doing so adds no sectors.

This is now the ONLY remaining correctness obligation for the two-quantifier
projection decision.

### Proof notes

`fib_swap` had to be factored out: inlining it consumes the universal
hypothesis the other direction of `sem1_fib` still needs. And twice a step
instantiated a lemma with the theory VARIABLE `x` instead of the skolem
constant `x!1`, which looks like it works and then silently proves nothing
useful -- skolemize, read the actual constant name, then instantiate.
`every_mem` is typed for sign-vector lists; `Sect` lists need cad_lift's
`everyS_mem`/`everyS_all`/`someS_mem`/`someS_intro`.

### gate.sh blind spot #2, and how it was found

The T7 volume unmounted mid-gate. Runs 3 and traces produced NO output at all,
and `gate.sh` reported `cad_delin GATE PASSED` anyway, because `check` only
looked for failure PATTERNS -- absence of evidence was being read as evidence
of success. Fixed: a run now fails unless it has a `Grand Totals` line whose
proofs / attempted / succeeded counts are equal and nonzero, `proveit` exited
0, and the library directory still exists (checked before each run, since the
volume can vanish again). Self-tested against an empty log. `cad_delin` was
then re-gated for real: 7/7 on all three runs plus traces.

## 2026-09-17 — the Bath benchmarks say item E is the blocking gap

`cad-bench` (a new strategy) reports what the projection decision answers on a
closed prenex formula WITHOUT touching the sequent and without claiming a
proof. It reuses `cad`'s formula-to-family translation verbatim, so the
families are the strategy's own, not hand-written; `osstr` is already
outermost-first, which is what `pdecide` wants (`decide2` has to reverse it).
`pdecidef` in cad_pdec is the bform entry point that makes this a one-liner.

Independent confirmation first: on the four examples `cad-bench` reports
ok = TRUE, val = TRUE, matching `pdec_examples` exactly -- so the families
hand-written in `cad_meas` were right.

Then the Bath bank (10 of 12 entries; see the two source defects below):

| problem                          | vars | polys | ok    | val  | time    |
|----------------------------------|------|-------|-------|------|---------|
| 01 ball and circular cylinder    | 3    | 2     | FALSE | TRUE | 2.6 s   |
| 02 term rewrite                  | 3    | 3     | FALSE | TRUE | 77.8 s  |
| 03 collision of circle & square  | 3    | 7     | FALSE | TRUE | 6.5 s   |
| 04 McCallum trivariate random    | 3    | --    | --    | --   | >280 s  |

**ok = FALSE on every Bath problem.** The sample points are not exactly
rational, so `rsv` fell back to 0 and **those val answers are not
trustworthy** -- the same silent-fallback trap `ok` caught on ex_line. The
four textbook examples pass only because their section coordinates happen to
be linear.

So **item E (exact algebraic sample points) is not a later refinement, it is
the blocking practical gap**, and only the benchmarks could have shown it: no
amount of work on the four examples would have revealed it, because all four
avoid the case.

### Two defects in the SOURCE bank, not in the translation

Checked directly against `QEPCADexamplebank_v4.txt`:
  - entry 06: its third conjunct is a bare polynomial with NO relation
    operator -- the only such atom in any formula line of the whole bank
  - entry 11: its formula line has two closing brackets to one opening
Both are excluded rather than guessed at; adding "= 0" to 06 would be
inventing the problem rather than translating it.

`bench_pdec.pvs` holds the translated problems and is NOT wired into top.pvs;
whether to vendor the CC-BY-SA text into the repo is still the user's call.

## 2026-09-17 — the hybrid: sound but too slow, and why that settles item E

`pdecq` (in cad_pdec) is cad_lift's `decq2` with `proj` in place of
`clos1`/`clos` and `svsec`'s dispatch in place of `svs_sg` at level 2. It
carries no `ok` flag because it needs no rational samples: algebraic
coordinates go through the PROVED `svs_sg`/`asgS`/`alg_sign2` route, so the
silent fallback that made the earlier `val` answers untrustworthy is gone.

Proved as `hybrid_examples` and `hybrid_controls`:

    ex_line 0.85 s, ex_circle 0.24 s, ex_disc 0.30 s, ex_three 0.33 s,
    both controls FALSE

**And it times out past 280 s on every Bath problem tried** (01, 03, 12),
where the rational-sample route answered in 2.6-6.5 s but with `ok = FALSE`.
So the fast route cannot vouch for its answers on real problems, and the route
that can is too slow for them. I built the hybrid expecting it to close the
gap; it closed the soundness hole and opened a performance one.

### Why, and why this is structural

`svs_pt` is polynomial but TYPED on `list[rat]` -- it cannot represent an
algebraic coordinate at all. `svs_sg` handles algebraic coordinates at 3^|F|.
Real problems have an algebraic coordinate at the OUTERMOST level -- measured,
`cad-bench` reports `outer-level-rational = FALSE` on bath_01 and bath_03 --
so they enter the exponential branch immediately. The four textbook examples
pass only because their coordinates happen to be rational, which is exactly
why no amount of work on them could have revealed this.

**Item E is therefore not a dispatch trick but the real thing: exact
arithmetic in an algebraic extension, so that root isolation works AT an
algebraic sample point.** That is what every serious CAD implementation does.
The hybrid was an attempt to dodge it and the benchmarks refuse the dodge.

`cad-bench` now reports the hybrid's answer alongside the rational route's
`ok`, plus whether the outermost level is rational, so the distinction is
visible per problem.

## 2026-09-17 — item H: gating the older Phase 6 files, and what it caught

GATE PASSED: `earr_deriv` (8/8), `mpoly_div`, `prem_arr`, `sturm_step`,
`sturm_step2`, `alg_fast`, and `earr_ops` (38/38) after a fix.

**`earr_ops` was carrying an unproved obligation.** `nth_lscal_TCC1` --
`i < length(l) IMPLIES i < length(lscal(h, l))` -- had a stored proof that no
longer completed, so the file verified 37 of 38 while looking finished.
`lscal_length` in `mpoly_pdiv` already had exactly the needed fact and is
reachable from `earr_ops`, so the repair was one step.

Two things worth keeping from this:

  - it is the argument for the gating rule in miniature: the file typechecked,
    had a `.prf`, and had never been gated, so nothing ever re-ran the proof
    and noticed it had gone stale;
  - it was invisible to the OLD `gate.sh`. What exposed it was the count check
    (38 proofs / 38 attempted / 37 succeeded) and the nonzero exit status --
    both added this afternoon after the T7 unmount produced a false
    `GATE PASSED`. The blind-spot fix paid for itself the first time it ran.

The `.summary` files are NOT a reliable guide to this debt: `earr_ops`'s
claimed 14 unfinished where a fresh run found 1. They are stale artefacts of
older runs; only a fresh `proveit` counts.

### cell1 had TWELVE unproved TCCs; now 85/85

Gating `cell1` found it verifying 72 of 84 -- twelve unproved TCCs in the
FOUNDATIONAL theory that `svs1_sound`/`svs1_complete` live in and that
`cad_delin`'s whole reduction rests on. The main lemmas were proved, so the
reduction argument stands, but the definitions those TCCs guard were not
justified and the file was not verified.

All twelve are now proved and `cell1` verifies 85/85 (84 + the new lemma):

  - `cmpf_TCC2/3`, `gapf_TCC2/3` -- `refine(a)` needs `alg?(a)`, i.e.
    `refine_alg`; the same shape as `rroot_TCC1` in cad_pdec
  - `torat_nth_TCC1`, `pl_TCC1` -- `torat_length`, which was already there
  - `samples_TCC1/2/3`, `gaps_TCC1/2` -- `rat_alg_alg`, instantiated at the
    specific rational each one needs
  - `ins_TCC2` -- needed a `length_cdr` at `list[Alg]`, which did not exist
    (mpoly_univ's is typed for `list[mpoly]`, sg_svs's `len_cdr_LL` for
    `list[list[mpoly]]`). Added as `len_cdr_alg`, declared BEFORE `ins` so its
    TCC can see it.

Two tactic notes worth keeping. `len_cdr_alg` would not fall to a global
`(expand "length")` -- that rewrites both sides into `CASES` and leaves a
tautology PVS will not close -- but `(expand "length" 1 1)`, targeting the ONE
occurrence on the left, closes it immediately. Same fold/unfold asymmetry as
ever. And `gaps_TCC2` needed the recursive value's own type via
`(typepred "v(cdr(rs))")`, then `every` expanded to the SAME depth on both
sides: `(expand "every" 3 1)` to peel the cons, then `(expand "every" 3)` so
the goal matches the antecedent's `CASES` form.

## 2026-09-17 — delin_projc's first half is PROVED (sect_svec)

`sect_svec` GATE PASSED (9/9). `delin_projc` splits in two, and this is the
half that is about the SECTOR DECOMPOSITION rather than delineability:

    on a sector of sects(rts(P)), every member of P keeps its sign, so
    svec(P, (: x :)) = svec(P, (: r :))  for x in the sector and its
    rational sample r.

The second point is RATIONAL because cell1's `svec_between` is stated that
way -- and that is exactly the shape the decision needs, since it compares an
arbitrary point of a sector against the sector's rational sample `rsv(s)`.
Two arbitrary points follow by going through the sample twice.

`svec_between` supplies the conclusion once "no isolated root lies between",
and `below_first`/`above_last` already covered the outer sectors. The work was
the mid and above cases, because **`gsects` has no inverse-structure lemma**:
nothing said that a mid sector's endpoints are consecutive roots, or that an
above sector sits at the maximum. So six lemmas by induction:

  - `gsects_mid_mem`, `gsects_mid_noroot` -- a mid sector's endpoints are
    roots of the list, and nothing lies strictly between them
  - `gsects_above_mem`, `gsects_above_max`, `gsects_above_noroot` -- and
    above sits at the MAXIMUM root, not merely at some root. The first
    attempt proved only membership and got stuck: with `a = car(t)` and a
    witness in `cdr(t)` there is no contradiction unless `a` is known maximal
  - `gsects_kind` -- gsects produces only at, mid and above, never below or
    whole (which `sects` supplies separately); needed to kill the branch where
    a below sector is claimed to be in gsects
  - `in_between` -- every sector is an interval, so it contains anything
    between two of its points

Tactic notes. The datatype eta axioms are named `Sect_mid_eta` /
`Sect_above_eta` by the `<datatype>_<constructor>_eta` convention that
`mpoly_adt` shows -- `mid_eta` alone does not resolve. `at` sectors must be
split off BEFORE `svec_between`: there x = r and the equality is trivial,
while `svec_between`'s hypothesis is FALSE at such a point (the point IS a
root). And the repeated fold/unfold asymmetry again: matching an expanded
hypothesis to a folded goal needs the SAME depth on both sides, so
`(expand "gsects" -2 1)` and `(expand "gsects" 2 1)` rather than a global
expand, which over-expands and leaves a tautology PVS will not close.

What remains of delin_projc is the mathematical core: same psc signs give the
same realizable sign-vector set.

## 2026-09-18 — Stage A done: psc_det? is now the ONLY open statement

`delin_bridge` GATE PASSED (4/4). Chaining it with `dec2_sem` and
`sect_svec`:

    psc_det?(F)  =>  delin? on every sector of projc(F)   [delin_from_psc]
    delin? on every sector  =>  the decision agrees with the semantics
                                                          [dec2_sem]

so **psc_det? alone implies the two-quantifier projection decision is
correct**, and it is stated with no CAD machinery around it:

    psc_det?(F):  svec(projc(F), (: x :)) = svec(projc(F), (: y :))
                  IMPLIES fib(F, (: x :)) = fib(F, (: y :))

The route goes through the sector's RATIONAL sample, because cell1's
`svec_between` -- and therefore `sect_svec` -- compares a real against a
rational. Two arbitrary points of a sector are related by applying `sect_svec`
twice through `sval(s)`, with `sval_in` supplying that the sample lies in its
sector (from `sects_ok` and `sample_in`). At an `at` sector both points
collapse to the root and there is nothing to prove.

### Both shortcuts to psc_det? are closed, by measurement

`inv1?(F, projc(F))` = FALSE (74 distinct reads against 10 members), exactly
as for McCallum's `proj`. That is stronger than "unproved": `inv1? = FALSE`
says some read genuinely CHANGES SIGN inside a sector, so the statement "the
reads are determined by the projection" is false, not merely open. `svs_det`
is sufficient, not necessary -- the reads may move while the answer does not.
And no cheap runtime certificate exists: `inv1?` is the only check the
architecture offers, and sampling more points is not a proof.

So the classical theorem is required. ITEM1_PLAN.md records the scope
reduction that removes its research risk: prove the NON-DEFECTIVE case and
have the decision check `lc`, `disc` and pairwise `res` nonzero at runtime --
all of them `projc` members, hence sign-invariant on a sector by `sect_svec`
-- reporting `ok = FALSE` otherwise, exactly as it already does for inexact
samples. That avoids the gap structure of the remainder sequence, which is
where the estimate would have doubled.

## 2026-09-18 — Stage B done: degree from sign data (spec_deg)

`spec_deg` GATE PASSED (4/4). `deg(pl)` is the largest index carrying a
nonzero entry, so it depends only on WHICH coefficients vanish -- and `sign3`
decides exactly that (`sign3_zero`). Hence two specializations of a member
with equal coefficient signs have equal degree, which is what Stages C-E need
to talk about "the leading coefficient" at all. The hypothesis is supplied in
practice by `sect_svec`, since `cofs` is part of `projc1` so every coefficient
is a projection member.

Proved as **one inequality plus antisymmetry** (`deg_le`, then `deg_signs`),
not as the equality directly. The hypothesis is symmetric in p and q, so the
second inequality is free; proving the equality head-on splits into a dozen
sign branches, while each half of the inequality is a few steps. An earlier
attempt at the direct route left the proof state with ten duplicate copies of
one hypothesis and a goal nested twelve deep -- a reminder that a looping
`try` chain that keeps re-applying the same `case` digs rather than closes.

`deg_le`'s content is just uniqueness of `deg`'s dependent-type
characterization: `nth(p, deg(p)) /= 0` and everything above it zero. If
`deg(p) > deg(q)` then q's own characterization forces `nth(q, deg(p)) = 0`,
while the sign equality forces it nonzero.

## 2026-09-18 — Stage C begins: the full subresultant (subres2)

`subres2` GATE PASSED (7/7), all three lemmas first try.

### Scoping first, per the plan

NASALib's Sturm counts roots by sign changes in `compute_remainder_seq`, a
pseudo-remainder sequence over integer coefficient arrays, with
`sturm_unbounded_left` / `sturm_unbounded_right` counting over all of R. At
+-infinity a chain entry's sign is just its LEADING COEFFICIENT's sign times
(-1)^degree. So Stage C's target is precisely:

    the remainder sequence's leading coefficients are the psc, up to
    positive factors

which is the classical subresultant/PRS correspondence. In the NON-DEFECTIVE
case (each step drops degree by exactly one) the two coincide up to
explicitly known factors -- which is exactly why the plan restricts to that
case and has the decision check it at runtime.

### What was missing, and is now there

`subres` gave only the leading coefficient. Sturm needs whole entries, so
`subres2` builds Sres_j itself: the same determinant with the last column
ranging over degrees 0..j. One generalized matrix serves both --
`sresm(f,g,j)` is `sresm2(f,g,j,j)` (`sresm2_sresm`), psc is the j-th
coefficient of Sres_j (`psc_sres`), and evaluation commutes as before
(`sresc_eval`, free from `det_eval` again).

Remaining in Stage C: the PRS correspondence itself.

### Non-defectiveness is a sign condition (sturm_habicht)

`sturm_habicht` GATE PASSED (4/4). The restriction to the non-defective case
turns out to cost nothing to check, which is the fact that makes
ITEM1_PLAN.md's scope reduction usable rather than merely convenient:

    ndef_signs:  if every psc has the same sign at ys and zs, then
                 ndef_at(f, g, j, ys) IFF ndef_at(f, g, j, zs)

**Non-defectiveness is itself a sign condition on the psc.** So two points of
a sector are either both defective or both not, and the runtime check the plan
calls for -- "every psc is nonzero" -- is one `sect_svec` away from being
constant along the sector, since the psc are `projc` members. Nothing extra is
computed, and the check cannot disagree between the sample and the rest of the
cell.

`sh_count` -- that NASALib's integer pseudo-remainder sequence has the psc as
its leading coefficients up to positive factors -- is STATED AND NOT PROVED,
and is what remains of Stage C.

Proof note, the same trap as ever: the induction step must expand `ndef_at`
in the GOAL ONLY. `(expand "ndef_at" -1)` unfolds the induction hypothesis a
level too far and leaves `ndef_at(f, g, j_1 - 1, zs)` to chase, which no
amount of instantiation closes. And the sign hypothesis has to be instantiated
with `inst-cp`, not `inst`, because every branch needs it again at a different
index.

### The fact that licenses sh_count's whole approach (nsc_scale)

`nsc_scale` GATE PASSED (2/2). Scoping `adjusted_remainder` turned up the
enabling fact, and it is better than expected. `adjusted_remainder_def` says

    polynomial(thispoly, thisdeg) = polynomial(-cp * pd`rem, pd`rdeg)
    for some cp: posreal

so NASALib's chain entries are the classical Sturm sequence -- negated
remainders -- **up to POSITIVE factors only**. Two consequences:

  - the entries are pinned enough for their leading-coefficient SIGNS to be
    well defined, and those signs are exactly what the psc correspondence is
    a statement about;
  - the positive factors are harmless, because the COUNT cannot see them.
    That is `nsc_scale`, and it came almost free: `number_sign_changes_eq`
    already gives equal counts from pointwise equal `sign_ext`, and
    `sign_ext_mult` reduces positive rescaling to that.

Had the factors been of either sign, the leading-coefficient signs would not
have been well defined and the approach through psc signs would have needed a
different formulation. Worth having checked before writing statements.

## 2026-09-18 — quad_sign: the degree <= 2 groundwork (Stage C/E)

`quad_sign` GATE PASSED (14/14).

Every member of all four worked examples has degree <= 2 in the main
variable, so the degree <= 2 case of `psc_det?` is what makes their fast
decision proved, and at that degree the discriminant does the work that
subresultant sign determination does in general. `disc` is already a `projc`
member, so `sect_svec` supplies the hypothesis along a sector for free.

Proved: `qv_shift` (completing the square), `qv_square`
(4a*qv + discr = (2ay+b)^2) and the extremum bounds `qv_sq_ge`, `qv_min`,
`qv_max`, the beyond-roots witness `bey`/`qv_bey`/`bey_gt` from NASALib's
`quadratic_aux`, and `qset_zero` -- zero is realized exactly when a root
exists.

### Three things this cost time, all worth recording

**`discr` is declared on `nonzero_real`.** Stating `qv_square` for arbitrary
`a` generated the TCC `FORALL a: a /= 0`, which is false. Every use has
`a > 0` or `a < 0`, so the hypothesis is free -- but the file verified 12 of
13 until it was added, which is exactly the kind of thing gating catches.

**I stated a lemma that was false.** `qv_max` first said
`4a*qv <= -discr` for `a < 0`. But `4a*qv + discr` is a SQUARE, so
`4a*qv >= -discr` holds for EITHER sign of `a`; only the DIVIDED form flips,
because dividing by `4a` reverses when `a < 0`. The prover caught it.

**Division beats multiplication in PVS, and the first witness was wrong for
the tool.** The original unboundedness witness `-b/(2a) + 1 + |discr|/(4a^2)`
forced a quartic inequality, and `a^4 > 0` from `a > 0` is nonlinear so PVS
would not take it; a blind tactic loop then dug forty levels deep. Replacing
it with "a point beyond both roots", where `quadratic_aux` factors
`qv = a(y-x1)(y-x2)` and only the sign of `a` is left, removed the algebra
entirely. Likewise the forward direction wanted `qv_sq_ge` (multiplicative)
rather than `qv_max` (divided).

The three-way set characterisation -- which strict signs are realized, hence
that the set is a function of the sign data -- is the remaining piece. It
wants one small directional lemma per case (a > 0; a < 0 with discr > 0;
linear; constant; plus necessity) rather than one ten-branch IFF, which is
what made the first attempt grind. That is the next step, in quad_set.pvs.

## 2026-09-18 — quad_set: which signs a quadratic realizes

`quad_set` GATE PASSED (11/11). The restructuring worked: **one small
directional lemma per case** instead of one ten-branch IFF.

    qset_pos_apos  a > 0                    beyond both roots, or the vertex
    qset_pos_aneg  a < 0 and discr > 0      the vertex, where qv = -discr/4a
    qset_pos_lin   a = 0, b /= 0            (1-c)/b sends qv to exactly 1
    qset_pos_cst   a = 0, b = 0, c > 0      any point
    qset_pos_nec   necessity, via the multiplicative qv_sq_ge

Each is a handful of steps. The same lemma as one IFF had every branch
wanting a different witness AND a different division-vs-multiplication step,
and no single tactic covered them -- it dug instead of closing. Stage B's
lesson exactly (an inequality plus antisymmetry beat the direct equality).

**The negative case came free.** `qv(-a,-b,-c)(y) = -qv(a,b,c)(y)` flips the
realized signs, and `discr` is INVARIANT under negating all three
coefficients, since `sq(-b) - 4(-a)(-c) = sq(b) - 4ac`. So `qset_flip`
transports the characterisation with no case analysis repeated.

### pos_prod: the helper that should have come first

Nearly every stall in this file and in `quad_sign` reduced to the same thing:
**PVS's decision procedures are linear and will not chain products of
positives.** Even `u > 0 AND v > 0 IMPLIES u*v > 0` does not fall to
`assert`, `ground` or `grind`; it needs the prelude AXIOM
`posreal_mult_closed`. Adding `pos_prod` closed `qset_pos_apos` and
`qset_pos_nec` almost immediately after an hour of fighting the same wall in
different disguises -- the quartic in `qv_far_pos`, the triple product in the
beyond-roots case, the `-4a*qv` step in necessity. Worth reaching for at the
first sign of a stuck product.

## 2026-09-18 — psc_det? IS PROVED AT DEGREE <= 2 (quad_det)

`quad_det` GATE PASSED (7/7). `qset_det` says the realized sign SET of a
quadratic is a function of the signs of `(a, b, c, dsc)`:

    sign3(a) = sign3(a2) AND sign3(b) = sign3(b2) AND sign3(c) = sign3(c2)
      AND sign3(dsc(a,b,c)) = sign3(dsc(a2,b2,c2))
    IMPLIES (FORALL s: qset(a,b,c)(s) IFF qset(a2,b2,c2)(s))

**Every member of all four worked examples has degree <= 2 in the main
variable, so this is the case that matters for them**, and all of
`(a, b, c, disc)` are `projc` members, so `sect_svec` supplies the hypothesis
along a sector for free.

Assembled from `quad_set`'s directional lemmas via three characterisations --
`qset_pos_iff`, `qset_neg_iff`, `qset_zero_iff` -- each an explicit condition
on the sign data, with the negative one free from `qset_flip`.

### A total discriminant was necessary, not cosmetic

NASALib's `discr` is declared on `nonzero_real`, but the hypothesis has to
cover `a = 0`, and that is exactly the interesting case: `a = b = 0` gives
`dsc = 0`, the same discriminant sign as a genuine double root, yet a
completely different realized set. Hence `dsc`, total, with `dsc_discr`
agreeing wherever `discr` is defined.

### Two tactic facts, both cost real time

`sign3_iff` converts equal signs into equal comparisons ONCE and is then used
four times. Expanding `sign3` inside the six `IFF` characterisations instead
makes `ground` blow up combinatorially -- it ran past ten minutes and had to
be interrupted, and the interrupt left the server accepting connections but
answering nothing, requiring a restart.

And the three sign cases must be split and closed SEPARATELY. Handing
`ground` all ten hypotheses at once is what blew up; with one case and only
its two relevant characterisations, each `assert` closes at once.

## 2026-09-18 — the chain closes end to end (fib_quad)

`fib_quad` GATE PASSED (4/4). With `delin_from_psc` and `dec2_sem`, this is
the first time the whole chain is PROVED rather than validated:

    the two-quantifier projection decision is correct for
    single-polynomial families of degree <= 2.

Narrow, but complete: no measurement, no unproved hypothesis, no `ok` flag
standing in for an argument.

`meval3` specializes a member at the parameter, `fib1_qset`/`fib1_qset2`
phrase the fibre set as the 1-vectors of the realized signs, and `qset_det`
then applies directly.

### Two shapes that mattered

**State it over an EXPLICIT 3-element list, not `length(u) = 3`.** With the
length hypothesis, `meval` unfolds into nested datatype `CASES` that must be
resolved from the length, and the proof did not converge -- five rounds of
unfolding made no progress. A literal `(: u0, u1, u2 :)` cons chain unfolds
directly, and it is also how the examples' members are actually written.

**Use `meval_cons`/`meval_null`, not repeated `expand "meval"`.** Expanding
blindly also unfolds the atomic `meval(u_i)` terms and exposes their `CASES`;
the lemmas stop at exactly the right level, after which `hd`/`tl` reduce and
`assert` closes it.

`fib1_qset2` exists because the direct route drowned in skolem bookkeeping:
phrasing the fibre set as "there is a realized SIGN s with v = (: s :)" lets
`qset_det` transfer that s with no witness juggling at all.

### What the multi-member case needs, and why it is not more of the same

The fibre set is a set of VECTORS, so it turns on how different members' roots
INTERLEAVE -- and that is not settled by each member's own discriminant. It
needs the sign of one member at another's roots, i.e. Tarski queries, which is
exactly what the pairwise psc chains in Collins' operator are for. That is the
rest of Stage E.

## 2026-09-18 — projc_mem: what is actually IN the projection

`projc_mem` GATE PASSED (3/3). `fib1_det`'s hypothesis is about a member's
COEFFICIENT signs; `psc_det?`'s is about the signs of `projc`'s members.
Those agree only because `projc` really does contain those polynomials --
a structural fact about `projc1 = cofs ++ chain`, not something to assume.
`cofs_mem` and `cofs_projc` prove it, so `sect_svec` now makes every
coefficient sign-invariant along a sector for free.

`cofs` IS `map(as_list)` (`cofs_map`), and saying so is what made the proof
short: as an index induction it fights `nth` and the `CASES` that come with
it, while as a map lemma it is `map_mem` plus `member_append_l` twice through
the nested appends.

## 2026-09-18 — psc_quad1: the bookkeeping between fib_quad and delin_bridge

`psc_quad1` GATE PASSED (4/4). Three facts, none deep but all needed:

  - `svec_eq_sign` -- equal sign VECTORS give equal signs member by member,
    via `svec_nth`
  - `pscs_zero` -- a psc chain always contains its j = 0 entry (induction)
  - `disc_projc` -- so the DISCRIMINANT is in `projc`, since `psc0_res`
    identifies `psc(f, f', 0)` with `res(f, f')`, which is `disc(f)`

With `projc_mem`'s coefficients, these are exactly what let `sect_svec`
discharge `fib1_det`'s hypothesis along a sector: everything `fib1_det` needs
to see the same signs at two points of a sector is a `projc` member.

`disc_projc` was a long grind for a shallow fact, and the blocker was not the
mathematics: `jtop` had to be EXPANDED before `pscs_zero`'s side condition
`2 * jtop <= dg f + dg g` would discharge, and until it did, every
instantiation silently failed and the membership facts kept being consumed by
`assert` without closing anything. Unfold the definition behind a side
condition before blaming the instantiation.

## 2026-09-19 — disc_quad: what the projection's discriminant evaluates to

`disc_quad` GATE PASSED (1/1). The 3x3 Sylvester determinant of (f, f') at
degree 2 computes out to

    -c2 * (c1^2 - 4*c0*c2)   i.e.   sign(disc) = -sign(c2) * sign(dsc)

**This link is necessary, not decorative.** `fib1_det` needs the sign of
`dsc` of the SPECIALIZED coefficients, and that sign is genuinely not
determined by the coefficient signs alone -- (1,1,1) gives `dsc < 0` while
(1,3,1) gives `dsc > 0`, same signs throughout. So it has to come from the
projection, where `disc` lives, and the only way across is to compute what
`disc` actually evaluates to. With `sign(c2)` known from the coefficients
this pins `sign(dsc)` whenever `c2 /= 0`; when `c2 = 0` the discriminant
vanishes identically and `dsc = c1^2`, whose sign is fixed by `sign(c1)`.

The proof is a determinant expansion and it went by unfolding in the right
order: `disc` -> `res` -> `lderiv`/`deriv_list` to get a concrete second
argument, `det_eval` to cross into `rdet`, then `rdetl`/`rminor` three deep,
and finally `meval_mscal` and `meval_mconst` to turn the entries into
coefficient values. The recurring trap was reducing `length` and `nth` on the
literal lists early enough -- until those collapse, the `IF` guards inside
`rdetl` block every subsequent step and each expansion looks like it did
nothing.

## 2026-09-19 — psc_det_quad: Item 1 CLOSED at degree <= 2, single member

`psc_det?` was the last standing correctness obligation of the projection
route -- the one thing `dec2_sem` still carried as a hypothesis rather than
as an argument. For a single member of degree at most 2 it now holds
outright:

    psc_det_quad1: THEOREM psc_det?((: (: u0, u1, u2 :) :))

No hypotheses. Not `live?`, not non-defectiveness, not `ok`. For every pair
of parameter values where the Collins projection has the same sign vector,
the two fibres are the same set of sign vectors.

The chain, each link already gated before today:

  - `svec_eq_mem` -- equal sign vectors give equal signs at every MEMBER of
    the projection (`svec_eq_sign` indexed by `nth`, turned into membership
    through `more_list_props.member_nth`)
  - `mem_sign` -- the same fact stated on the mpoly instead of its coefficient
    list, which is `meval_as_list`; this is what makes `quad_mem0/1/2/d`
    usable, since `projc` stores members as `as_list(p)`
  - `quad_mem0/1/2` from `cofs_projc`, `quad_memd` from `disc_projc` -- the
    four polynomials whose signs the projection determines
  - `dsc_sign` -- the one piece of genuine reasoning: recover `sign(dsc)`
    from `sign(disc)`. `disc_quad_eval` gives `disc = -c2 * dsc`, so divide
    by `sign(c2)`; where `c2 = 0` the discriminant vanishes identically and
    `dsc = c1^2`, whose sign `sign(c1)` already fixes. A trichotomy on `c2`
    (`sign3_mult_pos`, `sign3_mult_neg`, and `sign3_mult` on `c1*c1`)
  - `fib1_det` closes it

and then the payoff, which is the point of having done it:

  - `quad_delin` -- every sector of `projc(F)` is delineable for `F`
  - `quad_dec2` -- `dec2_sem` for this family with NO delineability
    assumption in the hypotheses. What is left is entirely about the
    COMPUTATION: the isolated roots come out sorted (`incr?`), the gaps
    really separate them (`gaps_ok`), each sample is rational and lands
    inside its sector (`ratsamp?`, `in?`), and root isolation converged
    (`svs_ptok`). The executable code checks every one of those.

Two things cost time and are worth recording:

  - `(case "a" "b" "c")` in PVS is NOT a three-way split. Subgoal 1 assumes
    all three; the rest peel them off one at a time. For a genuine
    trichotomy, `case` the DISJUNCTION and `split` the hypothesis.
  - `lift-if` lifts one layer. Expanding `sign3` on both sides of an equality
    leaves nested conditionals, and `ground` cannot finish until a second
    `(lift-if)(ground)` has run. Two passes, not one.
  - The pvs-cli server has to be RESTARTED after new declarations are added
    to an already-loaded theory: `--typecheck` reported success while
    `--prove` still answered "Formula not found".

Scope, stated plainly so it is not mistaken for more than it is: ONE member,
degree AT MOST 2, in the two-quantifier setting. Multi-member is the next
piece and it is not a generalization of this argument -- the fibre set
becomes a set of VECTORS and the question turns on root INTERLEAVING between
members, which needs pairwise Tarski queries rather than one discriminant.

## 2026-09-19 — cad_decn: the decision is correct at ANY number of levels

`dec2_sem` settled two quantifiers. `decn_sem` settles all of them:

    dec(TW, qs, rs, Psi) IFF sem(qs, last(TW), Psi, rs)

and `pdecide_sem` lifts it to the executable entry point, so
`pdecide(F, qs, Psi)`val` IS the semantics of the quantified formula. That is
what a strategy has to cite to emit a proof instead of a measurement.

The shape matters as much as the theorem. Everything needed from the GEOMETRY
is collected in one predicate, `decok?`, stated along every path of sectors
the fold actually walks:

  - this level's isolated roots come out sorted (`incr?`)
  - every sector's sample point lies inside that sector
  - the value of everything INSIDE is the same at the sample as at any other
    point of the sector
  - and the same again, one level down, over each sector

with root isolation having converged at the innermost level (`svs_ptok`). The
third item is delineability in the only form the induction can use; at two
quantifiers it is exactly `sect_sem`, i.e. `delin?`. Keeping it in a single
predicate separates the combinatorial theorem -- provable today -- from the
mathematics that has to establish sector invariance, which is proved at
degree <= 2 (`psc_det_quad`) and open above it.

Two lemmas carry the weight:

  - `fold_quant` -- a fold over sectors IS a quantifier over the reals, given
    that each sample lies in its sector and the predicate cannot tell the
    sample from any other point of it. Four cases: FORALL/EXISTS crossed with
    the two directions, using `sects_cover` one way and the sample's own
    reality the other.
  - `qfoldS_cong` -- the fold only looks at members. Without it the induction
    is stuck: the induction hypothesis is available exactly on the sectors
    `decok?` ranges over, not on every `Sect`, so the two fold functions are
    equal only on members and function extensionality is unavailable.

What cost time, recorded because it will recur:

  - Unfolding `last` and `length` inside the induction turns every occurrence
    into datatype `CASES` and buries the argument. Factor the list
    bookkeeping into `last_car`, `last_cdr`, `tw_len` and prove those in small
    sequents.
  - `length(l) = 0 IFF null?(l)` is `structures@more_list_props.length_null_list`;
    reaching for it beats expanding `length`.
  - The list eta axiom is `list_adt[T].list_cons_eta` and needs its theory
    instance; the bare name does not resolve.
  - PVS orders a lemma's implicit binders by ASCII on the variable NAME, not
    by declaration order and not by first occurrence -- `ptsem` came out
    `(F, Psi, q, rs)`. Instantiate one and read the sequent before writing a
    chain of them.

**The gate earned its keep on this file.** Three fresh runs reported 18
proofs, 13 succeeded: five TCCs had never been proved, and one of them,
`last_cdr_TCC1`, was

    FORALL (TW: list[list[list[mpoly]]]): cons?(TW)

which is FALSE. The lemma had been stated

    last_cdr: LEMMA cons?(cdr(TW)) IMPLIES last(cdr(TW)) = last(TW)

and the `cdr(TW)` inside the HYPOTHESIS has nothing to its left to license
it, so PVS asked for `cons?(TW)` unconditionally. The lemma itself proved
Q.E.D. and `decn_sem` used it; only the gate saw that the statement was
ill-formed. Putting `cons?(TW)` first as a conjunct fixes it -- PVS makes
earlier conjuncts available to later ones. A Q.E.D. on a lemma says nothing
about its TCCs.

## 2026-09-19 — item H closed: every Phase 6 file is gated

GATE PASSED: `cad_examples` (9/9), `sg_norm` (13/13), `sg_chain` (19/19),
`sg_chain2` (20/20), `sg_conj` (17/17), `sg_conj2` (21/21). With `mpoly_div`,
`alg_fast`, `earr_deriv`, `sturm_step`, `prem_arr`, `sturm_step2`, `earr_ops`
and `cell1` already done, **no Phase 6 file is ungated any more.**

`cad_examples` could not gate before today because `ex_three` was stored as a
bare `(POSTPONE)` -- an unproved formula sitting in a file wired into
`top.pvs`. `(cad)` does not decide it: `decide2` is the read-closure route,
whose cost is 3^|F| and whose level-2 family here has ten members, then forty.
It is now proved directly, with a header block saying exactly that, and saying
that the projection route decides it in 0.33 s but cannot yet emit a proof
because `decok?`'s sector-invariance clause is proved only for single members
of degree <= 2. It will be switched to the strategy when the strategy can
prove it.

## 2026-09-19 — item A starts: mpoly_swap, and why Q(alpha) is not needed

`mpoly_swap` GATE PASSED (29/29). `mswap_eval` says the transpose of the
rational coefficient matrix is the variable swap:

    meval(mpol(mswap(f)))((: x, y :)) = meval(mpol(f))((: y, x :))

**Why this is the first step of item A.** `svs_pt` is typed on `list[rat]`
and cannot represent an algebraic coordinate, which is why every Bath problem
answers `ok = FALSE`. PHASE6_PLAN's item E proposed building arithmetic in
Q(alpha) and flagged a resultant shortcut as "measure first", objecting that
`Res_x(p, f)` gives a SUPERSET of the candidate roots and filtering the
superset is the same hard problem again.

**The superset never needs filtering.** What the lifting computes is the SET
of realized sign vectors. A candidate that is not a root of anything simply
subdivides a sector into two sectors carrying the same vector -- a refinement,
not an error. So the objection dissolves, and with it the extension field.
What is left needs the swap, because mpoly's `res` eliminates the MAIN
variable and this elimination is in the second one.

Keeping the transpose at the level of a rational coefficient matrix was the
design decision that made it provable in an afternoon. Over the mpoly datatype
the correctness would be a double induction; over `list[list[rat]]` it is one
lemma, `mcons_bev`, prepending a row to a column list:

    bev(mcons(r, cols), y, x) = pev(r, x) + y * bev(cols, y, x)

which is the sum interchange, and `transp_bev` then falls out by a single
induction.

Three things cost time:

  - a blanket `(expand "pev")` in the middle of the induction buries the ring
    identity under nested IFs and nothing closes afterwards. `pev_hdtl`,
    stating Horner in the padded form `mcons` uses, keeps it out; targeted
    `(expand "f" <fnum> <occurrence>)` does the rest.
  - the same for `length`: expanding it turns `0 <= length(l)` into a datatype
    CASES and the nat bound stops being visible.
  - Sturm's `Polylist` is NONEMPTY, and columns get built up from nothing, so
    a total Horner `pev` on `list[rat]` is needed, bridged to `polylist` once.
    Sturm carries no cons law for `polylist`; it comes out of
    `partial_eval_polylist` and `meval_mpol_cons`.

Two TCCs were unproved after the first gate -- both "this list is a list of
rationals" -- and `mpoly_univ`'s `rat_list_every_num` discharges them.

## 2026-09-19 — alg_lift: the lifting RUNS at an algebraic sample point

`svs_pt` is typed on `list[rat]` and cannot represent an algebraic coordinate
at all. That is the whole reason every Bath problem answers `ok = FALSE`, and
`alg_lift` removes it — **without any arithmetic in Q(alpha)**.

    svs_alg(F, a) : SVL      the realized sign vectors over the fibre above
                             an ALGEBRAIC coordinate value(a)

Three moves, each reusing something already proved:

  - **Candidates stay over Q.** `cand(a, f) = Res_x(p, f)`, for `p` the
    defining polynomial of alpha, is a RATIONAL polynomial in y whose roots
    include every y with `f(y, alpha) = 0`. `mpoly_swap` is what makes the
    elimination possible, since `res` eliminates the MAIN variable.
  - **Signs at rational y are `alg_sign2`.** `asgn(a, f, y0)` is the sign of
    the rational univariate `f(y0, .)` at alpha — decided and already proved
    correct by `alg_sign2_sign`.
  - **Vanishing AT a candidate is a SIGN CHANGE, not a zero test.** Testing
    `f(beta, alpha) = 0` at an algebraic beta is the two-algebraic-coordinate
    zero test that forces Q(alpha). Under `aok?` — lc and disc nonvanishing at
    alpha, so every root of `f(., alpha)` is simple — a member is zero at a
    candidate exactly when its signs at the two rational neighbours disagree.

### Measured first, as the standing rule requires

All at alpha = 1/sqrt(2), the root of `x^2 - 1/2` in [1/2, 1], and all proved
by ground evaluation in `alg_meas`:

    cand(alp, fcir) = (: 1/4, 0, -1, 0, 1, 0, 0 :)      i.e. (y^2 - 1/2)^2
    svs_alg(Fcir, alp)  = +, 0, -, 0, +
    svs_alg(Flin, alp)  = -, -, -, 0, +
    svs_alg(Fboth, alp) = (1,-1), (0,-1), (-1,-1), (0,0), (1,1)
    aok? TRUE on all three, FALSE on x*y at alpha = 0

**`Flin` is the one that matters.** `y - x` specializes to `y - 1/sqrt(2)`,
which has ONE root, but `Res_x(x^2 - 1/2, y - x) = y^2 - 1/2` hands back
`-1/sqrt(2)` as a candidate too. The measured lifting shows that spurious
section carrying the SAME vector as its neighbours: the decomposition is
refined, not corrupted, and the SET of realized vectors is right. That is the
claim the whole design rests on, and PHASE6_PLAN had rejected the resultant
route precisely because it assumed the superset would need filtering. It does
not.

`Fboth` kills a second assumption: the two members' roots COINCIDE at
+1/sqrt(2), and the section there reads (0, 0). A design assuming "exactly one
member vanishes at a section" — which the pairwise resultants would have let
one assume — is wrong there. The sign-change rule is per member and survives.

### Scope, stated so it is not mistaken

ONE algebraic coordinate. At three variables the level-3 lifting sits over a
level-2 SECTION whose coordinate is itself algebraic, and `alg_sign2` does not
reach that; ITEMA_PLAN.md records the correction and the A-II design (interval
refinement with `Res_x(p, g)` as a nonvanishing certificate, and `ok = FALSE`
where the certificate does not fire). **A-I as it stands is
2-variable-complete.**

## 2026-09-19 — alg_dec: what item A buys, and the point where A and B converge

`dec2a` is the two-quantifier decision with algebraic sample points. There is
no `rsv` in it and no fallback: `sample(s)` is an `Alg` for EVERY sector —
`rat_alg` encodes a rational one as the linear polynomial `x - r` — so
`svs_alg` covers open sectors and sections alike with no dispatch.

### What it buys, measured

`f_meet` is `y - x` together with `y^2 - 2`. They meet at `x = +-sqrt(2)`,
and those are SECTIONS of the projection at IRRATIONAL coordinates:

    allrat(sects(rts(proj(f_meet)))) = FALSE      the rational route refuses
    ok2a(f_meet)                     = TRUE       this one is certified
    dec2a(FALSE, FALSE, ...)         = TRUE       EXISTS x,y: y=x AND y^2=2
    dec2a(TRUE,  FALSE, ...)         = FALSE      not for every x

That is a problem the rational route cannot vouch for and this one decides,
with the check passing at every sector, sections included.

### Where it stops, measured

`f_rad2` is `x^2 + y^2 - 2`. Its sections are at `+-sqrt(2)` too, but there
they are roots of the DISCRIMINANT — the circle's vertical tangents, where
the fibre has a repeated root. Per sector:

    (: TRUE, FALSE, TRUE, FALSE, TRUE :)

the three open sectors pass and the two sections do not, because `f` does not
change sign at a double root and the sign-change rule is exactly what breaks
there.

**A discriminant root is a section of every CAD, so this residual case is not
exotic — it is the generic critical point.** `aok?` refuses it rather than
guessing, which is the right behaviour, but it means item A as built is a
partial win: it covers sections coming from coefficients and from pairwise
resultants, and not those coming from discriminants.

### The two blockers are the same theorem

Deciding the discriminant case needs the sign of a polynomial at a point with
TWO algebraic coordinates. The route that does not need an extension field is
the subresultant chain: it is division-free, `subres2`'s `sresc_eval` already
says evaluation commutes with it, and the signs of its entries at alpha are
`alg_sign2` calls on rational polynomials. Turning those signs into a root
count is `sh_count` — **which is precisely blocker B, the theorem
delineability needs.** So the two open problems converge, and `sh_count` is
the single remaining piece of mathematics for the whole project rather than
one of two independent ones.

## 2026-09-19 — alg_sturm: Sturm counting AT an algebraic parameter

This is the piece that was supposed to need a new theorem and did not.

`alg_lift` decides whether a member vanishes at a candidate by a SIGN CHANGE
between the two rational neighbours, which is exact only while every root is
simple. So it refuses a section sitting at a DISCRIMINANT root -- the generic
critical point, present in every CAD. Sturm counting does not care about
multiplicity, and **everything needed to run it at an algebraic parameter was
already proved here**:

  - `chain_sturm`'s `fchain_sturm` (Phase 3): the symbolic pseudo-remainder
    chain, READ AT ANY REAL VALUATION, is a `constructed_sturm_sequence?`,
    so `Sturm@sturm` applies at `ys = (: value(a) :)`. Its condition `fok` is
    just: not constant in the main variable, LEADING COEFFICIENT nonzero at
    the valuation, enough fuel. **No discriminant condition.**
  - `sg_chain`'s `rchain_sg_at` (Phase 6): the same chain built from a SIGN
    FUNCTION rather than a valuation, equal to it at `msg(ys)`. That is what
    makes it EXECUTABLE at an algebraic point -- the oracle is `alg_sign2`.
  - `nsc_scale`: sign-change counting is blind to positive rescaling, so
    counting the SIGNS is counting the values.
  - `prem_arr`'s `earr_eval_dg`: a chain entry read at a rational `y0` and at
    `x = value(a)` is a rational univariate at `value(a)` -- `alg_sign2` again.

So `algsg(a) = msg((: value(a) :))` (`algsg_msg`) bridges the sign oracle to
the valuation, `achain_at` makes the executable chain the proved one, and

    acount(k, a, f, y0, y1) = avar(k, a, f, y0) - avar(k, a, f, y1)

counts the roots of `f(., value(a))` in `(y0, y1]`, with

    acount_nneg   the count is not negative
    acount_zero   count 0 means no root in the interval
    acount_pos    count > 0 produces one

all proved. **The condition is `alc?` -- length >= 2, leading coefficient
nonzero at alpha, enough fuel -- and nothing about discriminants.** That is
exactly the case `alg_lift` had to refuse.

### Two corrections to what I said yesterday

  - I said the two blockers were one theorem, `sh_count`. That is too strong.
    They SHARE the Sturm machinery, but the executable side (item A) needs
    only to EVALUATE the chain at a specific alpha, which Phase 3 and Phase 6
    already make possible. Delineability still needs the chain's leading
    coefficients to BE projection members, which is `sh_count` proper and is
    still open.
  - `sh_count` was written up as the remaining content of Stage C. For item A
    it is not needed at all.

### PVS friction worth recording

Stating the count as a bijection into a subtype, the way `Sturm@sturm` does,
makes the proof fight two type rewrites at once: the codomain (`polynomial`
of the chain's first entry versus `meval` of the member) and the domain
(`below` of Sturm's sign-change difference versus `below` of `acount`).
`replace` does not reach inside a type. Stating the SAME content as a count
and an existence -- `acount_zero` and `acount_pos` -- removes both, and those
are what bisection actually needs. When a theorem's shape is fighting the
prover and nothing downstream wants that shape, change the shape.

## 2026-09-19 — alg_sturm2: the counts at infinity, and no Cauchy bound needed

Root isolation needs a starting interval and a test for when an interval has
caught every root. The obvious route is a Cauchy bound, and it is not
available here: a Cauchy bound needs MAGNITUDES of the coefficients at alpha,
and `alg_sign2` gives only signs. Refining alpha's isolating interval until
interval arithmetic pins the magnitudes would work but is a second machine.

Sturm's unbounded theorems need no magnitudes either. At `+-infinity` the sign
sequence is read off the chain's LEADING COEFFICIENTS alone -- `p(i)(n(i))`
and `(-1)^n(i) * p(i)(n(i))` -- and `chain_sturm`'s `arr_lc` turns the leading
array value into `meval(llast(.))` at the valuation, which is an `alg_sign2`
call. So:

    atotal = alo - ahi                    every real root
    aleft  = alo - avar(y0)               roots in (-inf, y0]
    aright = avar(y1) - ahi               roots in (y1, inf)
    asplit: atotal = aleft + acount + aright

`aleft_nneg` and `aright_nneg` say each part counts something, so

    acount(k,a,f,y0,y1) = atotal(k,a,f)

forces `aleft = aright = 0`, and `aleft_zero`/`aright_zero` then say there is
nothing outside. That is `acaptures`, the widening test: **no bound on any
coefficient appears anywhere in it.**

GATE PASSED 9/9, after the gate caught one more unproved index TCC.

With `acount_zero`, `acount_pos` and `acaptures`, bisection now has everything
it needs: widen until `acaptures` fires, then split any interval whose
`acount` exceeds one. Nothing in that loop touches a discriminant.

## 2026-09-19 — alg_lift2: the discriminant sections are decided, measured

`alg_lift`'s sign-change rule is silent at a repeated root, so `ok2a` refused
the two sections of `x^2 + y^2 - 2` -- the circle's vertical tangents -- and
reported `(: TRUE, FALSE, TRUE, FALSE, TRUE :)` per sector. Asking the same
question of `alg_sturm`'s count instead,

    f vanishes somewhere in (r1, r2]   iff   acount(k, a, f, r1, r2) > 0

and Sturm does not care about multiplicity. Measured:

    ok2a(f_rad2)                       = FALSE   the old rule refuses
    ok2b(f_rad2)                       = TRUE    this one does not
    dec2b(TRUE, FALSE, f_rad2, psi2)   = TRUE    FORALL x EXISTS y ... correct
    dec2b(TRUE, FALSE, f_rad2, psi2_f) = FALSE   negative control
    ok2b(f_meet)                       = TRUE    still agrees where the
    dec2b(FALSE,FALSE, f_meet, ...)    = TRUE    sign-change rule worked
    dec2b(TRUE, FALSE, f_meet, ...)    = FALSE

all in about a second each and all proved by ground evaluation.

**The condition has no discriminant in it any more.** `aok1b` per member is:
constant in the main variable, or else `alc?` -- length at least two, LEADING
coefficient nonzero at alpha, enough fuel -- plus the candidate polynomial
being nonzero. That is the whole of it.

### What is proved and what is measured

`alg_sturm`/`alg_sturm2` are proved: `acount_zero`, `acount_pos`,
`acaptures`. `svs_alg2` is measured, not yet proved: the step that is still
an argument rather than a theorem is that the resultant's candidate roots
CONTAIN every root of `f(., value(a))`, which is the classical resultant
vanishing property and needs a determinant-with-a-kernel-vector lemma this
library does not have. Two ways out, both open:

  - prove it -- `rres(r,m,s,n) = 0` when the two polynomials share a root,
    via the Sylvester matrix having `(z^{m+n-1-b})_b` in its kernel; or
  - drop the resultant candidates altogether and get the section points from
    BISECTION on `acount`, which `acaptures` already supports and which would
    need no resultant theory at all.

The second is more attractive: it would make the whole lifting rest on
`acount_zero`/`acount_pos`/`acaptures` and nothing else.

## 2026-09-20 — alg_bis: the lifting on bisection alone, no resultant anywhere

`alg_lift` and `alg_lift2` place the section points at the roots of
`Res_x(p, f)`. That works, but it leaves one step an argument rather than a
theorem: that those candidates CONTAIN every root of `f(., value(a))`.
Proving it needs the classical resultant vanishing property -- a determinant
with a kernel vector -- which this library does not have.

**It is not needed.** `acount` finds the roots itself:

    bwide   doubles an interval until acount = atotal, and acaptures turns
            that into "every root is inside" -- no Cauchy bound, no
            magnitudes, nothing about coefficients
    bint    splits until every gap holds at most one root of the product,
            with bpick choosing separators that are not roots
    bwalk   reads a vector at every separator and one more per gap holding a
            root, where a member is zero exactly when acount says it has a
            root in that gap

So the lifting now rests on `acount_zero`, `acount_pos` and `acaptures`, plus
`sector_rep`'s `svec_same` and `prodl_zero`. No resultant, no discriminant, no
`mswap`.

Measured (`alg_bis_ex`, all by ground evaluation, under a second each):

    ok2c(f_rad2)                       = TRUE
    dec2c(TRUE, FALSE, f_rad2, psi2)   = TRUE
    dec2c(TRUE, FALSE, f_rad2, psi2_f) = FALSE
    ok2c(f_meet), dec2c both directions on f_meet -- agree with alg_lift2

and at the section itself,

    svs_bis(f_rad2, sqrt(2)) = (: (1, 0), (0, 0), (1, 0) :)

which is right: at x = sqrt(2) the fibre is y^2, a DOUBLE root at 0, reported
as a section with both members zero. That is the case the sign-change rule
could not see.

### Two things the measurement forced, neither of which I would have guessed

  - **The product must be over the LIVE members only.** `f_rad2`'s second
    member IS `x^2 - 2`, which carries no main variable, so including it makes
    the product vanish IDENTICALLY at exactly the sections. Without `lives`
    the widening exhausted all 24 doublings and `bseps` came back
    `(: -16777216, 16777216 :)` with nothing between them.
  - **The product must be STRIPPED of structural trailing zeros.** `lmul`
    pads -- `nn(l1,l2)` is `max(dg l1 + dg l2, dg(lmul(l1,l2)))` -- and
    `prodl` of the single live member came back `(: x^2-2, 0, 1, 0 :)`. So
    `llast` was `mconst(0)` and `alc?` refused, correctly, because `dg` was 3
    where the real degree is 2. Dropping structurally-zero trailing
    coefficients changes no value at any valuation.

Ten TCCs were unproved after the first gate, including one that wanted an
`every` over a map because the literal `0` inside a LAMBDA makes PVS infer
`number`; declaring a helper `bsg` with return type `Sign3` removes it
entirely rather than proving it.

GATE PASSED: `alg_bis` 18/18, `alg_bis_ex` 6/6.

## 2026-09-21 — review, FINISH_PLAN, and S1 (sturm_sg)

Reviewed every plan document and measured the PROVED route on ex_line's
family: read closure ~8 s, inv1? ~8 s, lifting 43 sectors with svs_sg ~29 s,
the same 43 sectors with item A's bisection lifting under 1 s. FINISH_PLAN.md
records the conclusion: the unconditional route never needed delineability,
it needs the lifting's answer to be invariant along a sector, which
DETERMINACY on the polynomials read supplies; the bisection walk's reads are
polynomially many, so closing the projection under those gives a decision
polynomial in |F| with nothing conditional in it.

S1 done: `sturm_sg` GATE PASSED (24/24). The Sturm counts restated for an
arbitrary oracle and proved at `msg(ys)` for ys of any length, plus `cnt_one`
(a count of one makes the root unique, from the bijection's injectivity and
the one-element domain). Entries are read as `sg(sub1(c, y0))`; `sub1` is
Horner over `madd`/`mscal`, so `mswap` and `partial_eval` leave the path.

## 2026-09-21 — S2: walk_fib, the lifting proved at any real point

`walk_def` (18/18) and `walk_ok` (29/29) GATE PASSED.

    walk_fib: wok?(F, msg(ys), Y) IMPLIES
              (member(v, walk(F, msg(ys), Y)) IFF fib(F, ys)(v))

for ANY separators Y that pass `wok?`, at ANY real valuation `ys`. The search
for separators (`seps`, widening and bisection) is therefore outside the
trusted argument, and one theorem serves a rational sample, an algebraic one,
and every point of a sector -- the last being what stage S4 needs.

Measured before proving: on all 43 read-closure sectors of ex_line's family
the oracle-general walk passes `wok?` and lifts in under a second, against
~29 s for `svs_sg`.

The proof's one real idea is `svec_same_live`: sector_rep's `svec_same`
assumes the product of ALL members has no root on the interval, which fails
as soon as one member vanishes identically along the fibre (`x^2 - 2` at
`x = sqrt 2`). Splitting members into those that strip below length two
(constant in the main variable, `short_const`) and live ones (vanishing only
where the live product does, `bprod_zero`) removes that assumption. The
section vector is then `sgn_at`: count positive means the member's root is
THE root of the gap by `cnt_one`; count zero means no root in the closed gap,
so the sign is the one at the left separator.

## 2026-09-21 — S4: the fast two-quantifier decision, proved (decw_correct)

`loc_const`, `sign_pers`, `walk_rd`, `sturm_sg2`, `sep_exist`,
`walk_transfer`, `cad_fast_def`, `cad_fast`, `cad_fast_ex` (gate results
below).

    decw_correct: decw(q1, q, F, Psi)`ok IMPLIES
                  (decw(q1, q, F, Psi)`val IFF sem((: q1, q :), F, Psi, null))

Unconditional in the sense of `decide2_correct`: `ok` is a boolean the code
computes. Measured (banked in `cad_fast_ex`): ex_line in about a second with
ONE root sector, where `decide2` takes 48 s over 43; circle, disc, the curves
meeting at `+-sqrt 2` and the sections at discriminant roots about a second
each, negative controls right.

### What was measured first, and what it refuted

S4 as first planned closed the projection under ALL the walk's reads, with
constant rational separators. Measured (`dec4`): fine on the bounded curves,
and on ex_line 164 roots at fuel exhaustion, 79 s, `ok = FALSE`. A read
`f(y_j, x)` at a constant separator vanishes wherever a root curve crosses the
horizontal line `y = y_j`; the line's root `(1 - x)/2` crosses every one, and
near a point where two root curves meet no finite set of constant separators
works at all. So an invariance certificate over the ENTRY reads cannot exist
in general. Closing under the INTRINSIC reads only (chain construction reads
and leading coefficients: `wi_rd`) measured at the projection's own sectors.

### The proof: delineability certified at run time, no subresultants

The entry reads are handled by argument instead of by certificate.

  T1 `sign_pers`     finitely many polynomials, each nonzero at x0 or zero
                     everywhere, keep their signs near x0 (`msg_pers`)
  T2 `walk_rd`       `walk_det`: oracles agreeing on `wi_rd` and `we_rd` walk
                     alike and pass `wok?` alike
  T3 `sep_exist`     at EVERY point there are separators that pass and at which
                     no chain entry vanishes
  T4 `loc_const`     a locally constant predicate on an interval is constant
  T5 `walk_transfer` `fib_local`, then `fib_const` on a convex set

T3 needed neither a root bound nor an enumeration of roots. The outer
separators come from induction on the unbounded counts (`left_step`: moving
the endpoint past a root lowers `left` by a positive `cnt`), the inner ones
from induction on the bounded count (`cnt_two` gives two distinct roots; a
rational strictly between them splits the count into two smaller positive
ones). The rational is found by density inside an interval on which the
polynomials to avoid have no root; such an interval exists because a
polynomial with a nonzero coefficient is not constant on an interval
(NASALib `poly_constant_on_interval`) and is continuous (`pf_cont`).

A member with no main variable after stripping contributes no chain, so its
sign would go unseen by the intrinsic reads: `mi_rd` adds its one coefficient.
Its entries are then handled separately from the rest (`me_sh`, by
`short_val` and the certified invariance of that coefficient), since they may
vanish at x0 without vanishing identically and so are outside `msg_pers`.

### PVS friction worth recording

- A `then` whose tail follows a `case` applies the tail to BOTH branches; a
  `hide-all-but` in it destroyed the main branch twice. Use `branch`.
- `(expand "member")` without an occurrence number unfolds the instantiated
  hypothesis two levels deep and buries it; give fnum and occurrence.
- An induction over a list whose step mentions `car(strip(g))` produces a
  third goal (the TCC of the induction predicate) that receives the LAST
  tactic of the `branch` list.
- `grind` on the termination TCC of `icert?` unfolds `icert1?` into the whole
  walk and does not return; `(expand "length" 2 2) (assert)` after hiding it.

## 2026-09-21 — (cad) rewired to decide3; two-variable problems in seconds

`cad_decide3_def` / `cad_decide3`: `decide3` has `decide2`'s signature and
statement (`decide3_correct`), runs `decw` first at two quantifiers and keeps
its answer when the certificate passes, and is `decide2` otherwise. The
strategy cites `decide3_correct`; nothing else in it changed except the fix
below. `cad_examples` re-proved through it, `cad_examples2` added.

Wall clock for the whole proof through the server, session start included:

    problem                                        decide2     decide3
    ex_line     ALL x EX y: x + 2y = 1 AND y^2>=0   48 s        8 s
    ex_circle   ALL x EX y: on the circle or outside 14 s       3 s
    ex_circle2  EX x ALL y: outside the circle        --        3 s
    ex_disc     ALL ALL: inside the disc, x < 1       5 s       3 s
    ex_cubic    ALL x EX y: y^3 - 3y + x = 0          --        2 s
    ex_amgm     x^2 + y^2 >= 2xy                      --        3 s
    ex_disc2    on the unit disc x + y <= 2           --       12 s
    ex_meet     circle meets parabola                 --       11 s
    ex_quartic  x^4 + y^4 + 1 > xy                    --        3 s
    ex_ell      ellipse and a line, 2 atoms           --        6 s
    ex_hyp      NOT (ALL x EX y: xy = 1)              --        7 s

("--": not attempted with decide2; its cost is 3^|F| per sector over the read
closure.) ex_three is still proved directly: three quantifiers go to
`decide2`, which does not finish on it. That is stage S5.

### A strategy bug found by trying a false sentence

`(cad -1)` on a sentence in the ANTECEDENT never worked. Two causes. The
record is put at -1 by `eval-expr`, which shifts the sentence to -2, so
`cad-finish__` was handed the record and died reading a quantifier prefix off
it. And with that fixed, `(case "NOT phi")` is merged by PVS with the `phi`
already in the antecedent, so "formula 1" of the second branch is not the
case formula and the labels land on the record. Now a FALSE sentence in the
antecedent is refuted where it stands (which closes the goal) and a TRUE one
is only labelled. `ex_hyp` is the regression test.

## 2026-09-21 — working copy moved to the internal disk; S5c first measurements

The repository now lives on the internal disk; the external-drive copy
is stale. Tools and CLAUDE.md repointed.

`tower_def` (typechecks, NOTHING proved): the oracle tower and a measuring
three-quantifier decision `dec3m`. A level below the outermost is a walk over
rational separators through the oracle of the level above; at a separator the
cell's oracle is `sg o sub1(., y_j)`, at a section it is a bounded Tarski
query (`tq_b`) against the member of the level's family that vanishes there.
`(cad-m3)` runs it on a formula and prints value and time.

    ALL x ALL y EX z: z > x AND z > y          (ex_three)   TRUE   4 s
    ALL x ALL y EX z: z > x AND z < y          (control)    FALSE  1 s
    EX x ALL y EX z: z^2 = y - x                            FALSE  0 s
    ALL x EX y ALL z: z^2 + y > x                           TRUE   0 s
    ALL ALL ALL: x^2 + y^2 + z^2 >= 2xy                     TRUE   1 s
    ALL x ALL y EX z: on the sphere or outside the disc     TRUE   1 s
    ALL x ALL y EX z: z^2 = x^2 + y^2                       TRUE   1 s
    EX EX EX: x + y + z = 1 AND xyz = 1                     > 10 min, stopped

All answers right; `decide2` does not finish on the first. The last one is the
cost to look at next.

### What the measurement forced

`zc?` (alg_bis) tested `mconst?(u) AND mc(u) = 0`. One level up, lmul's padding
zero is multiplied by an mpol and comes back as `mpol((: 0, ..., 0 :))`; strip
left it, `llast(bprod)` was a zero term, `slc?` refused and `wok?` was FALSE on
ex_three's y-level. `zc?` now tests after `mnorm`; `strip_eval` re-proved with
`meval_mnorm`. And the section query ran against the whole product (degree 8
in x after the closure) and took 112 s for one cell; against the vanishing
member (`secp`) the whole decision takes 4 s.

## 2026-09-21 — S5a: the transfer theorem along one coordinate

`sign_pers` (7/7), `walk_transfer` (37/37), `cad_fast` (11/11) generalized in
place from parameters `(: x :)` to `cons(x, xs)` with `xs` held fixed, all
GATE PASSED. `fib_const` now reads: on a convex set of values of the FIRST
coordinate where the walk's intrinsic reads keep their signs, the fibre set
over `cons(x, xs)` does not vary. S4 is the instance `xs = null`; S5 uses it
in the y-direction at a fixed x. `sign_pers` no longer goes through
`cpl`/`pmc` (one variable only): `msg_pers1` is by cases on the term, `pf_cont`
for an `mpol`, nothing to do for a constant, and the theory now imports only
`pos_dec` and `sg_norm`. 33 of `walk_transfer`'s 37 proofs replayed after a
textual substitution; the four inductions needed `xs` in their IH instances.

## 2026-09-21 — S5b: the tower theorem

`tower_def` (18/18, TCCs only: executable) and `tower_ok` (15/15) GATE PASSED.

    tower: tok(k, l0, g, ys) AND lo < hi
           AND nzall?(msg(ys), tchain(k, l0, g, ys), lo) AND nzall?(..., hi)
           AND one?(ys, l0, lo, hi, beta)
           IMPLIES s3(tq_b(k, msg(ys), l0, g, lo, hi))
                   = sign3(meval(mpol(g))(cons(beta, ys)))

The bounded Tarski query, read entirely through a sign oracle, is the sign of
g at the one root of l0 in the gap. So a level below the outermost can have
SECTIONS with no algebraic number anywhere: the oracle at a section is a
function of the oracle one level up. `tq_nsol` is NASALib's `sturm_tarski`
applied to `tchain_sturm`; `nzall?` (no chain entry vanishes at an end) is
exactly its side condition, via `gc_cons`. `nsol_gt`/`nsol_lt`: with one root
in the gap each solution set is a singleton or empty, by extensionality and
`card_singleton`/`card_emptyset`.

## 2026-09-21 — S5b: cell_ok, the cells of an inner level are read correctly

`tower_def` (23/23, certificates `secok?`/`ptok?`/`cellok?`/`in2ok?` added;
measured: `ok3m(f_three) = TRUE`, 5 s), `tower_ok` (15/15), `cell_ok` (10/10)
GATE PASSED.

`pt_fib`: at a separator the oracle `sg_pt(msg(ys), y0)` is literally
`msg(cons(y0, ys))` (extensionality, `sub1_eval`, `meval_as_list`), so the
inner walk lists the fibre set by `walk_fib`. `sec_fib`: at the section of a
gap each sound query returns the sign at `(beta, ys)` (`qsec_val`: `secp_ok`
makes the query polynomial a factor of the level's product with nonzero
leading coefficient, `sec_one` turns `cnt = 1` between the query's own ends
into the one-root hypothesis of `tower`); when every query the inner walk
makes is sound the oracle agrees with `msg(cons(beta, ys))` on all the walk
reads and `walk_det` transports `walk_fib`. beta occurs only in statements.

## 2026-09-21 — S5d claim A: inner2_sem, two inner quantifiers at a fixed point

`level_ok` (21/21) GATE PASSED.

    inner2_sem: in2ok?(F, msg(ys)) IMPLIES
      (inner2(q2, q3, F, Psi, msg(ys)) IFF sem((: q2, q3 :), F, Psi, ys))

at ANY real valuation ys of the outer variables. cell_ok reads the inner
quantifier at each cell; what this adds is that the cells cover the line.
`T_same` is the transfer theorem `fib_const` used in the y-direction with ys
fixed: `Srf(P, ys, y0)` (no root of P's product between y0 and y) is convex,
and `inv?` holds on it because each intrinsic read of the inner walk is a
MEMBER of P (`clok?`), so `mem_same` keeps its sign where P's product has no
root. `cv_gap` places any y of a gap at one of its at most three cells (left
separator, section, right separator); `cv_mid`, `cv_last`, `cv_sound`,
`cv_all` are `walk_ok`'s `walk_mid`/`walk_last`/`walk_sound`/`walk_fib` one
level up with the truth value T(y) in place of the sign vector.

### Claim B, as it will be proved (design settled while this gated)

Local constancy in x of G(x) = sem((: q2, q3 :), F, Psi, cons(x, xs)) on a
sector where the intrinsic reads of P's walk are invariant, then loc_const.
Three simplifications over the first sketch:
- NO ordered-list correspondence between cells at x and at the sample. The
  closure property "the inner walk's intrinsic reads at this cell are members
  of P" depends only on the cell's sign vector on P, and S4's fib_const for
  the family P gives equal SETS of sign vectors; wi_det moves the read set.
  For this the closure must hold at SECTION cells too (executable change).
- NO determinacy of the tower across x: the tower is used pointwise, at the
  sample only, through inner2_sem. At a section the signs of the intrinsic
  reads at (beta(x), x) are read off P's sign vector at the section, which is
  part of P's walk and locally constant by walk_det.
- entry reads at a section: nonzero at (beta0, x0) by the choice of inner
  separators, then persistent by continuity of the root (cnt_det between
  rational ends that persist) and joint continuity of a polynomial in (y, x).

## 2026-09-21 — S5c/d: decw3 measured with its certificate; first half of claim B

`cad3_def` (6/6), `joint_cont` (6/6), `cover` (9/9), `closed_pt` (10/10) GATE PASSED.

`decw3` (three quantifiers, full certificate) measured through `(cad-m3)`:

    ALL x ALL y EX z: z > x AND z > y          ok TRUE  val TRUE   9 s
    ALL x ALL y EX z: z > x AND z < y          ok TRUE  val FALSE  5 s
    EX x ALL y EX z: z^2 = y - x               ok TRUE  val FALSE  0 s
    ALL x EX y ALL z: z^2 + y > x              ok TRUE  val TRUE   0 s
    ALL ALL ALL: x^2 + y^2 + z^2 >= 2xy        ok TRUE  val TRUE   1 s
    ALL x ALL y EX z: sphere or outside disc   ok TRUE  val TRUE   3 s
    ALL x ALL y EX z: z^2 = x^2 + y^2          ok TRUE  val TRUE   1 s

The level's closure now includes SECTION cells (yreads, secok?): claim B needs
it, and the measurements above are with it.

`closed_pt`: `cl_transfer` moves "the inner walk's intrinsic reads at (y, x)
are members of P, and the walk's conditions hold" from the sample to every
point over the sector. The property depends on a point only through P's sign
vector there (`rdin_vec`: `rdin_agree`, then `wi_det` and `cert_det`), and S4's
`fib_const` for the family P says the SET of sign vectors over x is the set
over the sample; so each point over x has a twin over the sample. No
correspondence between cells, ordered or otherwise, is used.

## 2026-09-21 — S5d: claim B complete (the inner truth is constant on an outer sector)

`walk_same` (15/15), `root_cont` (6/6), `pt_local` (6/6), `cells_local` (4/4),
`inner_const` (7/7): GATE PASSED (three fresh runs + traces, zero
"fewer subproofs"), each file on its own.

The statement: for a convex S on which the level family P has invariant
intrinsic reads (`inv?`, `cert?` at the sample q) and with the closure `CL?`
over the sample,

    G_const:  S(a) AND S(b) IMPLIES (G(a) IFF G(b)),
              G(x) = sem((: q2, q3 :), F, Psi, cons(x, xs))

The pieces, in the order they are used:

- `walk_same` -- two valuations whose oracles agree on the walk's intrinsic
  reads and on the non-vanishing entry reads have the same fibre.  This is
  `fib_local`'s core freed from "the two points differ in x only".
- `root_cont` -- `root_near`: a gap with exactly one root over x0 has exactly
  one over x near x0 (`cnt_local`, counting through the oracle), and shrinking
  the gap first (`ends_exist`) puts the two roots within eta of each other.
  Continuity of a simple root without any implicit function theorem.
- `pt_local` -- at one cell (beta0, x0): points near it with the same P-sign
  vector have the same inner fibres, hence the same inner truth.
- `cells_local` -- induction over the separator list: near x0 the walk over P
  agrees, and every cell has the same inner truth over x as over x0.
- `inner_const` -- `V_sub`: equal cells give "each inner truth value over one
  point occurs over the other" (by `cover`, `T_same_r` across root-free
  intervals, `gap_sec` for sections); `G_from` folds that under either inner
  quantifier; `G_local`, then `G_const` by `loc_const`.

No cell correspondence, no ordering of roots across the sector, and no
delineability statement is used: only SETS of truth values over a point.

## 2026-09-21 — S5d closed: three quantifiers proved and wired into (cad)

`cad3`: **`decw3_correct`** -- `decw3(q1,q2,q3,F,Psi)`ok IMPLIES (val IFF
sem((: q1,q2,q3 :), F, Psi, null))`. Per sector: `sect3_const` is `G_const`
with S = insec(s), P = lvl2(F, s) (inv? from `inv_sect` over the level's
family, cert? from `cert_w`, CL? from `cl_cells` out of `in2ok?`; a root
sector is a point); `sect3_sem` adds `inner2_sem` at the sample; `fold3_sem`
is `foldw_sem`'s fold over the sectors.

`cad_decide4_def` / `cad_decide4`: `decide4` = decw for two quantifiers, decw3
for three, decide2 as the fallback and for every other prefix;
`decide4_correct`. `(cad)` now cites it.

`cad_examples3`: seven three-variable sentences, each closed by the single
step `(cad)` (two FALSE ones refuted by `(cad -1)`). `ex_three` in
`cad_examples`, proved by hand until now because decide2 did not finish on it,
is `(cad)` as well: 12.7 s wall clock including the proof replay.

GATE PASSED, each file on its own: `cad3` (6/6), `cad_decide4_def` (3/3),
`cad_decide4` (6/6, after three `rev3` typing TCCs the server had not
generated were proved), `cad_examples3` (9/9), `cad_examples` (9/9, ex_three
now `(cad)`), `cad_examples2` (14/14).

S5e (n quantifiers) is designed in FINISH_PLAN 3d. `towern_def` is its
executable, to be measured first.

## 2026-09-22 — why four quantifiers blew up: measured, half fixed

Four quantifiers (`ALL x ALL y ALL z EX w: w > x AND w > y AND w > z`, three
linear members, ~105 bottom cells) ran > 15 min on `decnm` while three took
5 s. Not the CAD exponent: a bottom walk with the coordinates substituted is
0 s. Profiled to two causes (FINISH_PLAN 3e):

1. **Chains rebuilt inside every count** -- `svar` built `schain` inside the
   lambda passed to `number_sign_changes`; `tvar`, `tlo`/`thi`, `qsec` (which
   also recomputed `secp` per query) the same. FIXED, trusted definitions
   unchanged in meaning: `svarc`/`sloc`/`shic`/`cntc`/`leftc`/`rightc` take the
   chain, `svar`/`slo`/`shi`/`cnt`/`left`/`right`/`tq_b`/`qsec`/`sg_sec`/`wok_w`
   are stated through them with `_def` lemmas (old statements), `wokc?` and
   `sepokc?` proved equal to `wok?`/`sepok?`; `seps`, `tlo`, `thi` share one
   chain. Twelve proofs in six files repaired (rewrite with the `_def` lemma
   where they expanded). Same objects before -> after: `cnt` 19 s -> 2 s,
   `seps` 317 s -> 1 s, `wok_w` 12 s -> 2 s, a bottom walk at a section
   > 20 min -> 56 s.

2. **Symbolic pseudo-remainder swell** -- chains carry every not-yet-eliminated
   variable symbolically; a degree-3 product chain at the four-variable level
   is 1 s, a degree-4 one > 10 min. Each level adds a free variable and a
   nesting of Tarski queries. The fix is S5e-0 (oracle descriptors: `meval` at
   rational cells, chains once per level via the proved determinacy lemmas),
   then S5e-1 (no product chain in the certificate).

GATE PASSED, each on its own: `sturm_sg` (31/31), `sturm_sg2` (7/7),
`walk_def` (22/22), `walk_rd` (40/40), `walk_ok`, `tower_def`, `tower_ok`,
`cell_ok` (10/10), `cad_fast`. Whole-library run: see the next entry.

Whole library after the change: `proveit -a top.pvs` **2698/2698**.

## 2026-09-22 — walk_od: descriptors and a chain table (S5e-0, first half)

`walk_od` (26 lemmas + TCCs, all proved): oracle descriptors
`OD = pt(ys) | alg(a) | sec(od, P, lo, hi)` with meaning `osg`, entry signs at
a rational point by `meval` (`osent_eq` from `sent_sign`), and a chain table
`CT` whose entries `(f, k, chain, reads, signs)` are used at any oracle that
agrees with the recorded signs on the reads -- sound by `i_det`
(`chain_t_eq`). `walk_t`, `wok_t`, `seps_t`, `svs_t`, `wok_wt` are each
proved equal to the `walk_def` original at `osg(od)` for a valid table
(`tblof_valid`). Measured on the four-variable family at rational z-cells:
ten cells 15 s -> 5 s, and the 5 s is the once-per-level table (four
chains at ~1.2 s each); the per-cell work is ~0.1 s.

What remains expensive is a SECTION cell over a rational base point: its
oracle `sg_sec` runs a symbolic Tarski chain per query (56 s for one bottom
walk). Over a rational base the section point is ONE algebraic coordinate,
so `alg_sign2` on the specialized univariate member (Phase 3, proved) gives
the sign directly -- a descriptor `mix(rs, a, ys)`; the certificate becomes
`alg?` (one root in the gap) instead of the tower query. That changes the
specification of the level (`tower_def`'s `sg_sec` inside `cellvals`,
`cellok?`) and so re-proves S5b-S5d's ~40 lemmas along a simpler route; the
tower theorem stays for points with two algebraic coordinates. Decision
pending.

## 2026-09-22 — descriptors at n levels (towern_od): measured, and the next wall

`walk_od` extended: `OD = pt | mix(rs, a, ys) | sec | sp`, `mix` = rationals
above ONE algebraic coordinate above rationals, its oracle `alg_sign2` on
`partial_eval(subs(c, rs), ys)`, EXACT (`mix_exact`, from
`partial_eval_polylist` + `alg_sign2_sign` + `subs_eval`); 50/50.

`towern_od` (typechecks, nothing proved): the n-level executable on
descriptors -- sections over a rational point become an `Alg` of the
specialized member (certificate `alg?`), the tower query only over a point
that is already algebraic; one chain table per level per sector along the
leftmost cell path; the read closure through the tables. Measured:

    three quantifiers, ex_three, WITH certificate     3 s   (decw3: 9 s)
    its negative control                              1 s   (decw3: 5 s)
    four variables, one closure round (82 s before)   7 s
    four variables, the whole decision                > 10 min, killed

Where the four-variable time goes now: after ONE closure round the y-level
family has 10 live members, the z-level 8, with products of degree 24 and
25; and the members themselves -- the reads, i.e. coefficients of the
z-level pseudo-remainder sequences -- are swollen polynomials: building the
chains of the 8 y-level members alone takes 122 s (15 s each, with a single
symbolic variable). The read closure materializes unnormalized PRS
coefficients (extraneous powers of leading coefficients), which then feed
the next level's chains: this is the structural wall, and it is the
certificate's, not the evaluator's. Options recorded in FINISH_PLAN 3f.

## 2026-09-22 — the redesign works: four quantifiers CERTIFIED in 37 s (branch s5e-redesign)

Hardest part first, measured before proving. With the walk redesigned --
per-member root isolation on the REDUCED chain (sg_chain2), coincidence in
a gap by the PAIR product's count, reads normalized to a canonical scalar
multiple (`rd_norm`), and a member identically zero at a cell (all
coefficients vanish under the oracle: `livea?`) reading sign 0 with no
roots -- `decn_o` on descriptors gives

    ALL x ALL y ALL z EX w: w > x AND w > y AND w > z   ok TRUE  val TRUE   37 s
    same with w < z                                     ok TRUE  val FALSE  26 s
    ex_three (three quantifiers)                        ok TRUE  val TRUE    1 s

against no answer in 30 minutes yesterday. What each step bought, on the
same objects: the y-level after one closure round had 10 live members with
a degree-24 product; member chains 122 s -> 2 s (reduced chain); the
product's chain 504 s -> gone (per-member walk); the closed level's 33
"live" members were ~7 distinct polynomials up to a constant -> 8
(rd_norm); the at? sector failed because x(y-x)^2 is identically zero at
x = 0 -> livea?.

The trusted definitions changed (walk_def, walk_rd, sturm_sg), so the
proofs of their clients do not replay; this is on the branch until the
re-proof (FINISH_PLAN 3g): sturm_sg through the bridge lemmas, walk_ok's
gap_beta/gap_none from the per-member conditions, walk_rd's determinacy
per member and pair, then the tower and everything above.

Through `(cad-mn)` (now on `decn_o`), all with certificate TRUE:

    ALL x EX y ALL z EX w: w > x + y + z            2 s
    ALL x ALL y EX z ALL w: w^2 + z > x + y         4 s
    ALL x ALL y ALL z: x^2 + y^2 + z^2 >= 2xy       1 s
    ALL x ALL y EX z: sphere or outside the disc    1 s

## 2026-09-23 — odreads: the executable's read lists contain the walk's (S5e-2 (a))

`odreads` 18/18: `ird_t_eq` (the chain table returns
the construction reads, mirror of walk_od's `chain_t_eq`), `feff_mem` /
`feff_cons` / `feff_null` (feff as a predicate and as a recursion),
`mi_sub` / `pi_sub` / `pairs_sub` / `wi_sub` (every intrinsic read of
`wi_rd(feff(F, od), osg(od))` is in `wi_rd_t(F, od, tb)` at a valid table:
member reads through the table, all coefficients of every member as extra
reads, pair reads over the whole family), `e_rd_t_eq` / `me_sub` / `pe_sub`
/ `pairse_sub` / `we_sub` (the entry reads likewise), and `wi_agree` /
`we_agree` (agreement on the executable's list transports to the walk's).
towern_od now uses `bk(feff(F, od))` in the member and entry reads and the
tables, so the walk on feff and the certificate agree on the chain bound
(no monotonicity lemma about the bound is needed). towern_def, towern_od
and odreads are wired into top.pvs; the n-level executable is now part of
the whole-library run (as TCCs).

## 2026-09-23 — S5e-2 begun: the reads of a section query (qsec_rd 19/19, qsec_lift 2/2)

`qsec_rd`: `q_rd(sg, P, lo, hi, c)` lists every sign query qsec makes --
the candidate members' chain reads and counts (`secp_rd`), the coefficient
signs that normalize c (`snorm_rd`), the Tarski chain's construction reads
(`tchain_rd`), EVERY probe of the end search (`tlo_rd` / `thi_rd`: the
search is untrusted but its result enters the answer), and the entry reads
at the two ends. `qsec_det`: two oracles that agree on q_rd give the same
ok flag and value, and the same q_rd (`svarc_det` / `cntc_det` /
`nzall_det` / `tlo_det` / `thi_det` / `secp_det` / `qsecl_det`); `qs_det`
for a read list, with the two section oracles agreeing on it. `qsec_lift`:
`allok_agree2` -- at a base oracle that only agrees with msg(ys) on the
queries' reads, every certified query still answers the sign at the section
root (through qs_det and cell_ok's allok_agree). This is the piece that
lets claim A at n levels carry a read list instead of an exact oracle.

Executable fix found while reading towern_od's read lists for claim A: the
certificate read `llast(bprod(F))` (the product of ALL live members) while
the walk runs on `feff(F, od)` (the members not identically zero at the
cell); the product of all of F vanishes identically wherever a member does,
so its leading sign said nothing about the walked product. `wi_rd_t` now
reads `llast(bprod(feff(F, od)))` (feff moved above its first use).

And a real regression, caught only by RE-MEASURING: the 09-22 executable
walked with `livea?` inside the trusted walk; when that moved to `feff`
(09-23), only the lower levels were switched, so at a section-root sector
(`at?`) the top level walked the UNFILTERED family, a projection member
vanishing identically there defeated `nzat_t` everywhere, the widening ran
to 2^24, and `decn_o` answered ok = FALSE on every four-quantifier example
(three quantifiers still passed because that sector is decided at the
sample). Fix: every level walks `feff(car(TW), od)` (okn_o, innern_o,
treads_o, tables), while the closure family for `clok?` stays `car(TW)`;
the member reads and the tables use `bk(feff(F, od))`. Re-measured: ex_three
ok TRUE 5 s; ALL ALL ALL EX (w > x, y, z) ok TRUE val TRUE 27 s (was 37 s),
its control ok TRUE val FALSE 19 s. Lesson: any change to the trusted walk
must be followed by re-running the executable's examples.

Tooling lessons (cost half a day): pvs-cli's `undo` walks the WHOLE proof
tree back, one step per call, across branches -- never use it to back out
of a branch; `name-replace` on a rational IF-expression spawns
`real_pred` TCC subgoals in every later split -- split on the IF's condition
first instead; `prop` on a sequent with many IFF hypotheses multiplies
branches -- `replace` the equalities and `assert` first; `runproof.sh`
starts a new proof and thereby QUITS an unfinished one -- check "No active
proof session" before moving on. What worked: a per-lemma shell script with
formula numbers looked up by content (awk on the sequent), replayed from
scratch (`qsecl.sh`).

## 2026-09-23 — branch s5e-redesign: whole library 2846/2846; walk_od twins and rd_norm proved

`proveit -a top.pvs` on the branch after the client files: 2846 formulas,
2826 proved, the 20 misses all in walk_od (the `_eq` twins of the per-member
walk). Then walk_od 67/67: `valid_append` / `mkpairs1_valid` /
`mkpairs_valid` / `tblof_valid` (the pair-product chains join the table),
`rootin_t_eq` / `sgn_t_eq` / `gap_t_eq` / `nzat_t_eq` / `atmost1_t_eq` /
`coin_t_eq` / `coins_t_eq` / `sepok_t_eq` / `leftok_t_eq` / `rightok_t_eq` /
`wok_t_eq` (each an induction whose step is `inst?` on the hypothesis plus the
component twins, closed by `replace`/`propax` -- boolean equalities do not
close by `assert`), `spick_t_eq` / `sint_t_eq` / `swide_t_eq` (fuel
inductions; two IH copies for `sint`), two TCCs. rd_norm: `rd_norm_eval`
(the scaling constant is 1 or 1/lrat), `lrat_nz` through `lrat_normalx`
(size induction over the ADT eta axioms: a normal nonzero term's last
coefficient is a nonzero constant or a term with a main variable) and
`llast_lrat`. So every file of the redesign is proved; the executable
n-level files (towern_def, towern_od) carry no theorems yet and are not
reachable from top.pvs. Next: the n-level correctness claims for `decn_o`
on descriptors, then `(cad)` rewiring and the merge to main.

Later the same day: `proveit -a top.pvs` with rd_norm wired in: 2853/2853.
Branch s5e-redesign fast-forwarded into main (b92be91); `(cad)` still runs
decide4 (three quantifiers, decw3_correct) until decn_o has its theorem.
Started S5e-2: `qsec_rd` (the reads of one section query, typechecked; its
determinacy lemmas next -- FINISH_PLAN 3h).

## 2026-09-23 — S4/S5 clients re-verified on the per-member walk (branch s5e-redesign)

Down the import chain after walk_transfer, one `proveit -f` per file:
walk_same 17/17 (`pe_pz`, `pairse_pz`, `wnz_pz` mirror the `_nz` lemmas;
`short_inv_g` replayed), cad_fast_def 7/7 and cad_fast 11/11 unchanged,
tower_def 27/27, tower_ok 15/15, cell_ok 10/10 unchanged (FINISH_PLAN B3 --
tower_def on tchain2 -- is NOT needed: the n-level executable walk_od /
towern_od never touches the tower chain), level_ok 21/21 (`cv_gap`,
`cv_sound`, `cv_all` redone: a gap's section comes from `gapok_beta` /
`gapok_none` instead of the product count, the ends from `nzat_P`, the
outside from `left_P` / `right_P`; `cv_gap` / `cv_mid` / `cv_sound` carry
`slc?(bprod)` since `lvl?` demands it), cover 9/9 (same for `cover_gap` /
`cover_mid` / `cover`), closed_pt 9/9 unchanged, root_cont 9/9 REWRITTEN:
the section root is tracked through the MEMBER that owns it (`own_root`,
by `P_zero_mem` + `cert_nzm`), whose chain reads are certified (`mi_mem`);
`lev_ird` / `cnt_local` / `ends_exist` / `cnt_one_gap` are the member
versions and `root_near` is unchanged in statement. pt_local 8/8
(`sepok_adj` restated at a general oracle: `gapok?` + `nzat?`, with
`sepok_hd_sg`, `gap_lives`), cells_local 4/4 unchanged, inner_const 7/7
(`gap_sec` through `sepok_adj` + `gapok_beta`), cad3 6/6 (`decw3_correct`,
three quantifiers, unchanged). Every S5d client is back; what is not yet
re-proved on the branch is walk_od's `_eq` twins and rd_norm's two lemmas
(whole-library run next).

Lesson: a proof replay that instantiates a lemma with the WRONG binder
order can succeed silently on the wrong instance (a TCC subgoal then carries
the main goal); locate hypotheses by content (awk on the sequent) and read
the binder order off `(lemma ...)` before `inst`. Blanket `(expand "member")`
and stray `(ground)` in a branch with unrelated implications blow the goal
into dozens of subgoals -- `undo` and target the formula number.

## 2026-09-23 — walk_transfer 69/69: separators exist for the per-member walk

`walk_transfer` re-proved on the per-member walk (branch s5e-redesign). The
transfer argument is unchanged (`fib_local`, `fib_const`); what was rebuilt is
the existence of separators that pass the NEW `wok?`:

- `wok_exist`: `sep_exist` still produces separators for the PRODUCT `bprod(F)`
  (avoiding every chain in `allch`: the members' chains `mch`, the pair
  products' chains `pchs`, and the product itself). The per-member conditions
  follow gap by gap (`sok_sepok` through `gapc?` / `gapok_all`):
  `av_nzat` (no member vanishes at a separator: long members through their
  own chain, short ones through `nzm?`), `atmost1_all` (`cnt_le`: a member
  cannot count two roots where the product counts at most one, by
  `cnt_two` / `cnt_zero` / `cnt_one`), `coin_all` / `coins_all` (`pair_cnt`:
  two members with a root in the gap share it, so their product has count
  exactly one, by `meval_lmul` + `zero_times3`), `leftok_all` / `rightok_all`
  (`left_pos` / `right_pos`: a member root outside the ends would be a
  product root outside the ends).
- A real gap found and closed: with `nzat?` per member, a member with a main
  variable that is identically zero on the fibre fails at EVERY point, so
  `wok_exist` needs "no such member" (`nzm?`). It is DERIVABLE from the old
  `cert?` (`cert_nzm`): `live?` is syntactic (`length > 1`), so P includes
  every such member, and `slc?(bprod)` makes P a nonzero polynomial
  (`nonroot` gives a point where it is nonzero, `P_zero_mem` + `short_val`
  give the member's constant). So `cert?` is UNCHANGED, and `cert_w`
  (cad_fast) / `wok_cert` (closed_pt) stay as they are. The executable's
  `feff` filter is the same condition applied syntactically.
- `allch_lcok` through `pch_lcok` / `pchs_lcok` / `slc_lcok`; the entry
  reads' nonvanishing `pe_nz` / `pairse_nz` / `wnz_nz`; determinacy
  `pi_det` / `pairs_det` / `wi_det` / `nzm_det` / `cert_det`; membership
  `mch_mem` / `pch_mem` / `pchs_mem` / `bprod_allch`.
- Tooling: `/tmp/cad_scratch/prf2strat.py` turns a saved .prf script into one
  `then`/`spread` strategy; mirror proofs (`rightok_all` from `leftok_all`,
  `sok_right` from `sok_left`) were replayed with textual substitutions.
  Lesson relearned: `lemma` of a declaration LATER in the theory is a silent
  "No change" (`short_val` had to move up).

Verified: fresh `proveit -f walk_transfer.pvs` 69/69 (gate later, with the
whole-library run of the branch). Next down the chain: walk_same, root_cont,
tower_def/tower_ok/cell_ok/level_ok, cad_fast, cover, closed_pt, pt_local,
cells_local, inner_const, cad3; then walk_od's `_eq` twins and rd_norm.

## 2026-09-23 — the re-proof (branch s5e-redesign): sturm_sg, walk_def, walk_ok done

`sturm_sg` 38/38 on the reduced chain: `schain_at` (equality with `fchain`)
became the bridges `schain_prop` / `schain_len` / `schain_nth` /
`schain_sign` / `schain_lc` (entry-wise positive multiples; sign variations,
entry signs, leading signs and degrees are unchanged), with `prop_earr`,
`prop_dg`, `sign3_pos`; the fifteen dependent proofs redone through them.
`sturm_sg2` 7/7. `walk_def` 27/27. `walk_ok` 49/49 on the per-member walk:
the lifting's semantic core (`P`, `gapf?`, `mem_same`, `svec_sub`,
`walk_sound`, `walk_mid`) is unchanged; the bridge from the executable
conditions is `gapok_beta` / `gapok_none` (a gap with a member root holds
exactly one distinct root: per-member counts + pair-product coincidence,
`mem_one` / `pair_one` / `coins_mem`), `nzat_P` (no live member vanishes at
a separator, so the product does not), `left_P` / `right_P` (nothing outside
the ends), and `walk_fib` re-proved on those. `livea?` was taken OUT of the
trusted walk: a member identically zero at a cell is filtered by the
executable level (`feff` / `ins0` in towern_od), so the semantic layer keeps
its product.

## 2026-09-23 — walk_rd 50/50; one adjustment to the redesign

`walk_rd` re-proved on the per-member walk (determinacy per member and per
pair: `rootin_det`, `some_det`, `nzat_det`, `atmost1_det`, `coin_det`,
`coins_det`, `leftok_det`, `rightok_det`, `gapok_det`, `sepok_det2`,
`walk_det`). One adjustment: the PRODUCT's leading coefficient stays in the
certificate (`wok?`, `cert?`: one sign query per cell, no product chain) and
is one intrinsic read (`llast(bprod(F))` in `wi_rd`). Deriving it from the
members' leading coefficients would need syntactic facts about `mmul`'s
zero padding (`mmul` pads a zero top when a factor is a constant), which are
not worth proving; `mmul_length`/`lmul_len`/`pair_slc` (for pair products of
live members, length >= 2 each) are proved instead. The executable checks
the same sign (walk_od's `wok_t`), so nothing measured changes.

## 2026-09-27 — new machine; the n-level certificate fixed; N1-N5 of the finish (FINISH_PLAN 3i)

The repository moved to a new machine (`~/src/CAD`, PVS 8.1 built from
source with SBCL 2.6.8, NASALib 8.1).  Tools made portable (`tools/env.sh`,
`tools/setup.sh`: the repo's `.venv` for pvs-cli; no machine paths), proofs
through pvs-cli, `.prf` files written only by PVS.  Whole-library replay on
this machine: 2954 formulas, 2949 proved in 16 minutes; the five others are
towern_od TCCs that never had proofs.

**A soundness gap in towern_od's certificate** (found while planning the
proof, FINISH_PLAN 3i): only the queries of the walk directly below a section
were certified, so a separator or a section below a section used unchecked
answers of the section oracle (four quantifiers), and with one inner family
the top walk was never checked.  Fixed: `okqs(od, R)` certifies every answer
recursively down the descriptor, `lvok_o` (okqs + wok_t) at every level of
every cell, `cellok_o` keeps the closure.  Re-measured through (cad-mn):
ALL ALL ALL EX (w > x, y, z) ok TRUE val TRUE 17 s, its control 13 s, the
other four-quantifier examples 1-2 s, three quantifiers 0 s.

**The semantic groundwork, all proved:**
- `mpar` 13/13: near?, continuity of meval in every coordinate, persistence of
  finitely many signs in many parameters (msg_mpers).
- `zfam` 25/25: the effective family zf(F, ws) (the executable's feff) and
  insz; wrs, certz?, rdz? (the executable's clok? stated semantically: the
  reads, after rd_norm, are members of the family above, so their signs are
  read off its sign vector -- rdz_agree, rdz_vec); invz?, fib_constz,
  rf_invz.
- `mwalk`: wagree_near, fib_mlocal (the base of the tower induction: the fibre
  is locally constant with every coordinate moving), near_cells (the walk's
  separators, gaps, separator and section vectors unchanged near a point).
- `mroot`: mroot_near, root_near in many parameters (cnt_mlocal; root_cont's
  lemmas reused at a one-point set).
- `cvl`: the cell value list of a level (the shape of cellsf_o at the exact
  point), cvl_all (its members are exactly the values of the truth function
  when that function does not change across root-free intervals), bfold_cvl,
  cvl_eq.

Gates: mpar, zfam, mwalk, mroot, cvl PASSED.  Tooling lessons: a
lemma's free variables are instantiated in ALPHABETICAL order; `(use "l"
:subst ("x" "t" ...))` instantiates by name and is what to use; `(then A
(split) B C)` applies B and C to EVERY branch -- use spread; `(reveal *)`
recovers formulas lost to a bad hide-all-but; editing gate.sh while a gate
runs breaks it (bash reads scripts incrementally).

## 2026-09-27 — N6-N9: the n-level decision is proved correct (decn_correct)

The semantic core and claim A, then the decision itself, all through pvs-cli,
every theory gated (three fresh proveit runs + traces, zero warnings):

- `tclf` 26/26: the closure CLF of a tower, prefixes, the all-EX sentence, the
  three height-n statements CBh / LCh / CTh (guarded by cons?(TW), which the
  TCCs demanded), ct_step and cb_step.
- `tlc` 9/9: LCh at every height (lc_base from fib_mlocal; lc_step from the walk
  agreeing near the point, equal cell value lists, rfc_tw).
- `tower_sem` 3/3: tower_all by strong induction on the height; tower_cb and
  tower_ct, the forms the decision uses.
- `oddef` 15/15: den, wf?, okqs_agree (the recursive certificate makes each
  oracle right on the reads it certifies), opt_den / osec_den, feff_zf.
- `innern_sem` 19/19: claim A -- okn_o at a well formed descriptor gives
  innern_o IFF sem at den(od), and CLF there (ia_step by induction on the
  tower).
- `decn_ok` 22/22: the tower of a sector has k levels ending with F
  (lvln_shape, through zipadd / tclos_o), valid tables, the sample's
  descriptor exact and denoting the sample; inv_topreads (inv_chk on the
  normalized top reads gives invz? on an open sector: rd_norm scales by a
  nonzero constant, rdn_msg); sectn_sem (claim A at the sample + tower_cb
  along the sector); foldn_sem (sects cover the line, samples in their
  sectors); **decn_correct**: decn_o(qs, F, Psi)`ok IMPLIES
  (decn_o(qs, F, Psi)`val IFF sem(qs, F, Psi, null)) for every prefix of two
  or more quantifiers.

Lessons: `(then (case ..) X)` runs X on BOTH case branches -- use spread; a
qualified name is needed where two theories export one (cad_lift.cfuel);
pv.sh shows only the last lines of output, so a strategy's printf needs a
larger tail (pv.sh ... 60).

## 2026-09-27 — N10: (cad) on the n-level decision; towern_od's TCCs closed

- `cad_decide5_def` / `cad_decide5` 2/2: decq5 runs decn_o for three or more
  quantifiers and falls back to decide4's route (decw3 for three, decw for
  two, decide2) when its certificate is not TRUE, and for two quantifiers;
  decq5_correct from decn_correct and decq4_correct; decide5_correct for the
  strategy.  `(cad)` now cites decide5_correct (the theory must import
  cad_decide5); cad_examples, cad_examples2, cad_examples3 re-gated through it.
- `cad_examples4` 5/5: FOUR quantifiers by the single step (cad) -- e4_above
  (ALL ALL ALL EX: w above x, y, z) 17 s, e4_between (its FALSE control,
  refuted by (cad -1)) 13 s, e4_sum (ALL EX ALL EX) 5 s, e4_square
  (ALL ALL EX ALL) 3 s, wall clock through pvs-cli.
- towern_od: six TCCs had never been proved.  Five were true and needed only
  a controlled step (a sub-descriptor is smaller, lengths of tails, seps_t is
  never empty).  One was FALSE: secp_n called nroots on a member's
  specialization at the point, whose degree can drop to 0.  secp_n now skips
  such a member (deg > 0 guard): the members there are not identically zero
  (feff), so such a specialization is a nonzero constant with no root in the
  gap; oddef's secp_n_mem re-proved.  towern_od 38/38.

## 2026-09-27 — N11: close-out; benchmark table; a Bath problem by (cad)

**Whole-library replay** (`proveit -a top.pvs` in a scratch copy, this
machine): 3118 proofs, 3118 attempted, 3118 succeeded, 15 minutes (it was
2949 of 2954 before the finish; the new theories and the closed towern_od
TCCs make up the difference).  cad_bath, a leaf added after the replay, is
gated on its own.

**Benchmarks.** Wall clock of the whole proof by `(cad)` through the pvs-cli
server on this machine (Apple M5 Pro, 64 GB), decision by decide5:

| theory | sentences | prefix | per proof |
|---|---|---|---|
| cad_examples | ex_above, ex_zero, ex_sos, ex_circle, ex_circle2, ex_line, ex_disc, ex_three | 2-3 quantifiers | 1.1-1.5 s |
| cad_examples2 | ex_cubic, ex_quad, ex_amgm, ex_disc2, ex_meet, ex_quartic, ex_ell, ex_two, ex_hyp (FALSE, (cad -1)) | 2 quantifiers | 1.2-1.6 s |
| cad_examples3 | t_above, t_shift, t_sos, t_sphere, t_cone, t_between and t_sqrt (FALSE, (cad -1)) | 3 quantifiers | 1.2-2.0 s |
| cad_examples4 | e4_above | ALL ALL ALL EX | 16.8 s |
| | e4_between (FALSE, (cad -1)) | ALL ALL ALL EX | 13.3 s |
| | e4_sum | ALL EX ALL EX | 2.4 s |
| | e4_square | ALL ALL EX ALL | 3.3 s |
| cad_bath | bath_08_false (FALSE, (cad -1)) | EX ALL EX, degree 7 | 274 s |

**The Bath bank** (bench_pdec's ten closed problems), decn_o alone through
(cad-mn), 300 s limit each: bath_08 (Random B Grobner from Buchberger-Hong)
ok TRUE, val FALSE in 280 s -- now proved as cad_bath.bath_08_false; bath_01,
02, 03, 04, 05, 07, 09, 10, 12 did not finish.  Where the time goes, on
bath_01 (two quadrics, EX EX EX): the tower is (proj(F): 9 members, F), the
outer projection 34 members, 11 sectors to start with; the OUTER closure
nclos_o alone was still running when stopped after 22 minutes -- each round
recomputes the closed tower (tclos_o, all cells of every level) at every open
sector to collect the top reads it must keep invariant.  Sharing that work
across rounds (memoizing lvln_o per sector, or seeding the outer family with
the top reads once) is the obvious next step for speed.  It touches only how
the outer family Q is found: foldn_sem holds for ANY Q that passes gaps_ok and
the sector certificates, so decn_correct's proof carries over with only the
instance of Q changed.

## 2026-09-27 — performance, first stages (PERF_PLAN P1, P2, P4, P5, P7)

Profiled the evaluator (SBCL's sb-sprof and sb-profile on the compiled PVS
functions, scratch Lisp only).  The time went to the SAME pure computations
repeated: section oracles rebuilt at every sign query, 66,890 signs at one
algebraic sample with 302 distinct arguments (bath_08), every chain step
built about seven times per table entry, the family product recomputed for a
degree bound, the projection and each sector's tower rebuilt per sector and
per phase.  A scratch cache in front of two functions took bath_08 from 256 s
to 2 s -- not kept (unverified code on the trusted path); each fix below is in
the PVS executable, proved:

- P1 `chain_rd` 4/4: a chain and its reads in one pass (rchain2_cr_eq,
  schain_rd_eq); walk_od's mkce through it (mkce_eq; chain_t_eq, ird_t_eq,
  valid_cons re-proved).  bath_01, one sector's tower: 123 -> 34 s.
- P4 `alg_isign` 6/6: the sign at an algebraic number by an interval-Horner
  enclosure (NASALib interval_arith: Add_inclusion, Mult_inclusion) over the
  isolating interval, alg_sign2 otherwise (alg_isign_sign); the mix oracle
  uses it (mix_exact re-proved) and odS refines an algebraic sample 32 times
  first (refine_n; odS_den re-proved).  bath_08: 272 -> 7 s.
- P7: bk(F) is the sum of the live members' lengths + 2 instead of the
  length of their product; the certificates check the bound at run time, and
  every theory that mentions bk replayed unchanged.  bath_01 sector 34 -> 20 s,
  e4_above 12 -> 3 s.
- P2, P5: decn_o computes the initial tower once (lvln_o, nbads_o, nclos_o
  take it) and each sector's closed tower and tables once (scof), shared by
  the certificate (scok?) and the value (scval); decn_ok re-proved over the
  sector records (every_map_*, some_map_*).

Gated: chain_rd, walk_od, odreads, alg_isign, towern_od, decn_ok, alg_bis;
whole-library replay 3140/3140.  Measured through (cad-mn): e4_above 16 -> 4 s,
e4_between 13 -> 2 s, bath_08 256 -> 6 s.  bath_01..04 still run past 600 s:
on bath_02 the sector invariance check (inv_chk) is 60 % of the time, almost
all of it zero_at (0.31 s per test, 74 % of the tests true) -- next, P6b.

## 2026-09-27 — P6b: the zero test at an algebraic number through a gcd

`poly_gcd` 12/12: Euclid on rational polynomials (pmod, pgcd, fuel-bounded),
pgcd_root -- a point is a common root of p and q exactly when it is a root of
their gcd.  alg_zero's zero_at now decides "q vanishes at value(a)" by whether
the gcd with a's polynomial has a root in a's interval; the old sum-of-squares
test (renamed zero_sos, same proof) is the fallback when Euclid runs out of
fuel.  zero_at_def re-proved; every other proof is unchanged.  bath_02: the
zero tests fell from 0.31 s each (60 % of the time) to about 1 ms.  bath_08
now 2 s.  Gated: poly_gcd, alg_zero, alg_sign, sect_inv; whole-library replay
3155/3155.

Where bath_02 stands: its time is now in inv_chk's Sturm root counts on the
top reads -- 239 reads at one sector, degrees up to 102 (median 18): the
coefficients of the pair-product chains of the level-1 walk.  Refining each
sector's ends once (tried) halves the counts but makes each dearer; the reads
themselves have to become fewer and smaller (resultants instead of the chain
coefficients of products, or squarefree parts) -- a change in what the walk
certifies, not a cache.

## 2026-09-27 — R3: Sturm counts evaluated once per chain element (sturm_fast)

NASALib's roots_closed_int evaluates every chain element through reals'
polynomial (a sum of a(j) * x^j, each power recomputed) inside
number_sign_changes, which asks for each element up to three times.
`sturm_fast`: hornz (Horner on the integer coefficient list; hornz_poly: it is
polynomial), chvals (every element's value at x once), rcf (the same count:
rcf_eq -- rcf = roots_closed_int(.., TRUE, TRUE, ..)), hornA (Horner on an
array).  nroots_a (alg_count) and nroots_c (sect_inv) are rcf; alg_isolate's
nrh is the half-open count (nrh_eq: = number_roots_interval on hopen) and
alg_fast's nroots_hc (root isolation, isoc) goes through it.  Re-proved:
nroots_a_bij, nri_closed, nroots_hc_h, isoc_TCC3/5/7 (from iso's TCCs),
isoc_iso; nroots_c_def replays unchanged.  bath_02: the Sturm counts of the
invariance checks, 155 s per 300 s before, now about 3 s for 11,000 counts;
bath_08 1 s, e4_above 3 s.


## 2026-09-27 — (cad) on the Bath bank: fail fast, degree drops, witness first

Investigating why the Bath problems ran for hours found that several were not
slow at all: their certificate FAILED, and (cad) then fell back to decide2's
read closure (3^|F|), which never returns.  Three changes, in order.

1. **Fail fast** (cad_decide5_def).  decq5 is decn_o alone at three or more
   quantifiers, decw then decn_o at two (decn_o certifies problems decw's
   certificate refuses: the y = 0 slice of bath_05 fails decw in 0 s and passes
   decn_o in 0 s), decide2 at one.  No exponential fallback above one
   quantifier: a failed certificate now comes back at once, and (cad) says so.
   decq5_correct re-proved (decn_correct, decw_correct + rev2, decq2_correct);
   decide5_correct replays; decq5_TCC1/2 (the list shape at two quantifiers).

2. **Degree drops** (ztrunc, new; towern_od, zfam, oddef, odreads, innern_sem,
   decn_ok).  The walk asks for a nonzero leading coefficient at every cell
   (memok?/slc?), so a member whose leading coefficient vanishes at a cell --
   while the member does not -- failed the certificate there.  Measured:
   bath_02 with r = 1 is (2x^2-1)y^2 + 4x^2y + x^2 in y, and decn_o's
   certificate failed at exactly the two sections x = +-1/sqrt(2); a
   three-variable version failed after 35 s; bath_04 fixed at x = 1 failed at
   y = 1; ex_hyp (x*y = 1, leading coefficient x) had needed the fallback.
   Now the effective family at a cell truncates every member: ztrunc's tz(sg,
   l) removes the top coefficients the oracle says vanish (tz_eval: the value
   at every point above a point with a right oracle is unchanged; tz_top: the
   new top is nonzero; tz_agree: decided by the coefficient signs, which are
   reads of every certificate -- crd, moved here from zfam).  zf (semantic)
   and feff (executable) are the truncated families; the executable's reads
   are crd(F) ++ walk_rd's reads on the effective family through the table,
   and odreads now proves them EQUAL to the walk's (wi_rd_t_eq, we_rd_p_eq,
   with a valid table) instead of containing them.  Re-proved: zf_null,
   zf_cons, zf_mem (restated for the truncation), svec_insz, zf_agree; feff_zf,
   crd_wr; odreads 19/19 (feff_null, feff_cons, mi/pi/pairs/me/pe/pairse
   equalities, wi_sub, wi_agree, crd_wi, we_sub, we_agree); lvl_exact,
   rdz_cell; wrs_top.  Removed as superseded (their statements do not hold
   for a truncating family, and nothing used them): feff_idem, feff_mem,
   feff_filter, crd_mi.  The generic walk and its proofs are untouched.
   Measured after: reduced bath_02 certified in 3 s (proof 3.6 s), the
   three-variable version in 31 s (35 s), the bath_04 slice 0 s (2.3 s),
   ex_hyp's formula 1.3 s.

3. **Witness first** (pvs-strategies; the old (cad) is now (cad-direct)).
   (cad) tries, in order: a model search when one point settles the goal (an
   existential target: proving an existential sentence or refuting a
   universal one) -- the matrix compiled to Lisp closures, a small grid and
   pseudo-random rationals, the point confirmed by the ground evaluator, the
   proof instantiation and eval-formula; with three or more quantifiers the
   full decision if it answers within BUDGET (10 s); else ONE existential
   position of the target fixed to a small constant, the smaller sentence
   decided (BUDGET/2 each, 3 BUDGET in all), the proof a case split on it
   ((cad-direct) proves it) and instantiation (a constant witness does not
   depend on the outer variables, so it is one); else the full decision.
   Nothing new is trusted: the searches only choose.

Bath closed problems, before -> after (whole (cad) proof):

| problem | before | after | how |
|---|---|---|---|
| bath_01 ball and cylinder | > 30 min | 0.5 s | model search |
| bath_02 term rewrite | > 30 min | 12.4 s | r = 1, then the two-variable decision |
| bath_03 circle and square | > 30 min | 0.5 s | model search |
| bath_04 McCallum | > 30 min | 0.4 s | model search (0, 0, 0) |
| bath_05 Random A (false) | > 30 min | 11.8 s | y = 0, then the two-variable decision |
| bath_07 Random B (false) | > 30 min | 12.2 s | y = 0, then the two-variable decision |
| bath_08 Random B Groebner | 4.0 s | 5.0 s | full decision (checked within the budget first) |
| bath_09, 10, 12 Joukowsky, UHP | > 30 min | > 30 min | universal, no witness; open |

(Whole (cad) proofs on a quiet machine after one warm-up proof, commit
9c910b7.)  The 28 library examples prove in 0.8-3.9 s; at three or more
quantifiers the budgeted check before the full decision evaluates the
decision twice, so e4_above went from 2.8 to 3.9 s and bath_08 from 4.0 to
5.0 s.  The conflict probes: u1 2.0 s, u2 1.7 s, u3 41.5 s (37.4 s before;
the reduction is tried and cannot help there), u4 2.4 s.  The literature (Nalbach and Kremer 2024; Wilson, Bradford and
Davenport 2012) has the same split: the seven easy problems are decided in
milliseconds to seconds by tools that decide rather than build a full
decomposition (coverings, partial CAD), while the Joukowsky family times out
in every tool unless reformulated by hand.

## 2026-09-27 — strategies name formulas by fresh labels; robustness set

Every strategy in `pvs-strategies` now names the formulas it works on by
fresh labels (extrategies' `with-fresh-labels` and `discriminate`, as
NASALib's own strategies do) and never by position: no `-1`, `1` or
`(hide-all-but 1)` is left in a generated step.  Converted: mpoly-eq,
mpoly-simp, alg-roots, poly-pos, poly-nonzero, poly-sign, poly-nosign,
qe-exists, cad-direct and cad (model search, one-variable reduction,
reflection equations).  The only numbers left are the entry points' default
`(fnum 1)`; every entry point also takes a label.  Devices, each checked on
the server first:

- A fact the strategies add is split on as `case "id(FACT)"` (extrategies'
  own device, `cad-fact-case`), and each branch expands `id` first.  A plain
  `(branch (discriminate (case A) l) ...)` loses a branch that PVS closes on
  its own (a case on the goal itself) and moves `NOT A` across the sequent,
  so the branch steps shift.  That is what made `t_above` fail in the first
  version of the conversion.
- `flatten` copies a label onto every part of the formula it splits; `inst`,
  `skolem` and `skeep` take the first formula under a label they can act on,
  so the quantified conclusion of a flattened fact is found by its label.
- Nested `with-fresh-labels` with the same variable is scoped correctly
  (PVS's `subst-stratexpr`); labels are interned symbols, so a label must not
  be spliced into a Lisp lambda (mpoly-unfold__ builds its steps first).

Two old defects went with the positions.  (1) `(cad)` on a FALSE sentence in
the consequent, and on a TRUE one in the antecedent: the case split on the
answer was vacuous (PVS reads the hypothesis `NOT A` as the consequent `A`),
and the old step put the `cad` label on the decision record.  Now the
sentence stays, labelled `cad`, the record is deleted, and a message says
whether it is TRUE or FALSE.  (2) `(cad)`'s docstring said the theory must
import cad_decide5; it also needs mpoly_embed.

Checked: the 7 Phase 1-3 example theories (128 proofs) and the 5 (cad)
theories re-proved with proveit; edge cases on the server (false goal,
true hypothesis, label arguments, a sentence at formula 2 or -2 among other
formulas, model search in both directions, the reduction in both
directions, bath_01-05/07, the conflict probes).

**Robustness set** (scratch, not in the library): 100 closed sentences,
generated from small to large: 1-6 quantifiers, 44 different prefixes (every
mix of FORALL and EXISTS up to three quantifiers, a sample beyond), total
degrees 1-8, 1-4 atoms under AND, OR, NOT and IMPLIES, with =, /=, <, <=, >
and >=.  Z3 5.1 decided 99 of them (51 true, 48 false; one unknown); true
ones are proved by `(cad)`, false ones refuted by `(then (flatten) (cad -1))`.
Result (300 s cap, before the label conversion):

| quantifiers | sentences | proved | median | max |
|---|---|---|---|---|
| 1 | 16 | 16 | 0.6 s | 5.1 s |
| 2 | 22 | 21 | 1.6 s | 15.3 s |
| 3 | 22 | 22 | 2.2 s | 11.7 s |
| 4 | 20 | 20 | 2.7 s | 14.4 s |
| 5 | 12 | 12 | 3.3 s | 14.5 s |
| 6 | 8 | 6 | 4.3 s | 12.4 s |

No certificate failure and no answer contrary to Z3; rerun after the label
conversion, the same 97 proved and the same three not.  The three not proved
in 300 s: r038 (FORALL x EXISTS y, degree 6, false: the only refuting x is
the algebraic number -1.63834..., so no constant shortcut applies and the
full decision is the cost), r096 (six quantifiers, false only at z = -4/5,
which is not among the reduction's constants; rational roots of the atoms as
candidates would find it), r100 (six quantifiers; Z3 cannot decide it
either).

## 2026-09-27 — root candidates and folding; completeness plan; C1 (decide6)

**Witness constants from the atoms' roots.**  (cad)'s reduction fixed an
existential position only to 0, ±1, ±2, ±1/2, ±3.  Robustness sentence r096
is false only at z = -4/5, the root of its atom 5 * z + 4 /= 0.  Now each
position also tries the rational roots (rational root theorem on exact
Newton-interpolated coefficients) of every atom in that variable alone, and
the reduced matrix is FOLDED: atoms in the fixed variable alone are evaluated
exactly and the Boolean structure simplified.  A matrix that folds to TRUE
needs no decision at all (the proof is the instantiation walk and ground; this
is checked before the budgeted decision, at no cost); otherwise the smaller
folded sentence is decided as before.  r096: 300 s timeout -> 1.2 s; the
robustness set: 98 of 100 proved (r038, irrational witness; r100, which Z3
cannot decide either).  A bug found on the way: cadw-vars collected the
variables of an atom with mapobject, which reaches objects outside the atom's
own syntax and reported x in 5 * z + 4; it uses freevars now.

**Completeness plan (COMPLETENESS_PLAN.md).**  The user set the goal: (cad)
verified COMPLETE.  A review of every path to ok = FALSE: all five are fixed
fuel constants (sfuel2 = 24, gfuel = 64, ifuel = 64, tfuel = 12,
cfuel = 64); no check needs more than fuel (memok?/slc? by ztrunc, clok? and
inv_chk at the closures' fixpoints, the searches over finitely many
separable roots), and nothing needs delineability.  Canaries (C0), each
ok = FALSE within 2 s on the fast path, all TRUE: EXISTS x: 0 < x < 10^-25
(gfuel), FORALL y: EXISTS x: x > 10^8 (radius 2^24), roots 1/3 and
1/3 + 10^-8 (bisection depth 24), and the three-quantifier z > 10^8.

**C1: decide6 (cad_decide6_def, cad_decide6).**  decide6 = decide5 when its
certificate passes, else the complete Phase 5 decision decide (cad_decide,
decq_correct: no flag, no hypothesis, exponential).  decide6_correct:
decide6(reverse(os), F, phi) IFF fsem(os, F, phi, null), for every closed
prenex formula.  (cad :complete? t) and (cad-direct :complete? t) fall back
to decide through decide_correct_os when the certificate does not pass;
(cad) itself stays fail-fast.  The four canaries prove this way in 2-9 s.

## 2026-09-28 — C3: total refinement at the outer level; one-quantifier completeness

COMPLETENESS_PLAN stage C3.  The outer level's searches on exact algebraic
numbers no longer end in ok = FALSE when their fuel runs out: each fuelled
search still runs first (the fast path is unchanged), and when it runs out
a total one, by well-founded recursion on a positive distance that is not
computed, finishes the job, as alg_order's sepr and alg_isolate's iso do.

- cell1: `gapw` (a point between two distinct algebraic numbers; measure
  mwidth BY real_ord_ep(dist), sepr_step as the descent), `gapw_inv` by
  measure induction; `gap`/`gapok` fall back to it, so `gapok_lt` and
  `gaps_ok_incr`: gaps_ok holds on every strictly increasing list.
- sect_inv: `sepw` (two distinct roots separated), `clr1` (an end root that
  is a root of ql, refined until it is ql's only root in its interval;
  measure rwidth BY real_ord_ep(mrd(ql)), `clr1_step` from mrd_sep and the
  halving of real_ord_ep), `clrw` = clr1 or alg_sign's sep (`sep_sub`: sep
  only narrows), and the wrappers `sepx`, `clrx`.  The free tests use them;
  their soundness lemmas are re-proved, and they are now COMPLETE:
  `between_free_complete`, `below_free_complete`, `above_free_complete`,
  `whole_free_complete`, `inv_chk_complete` (a polynomial without roots in
  an open sector always passes), with `nroots_two` for the count.
- complete1: `svs1ok_complete`, `decq2_complete1`, `decq5_complete1`,
  `decide5_complete1`: **the fast decision answers every closed formula with
  at most one quantifier** (with decide5_correct, a verified complete
  decision there).  Canary k1 (EXISTS x: 0 < x < 10^-25), ok = FALSE before,
  proves on the fast path in 9 s.
- cad_lift's clos_TCC2 (fuel - 1 < fuel) was proved by termination-tcc,
  which grinds: its formula mentions samples, and grind now expanded the new
  gap into a timeout.  Proved directly instead.

## 2026-09-28 — C4, part 1: the Tarski query needs only p0 nonzero at the ends

COMPLETENESS_PLAN stage C4.  The bounded Tarski query of tower_def searches
(tlo/thi, tfuel = 12 probes) for ends where no entry of the Tarski chain
vanishes, because NASALib's sturm_tarski asks that of every entry.  The
standard theorem asks it only of the first polynomial.  sturm_tarski_ends
proves it: ends_inward moves both ends inward past no root of any entry
(constructed_sturm_roots_between_enum lists them); tsig_near shows the
sign-change count is unchanged between an end and such a point
(NASALib's nsc_edge_diff, with tss_opposite -- an entry vanishing at a
point has neighbours of opposite signs, from the remainder relation -- and
tss_no_two_zeros -- no two consecutive entries vanish where p0 does not,
from constructed_sturm_seq_repeated_root); sturm_tarski applies on the inner
segment; NSol_union_top and nsol_none carry the root sets back.  Gated
(11 proofs).  Next: the query at the gap's own ends, no search.

## 2026-09-28 — C4, part 2: section queries at the gap's own ends; queries complete

The bounded Tarski query now reads its chain at the two ends of the gap, with
no search.  tower_def: `qsecl` asks lo < hi, the vanishing member l0 nonzero
at lo and hi, and a Sturm count of one; its value is the sign-change
difference at lo and hi.  `tlo`, `thi`, `nzall?` and `tfuel` are removed.
tower_ok: `tchain_first` (the chain's first entry evaluates to l0), `tq_nsol`
restated on sturm_tarski_ends (only l0 nonzero at the ends), and `tower`
without any end hypothesis -- `one?` (one root strictly inside, none other in
the closed gap) already makes l0 nonzero at lo and hi.  qsec_rd: the reads
lose the search probes (`tlo_rd`, `thi_rd`, `nzall_det`, `tlo_det`,
`thi_det` removed); `sent_det` (the member's sign at an end is one of the
chain's entry reads there) re-proves `qsecl_det`; `qsec_det`, `qs_det`
replay unchanged.

cell_ok gains the first completeness facts below the outer level:
- `cnt_unique`: a unique root in (y0, y1] with nonzero ends counts one
  (from sturm_sg2's cnt_root and cnt_two);
- `secp_or`: secp returns the product or a member with a counted root;
- `secp_gap`: at a gap the walk above certified (`lvl?`), the member the
  query runs against is nonzero at the ends, vanishes at beta, and counts one;
- `qsec_ok_complete`: every query at such a gap is sound, and
  `allok_complete`: so is every list of queries.
`qsec_val` is re-proved on the new `tower` (sec_one at a = lo, b = hi).

## 2026-09-28 — C4 finished (od_exact) and C5: exact oracles, leading coefficients always nonzero

od_exact.  With the section queries complete, the executable's recursive
certificate `okqs` holds at every well-formed descriptor, on any read list
(`okqs_complete`, induction on the descriptor: a section's queries pass by
allok_complete at the exact oracle below and qs_det, since the oracle below
agrees with its point on everything by induction and oddef's okqs_agree).
Hence `wf_exact`: osg(od) = msg(den(od)) for every wf? od.  Every walk of the
cell tree below a certified level therefore runs at its point's own oracle,
which is what the remaining completeness stages need (C6 at exact oracles
only).

cert_all (COMPLETENESS_PLAN C5).  `certz_all`: certz?(F, ws) -- memok? of the
effective family and slc? of its live product -- holds at every point.
- `zc_iff`: a coefficient is structurally zero (zc?) iff it vanishes at every
  point (mpoly_unique's mnorm_eq_iff against zero); `strip_top`, `strip_at`
  (strip keeps a list whose top is nonzero at a point; it cuts exactly the
  structural zeros above the first coefficient that is not one).
- `prodl_above`: the product of coefficient lists has no coefficient above
  the sum of the degrees (NASALib polynomial_prod, sigma_restrict_eq_0);
  `prodl_top`: at that index it is the product of the leading coefficients
  (sigma_last), nonzero at ws when each factor's is; `prodl_strip`.
- `zf_top`, `lsumk_mem`, `lsd_lives`, `memok_zf`, `bprod_zf`.
With walk_transfer's wok_exist this says separators passing the walk's
certificate exist at every cell of every level.

## 2026-09-28 — C6: the walk's separator search succeeds at every exact oracle

COMPLETENESS_PLAN stage C6, at the level of one walk (walk_def's search).
- walk_fuel: `seps_n(F, sg, n)`, the search with fuel n; `seps_n_fuel`.
- walk_count: `cnt_ge` (a Sturm count is at least the number of distinct
  roots one lists: split at rational non-roots between them), `cnt_le_total`,
  `cnt_two_roots`, `nzat_P_iff` (no live member vanishes iff the product does
  not), and `stop_ok`: at an exact oracle with a certified family the
  bisection's stop test (atmost1? AND coins?) passes on every gap whose ends
  are not roots and where the product has at most one distinct root -- no
  condition on the chain entries at the ends (walk_transfer's versions
  needed them).
- walk_search: each search returns its first success, so success within
  some fuel is stable under more fuel (`spick_mono`, `sint_mono`,
  `swide_mono`); each search succeeds at an exact oracle:
  `spick_exists` (more than total(...) distinct probes cannot all be roots,
  cnt_ge against cnt_le_total), `sint_exists` (strong induction on the
  product's count in the gap; with two roots z1 < z2 inside, `sint_inner`
  inducts on a budget K: a child keeping all the roots keeps z1, z2 and is
  at least (z2 - z1)/2^(total+1) narrower, `spick_lb` -- no global root
  separation bound needed), `swide_exists` (`P_bounded` from lo_exist /
  hi_exist, `leftok_P`/`rightok_P` from left_pos/right_pos).
  `seps_ok`: cert?(F, msg(ys)) implies some fuel N with
  wok?(F, msg(ys), seps_n(F, msg(ys), n)) and seps_n(.., n) = seps_n(.., N)
  for all n >= N.
With C5 (certz_all) this holds for the effective family zf(F, ws) at every
point; with od_exact, at every well-formed cell of the tree.

## 2026-09-28 — C2: the fuel is a parameter of the n-level decision

COMPLETENESS_PLAN stage C2.  One `u: nat` is threaded from decn_o down to
every fuelled search: walk_od's `seps_t(u, F, od, tbl)` runs swide/sint with
fuel sfuel2 + u (`seps_t_eq`: it equals walk_fuel's seps_n at sfuel2 + u);
towern_od's tables, svs_o, innern_o, wr_t, lvok_o, okn_o, treads_o,
tclos_o, lvln_o (closure fuel cfuel + u), nbads_o, nclos_o (cfuel + u),
scof, scok?(u), scval, decn_o all take u.  `decn_correct` now holds for
every u.  cad_decide5_def calls decn_o(0, ...), so decide5, (cad) and the
examples are unchanged; the escalation over u comes in C8.  walk_def's seps
and the two-level decision are untouched.

Repairs: walk_od (seps_t_TCC1, seps_t_eq), innern_sem (7: lv_agree,
lvl_exact, innern_base, ia_sep, ia_sec, ia_step, innern_sem), decn_ok (7:
treads_len, tclos_shape, lvln_shape, sectn_sem, memn_ok, foldn_sem,
decn_correct), each by replaying its old script in pvs-cli with the new
signatures substituted and the extra u instantiated.

Verification (C6 + C2): gates passed for walk_fuel, walk_count, walk_search,
walk_od, towern_od, oddef, innern_sem, decn_ok, cad_decide5_def, cad_decide5,
complete1; whole library 3320/3320 (13 min); demos cad_examples 9/9,
cad_examples2 14/14, cad_examples3 9/9, cad_examples4 5/5, cad_bath 8/8.

## 2026-09-28 — C7: the closures reach their fixpoints

COMPLETENESS_PLAN stage C7.  The reads a closure can add come from a finite
list fixed by the initial tower, so the closures stop, and where they stop
the checks they close under pass.
- list_flat (generic): flat, pre?/prefs (every prefix is listed).
- read_univ: a Sturm chain's reads and elements at ANY oracle lie in lists
  computed from its inputs (rd_in, el_in, i_rd_in): sstep2 picks one of
  three candidates (s3cands), snorm_sg leaves a prefix (snorm_pre).
- read_fam: a level's intrinsic reads, at any cell with any valid table, lie
  in WU(F) (wi_t_in; the effective family is one of effs(F), feff_in);
  rw_in for the normalized lists the closure adds.
- tower_univ: tul(T0), each level's universe from the innermost up; tinv?
  (initial family + new members of the universe, no repeats) survives every
  round (treads_sub, zipadd_inv), so tsize <= tbnd(T0) (tinv_size, nd_len);
  tclos_fix / lvln_fix: u >= tbnd(T0) makes lvln_o a fixpoint.
- clos_ok: cells_o (a walk's cells), cellsf_every, cellsr_has, zipadd_zsub;
  fixp_clk: at a fixpoint cellok_o holds at every cell of every level.
- nclos_ok: memb_inv (a member of the outer family passes inv_chk on every
  sector of its roots: allroots_complete, sect_noroot, inv_chk_complete), so
  every bad read is new (nbads_new) and lies in rwall(tul(T0)) (nbads_in);
  nclos_fix: with enough fuel no bad read remains.
Gated: list_flat, read_univ, read_fam, tower_univ, clos_ok, nclos_ok.  TCCs
of recursive definitions whose bodies mention cells_o/cellok_o get explicit
proofs: the default TCC strategy loops on them.

## 2026-09-28 — C8: (cad)'s decision is complete

COMPLETENESS_PLAN stage C8.
- ev_pred, ev_nat: ev? / evc? over the escalation parameter u, ev_list
  (finite lists), lim.
- lev_ev: at a well-formed cell a level passes from some u on with fixed
  separators (lev_ok), its cells are table-independent and well formed.
- tower_ev: okn_split (okn_o = lvall? AND clk?); tower_ev by induction on
  the tower for eventually constant valid tables; tables_evc.
- clos_ev: the tower and outer closures are eventually constant (tclos_stop,
  lvln_evc, nclos_stop, nclos_evc_fuel); okn_ev.
- decn_complete: decn_ev -- for every family and >= 2 quantifiers,
  decn_o(u, ...)`ok for every large u.
- decide_u_def / decide_u: decn_u raises u from a start until the
  certificate holds (terminates by decn_ev; the bound is only in the
  measure); decn_u_correct, decn_u_complete.
- cad_decide5_def now uses decn_u(reverse(qs), F, Psi, 0) where it used
  decn_o(0, ...) (identical when u = 0 certifies, as in all the demos);
  cad_decide5's decq5_correct re-proved with decn_u_correct.
- complete_all: decq5_complete, decide5_complete, and
  decide5_decides: decide5(reverse(os), F, phi)`val IFF fsem(os, F, phi, null)
  for EVERY closed formula -- the decision behind (cad) always answers, and
  its answer is the truth.

Verification (C7 + C8): gates passed for list_flat, read_univ, read_fam,
tower_univ, clos_ok, nclos_ok, ev_pred, ev_nat, lev_ev, tower_ev, clos_ev,
decn_complete, decide_u_def, decide_u, complete_all, cad_decide5_def,
cad_decide5, complete1, cad_decide6 (cad_decide6_def, unchanged, has no
formulas: the gate's zero-proofs check flags it); whole library 3463/3463
(14 min); demos cad_examples 9/9, cad_examples2 14/14, cad_examples3 9/9,
cad_examples4 5/5, cad_bath 8/8 (each ~25 s longer: decide5 now imports the
completeness chain, typechecked once).

## 2026-09-28 — (cad *): the polynomial content of a whole sequent

CADSTAR_PLAN.md.  `(cad *)` (also `(cad -)`, `(cad +)`, `(cad (fnums))`)
collects every sequent formula that is a real quantifier prefix over a
Boolean combination of polynomial comparisons, treats every other real
subterm free of bound variables (constants, sqrt(x), f(a), nat variables)
as an unknown real, forms the closed prenex implication from the usable
antecedents to the usable consequents (an antecedent's quantifiers flip,
bound variables renamed apart, type facts of posreal/nnreal/... terms
added), and applies it by case: in one branch the goal follows by
instantiation/skolemization and prop, in the other (cad) decides the
formula.  Nothing new is trusted.  A FALSE formula is reported and the
sequent is left unchanged (finalize).  cad_star_ex: 15 sequents, 16/16.
Plain (cad) is unchanged (demos pass).

## 2026-09-28 — redundant imports removed

59 IMPORTING entries in 44 files named a theory (same library, same
instance) that another import of the same theory, at or before that point,
already brings in; they are gone (tools/redundant_imports.py; importing is
transitive and nothing in the library uses EXPORTING).  Position matters:
an IMPORTING takes effect where it is written, so an early import that a
later one repeats stays (a first attempt that ignored this broke
alg_examples).  top.pvs, the index, is unchanged.  Import paths through the
library (what PVS 8.1's post-typecheck circularity check walks, see
~/ITP_notes/pvs-circular-deps.md) drop from 910 million to 91 million from
top.  Whole library 3479/3479; demos and cad_star_ex pass.
tools/import_paths.py reports theories, edges and path counts per directory.

## 2026-09-28 — documents, playground theories, and where (cad) runs out

- docs/cad_overview.pdf (+ .tex, LaTeX via Tectonic): a three-page overview for
  readers who know theorem proving but not this effort -- the semantics fsem,
  decide5_correct, decide5_complete and decide5_decides as stated, how a (cad)
  proof is built and what is trusted, the stages, library totals (230
  theories, 3479 formulas proved: 2367 lemmas and 1112 TCCs, 18,200 lines of
  PVS, 1,890 lines of strategies, no axioms), measured times and limits.
- docs/cad_proof_traces.pdf (+ .tex): real transcripts of 14 (cad) and 7
  (cad *) proofs from a scripted `pvs -raw` session, plus the expanded
  (cad$) witness route, (cad-direct$ 1) on EXISTS x: x^2 = 2 in nine stages,
  and (cad$ *) on the discriminant sequent.
- Playground theories, deliberately NOT in top.pvs because they contain FALSE
  sentences and sentences (cad) does not finish: cad_demo (a first file to
  try (cad) in Emacs), cad_limits, cad_limits2, cad_limits3 (graded by
  variables, degree and Boolean structure; each lemma annotated with its
  measured time or "not done in N s").
- Emacs checked end to end with ~/.pvs.lisp (the circular-deps fix, see
  ~/ITP_notes/pvs-circular-deps.md): M-x typecheck of cad_demo returns to
  (PVS :ready) after 70 s; M-x prove and (cad) give Q.E.D.
- Found by an overnight run: m_cover20 (one variable, 42 atoms) answers in
  0.8 s but exhausts the 6 GB SBCL heap while the proof is BUILT.  The cause
  is cad-strategy's endgame `(expand "sign3") (repeat (lift-if)) (ground)`:
  every atom's sign3 becomes an IF and lifting them all makes a case tree
  exponential in the number of atoms.  Next: rewrite each atom with
  IFF-lemmas (sign3(v) = 1 IFF v > 0, = 0 IFF v = 0, = -1 IFF v < 0) so the
  unfolded skeleton has the goal's own Boolean shape and closes without
  splitting.  The heap itself is PVS_SBCL_DYNAMIC_SPACE_SIZE (MB, default
  6000) in bin/*/runtime/pvs-sbclisp.

## 2026-09-28 (night) — the endgame without a case explosion (ENDGAME_PLAN.md)

- (cad) used to close its proof with `(expand "sign3") (repeat (lift-if)) (ground)`,
  which builds a term exponential in the number of atoms: m_cover20 (42 atoms) exhausted
  the 6 GB heap.  Now each atom of the goal is restated as the sign conditions the
  decision reads (one small equation per distinct atom, proved by cad_endgame's three
  rewrites -- sign3(x) = 1 / 0 / -1 IFF x > 0 / x = 0 / x < 0 -- and ground) and
  replaced in the goal; goal and the formula from decide5_correct then share their atoms
  and bddsimp closes the goal.  The old endgame stays as the fallback, inside finalize,
  after a whole-sequent assert; it prints "cad: case-split endgame".
- Three things the development runs found: the unfolding's asserts must leave the goal
  as written (a whole-sequent assert reorders sums and moves disequalities), so they
  name the lemma formula and the two case facts by fresh labels (`(^ label)` is not a
  complement); bddsimp treats a real `a /= b` as its own variable, so both sides use
  NOT (... = 0); members with the same coefficient list take the FIRST member's text,
  as the reflection chain leaves it.
- cad_endgame (3 lemmas) and cad_endgame_ex (18 tests: every comparison and connective,
  TRUE/FALSE, a repeated atom, division, alternation, an irrational witness, a refuted
  hypothesis) gated.  Before/after (ENDGAME_PLAN.md section 4): the same result for every
  (cad) proof and benchmark; the 50-lemma timing suite 335 -> 306 s; m_cover10 37 -> 11 s;
  m_cover20 now 41 s; small implications +0.1-0.2 s.  70 decisions in the eight theories
  with (cad) proofs, zero fallbacks.  Whole library 3502/3502 (232 theories, 994 s).
- Also: docs/cad_overview.pdf (examples first, references, author and Claude footnote),
  README rewritten, NOTICE.md (third-party material), tools/pvs-circular-deps.lisp and
  its README (the PVS 8.1 import-check fix), machine paths removed, the JAR draft PDF
  removed (cited by DOI).

## 2026-09-29 — GAP_PLAN Tier 0: psc_det? is false; the record corrected

- GAP_PLAN.md (new) is the roadmap from decide5's verified decision to a verified CAD in
  the classical sense: Tier 0 correct the record, Tier 1 prove the run computes a CAD,
  Tier 2 QE output, Tier 3 Brown's reduced McCallum projection on open cells, Tier 4
  Collins only on a trigger.  Tiers 0 and 1 adopted.
- psc_det_ce (4 formulas, gated): psc_det?, described since 2026-09-18 as the only open
  statement of the projection route, is FALSE.  For f = y^2-3y+2, g = y-x, every member
  of projc has the same sign at x = 1/2 and x = 3 (ce_svec, evaluation), but (0,+) is
  realized over 1/2 (y = 1) and not over 3 (ce_fib_half, ce_fib_three); psc_det_false.
  The resultant x^2-3x+2 is positive at both points and negative between: g's root
  crosses both roots of f in between, which psc signs at two unrelated points cannot
  see.  Stage E of ITEM1_PLAN cannot work; the open obligation of that route is the
  sector-local delin_projc, which needs connectedness.  Nothing verified used
  psc_det? (a hypothesis of delin_from_psc only; psc_det_quad stands).
- Also corrected, by dated notes rather than rewrites: delin? is FIBRE-SET invariance,
  weaker than classical delineability ((y^2-x)(y-5) realizes {-,0,+} on every fibre
  while its root count is 1,2,3,2,3), so "delineability certified at run time"
  (walk_transfer, top.pvs, the overview) now says fibre-set invariance; cad_proj's
  operator is McCallum-shaped, not Collins'; projc has no reducta; NASALib's det IS a
  Laplace expansion (ring_det, CAD_PLAN); cad_meas5's inv1? gives delin_projc for that
  F, not psc_det?.  README, docs/cad_overview (rebuilt, 5 pages) and the paper notes now
  say "CAD-based decision procedure" until Tier 1C proves the run's cells form a CAD.
  Earlier entries here are left as written.
- Whole library 3506/3506 (233 theories, 978 s), replayed from the committed tree 44232cf;
  docs/cad_overview figures updated (233 theories, 3,506 formulas, 2,392 lemmas, 1,114
  TCCs, 18,367 lines).  GAP_PLAN.md trimmed of the draft public replies.  This state is
  the second public pvs_cad snapshot.

## 2026-09-29 — GAP_PLAN Tier 1A/1B: the n-level run computes a CAD

- Ten new theories, all gated; no existing proof changed.
  - cad_roots / cad_fibre: the roots over a point as a sorted list (rtl; rootat? = zeros of
    the members not identically zero on the fibre), the stack index sidx, the sign vectors
    at the roots and on the bands (rsvl, bsvl); the sign vector at a point is the entry its
    index names.
  - cad_gpar / cad_local: near a certified point with agreeing reads the stack is the same
    and every root moves continuously (from near_cells and mroot_near).
  - cad_conn / cad_stack: connected sets; delin_cl?, CLASSICAL delineability (roots listed,
    constant count, continuous root functions, every member sign-invariant on every section
    and band); stack_const: if the walk's reads keep their signs across a connected set,
    the family is classically delineable over it.  This turns decide5's run-time check
    into delineability.
  - cad_slab / cad_stkc: slabs over a connected set are connected; every cell of a
    delineable stack is one.
  - cad_tower: a certified tower over a connected base cell is a CAD (tower_cad); its
    cells partition the cylinder and the top family is sign-invariant on each.
  - cad_run: when decn_o's certificate holds, the cells (outer sector, stack indices)
    cover R^(k+1), are pairwise disjoint and connected, are the sections and bands of
    continuous root functions at every level, and F is sign-invariant on each (cad_run).
    The outer sectors partition the line (sects_disj, new).
- Tier 1A's two-variable trial run was skipped: the theorems are stated for any number of
  variables from the start.  Root indexing is by sorted lists (rl?), not system_roots_enum.
- Next: Tier 1C, the correspondence with the run's own cell descriptors and the CAD as
  returned data; then public wording ("verified CAD" becomes true for decn_o).

## 2026-09-30 — GAP_PLAN Tier 1C: the CAD as returned data; it decides every sentence over F

- Six new theories (82 formulas: cad_out 13, cad_out_ok 27, cad_fold 9, cad_fold_ok 23,
  cad_sample 6, cad_out_ex 4), each gated (three fresh runs + traces); no existing proof
  changed.  Whole library 3754/3754 (249 theories, 1051 s).  decide5's n-level engine now
  provably RETURNS its decomposition: finitely many connected cells partitioning
  R^(k+1), cylindrical over continuous root functions, F sign-invariant, as data that
  decides every sentence over F.  Still missing for a CAD in the sense of BPR Def. 5.1:
  semi-algebraicity of the cells (first-order definability, the plan's cad_spec); the
  1B entry and cad_run's header overstated this and are corrected (GAP_PLAN status,
  cad_run comment, top.pvs).
  - cad_out (executable): per sector of the run, the tree of the walk's cells -- kids lists
    the separators (bands) and the root gaps (sections) of a level with their stack
    indices; ctree follows them through the tower -- one record per path: sector, stack
    indices, exact sample descriptor (OD), and F's sign vector read by the descriptor's
    own oracle.  A band that holds several separators gets a record for each.
  - cad_out_ok: when decn_o's certificate holds, every record's sample lies in the cell
    (rcell) its sector and indices name, with F's sign vector there (osv_ok), and every
    nonempty cell has a record (cad_out_ok).  One level: kids_lvl -- the walk's children
    carry the stack indices of their points (twice the roots below, plus one at a root)
    and every index up to 2 nroot occurs; the tree: ctree_in, ctree_cover.
  - cad_fold (executable): a sentence is folded over the records -- the outer quantifier
    over the sectors, each inner one over the stack indices of the next level, Psi on the
    recorded sign vector at the leaf.
  - cad_fold_ok: afold_sem, a theorem about ANY cad_over? tower: when records lie in the
    cells their addresses name with F's sign vectors, every nonempty cell has one, and F
    has one sign vector per top cell, the fold of the inner quantifiers is their meaning
    at every point of the base cell (at each level the records' next indices are exactly
    the stack indices over the point: rec_idx, idx_rec, lvl_all, lvl_some).  cad_decides:
    when decn_o's certificate holds, the CAD computed ONCE by cad_out decides every
    sentence with the same polynomials and number of variables, whatever its quantifiers
    and Boolean combination of sign conditions.
  - cad_sample: every record's sample is a point of R^(k+1) with the recorded signs
    (rec_pt); a sign condition holds somewhere iff at some record (cad_sat: witnesses and
    counterexamples); the fold over a sector is the sentence's meaning at the sector's
    sample (cad_outer); and cad_complete: for every F and prefix of at least two
    quantifiers some u makes the certificate hold (decn_complete), so a CAD that decides
    every sentence over F is always obtained.
  - cad_out_ex: the unit circle -- certificate at u = 0 (2 s), 13 cells in 15 records, the
    recorded indices and sign vectors, and cad_out_ok for that F.
- The plan's tfold_fusion (fold = innern_o) was not needed: the fold is proved correct
  directly from the CAD properties (cad_run + cad_out_ok), so it holds for any CAD given
  as records.  Checked on the circle: cfold agrees with decn_o on 16 sentences (4
  prefixes x 4 sign conditions), each right by hand.
- Scope: decn_o (decide5's n-level engine: three or more quantifiers, and the fallback at
  two).  decw (the two-quantifier fast path) and decq2 are not covered (GAP_PLAN §9).
- Lesson: lemmas taking cdr of a list generate TCCs the typechecker leaves open
  (cad_out_mem_TCC1, sector_fold_TCC1, cad_outer_TCC1 failed first gates); run proveit -f
  once before gating.
- Next: semi-algebraicity of the cells (first-order definability; estimate 80-100
  lemmas) before any public "CAD" wording -- both with the user's approval; Tier 1D
  optional.

## 2026-09-30 — GAP_PLAN Tier 1 cad_spec: every cell is first-order definable; the run computes a CAD

- Five new theories (51 formulas: rcf_fol 19, rcf_cad_def 8, root_fol 13, rcf_cells 9,
  cad_verified 2), each gated (three fresh runs + traces); no existing proof changed.
  Whole library 3805/3805 (254 theories, 1110 s).  With them the run's output meets
  Basu-Pollack-Roy Def. 5.1: cad_verified (under decn_o's certificate) and cad_exists (some u
  always) state the whole definition in one predicate, cad_of?.
  - rcf_fol: a first-order language over the reals -- Fm (ftrue, fsg(p, t) = "p has sign t",
    fnot, fand, fex), fsem; variables are positions in the point list, head innermost, as in
    meval and sem.  mins(p, d) inserts a dummy variable at depth d of a polynomial and
    meval_mins proves it is evaluation with that entry deleted (pdel), for every point list;
    shiftF / fsem_shift lift that to formulas.  fod?(n)(S): S is definable in R^n.
  - rcf_cad_def (executable): rootF (a root over the point: rootat? as a formula, the
    "not identically zero" part under its own fex), geF(G, i) (at least i roots below),
    sidxF (the stack index), stkF / cellF (stack and tower cells), cmpF / sectF (the sectors).
  - root_fol: rootF_ok, geF_ok (i <= nlt of the root list; witness the i-th root via nlt_mem,
    nth_below), sidxF_ok (parity via hf_even/hf_odd/odd_even), stkF_ok.  The root lists exist
    at EVERY point (rl_all, from rtl_ok and certz_all), so none of this needs a certificate.
  - rcf_cells: meval_pmc (an algebraic number's polynomial as an mpoly, any tail), cmpF_ok
    (the root is unique in its CLOSED isolating interval, value_char), sectF_ok, scell_ok,
    cellF_ok (every tower, every definable base, every address no longer than the tower),
    rcell_ok / rcell_fod (every cell of the run is definable), sec_graph / graph_fod (the graph
    of the i-th root function over a cell is the stack cell 2i+1, hence definable).
  - cad_verified: cad_of?(u, qs, F) -- cells cover R^(k+1), are disjoint, connected and
    first-order definable, cylindrical over delineable families (cad_over?), F sign-invariant
    on each, and cad_out lists exactly the nonempty cells with a sample and F's sign vector.
- "Definable" is first-order definability with rational polynomial sign atoms.  Semi-algebraic
  in the quantifier-free sense follows by Tarski-Seidenberg, which is not formalized here;
  quantifier-free cell descriptions are GAP_PLAN Tier 2B/2C.  Scope as before: decn_o.
- Design: mapped and adversarially reviewed by a 4-agent workflow before proving (it caught
  the closed interval of Alg values and cut the plan from an 80-100 lemma estimate to ~20).
- PVS 8.1 bug: a datatype field of NASALib type Sign3 crashes the positivity check
  (OCCURS-POSITIVELY?*); the atom's sign is an int instead (~/ITP_notes).
- Lesson again: new definitions generate TCCs (mins_TCC3; cad_of? took cdr of a possibly empty
  list and had to be guarded) -- the quick proveit pass before gating caught both.

## 2026-09-30 — (cad :cad-only? t); cad_of? at every level; public wording reviewed

- (cad :cad-only? t): the decision only through the verified CAD engine.  cad_decide7_def /
  cad_decide7 (5 formulas, gated): decide7 = decn_u (decn_o from u = 0, raising u) for two or
  more quantifiers, decq2 for fewer; decq7_correct, decq7_complete, decide7_correct,
  decide7_decides.  pvs-strategies: cad-direct and cad-finish__ take the decision name
  (default decide5, so (cad) is unchanged); (cad) and (cad *) take :cad-only?, which skips
  the witness search and the two-level fast path and runs cad-direct with decide7.
- Timing, (cad) against (cad :cad-only? t), whole proofs, one at a time on a separate
  server (scratch/time_cadonly.sh; 300 s cap):
  - the 54 library examples (cad_examples 1-4, cad_endgame_ex, cad_demo, cad_bath): all
    proved both ways, 0.3-5.9 s each with (cad) (95.5 s in all), 0.8-4.5 s with :cad-only?
    (88.7 s in all) -- the shortcuts buy nothing there;
  - Bath 01-04 (existential): (cad) 0.4 / 13.3 / 0.6 / 0.5 s by witness search; :cad-only?
    over 300 s on each -- there the witness search is what decides;
  - Bath 08 (false): FALSE both ways, 6.1 s / 1.8 s;
  - Bath 05 and 07 (false), stated as goals: over 300 s both ways -- a false goal cannot use
    the witness search.  In their refutation form ((...) IMPLIES FALSE, (then (flatten) (cad
    -1)), as bath_08_false in cad_bath and as measured at 9c910b7): (cad) 13.1 s and 13.4 s
    (11.8 / 12.2 s then), :cad-only? over 240 s.  No regression.
- cad_of? strengthened after an adversarial review of the public text (3 reviewers + merge):
  connectedness and first-order definability of the cells at EVERY level (rcf_cells
  rcell_ok_le, rcell_fod_le), and definability of the graph of every root function of the run
  over a cell of the level below (graph_fod applied in cad_verified), so "BPR Def. 5.1, with
  first-order definable in place of semi-algebraic" is exact.  Two new index TCCs (run_shape).
- Public wording (README, docs/cad_overview, rebuilt, 6 pages): "a verified CAD algorithm and
  a verified, complete decision procedure"; scope (decn_o, two or more variables), the
  certificate hypothesis, cad_out as a companion function (at least one record per nonempty
  cell), "same variables, same order" for cad_decides, delineability in the sign-invariant
  sense (delin_cl?), NASALib's saved proofs in the trusted base, the Rocq comparison
  (Vermande proves Collins's projection delineating), "multivariate" in the novelty
  sentence, the Motzkin sentence, the one-variable case and quantifier elimination as open.
  top.pvs descriptions, cad_run's header, GAP_PLAN status, setup.sh's library list corrected.
- Gates: cad_decide7, rcf_cells, cad_verified (three fresh runs + traces each; cad_decide7_def
  has no formulas).  Whole library 3814/3814 (256 theories, 1184 s), including every (cad)
  proof under the changed strategies.  Overview figures: 256 theories, 3,814 formulas (2,609
  lemmas and theorems, 1,205 TCCs), 20,133 lines of PVS, 1,964 lines of strategies.

## 2026-10-02 — License: CC0 1.0 instead of "All rights reserved"

- README: the copyright statement ("Copyright (c) 2026 J. Tanner Slagel. All rights reserved") is
  replaced by a CC0 1.0 waiver: to the extent possible under law, J. Tanner Slagel has waived all
  copyright and related rights to this work.  The library was generated with Claude models
  (README, "How it was made"), and the author does not claim copyright on it.
- LICENSE: the CC0 1.0 Universal legal code, as published at
  https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt.
- NOTICE.md: the waiver does not cover the third-party material (the Bath problems, CC BY-SA 4.0;
  tools/pvs-circular-deps.lisp, BSD 3-Clause), which keeps its own license.
- README, "How to cite": a request (not a condition) to cite pvs_cad, as PVS specifications and
  proofs (BibTeX @misc).  No CITATION.cff: that format describes a repository only as software
  or a dataset, and pvs_cad is neither.
