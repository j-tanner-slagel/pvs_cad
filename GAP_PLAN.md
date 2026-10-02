# Closing the gap between decide5 and "verified CAD" in the classical sense

> **Status.** 2026-09-29: plan adopted; Tiers 0 and 1 started.
> - **Tier 0 (correct the record): done 2026-09-29.** `psc_det_ce` proves
>   `NOT psc_det?(ceF)` (4 formulas, gated); dated corrections in cad_delin,
>   delin_bridge, subres, sturm_habicht, cad_proj, cad_projc, ring_det,
>   cad_meas5, walk_transfer, top.pvs, ITEM1_PLAN, CAD_PLAN, PERF_PLAN;
>   README, docs/cad_overview and paper notes re-scoped to "CAD-based decision
>   procedure" until Tier 1C.  Whole library 3506/3506; synced to the public `pvs_cad`.
> - **Tier 1A/1B: done 2026-09-29.** Ten theories (cad_roots ... cad_run, 166 formulas):
>   stack_const (sign-invariant reads imply classical delineability) and cad_run (the
>   n-level run's cells form a cylindrical decomposition adapted to F; definability
>   below).  Whole library 3672/3672.
> - **Tier 1C: done 2026-09-30.** Six theories (cad_out, cad_out_ok, cad_fold,
>   cad_fold_ok, cad_sample, cad_out_ex): cad_out returns the decomposition as records
>   (sector, stack indices, exact sample, F's sign vector); cad_out_ok: they name, at least
>   once each, exactly the nonempty cells of cad_run's decomposition; cad_decides: that one
>   decomposition decides every sentence over F (any quantifiers over the same variables
>   in the same order, any Boolean combination); cad_complete: one is always obtained.
> - **Tier 1 cad_spec (first-order definability of the cells): done 2026-09-30.** Five
>   theories (rcf_fol, rcf_cad_def, root_fol, rcf_cells, cad_verified): every cell of the
>   run, at every level, is defined by a first-order formula over the reals with rational
>   polynomial sign atoms (rcell_fod_le), and so is the graph of every root function over
>   a cell of the run (graph_fod, applied in cad_verified).  cad_verified: under decn_o's
>   certificate the run computes a CAD of R^(k+1) adapted to F in the sense of BPR Def. 5.1
>   (semi-algebraic in the sense of first-order definable; its agreement with the
>   quantifier-free definition is Tarski-Seidenberg, not formalized) -- cells cover and are disjoint,
>   connected and definable at every level, cylindrical over delineable families, F
>   sign-invariant -- returned as data (cad_out); cad_exists: some u always gives one.  "Definable" is first-order
>   definability; semi-algebraic (quantifier-free) follows by Tarski-Seidenberg, which
>   is not formalized here -- quantifier-free cell descriptions are Tier 2B/2C.
>   [Superseded 2026-10-01: Tarski-Seidenberg is formalized (qelim_ok's fod_qfd), and cad_sa's
>   cad_cells_sa gives these cells' quantifier-free definitions -- through qelim, not Tier 2B/2C.]
> - **`(cad :cad-only? t)` and public wording: done 2026-09-30.** cad_decide7_def /
>   cad_decide7 (5 formulas): decide7 = decn_u for two or more quantifiers, decq2 for
>   fewer; decide7_correct, decide7_decides; `(cad :cad-only? t)` uses it.  README and
>   docs/cad_overview say "verified CAD algorithm", scoped to decn_o in two or more
>   variables, with the limits stated.  Open: the one-variable case as one theorem.  [Closed
>   2026-10-01: col_line's col_cad_line (the sectors of the real roots of F form a CAD of the
>   line adapted to F; decq2 decides on them) and col_cells (every number of variables).]
> - **cad_found (the complete CAD function): done 2026-09-30.** cad_found_def /
>   cad_found_ok (6 formulas): cad_found(qs, F) raises u from 0 until the certificate holds
>   and returns the CAD's records; cad_found_cad: for two or more variables it always
>   returns a CAD adapted to F (cad_of?); cad_found_decides: its records decide every
>   sentence over F.  No hypothesis on u remains.
> - **Tier 2 stage 1 (QE, one free variable): done 2026-09-30.** qe_def / qe1_ok (46 formulas with
>   helpers): qe1_correct -- under the run's certificate the output holds at x iff the bound
>   quantifiers do; qe1_u_ok -- raising u always reaches the certificate; the output is
>   quantifier-free whenever the sign-separation check passes (qe1_qf).  (cad-qe) replaces a prenex
>   formula in one free variable by its proved quantifier-free equivalent.  Plan and status:
>   QE_PLAN.md.  EP/epc_ok done the same day: qe1_complete -- every prenex formula in one free
>   variable has a computed, proved-equivalent quantifier-free form.
> - **Tier 2 stage 2 (QE, any number of free variables): done 2026-09-30.** qe2_def / qe2_ok /
>   qe_all (93 formulas): qe_correct -- for every m >= 1 the computed formula holds at a point of
>   R^m iff the prenex formula does; quantifier-free for m = 1 always, for m >= 2 whenever the free
>   cells' signatures separate (reported).  (cad-qe) takes any number of free variables.
> - **Tier 2C (always quantifier-free): done 2026-09-30.** qe_thom ... qe2c_full (8 theories,
>   about 150 formulas): the run with the free families closed under the formal derivative
>   separates every sector's free cells (Thom's lemma), the augmentation stops inside a finite
>   universe, and qe_all's qe_complete: for every m >= 1 and prenex formula over sign conditions,
>   qe computes an equivalent quantifier-free formula -- quantifier elimination for the reals
>   (Tarski-Seidenberg), computed and proved.  Applying it to the cell definitions (rcf_cells'
>   first-order formulas) needs a prenex normal form for rcf_fol, not done; until then the cells
>   are semi-algebraic in the sense of first-order definable.  [Superseded 2026-10-01: no prenex
>   normal form was needed -- qelim eliminates from the inside out (qelim_ok), and cad_sa gives
>   the cells' quantifier-free definitions; see below.]
> - **Tier 4 (Collins' projection): adopted 2026-10-01.** The measurement gate passed on the
>   benchmark families (quadratic n = 3: 11 cuts against the read closure's 179; n = 4 reachable)
>   and was mixed on Bath (small for bath_01/02/05/08, explodes on the dense quartic bath_04).
>   Plan, measurements and proof architecture: COLLINS_PLAN.md.  M-A (determinants: kernels in
>   both directions via NASALib, column linearity) done the same day.  [Tier 4 was completed the
>   same day too: next line.]
> - **2026-10-01: Tier 4 done (COLLINS_PLAN.md).** col_stack's collins_stack: Collins's
>   N-reducta projection is delineating, in the sign-invariant sense delin_cl? (root
>   multiplicities are not tracked), for every input; cad_projn's projn_ok ties it to the
>   executable operator projn.  col_line's col_cells: the Collins cells form a CAD adapted to F in
>   every number of variables, one included (col_cad_line), with no certificate.  col_found_ok's
>   col_found_cad: col_found returns that CAD as data, with the search for u built in;
>   col_found_decides: its records decide every sentence over F in the same variables, in the
>   same order.  decide8 (for two or more quantifiers) and qe8 run on the Collins tower
>   (cad_decide8, qe8).
> - **2026-10-01: Tier 2 finished, with no prenex normal form.** qelim (qelim_def, proved in
>   qelim_ok: qelim_qf, qelim_ok) eliminates the quantifiers of every rcf_fol formula from the
>   inside out; fod_qfd: fod?(n)(S) IFF qfd?(n)(S) -- first-order definable = quantifier-free
>   definable, Tarski-Seidenberg for formulas over Q (rational coefficients, no real parameters).
> - **2026-10-01: the cells are quantifier-free definable (cad_sa).** col_cells_sa (every cell of
>   the Collins CAD at every level, and its root graphs) and cad_cells_sa (every cell, at every
>   level, of the n-level engine's CAD): Boolean combinations of sign conditions on polynomials
>   with rational coefficients -- semi-algebraic sets defined over Q, so semi-algebraic in the
>   sense of Basu-Pollack-Roy (whose definition allows real coefficients, a larger class).
> - **2026-10-01: formulas of any shape: FORMS_PLAN.md** (gform_ok's decide_g_ok and qe_g_ok;
>   IMPORTING pvs_cad).  Whole library 5142/5142 (355 theories, 2086 s), 2026-10-01; after the review fixes,
>   5183/5183 (355 theories, 2209 s, 2026-10-02).

## What remains (2026-10-01)

Only items the plans list; the roadmap below is the plan as of 2026-09-29.
- **A smaller projection with a delineability proof**: McCallum's or Brown-McCallum's, at first
  Tier 3's Brown reduced McCallum projection on full-dimensional cells with its G/F decision
  (3A, 3B); COLLINS_PLAN.md names a smaller projection (McCallum / Brown) for the Bath problems
  as next.  cad_proj defines a McCallum-shaped operator (the n-level engine starts its read closures
  from it, under its run-time certificate); nothing about its delineability is proved.  General McCallum and Brown-McCallum on all cells, and Lazard, are
  under "Not planned" in section 4 (analytic delineability; Puiseux with parameters).
- **The witness search on top of decide8** (COLLINS_PLAN.md, "Next": keep it, improve it -- CAD
  sample points, partial CAD, numeric search).
- **The Bath problems that time out with both engines** (bath_02-05, 07, 09, 10, 12: no answer
  within 90 s from decc_o or decn_o at u = 0, cad/PROGRESS.md 2026-10-01; there the profile of
  bath_04 puts the cost in the size of the projection, and the remedies named are a smaller
  projection, equational constraints and square-free factors; section 4, "Not planned", lists the
  published routes).
- **Tier 1D** (optional): a static projection operator read off the walk; not done.
- **Optional geometry** (Tier 1B, section 7 item 8): cells homeomorphic to open cubes, or
  path-connected; not proved.
- **QE output and speed items left in QE_PLAN.md section 12**: answers for two or more free
  variables are not merged into intervals as for one; the exact-zero test by the remainder modulo
  the sample's polynomial is not done.
- **A NASALib proof-chain check** of the theories the library imports (sections 2.11 and 6.1):
  not recorded as done.

*[2026-10-01: the roadmap is kept as written. The status header above records what was done since, and dated notes mark the main statements below that it overtook. Under `IMPORTING pvs_cad`, `(cad)` now decides through `decide8` (the Collins run for two or more variables), not decide5.]*

*Final roadmap, 2026-09-29. It combines five research reports, four plans, three reviews, twelve claim verifications and one critique. Nothing was edited and no prover was run. Labels used below:*
- *PROVED: the theory is in `cad/top.pvs`'s import closure with saved proofs. The whole library replayed 3502/3502 as of 2026-09-29 (cad/PROGRESS.md:4516; for the current count see the status header). This is relative to NASALib's saved proofs, which were not replayed here (§2.11).*
- *STATED: exists only as a predicate, a hypothesis or a comment.*
- *PROPOSED: part of this roadmap. Every name below that is not already in the repository is a placeholder.*
- *"Checked by reading": confirmed against the files for this report, but not checked by PVS.*

---

## 0. Short answer

1. **The gap is missing definitions and one global theorem. The analysis underneath is already there.**
   - decide5 is proved sound and complete, and its computation is cylindrical.
   - The library already proves the analytic core:
     - continuity of roots: `root_cont.root_near` (cad/root_cont.pvs:68), `mroot_near` (cad/mroot.pvs:49) and complex `croot_near.root_near` (cad/croot_near.pvs:56);
     - local sign-invariance of F near section and separator points in Rⁿ (`near_cells`, cad/mwalk.pvs:45-53);
     - fibre-set constancy along sectors (`fib_const`, cad/walk_transfer.pvs:259; `sect_delin`, cad/cad_fast.pvs:44).
   - What is missing:
     - a notion of a cell as a connected subset of Rⁿ for n ≥ 2;
     - root functions indexed by root number;
     - a step from local to global over cells that are not convex;
     - then the theorem that the run's cells form a CAD adapted to F.
   - Estimate: **3.5–7 days, 180–350 proved formulas** (Tier 1). The day range assumes about 50 formulas a day, which is the class-C pace. So the risk is the formula count, not the rate.
   - After Tier 1C, "an executable, formally verified CAD" becomes literally true. It is scoped to decide5's n-level engine `decn_o`, which `(cad)` runs for three or more quantifiers and as the fallback at two.
2. **A verified projection operator is a separate and harder goal.**
   - The cheapest named case is **Brown's reduced McCallum projection on full-dimensional cells** (Tier 3). The operator is from Brown 2001, and Strzebonski's 2000 "generic projection" is the same operator.
     - This is the regime of QEPCAD B's measure-zero-error mode, the F/G quantifiers, and rational samples only.
     - The mathematics is elementary, and part of its analysis (`croot_near`) is already proved.
     - Cost: **7–16 days on top of Tier 1's connectedness layer**.
     - As far as three literature searches found, no prover has a delineability proof for McCallum, Brown or Lazard.
     - It is not Brown 2001's full theorem, whose lower-dimensional cells need McCallum's analytic theory. It is also not Brown–McCallum 2020, which is about Lazard.
   - A possibly cheaper route, **not verified** by any reviewer: a static operator read off the walk itself (Tier 1D, perhaps 1–3 days after Tier 1).
     - It would give a proved delineating operator, but not a named one.
     - Its size is unknown.
   - Collins' theorem with reducta costs about **16–32 days and 600–1500 formulas**. It would be the second formal proof after Rocq, and it should wait for a concrete trigger (Tier 4).
3. **Quantifier elimination.**
   - With one free variable it is 1.5–2.5 days, from the proved `sectn_sem` and `memn_ok` (Tier 2A).
     - This gives the QE step that exact DAIDALUS bands need. It does not give the bands themselves.
     - The existing baseline is the branching QE `qtree_sound`: one ∃ with any number of free parameters.
   - With several free variables it needs Tier 1 first, then 1.5–3 days (Tier 2B).
4. **Do this first: correct the record (0.5–1 day, Tier 0).**
   - `psc_det?` is called "the only open statement" (cad/top.pvs:1076-1078). As a universal statement it is **false**.
   - F = (y²−3y+2, y−x) at x = ½ and x = 3 is a counterexample, and a non-defective one. It was checked by hand against the library's own definitions, but not yet in PVS.
   - The "equivalently" that ties it to `delin_projc` is wrong (top.pvs:1110-1113, cad_delin.pvs:86-88). `delin_projc` is sector-local and still open.
   - Public text overstates what is proved in the README, the paper title and the overview.
5. **Performance.** No tier targets the open closed-sentence Bath problems.
   - There are two distinct ones: Joukowsky, duplicated as bath_09 and bath_10, and Upper Half Plane, bath_12.
   - Their matrices mix = and ≠ atoms, so open-cell Brown–McCallum is **unsound** for them, not merely slow.
   - Tiers 2A and 2B do target problems `(cad)` cannot handle today: parametric questions, which are 48 of the 78 Bath entries (PROGRESS.md:33-34).

---

## 1. The gap in plain language

### 1.1 What is verified today (PROVED)

decide5 decides every closed prenex sentence of real arithmetic: rational polynomials, any Boolean skeleton, any quantifier prefix.
- The theorems are `decide5_correct` (cad/cad_decide5.pvs:18-19), and `decide5_complete` and `decide5_decides` (cad/complete_all.pvs:19-20).
- The semantics `fsem` is defined with PVS's own real quantifiers (cad/cad_decide.pvs:91-97).
- "Closed" is a convention, not a hypothesis. The theorems hold for every F and φ, and any variable beyond the prefix is read as 0 (mpoly_def.pvs:12, 52-53).
- No axioms are used beyond datatype-generated ones (mpoly_adt, btree_adt, PolyExpr_adt).
- The proofs are relative to NASALib's saved proofs. That is why PVS labels 2696 of the 3502 formulas "proved - incomplete" in the whole-library summary (/tmp/cad_scratch/endgame/after_all/top.summary; explained at PROGRESS.md:922-933).

How it works:
- It isolates roots exactly and walks rational separators with a sign oracle.
- It grows each level's polynomial family to a fixpoint of the polynomials the lifting reads (`nclos_o`, `tclos_o`).
- It checks at run time that those reads keep their sign on each outer sector (`inv_chk`, `clok?`, `wok_t`, `okqs`).
- The dispatch (cad_decide5_def.pvs:26-32):
  - three or more quantifiers go to `decn_u` (`decn_o` with a rising parameter u);
  - two quantifiers try `decw` first and fall back to `decn_u`;
  - one or none go to `decq2`.

What the proofs already establish:
- The outer family is sign-invariant on the outer sectors, which is a genuine one-dimensional CAD (`sect_svec`, `memb_inv`).
- Every fibre over every sample the run visits is decomposed exactly (`walk_fib`, cad/walk_ok.pvs:210).
- Along an outer sector, the truth of every prenex formula over F is constant, and so is the set of sign vectors realized in each fibre (`tower_cb`, `tower_ct`).
- Continuity of roots and local sign-invariance, all conditional on read agreements that are certified at run time:
  - `root_cont.root_near` (root_cont.pvs:68);
  - `mroot_near` (mroot.pvs:49), with every coordinate moving;
  - `croot_near.root_near` (croot_near.pvs:56), for complex roots;
  - `near_cells` (mwalk.pvs:45-53), local sign-invariance of F at section and separator points in Rⁿ.

### 1.2 What a CAD specialist means

A CAD of Rⁿ adapted to F is:
- finitely many **connected, semi-algebraic cells** that partition Rⁿ;
- arranged **cylindrically**: over each lower cell C, the cells are the graphs of continuous root functions ξ₁ < … < ξₖ on C and the bands between them;
- with **every f in F sign-invariant on every cell**. This follows Basu–Pollack–Roy, ch. 5.

"Verified CAD" then means one of two things:
- **(i)** An algorithm is proved to construct such a decomposition. The Rocq development of Cohen, Djalal and Vermande (paper: Vermande, CPP 2026) is of this kind.
- **(ii)** A named **projection operator** (Collins, Hong, McCallum, Brown–McCallum, Lazard) is proved *delineating*: if the projection is sign-invariant on a connected cell, the input's roots over that cell are finitely many continuous functions that do not cross.

Specialists also expect **quantifier elimination** with free variables as output.

### 1.3 Why the two differ

1. **The proofs never reach whole cells of dimension 2 or more.** Root continuity and local sign-invariance are proved (§1.1). What is missing:
   - (i) a notion of a connected cell in Rⁿ for n ≥ 2. Connectedness exists only for real intervals (`loc_const`), and the run's cells are descriptors that denote points (`den`, oddef.pvs:42-49);
   - (ii) a global theorem that F is sign-invariant on a whole section or band cell;
   - (iii) any theorem that sign-invariance of a projection gives delineability. [2026-10-01: (i) and (ii) were supplied by Tier 1 (cad_conn, cad_stack, cad_run, cad_verified); (iii) by Tier 4 for Collins's projection (col_stack's collins_stack, cad_projn's projn_ok).]

   The proofs avoid (i) and (ii) on purpose: FINISH_PLAN.md:155-156 says "Only the OUTERMOST variable needs connectedness".
2. **There is no projection theorem.** Each level's family is computed on demand and certified at run time. Correctness does not depend on the seed (`proj`, which is McCallum-shaped), so nothing about McCallum or Brown–McCallum follows from decide5. [2026-10-01: there is one now for Collins's projection (collins_stack); still none for McCallum or Brown–McCallum.]
3. **The library's "delineability" is weaker than the classical notion.**
   - `delin?` (cad/cad_delin.pvs:39-41) says only that the *set* of sign vectors realized on the fibre is constant along a one-dimensional sector.
   - Example: F = {(y²−x)(y−5)} realizes {−,0,+} on every fibre, so `delin?` holds on all of R. Yet its number of distinct roots is 1, 2, 3, 2, 3 on x < 0, x = 0, 0 < x < 25, x = 25, x > 25.
   - Classical delineability over a connected set implies fibre-set constancy, but not the other way round.
4. **The classical projection route is only conditional.**
   - `dec2_sem` (cad_delin.pvs:72-79) is proved given `delin?`.
   - `decn_sem` and `pdecide_sem` (cad_decn.pvs:99-111) are proved given `decok?`, which is never discharged (§2.4).
   - The one unconditional instance is a single member of degree ≤ 2 (`psc_det_quad1`, psc_det_quad.pvs:57).
   - The bridge predicate `psc_det?` is false as a universal statement (§2.1).
5. **decide5 decides only closed sentences.** Some parametric QE exists:
   - `qtree_sound` (cad/qe_tree.pvs:48-50) does verified QE for one ∃ with any number of free parameters. It decided the unwindowed DAIDALUS question in 8 s, but no variant of the windowed one finished in 25–47 minutes (PROGRESS.md:794-801).
   - `sem_peel` (cad/cad_decide.pvs:79) is stated for all ys, but it is exponential (3^|F|).

   Neither handles a general prefix at useful sizes. [Superseded 2026-09-30 / 10-01: quantifier elimination with free variables is proved for every prenex formula with at least one quantifier and m >= 1 free variables (qe_all's qe_complete, qe8's qe8_complete) and for every first-order formula (qelim_ok's qelim_ok); QE_PLAN.md.]

### 1.4 Public text that currently overstates (checked by reading)

| Where | Text | Problem |
|---|---|---|
| README.md:1, :6 | "a verified, complete CAD decision procedure"; "The procedure is cylindrical algebraic decomposition (CAD)" | No theorem says the run produces a CAD (until T1C) |
| paper/main.tex:10 | "An Executable, Formally Verified Cylindrical Algebraic Decomposition in PVS" | Same |
| docs/cad_overview.tex:196 | "delineability and separation are certified at run time" | What is certified is sign-invariance of the reads. That gives fibre-set invariance, not classical delineability |
| docs/cad_overview.tex:234-236 | "the first executable, proof-producing CAD that is formally verified sound and complete and is usable as a tactic" | Defensible only as "decision procedure in the CAD family" until T1C |
| cad/top.pvs:1076-1078 | "psc_det? is the only open statement" | `psc_det?` is false (§2.1) |
| cad/top.pvs:1110-1113; cad/cad_delin.pvs:16-19, 86-88 | "ONLY remaining correctness obligation … equivalently … same psc signs" | The equivalence is wrong. `delin_projc` is sector-local and strictly weaker than `psc_det?` |
| paper/main.tex:35 (LaTeX comment) | "Rocq (Cohen, Djalal, Vermande 2026): correct, not executable" | Needs precision, not retraction. The authors are right for the development; the CPP paper is by Vermande alone. The lifting uses the choice-based `rootsR`, so it is not practically executable, and no runs are reported |
| PERF_PLAN.md:121-122 (internal) | "every published tool times out on them without a hand reformulation" | Contradicted by Chen–Moreno Maza (ICMS 2014): RegularChains CAD solved a Joukowski instance in under a minute after mechanical negation and splitting |

---

## 2. Facts that shape the plan

1. **`psc_det?` is false for some two-member families. So ∀F. psc_det?(F) is false.**
   - `psc_det?` (delin_bridge.pvs:33-35) is pointwise: equal `projc` signs at *any* two points should give equal fibre sets.
   - Counterexample: F = (y²−3y+2, y−x) at x = ½ and x = 3.
     - Expanding the library's own definitions by hand (cad_projc.pvs:25-51, subres.pvs:40-63, ring_det.pvs:39-45), the members of `projc(F)` have signs (+,−,+,+,−,+,+,−,+,+) at both points.
     - Among them, psc₀(f,g) = x²−3x+2 exactly, with value ¾ at x = ½ and 2 at x = 3. The coefficient −x is negative at both points.
     - The sign vector (0,+) is realized at x = ½ (take y = 1). It is not realized at x = 3, where g = −2 and −1 at the roots of f.
   - The case is non-defective: lc, disc and res are nonzero at both points. So the run-time checks of ITEM1_PLAN.md:36-44 do not rescue it.
   - The failing step is Stage E (ITEM1_PLAN.md:74-77, sturm_habicht.pvs:62-64). The order of roots of different members cannot be read off psc signs at two unrelated points.
   - The real open obligation is `delin_projc`, restricted to one sector. It needs a connectedness or root-continuity argument, which ITEM1_PLAN claimed could be avoided.
   - Soundness is unaffected:
     - `psc_det?` appears only as a hypothesis (`delin_from_psc`, delin_bridge.pvs:42-45) and in the proved single-member instance (psc_det_quad.pvs:57);
     - decide5 and complete_all never mention it.
2. **`projc` has no reducta, and `proj` has no squarefree basis.** Low confidence, worked by hand.
   - Take f = (: x, −2, 1, 0 :), which has a structurally zero top coefficient. Every psc entry is 0. The fibre is {−,0,+} at x = ¾ but {+} at x = 2, and both points lie in the one `projc` sector x > 0.
   - So even the sector-local `delin_projc` probably needs a "normalized members" hypothesis.
   - Whether this bites depends on how `allroots` treats the zero polynomial (cell1.pvs:55-60).
   - For f = (z²−x)², disc ≡ 0, and `proj` misses x = 0.
3. **NASALib's determinant is a first-row Laplace expansion.** The only det on list matrices is nasalib/matrices/matrix_props.pvs:102-107. NASALib also proves:
   - row multilinearity and the alternating property (matrix_props.pvs:149-226);
   - `det_mult` (matrix_diag.pvs:94-95), `det_transpose` (matrix_inv.pvs:107-108) and `invertible_det` (matrix_inv.pvs:72).

   It has no adjugate and nothing named kernel or rank.
   - The comments claiming otherwise are **factually wrong**: cad/ring_det.pvs:12-14, CAD_PLAN.md:86, CAD_PLAN.md:503 and PROGRESS.md:733-735.
   - A bridge from `rdet` to `det` holds only for n ≥ 1, since det(null) = 0 but rdet(0,·) = 1, and `Square` needs rows > 0. So the easy half of "common root ⇒ resultant = 0" needs m+n ≥ 1.
   - The converse direction (det = 0 ⇒ a kernel vector) takes a few lemmas: `diag_det_zero_row` (matrix_diag.pvs:87-89) plus `diag`'s postcondition and `det_transpose`.
   - NASALib's own summary marks 349 of the 526 matrices formulas "proved - incomplete" (nasalib/summaries/matrices.summary).
4. **No delineability theorem can make the existing `pdecide_sem` or `decn_sem` unconditional.**
   - Their hypothesis `decok?` (cad_decn.pvs:85-96, 109-111) includes `in?(s, rsv(s))`.
   - That clause is false at any `at`-sector where `rsamp` finds no exact rational, because `rsv` then falls back to 0 (cad_pdec.pvs:73-75). This covers every irrational root, and also rationals such as 1/3 whose defining polynomial is not linear.
   - `pdecide`'s tower iterates the McCallum-shaped `proj` (cad_pdec.pvs:93-95), not `projc`.
   - `pdecide` already has an `ok` flag, `okpts` (cad_pdec.pvs:114-127), that checks exactly these rational-sample conditions, and `rsv_exact` (:90) turns them into `in?(s, rsv(s))`. The other clauses follow from `sortu_incr`, `svs1ok_complete` and `sval_in`.
   - So a Collins result on the rational route needs two new pieces: (a) a `projc` tower, and (b) a theorem "okpts ∧ delineability ⇒ decok?".
   - That result would only be "ok ⇒ correct", and `ok` is FALSE on every Bath problem (PROGRESS.md:2158-2166).
   - An unconditional, complete projection decision needs algebraic samples: `alg_dec`'s `dec2a` (alg_dec.pvs), or ITEMA_PLAN.md:136-139 (A6).
5. **Tier 1's premises exist, and two pieces are new.**
   - What exists:
     - `wok_exist` (walk_transfer.pvs:175-176) at (zf(F,vs0), vs0), plus `certz_all` (cert_all.pvs:59, which holds everywhere), give exactly `near_cells`' hypotheses. This chain is already used in mwalk.prf and tlc.prf.
     - Agreement of the reads across a cell is available one level at a time. CLF holds at the outer sample (innern_sem.pvs:127-130). `tower_ct` on the one-dimensional outer sector, with `in_conv`, carries it along the sector. `CLF_flat` (tclf.pvs:71-72) then gives `rdz?` at every point above it. Finally `rdz_agree` (zfam.pvs:92-93) gives agreement of the reads on any set where the family one level down is sign-invariant.
     - That last condition is the Tier 1 induction hypothesis, not an existing lemma. `tower_ct` needs no re-proof in higher dimensions.
   - What is new:
     - (a) an invariant indexed by root number. The walk's rational separators are valid only locally (mwalk.pvs:46-47).
     - (b) a step from local to global over non-convex cells in Rⁿ. Every existing globalizer is one-dimensional: `loc_const` (loc_const.pvs:15-17, 42), `in_conv` and `tower_ct`.
6. **The `ok` flag of `decn_o` depends only on u, F and the prefix length** (towern_od.pvs:303-311). It does not depend on Psi or on the quantifier kinds. So one certified run can serve every sentence over F in that variable order.
7. **Algebraic endpoints use closed isolating intervals** (alg_def.pvs:22, :30). QE output must write x = value(a) as p(x) = 0 ∧ lb ≤ x ≤ ub.
8. **decide5 does lift over irrational algebraic points**, through `mix`/`sec` descriptors and Tarski queries. It avoids algebraic-number *arithmetic*, not algebraic *samples*.
9. **Tier 1 covers `decn_o` only.** `decw`, the two-quantifier fast path, has its own architecture, and there `sect_delin` gives only fibre-set `delin?`. `decq2` is one-dimensional, where `sect_svec` is already a CAD.
10. **The existing branching QE is the baseline for Tier 2A.**
    - `qtree_sound` decided cw1, ∃t: (5−t)² + (t/2)² < D², in 8 s, as three branches on the sign of D²−5 (PROGRESS.md:794-797; qe_symbolic.pvs:32-35).
    - Three windowed variants did not finish in 25–47 minutes: closed window, open window, and t(10−t) > 0. They are documented at qe_symbolic.pvs:37-43 but not stated as formulas. Coefficients reached degree 30 or more in D (PROGRESS.md:798-801).
11. **New NASALib dependencies need a proof-chain check.** NASALib summaries mark these formulas "proved - incomplete":
    - matrices: 349 of 526;
    - Tarski: 425 of 515, including `poly_systems`;
    - topology: 4 of 154.

    The CAD replay does not re-establish them. The existing dependencies (reals, polynomials) carry the same label (§1.1), so one NASALib proof-chain check or replay covers all tiers.
12. **No computer algebra system is installed.** qepcad, sage, maple, mathematica, z3 and cvc5 are not on PATH, and python3 has no sympy. Cross-checks must use hand-computed examples, or an unbudgeted install. Building QEPCAD B from source on macOS 27 is an unknown.

---

## 3. How effort is estimated

**Calibration from this repository**, recomputed by the verifier from git and PROGRESS.md:

| Class of work | Measured | Examples |
|---|---|---|
| A: architecture on an existing base | 270–340 net formulas per calendar day (9/27: +271; 9/28: +340) | N1–N11: about 177 genuinely new formulas (206 net, but 32 of towern_od's predate it) in 2.7–3.0 active hours. C0–C8: 313 net in 7.2–9.6 active hours (16.2 h wall clock) |
| B: textbook theorem with NASALib support | under 1 h to ½ day per theorem | `thom_encoding_distinct` 35 min; `root_near` about 1 h; `sturm_tarski_ends` under 1 h |
| C: classical CAD mathematics without scaffolding | 61–115 formulas per day (9/16–9/20) | the `psc_det` chain: 75 formulas in 1.17–1.5 calendar days |

For scale, the whole library is 3502 formulas over 17 dates in PROGRESS.md (19 in git).

How to read the numbers below:
- "Days" are calendar days at this project's pace: you direct, and Claude proves through pvs-cli under `tools/gate.sh`.
- Historically a day meant roughly 3–10 hours of attended session time. CLAUDE.md:34-41 requires proving in the main conversation, in visible steps with no background agents, so every day below needs you present for much of it.
- "Formulas" include TCCs, at about 1.45 per named lemma.
- The day ranges already assume a pace near class C, about 50 formulas per day. At class-A rates Tier 1 would take 0.5–1.3 days. **The risk is the formula count, not the rate.** Tier 1 exceeds its upper bound only if it goes past about 420 formulas.
- Class-C figures should be treated as ±2×. Phases 0–3 of the calibration used earlier models (Fable 5.1, Opus 5).

Four risk factors recur in the history:
- false mathematical claims inside plans (5 recorded, including `psc_det?`);
- re-proof cascades (about 380 formulas on 09-22/23);
- nonlinear-arithmetic and `grind`/`ground` blow-ups;
- tooling incidents.

**Overheads.**
- Already inside the historical day rates: gate runs (three fresh `proveit` runs plus traces per file), top.pvs description blocks and PROGRESS entries.
- Not inside them, so allow about **+0.5–1 day per tier that has one**:
  - Lisp strategy code (about 200–300 lines for `(cad-qe)` and the Tier 3 dispatch, with no calibration row);
  - untrusted prototypes (`cad_tree`, the Brown–McCallum prototype, a multivariate gcd that does not exist yet);
  - a full replay before any public proof count changes (994 s each);
  - syncing to the public `pvs_cad` repository.
- **Paper writing** is not estimated. Intro, Background, Related work, Application and Conclusion are stubs (paper/main.tex:23-38, :729-733, :874-880), and no venue or deadline has been named.

---

## 4. The roadmap

Gate outcomes marked **[your decision]** change what gets proved. CLAUDE.md:45-47 says never skip, defer or weaken a lemma, so these are yours to take, not the prover's.

### Tier 0: Correct the record

**Goal.** Nothing false or overstated remains before specialists look.

**What it takes.**
- A new theory `psc_det_ce` (PROPOSED):
  ```
  ceF: list[list[mpoly]] = (: f, g :)        % f = y^2 - 3y + 2, g = y - x
  ce_svec:       LEMMA svec(projc(ceF), (: 1/2 :)) = svec(projc(ceF), (: 3 :))   % ground evaluation
  ce_fib:        LEMMA fib(ceF, (: 1/2 :))((: 0, 1 :)) AND NOT fib(ceF, (: 3 :))((: 0, 1 :))
  psc_det_false: THEOREM NOT psc_det?(ceF)
  ```
  - `ce_fib`'s negative half is a small real-arithmetic lemma: f(z) = 0 ⇒ z ∈ {1, 2} ⇒ g(z) < 0.
  - Optionally bank the no-reducta example with explicit points.
- Comment fixes. Dated notes, not rewrites of history:
  - cad_delin.pvs:11-19 and 81-92;
  - the delin_bridge.pvs header;
  - top.pvs:1076-1078 and 1110-1113;
  - subres.pvs:13-21;
  - sturm_habicht.pvs:52-65 (Stage E cannot work as stated);
  - cad_proj.pvs:3, which calls the McCallum-shaped `proj` "Collins" (cad_projc.pvs:7 names it correctly);
  - ring_det.pvs:12-14;
  - cad_meas5.pvs:8: check it. It is a conditional ("if inv1? … holds"), probably fine.
- The headers of fib_quad, quad_det, quad_sign, quad_set, psc_quad1 and psc_det_quad are **correct as written**, since they concern single members of degree ≤ 2. Leave them.
- Plans: ITEM1_PLAN.md:1 and 74-77; CAD_PLAN.md:86 and :503; PERF_PLAN.md:121-122.
- Add a dated PROGRESS.md entry. Do not rewrite earlier entries.
- Public text:
  - README.md:1 and :6;
  - paper/main.tex:10 and :35;
  - docs/cad_overview.tex:196 and :234-236;
  - make_card.py and make_card_surface.py, if the cards will be reused.

- **Keep the name `delin?`.** Correct its comment to "fibre-set invariance" and add the classical notion under a new name in Tier 1. A rename would force re-proving `.prf` files, which are written only by PVS (CLAUDE.md rule 8).
- Optional, machine time only: a NASALib proof-chain check for the theories the library imports (§2.11).

**Effort.** 0.5–1 day, 5–20 formulas. Class A. Re-gate only the theories whose text changed.

**Risks and gate.**
- Sign conventions are not a risk: the verifier found psc₀ = +(x²−3x+2) under the library's convention, and both points agree either way.
- Fallback if needed: F = {(z−5)(z−7), z−x} at x = 4 and x = 8.
- Go/no-go: `ce_svec` evaluates to TRUE and `ce_fib` proves.

**Benefit.**
- Removes the one mathematically false claim a reviewer can find.
- Re-scopes the open obligation correctly: sector-local, with normalized members.
- The finding itself deserves a sentence in the paper.

---

### Tier 1: Prove that the run computes a CAD

This is the core answer to reading (i) of "verified CAD".

**1A. Two variables first, plus an executable prototype (the go/no-go stage).**
- Before proving anything, write `cad_tree` as untrusted executable code, in its own theory (CLAUDE.md rule 9).
- Ground-evaluate it on the unit circle, a sphere and ex_line, and compare cell counts with hand counts. A minimal projection gives 13 cells for the circle and 25 for the sphere.
  - More cells than that is acceptable, because the closure adds outer roots.
  - A band with no sample means the plan is wrong.
  - No CAS is available for comparison (§2.12).
- Then prove `stack_const` for n = 2, where the base C is an interval and `loc_const_iff` suffices.
- Root indexing: build on NASALib `system_roots_enum` (nasalib/Tarski/poly_systems.pvs:20), a sorted enumeration of all real roots of a finite system with nonzero leading coefficients. Apply it after `zf`'s truncation. Do not use `card` over epsilon-defined zero sets.
- 1–2 days, 40–80 formulas.
- **Gate:** if root indexing fights back for more than about a day, switch the proof to walk-relative indexing: count the root-holding gaps below, and prove the count does not depend on the separator list.
  - This changes the proof, not the `cad?` statement.
  - `roots_finite` (alg_count2.pvs:33) covers closed rational intervals only.

**1B. n levels.** Key statements (PROPOSED):
```
% cad_conn -- points innermost first; near? = mpar.pvs:25-28 (sup-norm ball, same length)
lcon?(Phi, C): bool = FORALL p0: C(p0) IMPLIES EXISTS (d: posreal):
    FORALL p: C(p) AND near?(p, p0, d) IMPLIES (Phi(p) IFF Phi(p0))
conn?(C): bool = FORALL Phi, p, q: lcon?(Phi, C) AND C(p) AND C(q) IMPLIES (Phi(p) IFF Phi(q))
cont_on?(r, C): bool                                   % epsilon-delta continuity on C
conn_int:   LEMMA conv?(S) IMPLIES conn?(LAMBDA p: length(p) = 1 AND S(car(p)))  % loc_const_iff
conn_graph: LEMMA conn?(C) AND cont_on?(r, C) IMPLIES conn?(graph(C, r))
conn_band:  LEMMA conn?(C) AND cont_on?(r1, C) AND cont_on?(r2, C) AND (r1 < r2 on C)
              IMPLIES conn?(band(C, r1, r2))           % plus below / above / whole variants
% cad_stack
nroot, rt, sidx                                        % root count, i-th root, stack index (via system_roots_enum)
delin_cl?(G, C): bool   % CLASSICAL: nroot constant on C; each rt(., i) continuous on C;
                        % svec(G, cons(y, p)) depends only on sidx(G, p, y)
lstable?(G, C): bool    % the same, locally at each point of C
stack_glob:  THEOREM conn?(C) AND lstable?(G, C) IMPLIES delin_cl?(G, C)
stack_const: THEOREM conn?(C) AND C(p0) AND (FORALL p: C(p) IMPLIES agree(msg(p0), msg(p), wrs(G, p0)))
               IMPLIES delin_cl?(G, C)                % lstable? from near_cells + mroot_near
% cad_spec (about 60 lines, independent of the internals, BPR Def. 5.1 style)
cad?(n, F, K): bool     % partition of R^n; cylindrical over continuous root functions;
                        % every cell conn? and definable by a first-order formula;
                        % every f in F sign-invariant on every cell
cad_run:   THEOREM length(qs) >= 2 AND decn_o(u, qs, F, Psi)`ok
             IMPLIES cad?(length(qs), F, run_cells(u, length(qs), F))   % also every tower family
cad_total: COROLLARY n >= 2 IMPLIES EXISTS u: cad?(n, F, run_cells(u, n, F))   % decn_complete / decn_u_complete
```
- **Mathematics.**
  - The CAD definition follows BPR ch. 5.
  - Semi-algebraicity is included as first-order definability, which is cheap: root-index conditions are formulas that `sem` interprets. Quantifier-free cell descriptions need 2B/2C. [2026-10-01: obtained instead through qelim and fod_qfd (cad_sa's cad_cells_sa, col_cells_sa).]
  - Cells homeomorphic to open cubes follow from the graph/band recursion but are not proved here (optional).
  - Connectedness is the "locally constant ⇒ constant" form. For subsets of Rᵏ this is exactly topological connectedness. The optional bridge to nasalib/topology/connected_def.pvs costs about ½ day.
  - The band proof: Φ on a vertical interval equals Φ at a continuous midpoint section, by `loc_const`. On that section's graph Φ is locally constant, hence constant.
  - The induction invariant: F_{j−1} is sign-invariant on a connected level-(j−1) cell C.
    - Base: the outer sector, which is convex (`in_conv`), with `inv_topreads` giving agreement of the reads.
    - Step: agreement of the reads of F_j on C, by §2.5's chain. Then `stack_const`, then `conn_graph`/`conn_band` for the new cells.
- **Alternative for the local-to-global step**, to choose at 1A: re-run the tower induction (tclf.pvs:91-105: CBh/LCh/CTh) with a structure-valued invariant (root count and the sign vector per index) in place of the boolean `sem`. It needs only one-dimensional `loc_const`. Connectedness of the resulting cells is then `conn_graph`/`conn_band` alone.
- **Reused (PROVED):**
  - mpar and mwalk (`near_cells`), mroot (`mroot_near`);
  - walk_transfer (`wok_exist`), cert_all (`certz_all`);
  - zfam (`rdz?`, `wrs_det`, `rdz_agree`, `rf_svecz`);
  - tclf, tlc and tower_sem (`tower_ct`, `CLF_flat`), innern_sem;
  - loc_const, decn_ok (`inv_topreads`), decn_complete, decide_u, cad_fast (`in_conv`), sect_svec.
- **New:** cad_conn, cad_roots, cad_stack, cad_spec, cad_run. **No proved theory is edited.**
- 1.5–3 days, 90–170 formulas.

**1C. Correspondence with the run, and the CAD as returned data.** Only this stage makes "the procedure *computes* a CAD" true. 1B shows that a CAD with the run's shape exists.
```
cells_sidx:   THEOREM ... the run's cells_o over den(od) hit every odd stack index exactly once
                (sections) and every even index at least once (separators in one band)
cad_tree(u, n, F): list[CellRec]      % address, OD sample, sign vector via osg; one record per cell
cad_path(u, n, F, v): ...             % one root-to-leaf path, enough for a counterexample point
tfold_fusion: LEMMA tfold(qs, Psi, ctree_o(u, TW, TB, od)) = innern_o(u, qs, TW, TB, Psi, od)
cad_decides:  THEOREM cad_o(u, n, F)`ok IMPLIES FORALL qs, Psi: length(qs) = n IMPLIES
                (tfoldS(qs, Psi, cad_o(u, n, F)) IFF sem(qs, F, Psi, null))
cad_exact:    THEOREM ... every recorded sign vector equals svec(fam, den(od)) at a well-formed descriptor
```
- Reuses `cells_o` (clos_ok.pvs:30), `svs_o`, `lvl_exact`, `wf_exact`, `opt_den` and `osec_den`. The one-variable case restates `sect_svec`.
- `cad_o` always calls `decn_o`, escalating u as `decn_u` does. It never calls `decw`.
- A full `cad_tree` can be very large: one bath_02 sector already has 239 reads of degree up to 102 (PERF_PLAN.md:86-94). `cad_path` is the practical output.
- 1–2 days, 50–100 formulas.

**1D (optional; a route to a proved static operator, unverified).**
- The idea:
  - The reads are `wrs(F,p) = crd(F) ++ wi_rd(zf(F,p), msg(p))` (zfam.pvs:80).
  - `wi_rd` (walk_rd.pvs:96) depends on the oracle only through the sign-dependent normalization in the remainder chains: `schain` (sturm_sg.pvs:46), and `snext2_sg` = `snorm_sg(sstep2(…, sg), sg)` (sg_chain2.pvs:27-28).
  - So the union of reads over all sign branches, P_walk(F), is a finite set determined by F alone. It consists of the coefficients, the remainder-chain construction reads and leading coefficients of each member, of each pairwise product and of the product of the live members.
  - With one membership lemma, "every read at every point is (up to `rd_norm`) in P_walk(F)", plus `sign_rdn`/`rdz_agree` and `certz_all` (the certificate holds everywhere), Tier 1's `stack_const` gives: *P_walk(F) sign-invariant on a connected C ⇒ F classically delineable over C*.
- That is a delineability theorem for a static projection operator. It is Collins-like, but built from signed remainder sequences rather than subresultants, so it is **not a named operator**.
- Checked by reading for this report only; no reviewer has examined it.
- **Gate:** before proving anything, enumerate P_walk as untrusted code on ex_line, the circle and one Bath family. Stop if the branch count explodes (it can be exponential in chain length).
- Guess: 1–3 days, 40–120 formulas, after 1B.
- Benefit: an honest answer to "which operators are formalized": one, proved delineating; not yet Collins or McCallum.

**Tier 1 total (1A–1C).** 3.5–7 days, 180–350 formulas.
- Class A for the local layer and the induction skeleton, plus one new local-to-global step on the scale of the N5–N9 work. That series was logged in one day (PROGRESS.md:3846-3890).
- Above about 420 formulas the upper bound is exceeded.

**Risks.**
- Root indexing: the bridge to `system_roots_enum`, epsilon choices, TCC load.
- Composing continuity through `near?`, the history's nonlinear friction.
- Duplicate separators, and `sec` descriptors with two or more algebraic coordinates (1C).
- An unproved plan claim. The reviewers found no obstacle, but the history's false plan claims argue for proving n = 2 first.

**Benefit.**
- **Claim that becomes true after 1C:**
  > "For every finite family F of rational polynomials in n ≥ 2 variables, pvs_cad's n-level procedure builds, with proof, a cylindrical algebraic decomposition of Rⁿ adapted to F: finitely many connected, definable cells, arranged cylindrically over continuous root functions, with every polynomial of F sign-invariant on every cell and an exact sample in every cell. The procedure is total. Its projection sets are a fixpoint of what the lifting reads, certified at run time, and a proved theorem shows that sign-invariant reads imply classical delineability."
- It makes paper/main.tex:10 and the README literally correct. Keep "(cad) computes a CAD" scoped: at two quantifiers `(cad)` may answer through `decw` (§2.9).
- **Community.**
  - CAD specialists get a `cad?` definition, about 60 lines, that they can audit.
  - `stack_const` is a delineability theorem for a method that replaces a fixed operator's theorem with determinacy plus a run-time certificate. The literature report found no precedent; related work is Strzebonski's local projections, NLSAT and coverings. It is paper-worthy on its own.
- **Novelty, hedged.** As far as the searches found, this would be the first verified CAD construction that runs in practice and is used as a tactic. The Rocq development proves existence with a choice-based lifting (`rootsR`). Isabelle's QE (Kosaian–Tan–Platzer) is not CAD-based.
- **Users.**
  - Counterexample points where the full decision runs. Witness-first already finds counterexample constants in many cases (PROGRESS.md:4092-4101).
  - One run decides every sentence over F in that variable order.
  - Groundwork for Tiers 1D, 2B, 3 and 4.
- **Performance:** none gained, none lost.

---

### Tier 2: Quantifier-elimination output

**2A. One free variable, the outermost (independent of Tier 1).**
```
QF: DATATYPE qtrue | qfalse | qsign(p: mpoly, s: Sign3) | qnot(a: QF) | qand(a, b: QF) | qor(a, b: QF)
qfeval(f: QF, ys: list[real]): RECURSIVE bool
qe1_o(u, qs1, F, Psi): [# ok: bool, cells: list[[# sect: Sect, val: bool #]] #]    % decn_o without the fold
qe1_correct:  THEOREM cons?(qs1) AND qe1_o(u, qs1, F, Psi)`ok IMPLIES FORALL (x: real):
  (EXISTS c: member(c, qe1_o(u, qs1, F, Psi)`cells) AND c`val AND in?(c`sect, x)) IFF sem(qs1, F, Psi, (: x :))
qe1_complete: THEOREM cons?(qs1) IMPLIES EXISTS u: qe1_o(u, qs1, F, Psi)`ok          % decn_complete
sect_qf_ok:   LEMMA sfok?(s) IMPLIES (qfeval(sect_qf(s), (: x :)) IFF in?(s, x))
```
- `qs1` must be nonempty: at least one bound quantifier follows x (`sectn_sem`, and `decn_complete` needs cons?(cdr(qs))).
- **Endpoint formula.**
  - x = value(a) is written p(x) = 0 ∧ lb ≤ x ≤ ub, with closed intervals.
  - x > value(a) is written x > ub ∨ (lb ≤ x ≤ ub ∧ p_sf(x)·p_sf(ub) > 0).
  - The run-time check `sfok?` requires p_sf(lb)·p_sf(ub) < 0, where p_sf is a squarefree part from `poly_gcd`.
- **Reuses:**
  - `sectn_sem` (decn_ok.pvs:78-80);
  - `memn_ok` (decn_ok.pvs:83-85), the proved bridge from `ok` to `sok2?`/`scok?`;
  - `foldn_sem` (:87-91), which already combines `memn_ok`, `sects_cover` and `sectn_sem`;
  - `sects_cover` (sect_inv.pvs:228), `decn_complete`, `decide_u`, `alg_def`, `poly_gcd`, `branch_tree`.
- **Also:** a strategy `(cad-qe var)` that prints the formula and proves the equivalence by reflection, modelled on `cad-direct`.
- **Effort:** 1.5–2.5 days, 70–140 formulas plus about 200–300 lines of Lisp (+0.5–1 day overhead, §3). Class A.
- **Gate (measure before proving).** Ground-evaluate the qe1 computation on:
  - cw1: ∃t. (5−t)² + (t/2)² < D². The baseline is 8 s with the branching QE.
  - the windowed question ∃t. 0 ≤ t ≤ 10 ∧ (5−t)² + (t/2)² < D², on which no branching-QE variant finished in 25–47 min.

  The expected answer to both is D² > 5 (minimum 5 at t = 4, inside the window). Go if the windowed question takes under 60 s. Then try one straight-segment band with w free, under 10 min.
- **Uncosted alternative:** a smaller parametric remainder sequence inside the existing branching QE (the degree-30 coefficient growth is the failure mode).
- **Risks.**
  - There is no early exit, since every sector must be valued, so decide5's certificate cost is inherited.
  - Reflection proofs of large printed formulas: heap exhaustion at 42 atoms has happened before (ENDGAME_PLAN.md:7-21).
  - Printing is always sound, but complete only when `sfok?` passes. I expect it to pass, but that is not proved.
- **Optional side theorem `qe_exp`** from `sem_peel`: QE with free variables for any prefix, at 3^|fam| size. 0.25–0.5 day, 15–30 formulas. Not first: McLaughlin–Harrison (HOL Light, 2005), Cohen–Mahboubi (2012) and Kosaian–Tan–Platzer precede it. Low priority.
- **Benefit.**
  - Claim: "verified CAD-based QE in one free variable, any inner prefix, sound and complete".
  - It adds any inner prefix to the existing single-∃ branching QE, and may succeed where that one did not (the gate decides).
  - **It is the QE step exact DAIDALUS bands need, not the bands.**
    - NASALib ACCoRD already has verified bands for instantaneous maneuvers (trk_bands_2D, gs_bands_2D, vs_bands, bands_2D/3D).
    - The new target is kinematic bands. These need the tan-half-angle algebraization and a `trig_approx` treatment of the turn phase with subdivision (CAD_PLAN.md:683-700), plus the `exact_bands` function and its theorem (CAD_PLAN.md:716-722).
    - That work is not estimated here.
  - Threshold questions ("for which D does this hold?") become answerable.

**2B. Several free variables (after Tier 1).**
- Output: a list of free-level cells with truth values, and a formula of sign conditions on the free-level tower families.
- A run-time check `sep` confirms that no TRUE cell and FALSE cell share a signature within a sector.
- When `sep` fails, the output falls back to extended Tarski formulas with root-index atoms (as in QEPCAD's `_root_`), whose semantics come from Tier 1's `rt`.
- Theorem shape: Kosaian–Tan–Platzer's `qe_correct`, for every valuation of the free variables.
- Fallback if Tier 1 stalls (the QE plan's S5-alt): lift the free-level polynomials into the bottom family and use `sectn_sem`. It is sound with no new analysis, but gives larger families and no geometric claim. **[your decision]**
- **Effort:** 1.5–3 days, 60–120 formulas.
- **Gate:** run the untrusted executable on three small problems with two free variables. `sep` must pass on at least 2 of 3, each under 5 minutes.
- **Benefit:** verified CAD-based QE with free variables.
  - Novelty holds only with "CAD-based" explicit: McLaughlin–Harrison (Cohen–Hörmander) and Cohen–Mahboubi already do QE with free variables.
  - Whether Vermande's paper has a CAD-based QE theorem (reportedly Theorem 3.10) is unconfirmed; check before claiming.
  - It enables parametric bands with 1–2 symbolic parameters. Problems with 8–10 parameters stay out of reach for any CAD.

**2C (optional, research risk).** Guaranteed pure Tarski output, by making the free levels derivative-closed (Thom's lemma; Hong 1992, Brown 1999). The closure's completeness proof must be redone. 3–7 days, 100–200 formulas. Do it only if 2B's measured `sep` failure rate is material.

---

### Tier 3: Brown's reduced McCallum projection on full-dimensional cells (the open-cell case)

**Target, stated exactly.**
- Let A be a squarefree, pairwise coprime basis. BM(A) = {leading coefficients, discriminants, pairwise resultants}. This is Brown 2001's reduced McCallum projection, the same set as Strzebonski 2000's generic projection.
- If every member of BM(A) is nonzero at every point of a connected set C, then A is classically delineable over C:
  - its real roots are simple and pairwise distinct;
  - their number and which member owns each are constant;
  - each root is continuous on C.
- On top of this: an n-level decision that visits only open cells and only rational samples. It decides nested "for all but finitely many" (G) and "infinitely many" (F) sentences exactly.
- This is the full-dimensional case only. Brown 2001's Theorem 3.1 also covers lower-dimensional cells, through McCallum's analytic delineability, well-orientedness and nullification checks.

**3A. The theorem and the decision.**
```
res_root:    THEOREM m+n >= 1 AND polynomial(r, m)(z) = 0 AND polynomial(s, n)(z) = 0 IMPLIES rres(r, m, s, n) = 0
disc_simple: COROLLARY meval(disc(f))(xs) /= 0 AND f(xs, y) = 0 IMPLIES lderiv(f)(xs, y) /= 0
res_disj:    COROLLARY meval(res(f, g))(xs) /= 0 IMPLIES NOT (f(xs, y) = 0 AND g(xs, y) = 0)
persist:     THEOREM bmnz?(A, xs0) IMPLIES lstable?(A, near xs0)   % root count, owners, i-th root within e
bm_delin:    THEOREM conn?(C) AND (FORALL p: C(p) IMPLIES bmnz?(A, p)) IMPLIES delin_cl?(A, C)  % stack_glob
band_ocell:  THEOREM bm_ok?(TW) AND ocell?(TW, j, C) IMPLIES every band over C is ocell?(TW, j+1, .)
gsem(gs, F, Psi, ys)          % TRUE = G (exceptions finite), FALSE = F (infinitely many)
odecide_correct: THEOREM odecide(F, gs, Psi)`ok IMPLIES (odecide(F, gs, Psi)`val IFF gsem(gs, F, Psi, null))
```
- **Mathematics (elementary), four steps.**
  1. The easy half of the resultant theorem: a common root puts its power vector in the kernel of the Sylvester matrix. This needs the kernel lemma below first; the repository has none.
  2. Near each simple root: joint continuity gives a box where f_y ≠ 0. The end signs persist, so the IVT plus monotonicity gives exactly one root in the box.
  3. No stray roots between the boxes. lc ≠ 0 near x₀ bounds all roots uniformly. The proved `croot_near.root_near` (croot_near.pvs:56, with `root_bound` :50 and `cpoly_diff_bound` :43) puts every root of a nearby polynomial of the same degree within ε of a root of f(x₀,·). The alternative is a compactness argument: a positive minimum of |f(x₀,·)| off the boxes.
  4. Local constancy, extended by `conn?` (Tier 1's layer, through `stack_glob`).

  No implicit function theorem or Zariski equimultiplicity is needed.
- **Reused:**
  - Tier 1's connectedness layer and `stack_glob` (only `lstable?` is re-proved, via `persist`);
  - croot_near; sylvester (`res`, `disc`, `res_eval`); mpar (`mev_mcont`, `msg_mpers`); joint_cont; sign_pers;
  - sector_rep's IVT and Rolle (sector_rep.pvs:23, :48);
  - the rational-sample machinery of cad_pdec and cell1 (`gaps_ok`, `gaps_ok_incr`).

  `near_cells` and `mroot_near` are **not** reusable: they assume the walk's reads agree (`wi_rd` holds chain leading coefficients that BM does not control).
- **Kernel lemma via NASALib.** Bridge `rdet` to NASALib `det` by induction on n ≥ 1 (§2.3). Then `invertible_det`, `mult_Id_left` and `matrix_mult_assoc` give "Mv = 0 with v ≠ 0 ⇒ det = 0".
  - For a complex common root: M is real, so M·Re(v) = 0, and the last entry of Re(v) is 1.
  - Fallback **[your decision]**: certified cofactors R = u·f + v·g, checked by `mnorm_eq_iff` (mpoly_unique.pvs:51).
    - It takes about 0.3 day of proof, plus code to compute the cofactors, which does not exist yet.
    - The theorem is then about certified elimination polynomials, not `res` itself.

| Step | Days | Formulas |
|---|---|---|
| Benchmark bank + untrusted prototype | 1–1.5 | – |
| Kernel lemma | 0.5–1.5 | 30–60 |
| Persistence (lower half likely, given `croot_near`) | 2–6 | 90–180 |
| Open tower invariant | 0.5–1 | 25–50 |
| G/F decision | 0.5–1.5 | 50–90 |
| **3A total** | **4.5–11.5** | **195–380** |

Some steps are class B, some class C.

- **Gates.**
  - The prototype must show at least 5 in-class goals that take more than 300 s with `(cad-direct)` and less than 30 s with the prototype. If not, the payoff is formal only: finish 3A and stop. **[your decision]**
    - Candidates: Choi–Lam, Motzkin, Robinson; AM-GM and Schur with strict hypotheses; random strict ∃ systems; industrial strict-inequality examples, if available.
  - `persist1` (one member) must be proved by the end of its second day, stated first with abstract simple-root hypotheses and reusing `croot_near`. If not, re-plan.
  - The kernel lemma must be proved within 1.5 days. If not, take the cofactor fallback.

**3B. Usable inside `(cad)`.**
- **Squarefree, coprime basis by certificate.**
  - An untrusted multivariate gcd: no code exists, since cad/poly_gcd.pvs is univariate only.
  - A proved check `pcert?`: p = c·∏bᵢ^eᵢ by `mnorm` equality, so nonzero factors give a nonzero p.
  - 1–3 days (including 0.5–1.5 days of gcd code), 15–35 formulas.
- **Ordinary semantics.**
  - `open_ex`: an ∃ block over a strict matrix has the same truth under the F reading.
  - `closed_all`: a ∀ block over a non-strict matrix has the same truth under the G reading.
  - **Mixed prefixes do not transfer.** ∀x ∃y. y² < x² is false, but G x F y is true (the only failure is x = 0).
  - Add a dispatch in `(cad)` that falls back to decide5.
  - 1–1.5 days, 25–50 formulas plus Lisp.
- **Completeness, said plainly.** `odecide` is "ok ⇒ correct" only, and has no completeness theorem: `ok` fails when the basis or `bm_ok?` check fails. The `(cad)` tactic stays complete through the fallback; the G/F procedure alone does not.
- **Gate:** `bm_ok?` passes on at least 80% of in-class inputs within budget.
- **3B total:** 2–4.5 days, 40–85 formulas.

**3C (optional corollaries).**
- Two variables with ordinary semantics, lifting at section points through the proved walk. 0.5–1.5 days. In two variables the base cells are points and intervals, so **do not market this as a McCallum theorem**.
- Generic QE, correct outside a lower-dimensional set (Strzebonski 2000). It needs solution-formula output as in 2B, so it comes after 2B: 1–3 days.

**Tier 3 total.** About 7–16 days (6.5–16 by the rows), expected 10–11, and 235–465 formulas. This is **on top of** Tier 1B's connectedness layer.

**Benefit.**
- **Claim:**
  > "A PVS proof that Brown's reduced McCallum projection (Strzebonski's generic projection) is delineating on full-dimensional cells, and a verified decision that lifts only over rational points and decides nested 'for all but finitely many' / 'infinitely many' sentences exactly, and ordinary sentences that are a single ∃ block over a strict matrix or a single ∀ block over a non-strict matrix."
- As far as searches of the Isabelle AFP, HOL Light, Mathlib, math-comp/cad and Tau Ceti found, no prover has any McCallum, Brown or Lazard delineability proof, even for open cells. This is absence of evidence; re-check before publication.
- The elementary route is the planners' own. The published proofs go through McCallum's analytic delineability, so review it against Strzebonski 2000 and Brown 2001 before claiming novelty of the proof.
- It is the library's first *general* projection-based decision whose correctness needs no geometric hypothesis. `quad_dec2` is one only for a single member of degree ≤ 2.
- **Users:** true universal non-strict goals in 3–4 variables, where trying a witness first cannot help. The payoff is unmeasured, and the 3A gate must find such goals first.
- **What it will not do:**
  - Bath 09/10 and 12, and the CADSTAR example: equational hypotheses, where the method is unsound, not just slow;
  - non-strict hypotheses such as x ≥ 0 ⇒ …;
  - mixed prefixes.
- **Community:** it answers the most common specialist question about projection operators directly, and gives a natural short paper.

---

### Tier 4: Collins projection (only on a concrete trigger)

*[Done 2026-10-01, by a different milestone plan: COLLINS_PLAN.md (collins_stack, projn_ok, col_cells, col_found_cad, decide8, qe8). The estimate below is the 2026-09-29 one.]*

| Milestone | What | Days |
|---|---|---|
| M1 | Two-level `delin_projc` (sector-local), assuming normalized members | 10–20 |
| M2 | n levels with Collins reducta (`projcR`), and a projection decision | +4–8 |
| M3 | `decide_collins` in `(cad)`, with fallback to decide5 | +2–4 |

**Total:** about 16–32 days and 600–1500 formulas. That is 1.5–2× the Collins plan's own 380–770-formula scope, in line with CAD_PLAN's historical sizing (CAD_PLAN.md:422-423).

**M1 needs:**
- The `rdet` kernel theory in both directions.
  - det = 0 ⇒ a kernel vector takes a few lemmas via `diag_det_zero_row` (§2.3).
  - The expensive part is polynomial algebra: from a Sylvester kernel vector to a common factor of positive degree. NASALib has no polynomial gcd (CAD_PLAN.md:81-83).
- A complex multiplicity toolkit (`mult_unique`, `mult_deriv`, conjugate multiplicities over `cfact` index sets).
- The subresultant gcd-degree theorem in psc form.
- Continuity of complex roots with clusters (Vermande's Lemma 3.6, Nathanson–Ross). `croot_near` covers proximity but not multiplicity counting.
- Local Collins, then `loc_const` over the interval.

**M2 needs:**
- reducta;
- a `projcR` tower;
- the cells built from it;
- a projection decision.

There are two routes:
- **Rational samples:** a `projc` variant of `pdecide` that reuses `okpts`, plus the new theorem "okpts ∧ Collins delineability ⇒ decok?". It is ok ⇒ correct only, and `ok` is FALSE on every Bath problem (§2.4).
- **Algebraic samples:** `alg_dec`'s `dec2a` or ITEMA_PLAN A6. This is the only route to an unconditional, complete Collins-based decision.

**M3** drops `nclos_o`, `tclos_o`, `inv_chk` and `clok?` and keeps the pointwise checks. Completeness comes free through the fallback. `sh_count` is **not** needed.

**Hong's operator** (Collins with a reduced pairwise part) is probably a modest addition to M1–M2. This is not verified or costed.

**Gates.**
- Before any proof, measure `projcR` tower sizes and determinant times on Bath and the examples (0.5–1 day).
- `mult_unique` within 1 day.
- `one_per_disc` within 1 day.

**Benefit.**
- Claim: "Collins' projection theorem formalized in PVS": the second formal proof after Rocq, and the first in PVS.
- The Lean Tau Ceti roadmap has Collins delineability as a sorry'd target (PR #420, merged 2026-09-27). It mentions McCallum (Layer 7) and Lazard (Layer 8) only in prose.
- M3 *might* replace decide5's certificate bottleneck. But Collins towers with reducta grow doubly exponentially, and nothing has been measured.

**Triggers worth acting on:**
- a reviewer who insists on Collins;
- a measurement showing a Collins tower certifies a Bath problem faster than the closure.

---

### Not planned

- **General McCallum and Brown–McCallum (all cells).** They need order-invariance on analytic submanifolds, analytic delineability, and Zariski's equimultiplicity.
- **Lazard.** It needs Puiseux with parameters (McCallum–Parusiński–Paunescu 2019). The Collins plan's search found no implicit-function theorem, Weierstrass preparation or Puiseux in NASALib. All of these would be research-level first formalizations, and nothing in the history calibrates them.
- **The open Bath problems.** The published routes are:
  - equational-constraint projection, which rests on the same McCallum theory;
  - RegularChains CAD with triangular-decomposition preconditioning after mechanical negation and splitting (Chen–Moreno Maza, ICMS 2014).

  PERF_PLAN.md:121-123 names decide5-side alternatives (resultant coincidences, squarefree reads, a smaller projection). That is performance work, outside this gap. Note that the certificate-size bottleneck was measured only on bath_02; no profile of 09, 10 or 12 exists.

---

## 5. Summary table

| Stage | Depends on | Days | Proved formulas | Main risk and gate | What becomes true |
|---|---|---|---|---|---|
| T0 Correct the record | – | 0.5–1 | 5–20 | none serious; gate: ground evaluation | No false statement in the repository; honest public wording |
| T1A Two-variable stack + prototype | T0 | 1–2 | 40–80 | root indexing; gate: day 2 | Two-variable classical delineability from the reads |
| T1B n levels | T1A | 1.5–3 | 90–170 | local-to-global step, continuity composition, TCC load | A CAD with the run's shape exists (proved) |
| T1C Correspondence + CAD as data | T1B | 1–2 | 50–100 | duplicate separators, `sec` samples, tree size | **"The n-level procedure computes a CAD"**; certified cell tree and paths; one run decides every sentence over F |
| T1D Static walk operator (optional) | T1B | 1–3 (guess) | 40–120 | size of P_walk; gate: enumeration | A proved delineating static operator (not a named one) |
| T2A QE, one free variable | T0 | 1.5–2.5 (+Lisp) | 70–140 | decide5 cost; gate: windowed question in under 60 s | Verified CAD-based QE in x₁; the QE step for DAIDALUS bands |
| T2B QE, k free variables | T1 (or S5-alt) | 1.5–3 | 60–120 | `sep` failures; gate: 2 of 3 | Verified CAD-based QE with free variables |
| T2C Guaranteed Tarski output (optional) | T2B | 3–7 | 100–200 | redoing closure completeness | Always a pure Tarski formula |
| T3A Brown reduced McCallum, open cells | T0, T1B layer | 4.5–11.5 | 195–380 | persistence; gates: prototype, `persist1`, kernel | First (as far as found) proof of BM delineability on open cells; rational-sample G/F decision |
| T3B BM inside `(cad)` | T3A | 2–4.5 (+Lisp) | 40–85 | multivariate gcd; gate: `bm_ok?` ≥ 80% | Verified route for ∃-strict and ∀-non-strict goals (speed unmeasured) |
| T4 Collins M1–M3 | T1, T3A kernel | 16–32 | 600–1500 | gcd-degree theorem, clustered roots, reducta | Collins' theorem in PVS (second overall); decide_collins possibly faster |

*[Status 2026-10-01: done -- T0, T1A–T1C, T2A, T2B and T2C (QE_PLAN.md stages 1 and 2, 2C), T4 (COLLINS_PLAN.md). Not done -- T1D, T3A, T3B (see "What remains" at the top).]*

---

## 6. Recommended path

### 6.1 Order, decisions, and how disagreements were settled

1. **T0 now** (0.5–1 day).
2. **T1A** (1–2 days). It is the go/no-go for the central claim.
3. **T1B and T1C** (2.5–5 days). Consider T1D afterwards, only if its enumeration gate passes.
4. **T2A** (1.5–2.5 days). It is independent of Tier 1, so pull it forward if the DAIDALUS work is urgent.
5. **T3A, then T3B** (7–16 days).
6. **T2B** (1.5–3 days).
7. **T4 only on a trigger.**

| Milestone | Days (before overheads, §3) | What becomes claimable |
|---|---|---|
| After T0–T1C | 4–8 | "Executable, verified CAD" for the n-level engine |
| + T2A | 5.5–10.5 | One-free-variable QE |
| + T3 | 12.5–26.5 | Brown's reduced McCallum on open cells |
| + T2B | 14–29.5 | Full planned scope |


**Decisions that are yours** (CLAUDE.md rule 3):
- the cofactor fallback for the kernel lemma;
- S5-alt for 2B;
- "finish 3A and stop" if the prototype shows no speed-up;
- whether to pursue T1D;
- the paper venue.

Walk-relative root indexing (the T1A fallback) changes only the proof, not the statement.

**Housekeeping on adoption:**
- Write this as a plan file with a handoff section.
- Update CLAUDE.md:8, which still names COMPLETENESS_PLAN as the current goal.
- Run the NASALib proof-chain check once (§2.11).

How the disagreements were settled:
- **Tier 1 before Brown–McCallum.**
  - Tier 1 repairs claims that are already public, and it is mostly class A.
  - Its connectedness layer and `stack_glob` are reused by Tiers 1D, 2B, 3 and 4.
  - Tier 3's persistence cannot reuse decide5's local lemmas.
  - Three of the four reviews favoured this order.
- **Estimates.** Tier 1: 3.5–7 days, with the rate assumption stated. Tier 3: 7–16 days, on top of Tier 1. Collins: 16–32 days, restated so the number matches its reasoning.
- **`conn?`, not `pconn?`.** It is cheaper, equivalent on subsets of Rᵏ, and exactly what the proofs use.
- **Root indexing through NASALib `system_roots_enum`,** not `card`.
- **Kernel lemma through NASALib's Laplace `det`** (n ≥ 1), with the certificate fallback.
- **No claim that `pdecide_sem` becomes unconditional** (§2.4).
- **Closed-interval endpoint encoding** for QE output.
- **Keep the name `delin?`;** add `delin_cl?` for the classical notion.

### 6.2 What to say publicly now

**Wording changes.**

| Location | Interim wording (until T1C) | After T1C |
|---|---|---|
| README.md:1, :6; paper/main.tex:10 | "An Executable, Formally Verified Cylindrical Decision Procedure for Real Arithmetic in PVS"; "The procedure is a cylindrical, CAD-style decision procedure" | The original wording is accurate, scoped to the n-level engine |
| docs/cad_overview.tex:196 | "sign-invariance of the lifting's reads, hence invariance of each fibre's set of sign vectors, and root separation are certified at run time" | Add: "and a proved theorem turns this into classical delineability" |
| docs/cad_overview.tex:234-236 | "to our knowledge the first executable decision procedure in the CAD family that is formally verified sound and complete and usable as a tactic" | "…the first executable CAD construction proved to produce a CAD and usable as a tactic" (re-check the literature first) |
| paper/main.tex:35 | "Rocq/MathComp (development: Cohen, Djalal, Vermande; paper: Vermande, CPP 2026): Collins-type CAD with delineability proved; choice-based lifting (`rootsR`), not practically executable; no runs reported" | – |

**Do not say yet:**
- "verified CAD" without qualification;
- "verified Collins/McCallum/Brown projection";
- "no lifting over irrational points";
- "first verified CAD" (the Rocq development exists).

*[2026-10-01: Collins's projection is now proved delineating (collins_stack), and the Collins CAD is proved in every number of variables with no certificate (col_cells); McCallum's and Brown's projections are still not proved, and the other three items stand.]*

### 6.3 What to do first

1. Bank `psc_det_false` by ground evaluation. Fix the comments, plans and public text listed in Tier 0, and re-gate only the edited theories.
2. Start T1A with the **untrusted executable cell tree** on the unit circle (13 cells), a sphere (25) and ex_line. Then prove `stack_const` for n = 2 on `system_roots_enum`, with the day-2 gate.

---

## 7. Open questions

1. **Which open-cell operator matters most in practice?** The likely target is Brown 2001's reduced projection as used in QEPCAD B's measure-zero-error mode; Brown–McCallum 2020 (Lazard) is much less likely.
2. **Is the elementary open-cell proof correct as planned?** It is the planners' route; the published proofs are analytic. Review it against Strzebonski 2000 and Brown 2001. McCallum 1993's full text was not accessible, so whether it states this lc/disc/res theorem is unconfirmed.
3. **Does root indexing through `system_roots_enum` fit the budget?** The T1A gate decides. Walk-relative indexing is the fallback.
4. **Is P_walk (Tier 1D) finite and small enough to be useful?** The finiteness argument was checked by reading only, and the size is unknown.
5. **Facts checked only by reading:**
   - the `psc_det?` counterexample;
   - the no-reducta example (low confidence);
   - that `near_cells`' premises hold everywhere;
   - the NASALib `det` bridge (the n ≥ 1 edge case).

   Each is a first-day item in its tier.
6. **Performance is almost entirely unmeasured:**
   - decide5's cost on parametric QE (T2A gate);
   - how often BM bases fail the squarefree check, and the untrusted gcd's speed;
   - Collins tower sizes on Bath.

   No stage targets Bath 09/10 or 12.
7. **Novelty claims are time-sensitive.** Tau Ceti and hex-dev (issue #10300) are active on nearby targets. Re-run the literature search before each public claim.
8. **Do reviewers want path-connectedness or cells homeomorphic to cubes explicitly?** Each costs about ½–1 day if asked for.
9. **Paper:** which venue and which deadline? This decides whether Tier 1 alone or Tier 1 + 2A is the paper.
10. **Cross-checks:** is an install of QEPCAD B (or another CAS) worth the unknown effort on macOS 27, or are hand-computed examples enough?

---

## 8. Confidence and sources

**Key citations.**
- Q. Vermande, *Cylindrical Algebraic Decomposition in Coq/Rocq*, CPP 2026, pp. 45–58, doi:10.1145/3779031.3779100. Development: https://github.com/math-comp/cad (Cohen, Djalal, Vermande); https://rocq-prover.org/p/coq-mathcomp-cad/1.1
- C. W. Brown, *Improved projection for cylindrical algebraic decomposition*, J. Symbolic Comput. 32 (2001) 447–465, http://fitelson.org/pm/brown_projection.pdf
- C. W. Brown, *QEPCAD B: a program for computing with semi-algebraic sets using CADs*, SIGSAM Bull. 37(4) (2003), https://www.usna.edu/Users/cs/wcbrown/research/MOTS2002.2.pdf
- A. Strzebonski, *Solving systems of strict polynomial inequalities*, J. Symbolic Comput. (2000), https://www.sciencedirect.com/science/article/pii/S0747717199903279
- S. McCallum, *Solving polynomial strict inequalities using CAD*, Computer J. 36(5) (1993) 432, https://academic.oup.com/comjnl/article/36/5/432/392361
- C. W. Brown, S. McCallum, *Enhancements to Lazard's method* (2020), https://link.springer.com/chapter/10.1007/978-3-030-60026-6_8
- Han, Jin, Xia, https://arxiv.org/pdf/1205.1223 (generic projection = reduced McCallum); Han, Dai, Xia, https://arxiv.org/pdf/1401.4953
- Tau Ceti roadmap PR #420: https://github.com/TauCetiProject/TauCetiRoadmap/pull/420 ; hex-dev: https://github.com/kim-em/hex-dev/issues/10300
- McLaughlin–Harrison, CADE 2005, HOL Light `Rqe/` (https://github.com/jrh13/hol-light); Isabelle AFP `Quantifier_Elimination_Hybrid` (Kosaian–Tan–Platzer); Cohen–Mahboubi, LMCS 2012.
- Chen, Moreno Maza, ICMS 2014 (RegularChains CAD on the Bath challenges); local copy in the session scratchpad.
- Basu, Pollack, Roy, *Algorithms in Real Algebraic Geometry*, ch. 5.
- Narkawicz, Muñoz, Dutle, J. Automated Reasoning 54 (2015), doi:10.1007/s10817-015-9320-x

**High confidence (verified against files or by exact hand computation):**
- decide5's theorems, proof status and axiom-freedom (relative to NASALib);
- `delin?` is fibre-set invariance only;
- `psc_det?` is false as a universal statement;
- the NASALib `det` facts;
- `pdecide_sem` cannot become unconditional;
- Tier 2A's foundations, and the cw1 (8 s) versus windowed baseline;
- the Bath status.

**Medium confidence:**
- Tier 1 needs only the two new pieces of §2.5, and fits 180–350 formulas;
- the Tier 3 estimate and the `croot_near` reuse;
- the Collins restatement;
- which open-cell operator matters most in practice;
- the novelty of an open-cell BM proof (absence of evidence).

**Low confidence or unchecked:**
- the no-reducta counterexample to `delin_projc`;
- Tier 1D's finiteness and usefulness (my reading only);
- Vermande's theorem numbers (3.9 existence, 3.10 QE) and whether 3.10 is CAD-based;
- whether McCallum 1993 states the lc/disc/res theorem;
- every performance expectation;
- whether the public `pvs_cad` carries the old top.pvs text.

**Key files:**
- cad/delin_bridge.pvs
- cad/cad_delin.pvs
- cad/top.pvs
- cad/cad_decide5_def.pvs
- cad/decide_u.pvs
- cad/mwalk.pvs
- cad/mroot.pvs
- cad/root_cont.pvs
- cad/croot_near.pvs
- cad/walk_transfer.pvs
- cad/walk_rd.pvs
- cad/sg_chain2.pvs
- cad/zfam.pvs
- cad/tower_sem.pvs
- cad/tclf.pvs
- cad/decn_ok.pvs
- cad/towern_od.pvs
- cad/cad_decn.pvs
- cad/cad_pdec.pvs
- cad/ring_det.pvs
- cad/sylvester.pvs
- cad/alg_def.pvs
- cad/qe_tree.pvs
- cad/qe_symbolic.pvs
- cad/cad_decide.pvs
- cad/bench_n.pvs
- README.md
- CLAUDE.md
- PERF_PLAN.md
- FINISH_PLAN.md
- CAD_PLAN.md
- ITEM1_PLAN.md
- paper/main.tex
- docs/cad_overview.tex
- $NASALIB/matrices/matrix_props.pvs
- $NASALIB/matrices/matrix_inv.pvs
- $NASALIB/matrices/matrix_diag.pvs
- $NASALIB/Tarski/poly_systems.pvs
- $NASALIB/topology/connected_def.pvs