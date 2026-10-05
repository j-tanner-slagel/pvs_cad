# Next: fast determinants (P5), functions of bounded constants (T5), a full review, and P7

*2 October 2026. Asked: "P5 and T5 I would like to do. Then a thorough review. Then a thorough
review and plan of T7." There is no T7 (TERMS_PLAN.md ends at T5); this plan reads it as P7,
PROJ_PLAN.md's McCallum / Brown / Lazard projection. Estimates are estimates, at the pace of P1–P3
and T2–T4b.*

## 0. The sequence

**Status (4 October 2026).** Step 1 (P5) is done: proved, gated, replayed (5,526 of 5,526
formulas), in cad/PROGRESS.md. AM–GM in four variables no longer runs out of memory, and its
determinants take milliseconds, but it still has no answer within 900 s: the time is now in the
lifting. Step 2 (T5) is done: trans_bounds and the ladder in cad-num, with the pieces decided each
in its own branch (cad/PROGRESS.md has the details and the limits). Step 3, the review, is done
(4 October 2026): a multi-agent review with verified findings, all fixed or answered, decide8's run
proved a CAD (decb_run), new regression tests and checks, every proof replayed; cad/PROGRESS.md has
the entry, and a public sync waits for the owner's OK. Next: step 4, the P7 review and plan.

| step | what | why | size | ends with |
|---|---|---|---|---|
| 1 | **P5**: determinants in O(n³) (Bareiss, checked divisions) | AM–GM in four variables runs out of memory on side-23 determinants; the hardest Bath problems need side 40 | 150–200 formulas, 2–4 days | gates, whole-library replay, dev commit |
| 2 | **T5**: sin(c), exp(c), ln(c), ... of constants the sequent bounds | (cad) handles sin(1) but not sin(c) with 0 ≤ c ≤ 1 | about 2–3 days, mostly strategy code | gates, replay, dev commit |
| 3 | **A thorough review** | every public statement true, every proof replayed from a fresh clone | 1–2 days | findings report, fixes, a public sync proposal for your OK |
| 4 | **P7 review and plan** | decide whether the smallest projections (McCallum / Brown / Lazard) are worth months | 2–3 days, no library changes | `P7_PLAN.md` and a recommendation |

- **Checkpoints with you.**
  - After each step: a summary and the dev commit.
  - Before any public push: the files and the message (as always).
  - After step 4: the decision on P7.
- **Each step keeps the standing rules:**
  - proofs through pvs-cli;
  - .prf files written only by PVS;
  - `tools/gate.sh` on every new or changed theory;
  - a whole-library replay at the end of the step;
  - PROGRESS, top.pvs, memory, then commit and push to dev.
- **Not in this plan:**
  - P4 (Hong's operator) and P6 (the local projection) as library work. P6 comes back in step 4 as
    one of P7's alternatives.
  - Transcendental functions of variables under inner quantifiers (section 2, end).

## 1. P5: determinants in polynomial time

**Why.**
- Every psc_j is the determinant of a subresultant matrix with polynomial entries.
- `detf` (P1) builds the table of all minors of the first columns, about n·2ⁿ entries.
- The cost is fine up to side 19 (g_root9) and hopeless beyond [noted 2026-10-03: b10_amgm's
  side-19 determinants never finished with detf; P3's squarefree basis made them small]:
  - AM–GM in four variables (d_amgm4) needs side 23 even after P3's basis, and exhausts the 6 GB
    heap;
  - bath_09 and bath_12 need side-40 resultants under any operator.
- **What P5 does not fix:** after P3 the L_n family's largest determinant has side 4
  (PROJ_PLAN.md 1.2). L₄ and L₅ are slow for another reason, which the review profiles (section 3).

**The algorithm: Bareiss's fraction-free elimination with checked divisions.**
- Step k replaces every entry of the trailing block by
  `(a_kk·a_ij − a_ik·a_kj) / p`, where p is the previous pivot.
  - The division is exact.
  - The last entry is the determinant.
  - The cost is O(n³) polynomial operations instead of n·2ⁿ.
- **Division by checking, as in P3.**
  - P3's unproved `mexf` divides.
  - The quotient q is accepted only when `q · p` and the numerator have the same normal form
    (meq after mnorm; complete by mpoly_unique).
  - When a check fails, or a pivot is the zero polynomial, `bdet` falls back to `detf`. So the
    result is always the determinant; the checks only decide the speed. [As built (PROGRESS,
    P5 entry): a zero pivot is handled by adding a later row to the first, a zero first column
    gives 0, and detf runs only when a check fails.]
- **Matrices as lists of rows inside the algorithm.** A LAMBDA-built matrix would make the evaluator
  recompute earlier steps at every access. The proof reads the lists through nth, as det_fast_def
  already does.
- **Row exchanges** for a zero pivot only if the prototype (stage 0) shows that zero pivots are
  common on the benchmark matrices. Otherwise the fallback covers them.

**The proof.** No new linear algebra beyond one elimination step.
- **The cancellation lemma (new, theory `mpoly_dom`).**
  - Statement: if p is not the zero polynomial and p·q is zero at every point, then q is zero at
    every point.
  - Proof: by induction on the number of variables. A coefficient c of p that is not zero makes
    q's coefficients vanish wherever c does not. `roots_finite` gives the one-variable case.
    [As built: mpoly_dom inducts on msize(p) + msize(q), its one-variable case from NASALib's
    polynomials (prod_top_mpoly_dom, poly_nodiv).]
  - It also gives: a product of nonzero polynomials is nonzero.
  - Its absence was the only real gap in the library; mpoly_dom (P5) closed it.
- **Ordinary elimination over the reals, from NASALib.** NASALib has no determinant over a ring,
  no Sylvester identity and no Bareiss, but its real determinant has what one elimination needs.
  The library's rdet is NASALib's det (rdet_nl), so these apply directly:
  - adding a multiple of a row leaves det unchanged (matrix_props det_replace_row_sum_scal);
  - row exchange (det_swap);
  - a triangular determinant is the product of the diagonal (matrix_det det_upper_triangular).
- **The invariant.**
  - Statement: at a point where every pivot is nonzero, the Bareiss block after k steps is pₖ
    times the block of ordinary Gaussian elimination, where pₖ is the leading k×k minor.
  - The last Bareiss entry is then the product of the elimination's pivots, which is the
    determinant: `bdet(M)(ys) = rdet(ev(M, ys))`.
  - The checked division gives q(ys) = numerator(ys) / p(ys) there.
- **Every point.**
  - bdet − det vanishes wherever the product P of the pivots does not.
  - P is a nonzero polynomial, a product of nonzero normal forms.
  - So by cancellation bdet and det denote the same polynomial, and mpoly_unique gives
    `mnorm(bdet(n, M)) = mnorm(det(n, M))`.

**Integration.**
- `pscg` (cad_projn_def) uses bdet, and its result is normalized.
  - `pscg_eq` becomes `pscg(g, h, j) = mnorm(psc(g, h, j))`.
  - Its two users, cad_projn and cad_projb, are re-proved through meval_mnorm.
- A gain on the way: fpsc's test `zcst?` on a normal form is exact. A polynomial that is zero but
  not syntactically so no longer survives into the projection.
- **Optional (P5b, only if the measurements ask for it):** all psc_j of one pair from a single
  elimination.
  - With the rows of the subresultant matrix interleaved, psc_j is ± a leading principal minor.
  - This was checked on 910 random cases, but is unproved.

**Stages and gates.**
1. **Prototype (half a day).**
   - Bareiss in Python on the actual subresultant matrices of d_amgm4, b10_amgm, g_root9, bath_04
     and bath_09: time, intermediate sizes, zero pivots.
   - An unproved Bareiss in a scratch PVS server: the ground evaluator's time on the side-23
     determinant.
   - Go on only if it is well under a minute.
2. `mpoly_dom` (cancellation).
3. The elimination lemma.
4. `bareiss_def` / `bareiss` (bdet_det).
5. Integration and re-proofs.
- **Gate for each new theory:** `tools/gate.sh` (3 runs + traces).
- **Then:**
  - cad_projn, cad_projb and cad_decide8 re-gated;
  - cad_showcase, cad_forms_ex and cad_terms_ex replayed;
  - a whole-library replay.
- **Measured against today:** d_amgm4, g_root9, b10_amgm, g_amgm10, c_amgm3, c_schur, the Bath
  problems and the README's table.
- **Target:** d_amgm4 decided within 120 s, and nothing slower.

**Size and risk.**
- About 150–200 formulas, 2–4 days.
- **Risks:**
  - The evaluator's speed on the divisions of side-23 entries. The prototype measures this
    first.
  - d_amgm4's lifting in four variables may be slow even when the projection is fast. If so,
    P5's gate is the determinants and the AM–GM time is reported as it is.

## 2. T5: functions of constants that the sequent bounds

**Why.**
- (cad) handles sin(1) (T2: an enclosure by interval arithmetic).
- It does not handle `0 <= c AND c <= 1 IMPLIES sin(c) <= c`, with c a constant of the proof.
- Today sin(c) is an unknown with no facts, so the decision fails.

**Scope.**
- Terms built with sin, cos, tan, atan, exp and ln (also through + − × / ^, sqrt, abs, pi and e)
  whose arguments contain skolem or other free constants.
- **The goal's leading universal quantifiers are skolemized first.** So
  `FORALL (x: real): 0 <= x AND x <= 1 IMPLIES sin(x) <= x` is in scope as written.
- **Out of scope:** functions of variables under inner quantifiers (EXISTS x: sin(x) = 1/2,
  FORALL x: EXISTS y: ...). That is MetiTarski's territory: polarity-dependent polynomial bounds of
  high degree, and its own plan if ever wanted.
- **Same import as T2:** IMPORTING pvs_cad_num.
- **Same trusted base as T2:** NASALib's enclosures are proved by `numerical`, whose last step is
  PVSio's evaluator, as for (cad) itself.

**Two kinds of facts, both proved formulas about the terms.**

1. **Polynomial bounds valid on whole ranges (new theory `trans_bounds`, under pvs_cad_num).**
   - NASALib's bounds are restated in the polynomial form (cad) reads, each with its side
     condition:
     - sin: a − a³/6 ≤ sin(a) ≤ a for a ≥ 0, and the mirror for a ≤ 0 (trig@trig_approx
       sin_bounds, sincos sin_pos_bnds, sin_neg).
     - cos: 1 − a²/2 ≤ cos(a) ≤ 1 (cos_bounds).
     - exp: exp(a) ≥ 1 + a (lnexp exp_ineq2, exp_0), and (1 − a)·exp(a) ≤ 1 for a < 1
       (exp_ineq3).
     - ln: ln(x) ≤ x − 1, and x·ln(x) ≥ x − 1 for x > 0 (ln_ineq4, ln_ineq1).
     - atan: x ≤ (1 + x²)·atan(x) and atan(x) ≤ x for x ≥ 0, and the mirror (trig@atan
       atan_bnds, atan_neg).
     - The ranges: −1 ≤ sin, cos ≤ 1 and exp > 0.
     - Higher orders (sin_bounds and cos_bounds at n = 1, degree 7 and 6) as a second rung.
   - They are added exactly as T3 adds its facts: instantiated, with a case on the side condition.
   - They give what no enclosure can: tightness where the two sides touch (sin(c) ≤ c at c = 0).
2. **Enclosures over the constants' ranges (interval arithmetic).**
   - **The ranges.**
     - They come from the hypotheses: conjunctions split, types (posreal gives > 0),
       `c ## [| a, b |]`, abs(c) ≤ b.
     - They are passed to `numerical` as `:vars`, since it reads only top-level, unsplit
       hypotheses.
     - Every constant needs a rational bound on both sides. Without one there is no enclosure,
       and only the polynomial bounds apply.
   - **One enclosure over the whole box is weak.** sin(c) for c in [0, 1] is just [0, 0.85]: it
     knows nothing about how sin(c) moves with c.
   - **So refinement splits the box.** For the pieces, it adds
     `a_i <= c AND c <= b_i IMPLIES lb_i <= e AND e <= ub_i`. Each piece's enclosure is proved in
     the branch of a case on c's range, and (cad) decides with the whole tube.
   - Pieces are bisected where the decision fails, up to a depth limit, with the precision rising
     as in T2.

**The ladder, cheapest first.** It stops at the first rung that proves the goal; each rung is one
finalize, so a rung that fails changes nothing:
1. ranges and degree-3 bounds;
2. plus one enclosure per term;
3. plus the piecewise tube;
4. plus the higher-order bounds.
- **FALSE detection as in T2.** When the goal is false for every value that the facts and the
  hypotheses allow, (cad) says so.
- **Otherwise** it says how far it got, not FALSE.

**Tests (cad_terms_ex, part 3).**
- sin(c) ≤ c on [0, 1] (bound only), sin(c) ≥ c/2 on [0, 1], exp(c) ≤ 1 + 2c on [0, 1] (needs
  pieces).
- sin(a)·cos(b) ≤ 1 with two constants.
- ln(c) ≤ c − 1 for c > 0 (unbounded above: bounds only).
- atan(c) ≤ c.
- The same with FORALL written, and in a hypothesis.
- One FALSE: sin(c) ≥ c on [1/2, 1].
- One refusal with its message: sin of an existentially bound x.

**Size.**
- trans_bounds: about 30–50 formulas.
- The strategy code (ranges, pieces, ladder, skolemizing the leading FORALLs): the bulk.
- About 2–3 days.
- **Risk:**
  - A tube with many pieces makes (cad)'s formula large; the depth limit and the ladder keep it
    small.
  - numerical's branch and bound on several constants at once may be slow; it is measured on the
    tests.

## 3. A thorough review (after P5 and T5)

**Goal.** Every public statement about the library is true, every proof is replayed from a fresh
clone by the documented route, and nothing known to be wrong or fragile is left unrecorded.

**What is reviewed, and against what.**

1. **Claims.** Each is checked against the code, the proofs, or a fresh measurement:
   - README;
   - the four documents in docs/ (cad_overview, collins_cad, qe_capabilities,
     cad_proof_traces);
   - top.pvs's descriptions and the theory header comments;
   - the strategies' help texts;
   - the status lines of every *_PLAN.md;
   - the latest PROGRESS entries;
   - the citation and NOTICE;
   - public announcements outside the repository (only the discrepancies are reported).
   - Anything phrased as "first", "only" or "complete" gets a literature check.
2. **Soundness and the trusted base.**
   - No axioms and no unproved TCCs anywhere.
   - Every (cad) path ends in a proved theorem plus the ground evaluator, as the documents say.
   - No strategy step closes a goal by anything but PVS's own rules.
   - Every .prf written by PVS.
   - The documents' trust statements match what the proofs use. (cad)'s evaluation and NASALib's
     `numerical` both end in PVSio's ground evaluator (eval-expr, eval-formula), so "nothing new
     is trusted" must say relative to what.
   - A whole-library replay from a fresh clone of the public tree, set up only by README's
     instructions (tools/setup.sh).
3. **The strategies.**
   - pvs-strategies is 4,128 lines of Lisp after T4b, and more after T5. It is reviewed in full
     for:
     - the mapobject pitfalls found in T4b (nested walks, shared subterms);
     - errors swallowed by ignore-errors;
     - global state between calls;
     - messages that say something false;
     - dead code;
     - duplicated readers;
     - fixed formula numbers instead of labels.
4. **Tests.**
   - A coverage matrix: each feature × polarity (goal / hypothesis) × quantifier position ×
     command form ((cad), (cad *), (cad -1), (cad-qe), :cad-only?).
   - Missing cells get regression lemmas.
   - Failure modes get tests too: a FALSE goal reported as FALSE, and a refused formula refused
     with the right message.
5. **Performance.**
   - The benchmark theories (cad_limits*, bench_*, the Bath set) re-run with one script and a
     timing table.
   - README's numbers updated.
   - L₄ and L₅ profiled (section 1 says why P5 does not touch them).
6. **Usability.**
   - The commands as a new user meets them: README's quick start, the help texts, the messages
     of every refusal.
   - Gaps get a real fix or a recorded plan, not a workaround.
   - The showcase gets a part for the terms of TERMS_PLAN (constants, sqrt, abs, quotients,
     T5's functions).
7. **Repository.**
   - Portable paths only.
   - The tools/ scripts: used, documented, or removed.
   - Plans that are finished or superseded marked so.
   - .gitignore.
   - The public/dev split: what paper/ holds, and what must never be public.

**How.**
- One pass per area, with findings written down before anything is fixed.
- **Each finding gets:**
  - the evidence (file:line, a command and its output);
  - a severity: false claim, soundness, failing proof, misleading message, fragile code, polish;
  - the fix, or why not.
- Fixes are gated and replayed like any other change.
- **Optional:** the areas can run in parallel as a multi-agent review, with each finding checked by
  a second agent that tries to refute it. That takes your explicit go-ahead and costs noticeably
  more; done by me in sequence, it is 1–2 days.

**Deliverables.**
- A findings report.
- The fixes, committed to dev.
- A public sync proposal: what would be pushed and its message, for your OK.

## 4. P7: a thorough review, then a plan or a recommendation against it

**The question.** McCallum's, Brown's and Lazard's projection operators give the smallest
projection sets known.
- bath_04's bottom step has 11 roots under Brown's operator, against 61 after P2.
- The four-variable Bath problems get through only with them (PROJ_PLAN.md 1.2).
- Their correctness proofs rest on analytic geometry that NASALib does not have, and as far as
  PROJ_PLAN's survey found, no proof assistant has a formal proof of any of them.
- The review decides whether P7 is worth months, and in which form.

**The review.**

1. **Literature: the operators.**
   - Collins 1975; Hong 1990; McCallum 1985/1988/1998; Brown 2001; Lazard 1994.
   - McCallum, Parusiński and Paunescu's validity proof of Lazard's method (2019).
   - The equational-constraint operators.
   - Strzebonski's local projection (2016), and the single-cell and sample-based ("NLSAT-style")
     constructions.
   - For each: the projection set, the exact hypotheses (well-orientedness, ...), the theorem the
     correctness proof needs, and what fails without it.
2. **Literature: formalizations.**
   - What exists in Rocq/Coq, Isabelle, Lean, HOL Light and ACL2 for:
     - CAD and real quantifier elimination;
     - subresultants;
     - several-variable analysis: analytic implicit and inverse functions, Weierstrass
       preparation, Puiseux series, order of vanishing.
   - This confirms or corrects the "no formal proof of any of these operators" claim before
     anything says "first".
3. **The proof's dependency graph.**
   - For the cleanest route (MPP 2019 for Lazard; McCallum's for his operator): every lemma, from
     the analytic implicit function theorem up to "the projection set is delineating".
   - Each node marked present in NASALib, present elsewhere and portable, or missing, with a size
     estimate.
4. **Routes that may give the benefit without the theory.**
   - (a) **P6, Strzebonski's local projection.** Elementary: P2's argument cell by cell. It needs
     a new engine.
   - (b) **Verify instead of prove.** Compute a McCallum or Lazard CAD with unproved code, then
     check each cell's sign-invariance with an elementary certificate (P6's local argument as a
     checker). Completeness holds only when the checks pass, with Collins as the fallback.
   - (c) **Brown's operator** with its well-orientedness test as a run-time check.
   - For each: what is proved, what is checked at run time, the expected sizes on the Bath set
     (from the prototype in PROJ_PLAN.md 1.2), and the cost.
5. **Measurements.**
   - The sympy/flint prototype extended to the local projection (P6) and to a checked
     McCallum/Lazard run.
   - On bath_04 to bath_12 and L₃ to L₅: cells, roots and largest determinants.

**Deliverable: `P7_PLAN.md`.**
- The survey with sources.
- The dependency graph.
- The routes compared.
- A recommendation:
  - full analytic theory, staged, with milestones and a paper outline; or
  - route (a) or (b) first; or
  - stop.
- Estimates marked as estimates, and the decisions that are yours.
- About 2–3 days of reading, prototyping and writing; no library changes.

## 5. Decisions for you

[Taken (2026-10-03): the sequence (1) and T5's scope (3) were approved; P5 and T5 are done. The
review (2) runs as a multi-agent review with each finding cross-checked, at the owner's request.
The sync prepared on 2026-10-02 (4) was held; a new one follows the review.]

1. **The sequence:** P5, T5, the review, then P7's review and plan. Shall I start P5?
2. **How to review (step 3).**
   - Default: by me, area by area (1–2 days).
   - Or a parallel multi-agent review with each finding cross-checked. That needs your explicit
     go-ahead and costs noticeably more.
3. **T5's scope.** Constants and the goal's leading FORALLs, but not functions of variables under
   inner quantifiers. Widening it is a separate plan.
4. **The public sync prepared today** (one commit on top of the public repository as it then was,
   everything through T4b; superseded by the sync of 5 October, after the review).
   - Push it now, or hold it until after the review and push one larger sync.
   - Either way, nothing is pushed without your OK.

## 6. Sources and files

- **PROJ_PLAN.md** (P4–P7, measurements 1.1–1.2) and **TERMS_PLAN.md** (T1–T5).
- **This library:**
  - ring_det, rdet_lin and rdet_nl (determinants);
  - det_fast_def / det_fast (P1);
  - cad_projn_def (pscg);
  - mpoly_gcd_def and mpoly_cert (P3's checked division);
  - mpoly_unique (normal forms).
- **NASALib, as surveyed for this plan:**
  - matrices@matrix_props, matrix_det, matrix_inv, matrix_upper_triang (real determinants);
  - interval_arith's pvs-strategies (`numerical` and `interval`: variables, ranges, branch and
    bound);
  - trig@trig_approx, sincos, atan, atan_approx;
  - lnexp@ln_exp_ineq, exp_series, ln_series.
  - It has no resultants, subresultants, Sylvester matrices, Bareiss or ring determinants.
