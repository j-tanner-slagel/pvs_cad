# Slimming pvs_cad for NASALib (SLIM_PLAN)

**Status (6 October 2026).** Study done; the owner's decisions are below. Phase 0 and Phase 1 done
(`PROGRESS.md`); S1 to S11 and S3b (the cad-only? side decisions, after S11) done; Phase 3's library
items done (comments, imports, renames, strategies) and the folder in NASALib's layout
(`cad/README.md`, `top.pvs`'s tags, `cad/examples/`, the message tests and the Bath problems in
`tests/`); contacting the maintainers and the packaging in a NASALib clone wait for the owner;
Phase 4 (docs) done. The full library (5,628/5,628, 375 theories) is `v1.0-full` =
`5700fd9`.

**Goal (owner, 5 October 2026).** The development goes into NASALib (pvslib). The current state is
historical: the current `main` becomes a historical branch, and `main` becomes a slim library that
keeps
- the commands `(cad)` (with its witness search), `(cad *)`, `(cad-qe)`, `(cad-direct)`,
  `(cad :cad-only? t)`, and the constants and functions support (`pvs_cad_num`, `trans_bounds`:
  `(cad-num)`, `(cad-facts)`, TERMS_PLAN T2-T5);
- the results: the Collins CAD theorems (`col_cells`, `col_found_cad`, `col_found_decides`,
  `decb_cad_run`, `decb_cad_input`, `col_verified`), QE and semi-algebraicity (`qe8_complete`,
  `qelim_qf`, `qelim_ok`, `fod_qfd`, `col_cells_sa`, `decide_g_ok`), and the completeness of `(cad)`
  (`decide8_correct`, `decide8_decides`);
- examples that show and regression-test every kept command and result; all the fixes; nothing
  redundant that is not used.

The commands `(alg-roots)`, `(poly-sign)`, `(poly-nosign)` and the measuring commands go, and so do the
read-closure engine's own results (`decide5_decides`, `cad_verified`, `cad_found_cad`, `qe_complete`).
Depth: refactor where it pays (cut imports, move the few lemmas newer theories borrow from older ones,
re-prove what moves), each change gated.

**How the plan was made.** A multi-agent study on 5 October 2026: six static studies (the strategies,
the decision engine, QE, examples and tests, NASALib's conventions, the repository), one synthesis of
them, and two adversarial checks of the synthesis. They read the `.pvs` and `.prf` files, the
strategies and the replay log of 5 October; none of them ran PVS. The study's data and scripts are kept
outside the repository.

**Evidence so far.** A scratch library made of the import closure of `pvs_cad_num`, the theorem
theories (`col_line`, `col_found_ok`, `col_verified`, `decb_run`, `cad_sa`, `qelim_ok`) and 11 example
theories, 329 theories in all (64 fewer), replayed 5,105 of 5,105 formulas (`proveit -a`, 5 October
2026). Nothing outside that import closure is needed at run time. S1 deletes only theories outside
it, plus four that only deleted theories import (`cad_decide7_ex`, `cad_diag_ex`, `cad_out_ex`,
`cad_found_def`), so S1 is safe.

**The adversarial checks.** The static check confirmed that each of the 162 theories the plan removes is
a correct removal: no kept theory imports it after the planned edits, and no kept proof, text, strategy
path, example or tool needs it. It and the completeness critic also found steps that would not
typecheck as first written, and other gaps. The corrections below take precedence over the text of the
steps in §2.

## The owner's decisions (5 October 2026)

- **Commands on neither list (Q1):** "if they are not needed in order to do cad or cad-qe, we don't
  need them". `(mpoly-eq)`, `(mpoly-simp)`, `(poly-pos)`, `(poly-nonzero)`, `(qe-exists)`, `cad-time`,
  `cad-qeshow` and `cad-showf` go, with `mpoly_examples`, `mpoly_showcase`, `pos_examples`, `qe_run`,
  `qe_symbolic` and `msgcheck`'s `m_qe_nat`. The helpers `(cad)`'s reader borrows (`qe-sub-e`,
  `qe-sub-p`, `qe-atom-parts`, `qe-list-str`) stay; `cring` stays.
- **Unused mathematics (Q6):** delete everything unused, `qe_g_qf` included.
- **Playground and hard problems (Q8):** `cad_demo` and `cad_limits`, `cad_limits2`, `cad_limits3` leave
  `main` (they stay at `v1.0-full`). A new theory of hard problems that `(cad)` proves under `pvs_cad`
  (about 60-80 s) backs the README's timings with replayed lemmas.
- **NASALib directory name (Q13):** `cad` (imports stay `cad@pvs_cad`).
- **Defaults taken for the other questions:** `:complete?` and DEC go, with every call site changed and a
  regression check (Q2); `:cad-only?` keeps the witness search out of the side decisions too (Q3);
  decq1 (Q4); the 20 lending theories are dissolved (Q5); the six NASALib-clashing names and `Mat` are
  renamed in Phase 3 (Q7); `cad_bath` stays on `main`, outside the NASALib directory (Q9); the SBCL
  budgets are accepted until Phase 3's portable timeout (Q10); examples stay in `cad/` until Phase 3
  (Q11); `mpoly_mono` goes (Q12); the gate policy of the corrections below (Q15); `full`,
  `v1.0-full`, `v2.0` (Q16); an example of `qe8`'s `qe2cd` fallback (Q17); `qe2cc` stays (Q18);
  `cad_terms_ex`'s duplicated slow option tests move to cheaper formulas after measuring (Q19); the
  historical theory names stay for now (Q20). Q14 waits for Phase 3.

## Open items carried from the old plans

The plans left these open; they stay open on `main` and are not part of the slim:
- NEXT_PLAN step 4: the review and plan of P7 (PROJ_PLAN's McCallum / Brown / Lazard projection).
- PROJ_PLAN P4, P6 and P7: the problems still out of reach (Bath 04, 05 and 07 as decisions, the
  L_n family from n = 4, AM-GM in four variables, Mignotte's polynomial).
- TERMS_PLAN: n-th roots and `reals@quadratic` (T3 leftovers); Taylor-model enclosures for terms of
  two constants that need fine pieces (from T5).
- GAP_PLAN "What remains": the smaller projection with a delineability proof; the witness search on
  top of `decide8`; the optional geometry; the QE output items.

## How each step is checked (the owner's rule, 6 October 2026)

This replaces the gate policy of §2.0 and of the corrections below: each step is checked once,
by `tools/check.sh` on the theories it changed, which proves them and every theory of `top.pvs`
that imports them in one proveit session (traces on), in a scratch copy that keeps its compiled
library. Unchanged theories are not proved again; no per-theory runs, no three-run gates, no
full replay per step. When the strategies or an entry theory change, the affected set includes
the examples, and `tools/msgcheck.sh` and `tools/outside.sh` run. A full replay with traces is
made once, for the release.

## Corrections from the adversarial checks

**Typecheck blockers.** An import cut hides the types of VAR declarations that stay behind, and PVS
typechecks a VAR even when nothing uses it. The first version missed these:
- **S6:** delete `towern_def`'s unused VARs (all but `T1`, `T2`) and `tower_def`'s `s: VAR Sect` and
  `ss: VAR list[Sect]` (with the decw3 declarations).
- **S7:** delete `tlc.fin_near` (it uses `mpar`'s `near?`), `alg_sturm`'s `a: VAR Alg` and `cad_delin`'s
  `s: VAR Sect`. Add `IMPORTING reals@abs_lems` (and `reals@real_orders`, `structures@listn`) to `mpar`:
  its kept proofs `near_refl` and `near_hd` used their auto-rewrites.
- **S8:** delete `svs_tree`'s `cx`, `infvs` and `select_infvs`, `rsc_tree`'s `cx` (they use `snorm_ctx`
  and `tarski_ctx`), and `cad_decide`'s `t: VAR btree[SVL]`.
- **S9:** delete `cad_proj`'s `cofs`, `proj`, `proj1`, `projr`, `proj_null` and their 8 TCCs (the TCC
  proofs use `sg_svs.len_cdr_LL`); `cad_lift`'s `sg: VAR SG`; `far_sign`'s `ps` and `p`; `pos_dec`'s
  `b: VAR branch_tree[bool].Branch`; `crit_pos`'s `big_pos_left`, `far_neg_left` and `far_neg_right`
  (they cite `chain_sturm.arr_lc`), or give `crit_pos` a temporary `IMPORTING chain_sturm`.
- **S10:** do S11's deletions in `walk_transfer` (the `fib_local` family, 29 formulas) and `zfam` (13
  formulas) here: they use declarations of `sign_pers`, `level_ok` and `closed_pt` that S10 dissolves.
  Add `IMPORTING ints@abs_rews` to `sturm_step2` (`sstep2_prop` used its auto-rewrite). Every moved
  declaration takes the VARs it uses (29 VAR declarations at 11 destinations), placed before it, and
  goes before its first user in the destination. Expect to re-prove `crit_pos.pf_deriv_at_TCC1`.
  Move one source theory at a time.
- **S11:** in `branch_tree`, also delete the six VARs of the types `SignCond` and `Branch` and the
  mid-body IMPORTING whose actual is `Branch`.

**NASALib visibility.** A cut can hide NASALib judgements and auto-rewrites that kept proofs used:
`reals@real_orders`' `le_realorder`, `lt_realorder`, `ge_realorder`, `gt_realorder` (41 saved proofs in
7 kept theories) and `structures@listn`'s `listn_0`. Add the NASALib import at the step of the loss, or
once in a common base theory, and put those theories in the step's gate.
`IMPORTING cad@pvs_cad` will also stop bringing 22 NASALib theories into a user's context; the README
says so.

**Gate policy.** A step reruns every theory whose import closure (local or NASALib) changed, not only
the edited theories and their direct importers; the checker lists them. That is the rule "prove only
the edited theories and the affected examples", with the affected set computed. A fast example subset
runs at every step (`cad_showcase`, `cad_forms_ex`, `qe8_ex`, `cad_decide8_ex`, `tests/outside`, about
5 minutes). Library-only whole replays (12-15 minutes) after S8 and S11, then the release replay with
traces.

**S3.** Keep `cad-finish__`, the finisher of `(cad-direct)`'s prenex route; remove only its decide? and
complete? branches and the `dstr` binding, and make `"decide8"` the default.

**Q2 (`:complete?` and DEC).** Three internal calls pass COMPLETE? by position. Dropping the parameter
would put nil into the cad-only? slot and silently bring the witness search back under
`(cad * :cad-only? t)` and `(cad-num :cad-only? t)`, undoing a review fix. Either keep the parameters,
accepted and ignored, or change every call site (`pvs-strategies` lines 1356, 2118, 2421, 3132,
3171-3176, 3255, 3261, 3264, 3269, 4370, 4389, 4392, 4394, 4690 at `5700fd9`) and add a regression
check that `:cad-only? t` keeps the witness search out.

**An example for every kept result** (the owner's decision): add instances, in `col_found_ex` or a small
`cad_results_ex` (8-10 lemmas): `decb_cad_run` and `decb_cad_input` on the circle family,
`col_verified` (`ccad_of?`), `col_cells_sa`, `qelim` with `qelim_qf` and `qelim_ok` on a small formula,
and `fod_qfd`.

**Guards for earlier fixes.** A `.prf` lint (one proof per formula, no POSTPONE, no stale entries) in
`replay.sh` and the release gate; an outside test that imports `pvs_cad_num` and the theorem theories
(`col_line`, `col_found_ok`, `decb_run`, `col_verified`, `cad_sa`, `qelim_ok`) and cites a few
once-ambiguous lemmas; `msgcheck` rows for `(cad-qe)` without `qe8` and for `:cad-only? t`.

**Effort, re-estimated.** S6, S7 and S8 about half a day each; S10 2-3 days; S11 one day; Phase 2 in
all 8-11 working days, plus 1-2 hours of gates per step; Phase 3 3-4 days; Phase 4 1.5-2 days. A small
tool that deletes named declarations from `.pvs` files, driven by Appendix A, would pay for itself.

**Minor.** S11 touches 56 theories, not 61. Saved dependency lists are partial evidence (some are stale,
some lack same-theory uses): check the proof scripts too before deleting in place. Add `qe_g_qf` to Q6.
After S11, drop `croot_near`'s IMPORTING of `product` and its IMP TCC if the typecheck allows. The
export scan also looks for the machine's account name and `/tmp` and `/private` paths. Add to the
phases: `setup.sh` (Phase 1), the tools for `examples/` and `tests/msg/` and the circular-deps README
(Phase 3), `s_gen_answer.txt`, the robustness table and the priority wording (Phase 4). Run a
duplicate-name scan against NASALib master before contacting the maintainers.

## 0. In brief

1. **The target** (defaults of §6):

   | | today (`5700fd9`) | slim |
   |---|---|---|
   | library theories in `top`'s closure | 339 | **213** (none of the engine theories `cad_decide3`–`7`, `cad_lift`, `cad_fast`, `decn_ok`, `qe2c*`, `qe_all` remains; the QE answer-layer files keep their historical names, Q20) |
   | example and test theories in `top` | 38 | **15**: 12 kept, 1 new (`col_found_ex`), and 2 `mpoly` examples if `(mpoly-eq)` stays |
   | formulas, library / examples | 4,913 / 715 | **≈3,180 / ≈466** |
   | proof replay, library / examples (s, with traces) | 823 / 1,799 | **≈546 / ≈1,575** (`cad_terms_ex` alone is 994 s) |
   | per-theory typecheck time of the library (sum) | ≈259 s | ≈159 s |
   | PVS lines in library files | 24,180 | ≈14,300 |
   | `pvs-strategies` | 4,769 lines, 270 forms | ≈3,700 lines (≈3,600 without `mpoly-eq`) |
   | import closure of `pvs_cad` / `pvs_cad_num` | 307 / 309 | 206 / 208 |
   | import closure of `cad_decide8` / `qe8` / `cad_decide` | 247 / 280 / 64 | 154 / 190 / 5 |
   | import paths PVS 8.1's circularity check walks from `pvs_cad` | 3.25×10⁹ | ≈2.9×10⁶ (≈1.1×10⁶ once redundant imports go) |
   | theories outside `top` | 16 | 4 (the `msgcheck` inputs) |

   - Every KEEP result, every KEEP command and every fix stays.
   - Nothing is re-proved beyond 1 + 3 + 3 + 44 moved or edited formulas (S4, S5, S9, S10) and the
     example migrations (S2).

2. **The steps** (§2). Each is gated, and each leaves a library that replays.
   - **Phase 0 (preserve):** branch `full` and tag `v1.0-full` (dev), after the pending public push.
   - **Phase 1 (repository, no theory change).**
   - **Phase 2 (library):**
     - **S1:** delete the dropped leaves and the dropped commands.
     - **S2:** migrate the examples to `pvs_cad`; add `col_found_ex` and `q8_disc2g`.
     - **S3:** Collins-only dispatch in the strategies; `qe_all` goes.
     - **S4:** cut decide5 and decide7 from `cad_decide8`.
     - **S5:** the QE engines go.
     - **S6:** the n-level read-closure engine leaves the kept theories.
     - **S7:** the walk side's import-only imports go.
     - **S8:** the Phase 3/5 context trees go.
     - **S9:** decq1, after which the Tarski-query trees go.
     - **S10:** the 20 theories that only lend declarations are dissolved into their users.
     - **S11:** the remaining unused declarations go.
   - **Phase 3:** NASALib readiness.
   - **Phase 4:** docs.
   - **Phase 5:** release `v2.0` and the public export.
   - **Phase 6:** the NASALib pull request, after the maintainers agree.

3. **What is lost** (§3):
   - **Engines and their results:**
     - the read-closure decision engines decide3/4/5/6/7, with `decide5_decides`;
     - the n-level engine's CAD theorems: `cad_verified`, `cad_found_cad`, `cad_cells_sa`, `cad_run`,
       `cad_out_ok`, `cad_decides`, `rcell_*`;
     - the `qe`/`qe1`/`qe2`/`qe2c` QE engines, with `qe_complete`.
   - **The Phase 3 one-variable machinery** and the Phase 6 / item 1 / item A research routes.
   - **Commands:** `(alg-roots)`, `(poly-sign)`, `(poly-nosign)` and the measuring and inspection
     commands; by default also `(poly-pos)`, `(poly-nonzero)`, `(qe-exists)` and the `:complete?`/DEC
     options.
   - **Examples, tools and documents** of the above.

   Every kept result and command keeps at least one example or test. The gaps: the `qe2cd` fallback
   of `qe8` has no example, and the reduction path of the witness search is tested only by the CC BY-SA
   `cad_bath` (§3.4).

4. **Disagreements** between the reports, checked and resolved (§4). The main ones:
   - decq1 frees 27 theories (decide), not 16 (strategies).
   - `twrun_ok` does not need `qe2_ok`.
   - `cad_decide8` must import `cad_endgame`.
   - `cad_bath` is migrated on dev `main` but kept out of NASALib.
   - The circularity fix stops being essential once the imports are cut.

---

## 1. The target

### 1.1 Numbers after each step (library only; examples in 1.3)

"Freed" means the theories that leave the library at that step. "Deleted in kept" means declarations
deleted inside theories that stay (counts are of formulas).

| after step | library theories | formulas | proof s | theories freed (formulas, s) | deleted in kept (formulas, s) |
|---|---|---|---|---|---|
| today | 339 | 4,913 | 822.9 | — | — |
| S1 dropped leaves and commands | 317 | 4,747 | 803.2 | 22 library (166, 19.7) + 23 examples | 0 |
| S2 examples migrated | 317 | 4,747 | 803.2 | 0 | 0 |
| S3 Collins-only dispatch | 315 | 4,742 | 802.6 | 2 (5, 0.6) + `qe_cad_ex` | 0 |
| S4 decide5/7 chain | 305 | 4,707 | 797.6 | 10 (33, 4.9) | 2 (0.1) |
| S5 QE engines | 292 | 4,527 | 764.2 | 13 (145, 26.8) | 35 (6.6) |
| S6 n-level read-closure engine | 284 | 4,332 | 727.7 | 8 (87, 12.5) | 108 (24.0) |
| S7 walk-side import-only imports | 273 | 4,113 | 673.0 | 11 (124, 28.5) | 95 (26.3) |
| S8 Phase 3/5 contexts | 264 | 4,004 | 651.3 | 9 (84, 12.0) | 25 (9.7) |
| S9 decq1 | 233 | 3,398 | 570.7 | 31 (414, 48.1) | 192 (32.4) |
| S10 moves | 213 | 3,365 | 567.1 | 20 dissolved (44 formulas re-homed, 33 deleted) | 0 |
| S11 unused declarations | 213 | **3,179** (+≈4 from decq1 and the S5 moves) | **545.5** | 0 | 186 (21.6) |

Total change: 126 library theories leave (150 theories of `top`'s closure, with the examples).

### 1.2 The kept library: 213 theories

Counts in parentheses are `.prf` formulas after all steps, moved-in lemmas included. The groups are
`top.pvs`'s own headings.

- **Entry points and forms (5).** `pvs_cad` (0), `pvs_cad_num` (0), `gform_def` (17), `gform_ok` (23),
  `trans_bounds` (27).
- **Collins (71).**
  - Decision: `cad_decide8` (7), `cad_decide8_def` (0), `fsplit_top` (6), `fsplit_top_def` (5),
    `decb_def` (0), `decb_ok` (11), `decb_run` (8), `decb_u` (2), `decb_u_def` (3), `decc_def` (4),
    `decc_ok` (6), `decc_u_def` (3), `decc_walk` (8).
  - Projection and towers: `cad_projb` (30), `cad_projb_def` (11), `cad_projn` (30),
    `cad_projn_def` (18), `col_tower` (16), `col_tower_def` (4), `col_towerb` (5).
  - The Collins CAD: `col_def` (13), `col_eff` (36), `col_loc` (23), `col_out` (1), `col_out_ok` (6),
    `col_pair` (43), `col_real` (15), `col_run` (7), `col_sem` (8), `col_stack` (4),
    `col_verified` (3), `col_line` (7), `col_found_def` (2), `col_found_ok` (16).
  - Polynomial arithmetic for the checked basis and the determinants: `mpoly_gcd_def` (49),
    `mpoly_cert` (10), `mpoly_cert_def` (3), `mpoly_dom` (12), `det_fast` (48), `det_fast_def` (31),
    `bareiss` (75), `bareiss_def` (13), `rdet_lin` (12), `rdet_nl` (23), `sres_eval` (7),
    `sres_gcd` (8), `sres_rows` (38), `sres_thm` (33), `ev_near` (9).
  - Complex polynomials: `cpoly_alg` (33), `cpoly_der` (9), `cpoly_dist` (20), `cpoly_div` (13),
    `cpoly_ord` (17), `croot_disc` (9), `croot_lsc` (24).
  - QE and semi-algebraicity: `qe1c_def` (1), `qe1c_ok` (6), `qe2cc_def` (4), `qe2cc_ok` (14),
    `qe2cd_def` (4), `qe2cd_ok` (15), `ctwd` (29), `ctwd_def` (5), `twrun_def` (0), `twrun_ok` (5),
    `qe8` (6), `qe8_def` (0), `qelim_def` (5), `qelim_ok` (9), `cad_sa` (3).
- **QE answer layer (17).** These are engine-independent and live in the decide5-era files for
  historical reasons only. `qe_def` (12), `qe1_ok` (16), `qe1_full` (4), `qe2_def` (21), `qe2_ok` (54),
  `qe2_sep` (19), `qe_ep` (16), `qe_ep_def` (11), `qe_ep_ok` (17), `qe_fm` (4), `qe_fm_def` (5),
  `qe_ldd` (3), `qe_ldd_ok` (1), `qe_mrg` (17), `qe_mrg_def` (0), `qe_thom` (15), `qe_tsep` (3).
- **CAD records and semantics (16).** `cad_conn` (5), `cad_fibre` (29), `cad_fold` (0),
  `cad_fold_ok` (16), `cad_out` (12), `cad_out_ok` (23), `cad_roots` (30), `cad_run` (11),
  `cad_slab` (9), `cad_stack` (0), `cad_stkc` (21), `cad_tower` (18), `rcf_cad_def` (0),
  `rcf_cells` (7), `rcf_fol` (19), `root_fol` (13).
- **Walk, tower and oracle descriptors (44).** This is the machinery decide8's Collins run walks on.
  - Walk: `walk_def` (30), `walk_ok` (47), `walk_od` (65), `walk_rd` (49), `walk_search` (41),
    `walk_transfer` (40), `walk_count` (12), `walk_fuel` (1).
  - Towers and descriptors: `tower_def` (12), `tower_ok` (13), `tower_ev` (10), `towern_def` (0),
    `towern_od` (30), `innern_sem` (17), `lev_ev` (15), `oddef` (15), `od_exact` (3), `odreads` (16),
    `cvl` (14), `cover` (8), `cell_ok` (12), `cert_all` (18), `tclf` (5), `zfam` (12), `ztrunc` (12),
    `mpar` (11).
  - Sturm and signs: `sturm_sg` (38), `sturm_sg2` (7), `sturm_fast` (16), `sturm_tarski_ends` (11),
    `sep_exist` (17), `sect_svec` (9), `qsec_rd` (13), `qsec_lift` (2), `rd_norm` (3), `chain_rd` (4).
  - Other: `loc_const` (6), `ev_nat` (4), `ev_pred` (2), `alg_isign` (6), `poly_gcd` (12),
    `pl_shift` (3), `pl_shift_def` (0), `cad_endgame` (3).
- **Per-cell signs and roots (15).** `cell1` (111), `sect_inv` (50), `alg_fast` (12), `alg_sign2` (7),
  `earr_ops` (36), `map_member` (2), `mpoly_div` (11), `mpoly_eqd` (15), `nsc_scale` (2), `sg_chain` (7),
  `sg_chain2` (9), `sg_norm` (10), `sturm_step2` (8), `subres` (3), `subres2` (3).
- **Semantics, sign vectors and complex roots (9).** `bform` (8), `cad_decide` (10, the semantics
  `sem`/`fsem`/`qfold` only), `chain_sturm` (37), `sign_vec` (5), `sector_rep` (10), `sturm_step` (9),
  `cpoly_unique` (9), `croot_near` (10), `croots` (6).
- **Symbolic remainder sequences (12).** `branch_norm` (6), `branch_prs` (30), `branch_tree` (5),
  `btree` (0), `crit_pos` (9), `earr_deriv` (8), `mpoly_prod` (10), `mpoly_real` (10),
  `poly_unique` (10), `prem_arr` (14), `snorm_arr` (5), `tarski_chain` (38).
- **Algebraic numbers (12).** `alg_count` (27), `alg_def` (33), `alg_isolate` (40), `alg_order` (14),
  `alg_rat` (3), `alg_rat_def` (7), `alg_sign` (38), `alg_sortc` (13), `alg_sortc_def` (21),
  `alg_zero` (21), `thom_enc` (18), `thom_lemma` (22).
- **Polynomial kernel (10).** `PolyExpr` (datatype), `mpoly` (datatype), `mpoly_arith` (43),
  `mpoly_coefs` (8), `mpoly_def` (29), `mpoly_embed` (23), `mpoly_norm` (13), `mpoly_pdiv` (33),
  `mpoly_unique` (20), `mpoly_univ` (30).
- **Determinants (2).** `ring_det` (10), `sylvester` (1: only `coef_at`, `coef_at_earr` and
  `rcoef_at` are used).

**Runtime needs a proof-dependency slice misses.** The roots above cover them all, and I checked that
no step deletes or moves any of these names:
- `trans_bounds`, with the 14 bound lemmas T5 cites by qualified name;
- the `PolyExpr` datatype;
- `mpoly_embed` whole: `pnorm`, `pto`, `peval_pnorm`, the `peval_p*` and `nth0_*` lemmas, and
  `poly_eq_by_norm`;
- `gform_ok` whole: the 18 `gb_*` rewrites, 13 of which no saved dependency list shows, and `qe_g_ok`;
- `gform_def`'s `qe_g` and its 15 Gm constructors;
- `mpoly_def`'s `meval_as_list` and `as_list`, and `mpoly_norm`'s `meval_mnorm` and `mnorm`;
- `cad_endgame`'s `cadz_s3_pos`, `cadz_s3_zero` and `cadz_s3_neg`;
- the 81 evaluated-only definitions (for example `mpoly_gcd_def`'s untrusted basis proposal and
  `qe_def`/`qe2_def`'s pruning heuristics);
- the theory names `cad-imports?` checks: `cad_decide8`, `qe8`, `gform_ok` and `trans_bounds`;
- the record fields `ok`, `val`, `qf` and `out`.

`cring` (used by 24 kept proofs in 9 theories: `col_real`, `cpoly_alg`, `cpoly_der`, `cpoly_div`,
`cpoly_ord`, `croot_disc`, `croot_lsc`, `sres_rows` and `sres_thm`) stays in `pvs-strategies` as an
internal step.

### 1.3 Kept examples and tests

| theory | imports after S2 | formulas, s (today) | what it regression-tests |
|---|---|---|---|
| `cad_showcase` | `pvs_cad` | 63, 188.0 | README examples; every `(cad)` form; `(cad-direct)`; `:cad-only?`; `(cad-qe)` with `(cad *)` |
| `cad_forms_ex` | `pvs_cad` | 99, 108.9 | formulas of any shape (`decide_g`, `qe_g`); model search (`fx_h_grouped`) |
| `cad_terms_ex` | `pvs_cad_num` | 113, 993.9 | `(cad-num)` and its options, `(cad-facts)`, T2–T5 |
| `qe8_ex` | `qe8, mpoly_embed, cad_endgame` | 11 + `q8_disc2g`, 58.5 + ≈4 | `(cad-qe)` with the minimal import, without `gform_ok` |
| `cad_examples`, `cad_examples2`, `cad_examples3`, `cad_examples4` | `pvs_cad` (was `cad_decide5`) | 41, 48.2 | 2–4 quantifiers; constant fold (`w_trivial`, `w_trivial_h`, the only tests of `cadw-trivial`); grouped binders |
| `cad_endgame_ex` | `pvs_cad` (was `cad_decide5`) | 20, 23.0 | the endgame on every comparison and connective |
| `cad_star_ex` | `pvs_cad, reals@sqrt` (was `cad_decide5`) | 16, 31.2 | `(cad *)` abstraction, skipping, quantified hypotheses |
| `cad_bath` | `pvs_cad` (was `cad_decide5`) | 15, 34.4 | the witness search's one-variable reduction (`bath_02`, `bath_05_false`), its only test; CC BY-SA, kept out of NASALib |
| `cad_decide8_ex` | `cad_decide8, mpoly_embed` (drops `cad_decide5`) | 9, 21.1 | `(cad :cad-only? t)` on 2 quantifiers, 1 quantifier (`c8_one`, decq1's branch) and a hypothesis; `(cad-direct)` speed cases |
| `col_found_ex` (new) | `col_found_ok` | ≈7, a few s | the Collins CAD as data on the unit circle and the line; instances of `col_found_cad` and `col_found_decides` |
| `mpoly_examples`, `mpoly_showcase` (only if `(mpoly-eq)` stays, Q1) | `mpoly_embed, reals@sq` | 71, 11.1 | `(mpoly-eq)`, `(mpoly-simp)` |
| outside `top`: `cad_msg_ex.pvs` (`cad_msg_ex`, `cad_msg_pc`, `cad_msg_d5`→`cad_msg_d8`, `cad_msg_qe`) | `pvs_cad_num`; `pvs_cad`; `cad_decide8, mpoly_embed`; `qe8, mpoly_embed, cad_endgame` | by design not provable | `tools/msgcheck.sh`, 17 checks (`m_qe_nat` goes with `(qe-exists)`) |
| `tests/outside/use_pvs_cad` | `cad@pvs_cad` | 6 | the library imported from another directory; NASALib's `sign3_pos` is not hidden |

### 1.4 Removed theories, by step and reason

**S1, 45 theories in `top` (411 formulas, 257.4 s, 2,303 lines), plus 12 outside `top`.**
- **Examples of dropped engines or commands:** `cad_decide7_ex`, `cad_diag_ex`, `cad_out_ex` (replaced
  by `col_found_ex`), `alg_strategy_examples`, `sgn_examples`, `pos_examples`, `qe_run`, `qe_symbolic`,
  `qe_examples`, `tarski_examples`, `mpoly_mono_examples`, `alg_examples`.
- **Measurement:** `cad_meas`, `alg_bis_ex`, `alg_dec_ex`, `alg_lift2_ex`, `cad_fast_ex`,
  `cad_pdec_ex`, `alg_meas`.
- **The psc_det?, Phase 6 and item 1/A routes:** `psc_det_ce`, `psc_det_quad`, `quad_sign`, `quad_set`,
  `quad_det`, `psc_quad1`, `fib_quad`, `disc_quad`, `delin_bridge`, `spec_deg`, `sturm_habicht`,
  `cad_decn`, `cad_projc`, `projc_mem`, `alg_dec`, `alg_lift2`.
- **Support of the dropped commands:** `alg_strategy`, `sgn_dec`, `sgn_prune`.
- **The mult_poly bridge:** `mpoly_mono`.
- **Read-closure results that are not required:** `complete_all` (`decide5_decides`), `cad_found_def`,
  `cad_found_ok` (`cad_found_cad`), `cad_decide6`, `cad_decide6_def`, `decc_u` (only `decc_u_def` is
  used).
- **Outside `top`:** `cad_demo`, `cad_limits`, `cad_limits2`, `cad_limits3`, `bench_c`, `bench_n`,
  `bench_pdec`, `cad_meas2`, `cad_meas3`, `cad_meas4`, `cad_meas5`, `eval_probe`.

**S3, 3 theories (17 formulas, 44.0 s).** `qe_all`, `qe_all_def` (read-closure QE, `qe_complete`)
and `qe_cad_ex`.

**S4, 10 theories (33 formulas, 4.9 s).** `cad_decide3`, `cad_decide3_def`, `cad_decide4`,
`cad_decide4_def`, `cad_decide5`, `cad_decide5_def`, `cad_decide7`, `cad_decide7_def`, `cad3`, `decide_u`.

**S5, 13 theories (145 formulas, 26.8 s).** `qe2c_def`, `qe2c_ok`, `qe2c_u_def`, `qe2c_full`,
`aug_univ`, `aug_ev`, `runT_def`, `runT_ok`, `cad_sample`, `cad_verified`, `decide_u_def`,
`decn_complete`, `clos_ev`.

**S6, 8 theories (87 formulas, 12.5 s).** `cad3_def`, `cad_fast_def`, `nclos_ok`, `tower_univ`,
`tower_sem`, `read_fam`, `read_univ`, `list_flat`.

**S7, 11 theories (124 formulas, 28.5 s).** `alg_lift`, `alg_sturm2`, `mpoly_swap`, `cad_local`,
`cad_pdec`, `cells_local`, `joint_cont`, `mroot`, `mwalk`, `root_cont`, `walk_same`.

**S8, 9 theories (84 formulas, 12.0 s).** `qe_ctx`, `qe_tree`, `btree_prune`, `ineq_ctx`,
`tarski_ctx`, `prsp_ctx`, `snorm_ctx`, `hutch_oracle`, `svs_pt`.

**S9, 31 theories (414 formulas, 48.1 s).** These are needed only through decide8's call of
`cad_lift.decq2`.
- The read-closure lifting with Tarski-query trees: `sg_svs`, `svs_tree`, `tree_sel`, `sg_conj`,
  `sg_conj2`, `sign_oracle`, `conj_tree`, `ineq_ok`, `ineq_tree`, `many_ok`, `many_tree`,
  `tarski_count`, `tarski_many`, `tarski_multi`, `tarski_pair`, `tarski_tree`, `tarski_two`,
  `poly_farinf`, `poly_rolle`, `exists_dec`, `mpoly_cst`, `qe_conj`, `root_dec`, `sgn_count`,
  `sign_tree`, `alg_count2`, `branch_map`.
- What hangs off them: `bbindc_ex`, `branch_ctx`, `qe_formula`, `tarski_dec`.

**S10, 20 theories dissolved.** Their few needed declarations move to the theories that use them
(Appendix A.S10): `rsc_tree`, `alg_bis`, `cad_proj`, `cad_lift`, `complete1`, `cad_delin`, `cad_fast`,
`alg_sturm`, `clos_ok`, `closed_pt`, `decn_ok`, `inner_const`, `pt_local`, `level_ok`, `sign_pers`,
`tlc`, `far_sign`, `pos_dec`, `branch_sgn`, `cad_gpar`.

---

## 2. Ordered steps

### 2.0 Gate policy

The policy respects the owner's rules: prove only the edited theories and the affected examples, never
edit `.prf` files, and run one PVS at a time.

- **Every step** runs the following.
  1. A typecheck of the new `top`. It catches name-resolution breaks anywhere and takes about 3–4 min
     today, less later.
  2. `tools/gate.sh` on every theory whose text changed. A scratch theory that imports them all keeps
     the typecheck to one pass, as the QE study suggests.
  3. A rerun of the proofs of the theories that directly import a theory whose IMPORTING changed.
  4. If the step touches `pvs-strategies` or an entry theory: `tools/msgcheck.sh`, `tools/outside.sh`,
     and the examples that exercise the changed code.
  5. `tools/redundant_imports.py` and `tools/import_paths.py`, after import edits.
  6. `rm -rf cad/pvsbin` and a pvs-cli server restart (`tools/cli/srv.sh`) after theories are
     deleted.
  7. A cleanup of the ignored build products of deleted theories, after a `git clean -nX cad/` dry run.
- **Deletions and moves.**
  - Deleted declarations: PVS moves their proofs to `orphaned-proofs.prf`. Nothing is edited by hand.
  - Moved lemmas: replayed in their new theory through pvs-cli, from the saved script that
    `tools/cli/prfshow.py` prints.
  - New proofs (decq1): pvs-cli, with controlled steps, no `grind`.
- **Milestone replays** use a whole-library `tools/replay.sh` (added in Phase 1): after S5, after S9,
  and the release replay with traces after S11. Q15 asks whether the first two are wanted, given the
  owner's preference against full reruns.
- **Every step's commit** fixes the README, `top.pvs` description blocks, `msgcheck` table and plan
  citations that the step makes wrong. It also adds an entry to the root `PROGRESS.md`. Commit
  messages keep `Co-Authored-By` and have no session link.

### Phase 0. Preserve the full version (no library change)

- **Public repository, in this order.** The owner pushes the already-approved history rewrite
  (the staged rewrite, `2044e20` = dev `5700fd9` minus `paper/` and `CLAUDE.md`), then
  checks `git ls-remote`. Only then is the public annotated tag `v1.0-full` made at `2044e20`, with the
  noreply identity. Tagging before the push would pin the old history.
- **Dev repository:** branch `full` and annotated tag `v1.0-full` at `5700fd9`, then push both.
  Optionally delete the stale merged branch `s5e-redesign`.
- **Effort:** 15 min. **Risk:** only the ordering above.

### Phase 1. Repository-side commit (no theory change, no replay)

- **Off `main` (history only):** the 16 `*_PLAN.md` files, `cad/PROGRESS.md` and `cad/benchmarks/`.
  They stay on `full` and the tag.
- **New on `main`:** `HISTORY.md` (index, with links to the tag), a short root `PROGRESS.md` and
  `SLIM_PLAN.md`. `SLIM_PLAN.md` is this plan, carrying the open items: P4, P6 and P7; the rest of T3;
  the Taylor-model idea; the QE output items.
- **`tools/`:**
  - drop the 12 tools of the profiling and raw-session era: `prof.sh`, `prof/*.lisp` (3 files),
    `multi.sh`, `prove_each.sh`, `pvs_raw_timeout.sh`, `cmds.py`, `seqs.py`, `showlab.py`,
    `openstates.py`, `effective.py`;
  - add `replay.sh` (scratch-copy whole replay with `gate.sh`'s checks) and `stats.py` (the numbers
    the docs quote), with file-relative paths and environment overrides (portable-paths rule);
  - rewrite `tools/README.md`.
- **`export_public.sh`:** make the commit or tag argument mandatory (today it defaults to HEAD and
  could export a half-slim state), print a per-directory summary, and run the personal-information
  scan.
- **`CLAUDE.md` (private):** the reading order, the new location of PROGRESS, rule 2 removed, rule 6
  pointing to `replay.sh`, and the branch rules.
- **README:** a note that the slim is in progress and the full version is at `v1.0-full`.
- **Effort:** 2–3 h. **Risk:** low.

### S1. Delete the dropped leaves and the dropped commands

- **Theories deleted:** the S1 list of §1.4, 45 in `top` and 12 outside.
  - No kept theory imports any of them. I checked the import graph.
  - `cad_out_ex` goes here; its Collins counterpart comes in S2.
- **`pvs-strategies`,** whole forms deleted (line ranges of `5700fd9`; strategies study §6.1):
  - `(alg-roots)`: 234–362, 130 lines;
  - `(poly-sign)`, `(poly-nosign)`: 526–709, 185 lines;
  - the measuring and inspection commands `cad-bench`, `cad-m3`, `cad-mn`, `cad-time`, `cad-qeshow`,
    `cad-showf`, `cad-mx`: 3351–3567, 218 lines;
  - default (Q1): `(poly-pos)`, `(poly-nonzero)` (364–524, 162 lines) and `(qe-exists)` (712–1004,
    269 lines). Keep the helpers `qe-sub-e`, `qe-sub-p`, `qe-atom-parts` and `qe-list-str`, which
    `(cad)` uses;
  - default (Q1): keep `(mpoly-eq)`/`(mpoly-simp)` (101 lines; they need only `mpoly_embed`).
- **Other files:**
  - `tools/msgcheck.sh` drops the `m_qe_nat` row;
  - `top.pvs`: the IMPORTING list and the description blocks;
  - README: the command table, layout, examples and limits passages (repo study §4 lines 256–260,
    327–357, 375–394);
  - `NOTICE.md` (`bench_*`): see Q9 on `cad_bath`.
- **Proofs to redo:** none. The examples are replayed as the strategy regression (about 26 min) and
  `msgcheck.sh` is run.
- **Risk:** low.
  - A kept form could call a deleted helper. The strategies study's call graph says none does, and the
    examples replay checks it.
  - `mpoly_mono` goes with the mult_poly dependency (Q12).
- **Payoff:** 45 theories in `top` (411 formulas, 257 s of replay, of which 237 s are examples), 12
  playground and benchmark files with 115 untried lemmas (at least 14 of them FALSE), and about 964
  strategy lines.

### S2. Migrate the examples; the Collins records example

- **Migrate:** `cad_examples`, `cad_examples2`, `cad_examples3`, `cad_examples4`, `cad_endgame_ex`,
  `cad_star_ex` and `cad_bath` import `pvs_cad` instead of `cad_decide5, mpoly_embed`. `cad_star_ex`
  keeps `reals@sqrt`. `cad_decide8_ex` only loses `cad_decide5`. For each theory:
  - rewrite the header: it describes decide5, `decw`, `decn_o`/`decn_u` and read-closure timings;
  - fix `cad_star_ex.s_skip`'s and `s_two`'s comments (under `pvs_cad`, `s_two`'s four-variable
    version proves in 7.3 s);
  - rerun and save every proof on a pvs-cli server (`tools/cliprove.sh`; each proof is `(cad)`,
    `(cad -1)`, `(flatten)(cad -1)` or `(skeep)(cad *)`), so the dependency lists name
    `decide8_correct`. `cad_examples2.prf` still lists `decide4_correct`.
- **New theory `col_found_ex`** (examples study §6), replacing `cad_out_ex`:
  - `col_found` on `x²+y²-1, x²-1`: the `u` it stops at, each record's stack address and sign vector,
    and the one-variable line case;
  - instances of `col_found_cad` and `col_found_decides`;
  - optionally `decb_cad_run`.
  - The values are captured first by ground evaluation (`tools/cli/ev.sh`); then the lemmas are stated
    and proved through pvs-cli.
- **`qe8_ex`:** add `q8_disc2g`, which is `qe_cad_ex.qe_disc2g`: grouped binders through `(cad-qe)`
  without `gform_ok`.
- **Optional:** `bath_01`, `bath_03` and `bath_04` in `cad_bath` (model search, about 1.5 s), which
  turn a README measurement into a replayed lemma.
- **Proofs to redo:** about 70 one-command proofs rerun and saved; about 8 new lemmas.
- **Gate:** `gate.sh` on each migrated theory.
- **Risks:**
  - The K experiment of 1 October proved all 68 of these proofs with `cad_decide8`/`qe8` imported,
    twice. Not covered by it:
    - the lemmas added after 1 October (`ex_grouped`, `w_trivial`, `w_trivial_h`, `t_grouped`,
      `bath_02`, `bath_05_false`, three `cad_endgame_ex` lemmas);
    - `cad_star_ex` under `gform_ok`'s general route, which `pvs_cad` brings (`s_skip`).
  - `bath_02` and `bath_05_false` rely on SBCL wall-clock budgets (Q10).
- **Payoff:** the decide5-era examples stop pinning `cad_decide5`. This is a precondition of S3 and S4.
- **Effort:** half a day plus replays (the migrated set replays about +45 s slower).

### S3. Collins-only dispatch in the strategies; `qe_all` goes

- **`pvs-strategies`:**
  - `cad-dec` (1030–1033) returns `"decide8"`.
  - `cad-qe-fn` (1035–1037) returns `"qe8"`. Add a two-line refusal when `qe8` is not imported; today
    that case falls to a typecheck error.
  - `cad-main__`'s `odec` (3167–3172) is `decide8`. This is all that "re-pointing `(cad :cad-only? t)`
    to Collins" takes: under `pvs_cad` it already runs decide8.
  - Delete the exponential `cad_decide.decide`/`decide_correct_os` fallback in `cad-strategy` (1173,
    1225–1226) and `cad-finish__` (1241–1292).
  - Default (Q2): drop COMPLETE? and DEC (1294–1296, 1356, 1366, 4370, 4394, and the COMPLETE?
    threading at 3124–3269, 4389, 4392).
  - Rewrite the docstrings: 1006–1017, 1367–1397, 3270–3349, 3569–3589, 3879–3894, and the comment
    at 3717.
- **Optional** (Q3; the owner's "fix for real" rule argues for it): pass `cad-only?` to the side
  decisions `cadstar-tcc__`, `cadstar-typepred__`, `cadf-add__`, `cadf-loop__`, `cadt-sqrt__`,
  `cadt-div__`, `cadg-finish__`, `cadg__` and `cadstar-use`. That is about 15 call sites, so that
  `:cad-only?` really excludes the witness search.
- **Theories deleted:** `qe_all`, `qe_all_def` and `qe_cad_ex` (its `qe_disc2g` moved in S2).
- **`msgcheck` inputs:**
  - `cad_msg_d5` becomes `cad_msg_d8`, importing `cad_decide8, mpoly_embed`; `m_shape` keeps its text;
  - `cad_msg_qe` imports `qe8, mpoly_embed, cad_endgame`;
  - `m_nodec`'s expected text becomes "does not import cad_decide8". This must happen in the same
    commit as the `cad-dec` change.
- **Proofs to redo:** none. Gate with `msgcheck.sh`, `outside.sh` and the example replays.
- **Risk:** low to medium (strategy edits). The examples catch path changes and `msgcheck` catches
  text changes.
- **Payoff:**
  - 3 theories (17 formulas, 44 s);
  - about 90 strategy lines;
  - no kept command can reach decide5, decide7 or `qe` any more;
  - `cad_decide.decide`, `decide_correct_os` and `cad_lift.decide2` become unused, and S8 deletes them.

### S4. Cut decide5 and decide7 out of `cad_decide8`

The strategies study's §7.2 preconditions.

- **Edits:**
  - `cad_decide8_def`: IMPORTING `cad_lift, decb_u_def, fsplit_top_def`. Before:
    `cad_decide5_def, decb_u_def, fsplit_top_def`. `decq8` takes `decq2` from `cad_lift`.
  - `cad_decide8`: IMPORTING `cad_decide8_def, decb_u, fsplit_top, complete1, cad_endgame`. Before:
    `cad_decide8_def, cad_decide7, decb_u, fsplit_top`.
    - **`cad_endgame` is added on purpose.** No proof needs it, but without it every `(cad)` in a
      theory that imports `cad_decide8` without `pvs_cad` falls back to the exponential case-split
      endgame. Today `cad_decide8` gets it only through `cad_decide7`.
    - Move `len_ge2` here from `cad_decide7`. It needs only the prelude; replay its one-step script
      through pvs-cli.
  - `complete1`: IMPORTING `cad_lift`. Before: `cad_decide5`. Delete `decq5_complete1` and
    `decide5_complete1`.
  - `top.pvs`.
- **Theories deleted (10):** `cad_decide3`, `cad_decide3_def`, `cad_decide4`, `cad_decide4_def`,
  `cad_decide5`, `cad_decide5_def`, `cad_decide7`, `cad_decide7_def`, `cad3`, `decide_u`.
- **Proofs to redo:** `len_ge2` (moved); rerun `cad_decide8` (4 formulas) and `complete1` (2).
- **Gate:** `cad_decide8`, `complete1`; their importers `qelim_ok`, `gform_ok` and `pvs_cad`;
  `cad_decide8_ex`, `cad_showcase`'s `:cad-only?` lemma; `msgcheck`. I checked that after S1–S5 every
  kept theory still sees what its needed declarations use.
- **Risk:** low. **Payoff:** 10 theories (35 formulas). The read-closure decision engines leave
  `pvs_cad`'s import closure.
- **Effort:** 1–2 h.

### S5. The QE engines go

The QE study's steps 1–5 and 7.

- **The `qe2c` leftover.**
  - Move the one-line executable `dclx?` from `qe2c_def` to `ctwd_def`.
  - Move `every_mem_l`, `dclx_dcl` and `every_dclx` from `qe2c_ok` to `ctwd`, replaying their 5-to-10
    step scripts.
  - `ctwd` imports `qe2_def` (for `ttake`) in place of `qe2c_def`.
  - `qe2cd_ok` imports `qe2cd_def, qe2_sep, qe1_full`. Before: `qe2c_full, qe2cc_ok, qe2cd_def`; it
    needs nothing from `qe2cc_ok` and only `every_dclx` from `qe2c_ok`.
- **Engine parts deleted in place.** These are the "answer layer" files; no proof moves.
  - `qe_def`: the definitions `qe1`, `qe1_o`, `qe1_c`, `qe1_u` and `qe1_u_TCC1`, and its IMPORTING of
    `decide_u_def` (only `qe1_u`'s `MEASURE umeas` used it).
  - `qe1_ok`: 14 lemmas: `qe1_correct`, `qe1_qf`, `qe1_c_sem`, `qe1_c_qf`, `qe1_ent`, `qe1_cov`,
    `qe_ok_eq1`, `qe1_u_ok`, `qe1_u_eq`, `qe1_bf`, `qe1_bf_qf`, `all_cons`, `qe1_s_ok`, `qe1_sm_ok`.
  - `qe1_full`: `qe1_isqf`, `qe1_complete`.
  - `qe2_def`: `runok`, `qe2_c`, `qe2_o`, `qe2_u`, `qe2` and 3 TCCs.
  - `qe2_ok`: 13 formulas (`qe2_correct`, `qe2_qf`, `qe2_c_sem`, `qe2_u_ok`, `qe2_u_eq`, `qe2_bf`,
    `qe2_bf_qf`, `sect_sem_qe2_ok`, `runok_eq`, `rec_wf`, `liftp_sem` and their TCCs), and its
    IMPORTING of `cad_sample`.
- **`cad_sa`:** delete `cad_cells_sa` and its TCC, and cut `cad_verified`.
- **`twrun_ok`:** imports `cad_fold_ok` in place of `qe2_ok`. It uses `secr_mem`, `recin?`, `reccov?`
  and `fsinv?`, and nothing of `qe2_ok`.
- **Theories deleted (13):** `qe2c_def`, `qe2c_ok`, `qe2c_u_def`, `qe2c_full`, `aug_univ`, `aug_ev`,
  `runT_def`, `runT_ok`, `cad_sample`, `cad_verified`, `decide_u_def`, `decn_complete`, `clos_ev`.
- **Proofs to redo:** the 3 moved lemmas. Rerun `ctwd`, `qe2cd_ok`, `twrun_ok`, `qe_def`, `qe1_ok`,
  `qe1_full`, `qe2_def`, `qe2_ok` and `cad_sa`.
- **Gate:** those theories, then `qe8`, `qelim_ok`, `gform_ok`; `qe8_ex` and the `(cad-qe)` lemmas of
  `cad_showcase` and `cad_forms_ex`.
- **Risk:** low. The moved names are unique, and the QE study's `check_plan.py` and my check agree on
  visibility.
- **Payoff:** 13 theories and 180 formulas (33 s). After S5 the library is 292 theories and 4,527
  formulas. **First milestone replay.**
- **Effort:** half a day to a day, with the docs that it invalidates (`qe_capabilities.tex` rows
  `qe_correct`/`qe_complete`/`qe2c_ev`).

### S6. The n-level read-closure engine leaves the kept theories (no re-proof)

The engine is `decn_o`, `nclos_o`, `lvln_o`, `tclos_o`, `scof`, `scok?`; the run `runq`, `runsects`,
`runtw` and the n-level `cad_out`; the two- and three-level `decw`/`decw3`; and the read-closure
universe.

- **IMPORTING cuts:** `tower_def` and `cad_fast` drop `cad_fast_def`; `towern_def` drops `cad3_def`;
  `lev_ev` drops `nclos_ok`; `clos_ok` drops `tower_univ`; `innern_sem` drops `tower_sem`.
- **Direct imports added,** so that visibility is kept: `towern_def` + `mpoly`; `tower_def` +
  `alg_bis`, `sturm_sg`; `qsec_rd` + `walk_rd`; `innern_sem` + `tclf`; `lev_ev` + `clos_ok`,
  `inner_const`; `tower_ev` + `decn_ok`; `clos_ok` + `towern_od`.
- **Deleted in 17 kept theories:** 108 formulas (24 s) plus their definitions, closed under reverse
  references. The full list is in Appendix A.S6. The theorems among them:
  - `cad_run`: `cad_run`, `run_ok`, `sector_cad`, `sector_inv`;
  - `cad_out_ok`: `cad_out_ok`, `cad_out_mem`;
  - `cad_fold_ok`: `cad_decides`, `sector_*`;
  - `rcf_cells`: `rcell_ok`, `rcell_fod` and their `_le` forms;
  - `decn_ok`: `decn_correct`;
  - `cad_fast`: `decw_correct`;
  - `innern_sem`: `innern_sem`, `ia_*`;
  - `level_ok`: `cv_*`;
  - `towern_def`: trimmed in place to `Tower` and `zipapp`;
  - `tower_def`: loses decw3 (`inner2`, `dec3m`, `ok3m`, `cellvals`, ...).
- **Theories deleted (8):** `cad3_def`, `cad_fast_def`, `nclos_ok`, `tower_univ`, `tower_sem`,
  `read_fam`, `read_univ`, `list_flat`.
- **Proofs to redo:** none. 22 files are touched; their proofs are rerun.
- **Risk:** medium.
  - The step touches many theories, and the contexts of kept proofs lose names.
  - The proofs that stay depend, by saved lists and citations, on none of the deleted declarations.
  - 498 dependency lists were saved without a rerun; for those the citations are used, which leaves
    a small hidden-use risk. The gate catches it.
- **Payoff:** 8 theories, 195 formulas, 36 s. Every theorem about the read-closure engine leaves the
  library.

### S7. The walk side's import-only imports (no re-proof)

- **Cuts:** `cad_roots` and `tclf` drop `mwalk`; `tclf` and `cad_gpar` drop `mroot`; `mpar` drops
  `walk_same`; `pt_local` drops `root_cont`; `inner_const` drops `cells_local`; `cad_stack` drops
  `cad_local`; `cad_delin` drops `cad_pdec`; `alg_sturm` drops `alg_lift`; `alg_bis` drops
  `alg_sturm2`.
- **Adds:** `mpar` + `mpoly_def`; `sturm_sg` + `sg_chain2`; `cad_delin` + `cad_decide`; `cad_stack` +
  `cad_fibre`; `cad_roots` + `zfam`; `inner_const` + `cover`, `pt_local`; `tclf` + `zfam`;
  `cad_out_ok` + `cad_gpar`; `pt_local` + `cover`.
- **Deleted in 11 kept theories:** 95 formulas (26 s). Notable:
  - `tclf` is trimmed in place to `tlast`, `tlast_cons`, `len_cons_tclf` and `CLF`. It is not moved,
    because `"tclf.len_cons_tclf"` is cited qualified in 15 proof steps;
  - `cad_stack` is trimmed to `delin_cl?`;
  - `cad_tower` loses `tower_cad` and `rdag_up`;
  - `alg_sturm`, `alg_bis`, `cad_delin`, `cad_gpar`, `inner_const`, `pt_local` and `tlc` shrink to
    what S10 moves.
- **Theories deleted (11):** `alg_lift`, `alg_sturm2`, `mpoly_swap`, `cad_local`, `cad_pdec`,
  `cells_local`, `joint_cont`, `mroot`, `mwalk`, `root_cont`, `walk_same`.
- **Proofs to redo:** none. 19 files are touched.
- **Risk:** low to medium. **Payoff:** 11 theories and 219 formulas (55 s).

### S8. The Phase 3/5 context trees (no re-proof)

- **Cuts:** `rsc_tree` drops `bbindc_ex` and `qe_ctx`; `cad_lift` drops `svs_pt`.
- **Adds:** `rsc_tree` + `conj_tree`, `sign_oracle`; `cad_lift` + `sect_inv`.
- **Deleted in 4 kept theories:** 25 formulas.
  - `cad_decide`: `decide`, `decq`, `decq_correct`, `decide_correct`, `decide_correct_os`,
    `qfold_svs`, `sem_peel`. These are no longer referenced after S3.
  - `cad_lift`: `decide2`, `decide2_correct` and 11 helpers.
  - `rsc_tree`: `rsc`, `rsc_sound`, `rsc_complete`.
  - `svs_tree`: `svs`, `svs_sound`, `svs_complete`, `select_svs`.
- **Theories deleted (9):** `qe_ctx`, `qe_tree`, `btree_prune`, `ineq_ctx`, `tarski_ctx`, `prsp_ctx`,
  `snorm_ctx`, `hutch_oracle`, `svs_pt`.
- **Risk:** low (4 files). **Payoff:** 9 theories, 109 formulas, 22 s.

### S9. decq1: decide8's one-variable branch without the read closure

- **Change.** `decq8` calls `cad_lift.decq2` only with 0 or 1 quantifiers. `decq2`'s definition
  nevertheless carries the read closure for two or more quantifiers, and with it 27 theories of
  Tarski-query trees.
  - **New definition in `cad_decide8_def`:**
    ```
    decq1(qs, F, Psi): [# ok: bool, val: bool #] =
      IF null?(qs) THEN (# ok := TRUE, val := Psi(svec(F, null[real])) #)
      ELSE (# ok := svs1ok(F), val := qfold(car(qs), svs1(F), Psi) #) ENDIF
    ```
    These are exactly the two branches of `decq2` that run.
  - `decq8` calls `decq1` where it called `decq2`, and the IMPORTING of `cad_lift` goes.
  - **New lemma in `cad_decide8`:** `decq1_correct`, for `length(qs) <= 1`, from `sem`'s definition and
    `qfold_svs1`.
  - `decq8_correct` uses `decq1_correct` instead of `decq2_correct`. `decq8_complete` uses
    `svs1ok_complete` instead of `decq2_complete1`.
  - The statements of `decide8_correct` and `decide8_decides` do not change. The computation does not
    change. The strategies need no change.
- **Cuts:** `cad_decide` drops `svs_tree` and `tree_sel`; `cad_lift` drops `sg_svs`; `sect_inv` drops
  `alg_count2`; `sg_chain` drops `tarski_many`; `sector_rep` drops `poly_rolle`; `branch_prs`,
  `branch_sgn` and `rsc_tree` drop `branch_map`; `branch_sgn` drops `mpoly_cst`; `far_sign` drops
  `ineq_ok` and `sign_oracle`; `pos_dec` drops `root_dec`; `rsc_tree` drops `conj_tree` and
  `sign_oracle`.
- **Adds:** `cad_decide` + `rsc_tree` (for `SV`, until S10); `sector_rep` + `mpoly_prod`, `pos_dec`;
  `cad_lift` + `mpoly_eqd`; `pos_dec` + `mpoly_univ`; `sg_chain` + `tarski_chain`; `crit_pos` +
  `earr_deriv`.
- **Deleted in 16 kept theories:** 192 formulas (32 s; Appendix A.S9). Notable:
  - `cad_lift` keeps only `rts`, `sval`, `sval_sample`, `memb`, `memb1`, `memb1_member`, `dedup1`,
    `dedup1_member` and `qfold_svs1`. qe8 evaluates `rts`, `sval`, `memb1` and `dedup1`, so they must
    stay. `decq2`, `decq2_correct`, `lv_sound`, `sem_peel2` and `qfoldS_sem` go;
  - `sect_inv` loses 45 formulas (the `*_free_*` and `sep*` families);
  - `complete1` loses `decq2_complete1`;
  - `sg_chain`/`sg_chain2` lose the `tq`/`mts`/`lmn`/`slof` sign-oracle readers;
  - `chain_sturm` loses `ftree` and `select_ftree`.
- **Theories deleted (31):** the S9 list of §1.4.
- **Proofs to redo:** `decq1_correct` (new); `decq8_correct` and `decq8_complete` (edited scripts);
  reruns of the 16 trimmed theories.
- **Gate:** `cad_decide8`, `cad_decide8_def` (typecheck), `qelim_ok`, `gform_ok`, all examples,
  `msgcheck`.
- **Risk:** medium. This is the one new definition in the plan. `cad_decide8_ex.c8_one` tests the
  one-quantifier branch. Whether any example reaches the null branch should be checked by a trace;
  if none does, add a closed quantifier-free lemma to `cad_decide8_ex`.
- **Payoff:** 31 theories, 606 formulas, 80 s: the largest single payoff. After S9 the library is 233
  theories and 3,398 formulas. **Second milestone replay.**
- **Effort:** half a day to a day.

### S10. Dissolve the 20 theories that only lend declarations (re-proofs)

- **Moves:** 30 lemmas and 14 TCCs, plus definitions and types, to the theories that use them (full
  table in Appendix A.S10). The main ones:
  - `rsc_tree.SV`, `SVL` → `sign_vec`;
  - `alg_bis`'s `zc?`, `strip`, `lives`, `lsumk`, `bk`, `bprod`, `cad_proj.live?` and
    `cad_delin.fib` → `walk_def`;
  - `cad_lift`'s `rts`, `sval`, `sval_sample` → `sect_inv`; `memb`, `memb1`, `dedup1` and their
    lemmas → `mpoly_eqd`; `qfold_svs1` → `cad_decide8`;
  - `complete1.svs1ok_complete` and `far_sign.len_pos` → `cell1`;
  - `decn_ok`'s seven generic lemmas → `innern_sem` and `tower_ev`;
  - `clos_ok`, `inner_const` and `pt_local` → `lev_ev`;
  - `level_ok` → `cover`; `tlc.Tv` → `col_sem`; `cad_fast.insec`, `in_conv` → `cad_run`;
  - `alg_sturm.sign3_scale` → `sturm_sg`; `sign_pers.cont_sign` → `sep_exist`;
  - `pos_dec.pf`, `pf_cont` → `mpoly_real`; `branch_sgn.SL`, `msign_mnorm` → `sg_norm`;
  - `cad_gpar`'s `gap_lt`, `gr_nlt_hd`, `wsep?` → `cad_out_ok`.
- **Checks made:**
  - No moved name is already declared in its destination's import closure.
  - No proof or specification cites a moved name qualified.
  - No strategy cites a moved name.
  - The final graph has no cycle.
  - One VAR clash: `cont_sign` uses `f: VAR [real -> real]`, and `sep_exist` declares
    `f: VAR list[mpoly]`. Rename the variable in the moved lemma and adapt its script.
- **The final IMPORTING plan** changes 38 kept theories (Appendix A.final).
- **Deleted with the dissolved files:** 33 unneeded formulas (`cad_proj`'s projection with read
  closures, `closed_pt`'s `cl_transfer`, `decn_ok`'s list shapes, `sign_pers`'s `msg_pers*`, ...).
- **Proofs to redo:** the 44 moved formulas in their new theories, through pvs-cli from
  `prfshow.py`'s scripts; reruns of the 17 destination theories and their direct importers.
- **Risk:** medium (many small re-proofs). A move can be reverted per lemma.
- **Payoff:**
  - 20 theory files go, and the library reaches 213 theories;
  - the lending theories named after dropped engines (`cad_lift`, `cad_fast`, `cad_proj`, `decn_ok`,
    `clos_ok`, `complete1`) all go. The QE answer-layer files (`qe_def`, `qe1_ok`, `qe2_ok`, ...) and
    `towern_def`/`towern_od` keep their historical names (Q20);
  - the import paths from `pvs_cad` fall from about 8.4×10⁶ (after S9) to about 2.9×10⁶.
- **Alternative, if Q5 says no:** keep the 20 trimmed theories under their old names. The library
  stays correct with 233 theories.
- **Effort:** about a day.

### S11. Remaining unused declarations (no re-proof)

- **Deleted:** 186 formulas (21.6 s) and their definitions in 61 kept theories (Appendix A.S11).
  - Largest: `walk_transfer` 29 (the `fib_local` transfer family), `branch_tree` 22, `zfam` 13,
    `qe_mrg` 9 (unused QF lemmas; the QF check is made at run time), `thom_enc` 9, `crit_pos` 6,
    `subres` 6, `cad_tower` 5, `mpoly_norm` 5.
  - Each of these is reachable from no KEEP result and from no name the strategies use.
- **Needs an explicit yes from the owner (Q6):** corollaries and "coherent mathematics":
  - `col_verified.col_exists`, `col_found_ok.col_found_ccad`, `decb_ok.decb_complete`,
    `decc_ok.decc_complete` (cited in `cad_decide8_def`'s header comment);
  - `thom_enc.thom_encoding_distinct`, `thom_lemma.thom_distinct`, `sat_from_signs`;
  - `sylvester`'s `res`, `disc`, `res_eval`, `disc_eval`; `subres`'s `psc0_res`, `sres0_syl`;
    `subres2.psc_sres`;
  - `crit_pos.crit_exists`.
- **Not deletable, kept:** the IMPORTING TCCs of `crit_pos` (`IMP_derivative_props_TCC1`, `TCC2`) and
  of `croot_near` (`IMP_product_TCC1`), and every datatype that has a needed constructor.
- **Risk:** low. **Payoff:** 186 formulas, 22 s, about 700 lines. **Release replay with traces.**

### Phase 3. NASALib readiness

Decide the examples layout (Q11) before S2 if possible, so that the examples are rerun only once.

1. **Contact the maintainers first** (CONTRIBUTING requires it; this can happen in parallel with
   Phase 2). Agree on the directory name `CAD` or `cad` (Q13), the size (about 3,200 library formulas
   would be one of NASALib's largest libraries), the examples budget, the CC0 `@copyleft` line, the
   AI-generation statement and the circularity patch route.
2. **`top.pvs` tags:** `@library @description @author @poc @date @copyleft`. CC0 1.0 follows the
   `co_structures` precedent, worded as "PVS specifications and proofs", never "software". `@poc` is
   Q14.
3. **`CAD/README.md` in NASALib's template:** Highlights; a Major-theorems table with the 14 KEEP
   results; Strategies with their syntax; Examples; "How it was made"; how to cite (`@misc`, "PVS
   specifications and proofs"); Contributors; Dependencies. Add the `dependency-all` graphs.
4. **`examples/` subdirectory** with its own `top.pvs`, importing `CAD@pvs_cad` and `CAD@pvs_cad_num`.
   `tests/outside/use_pvs_cad` folds in, and a `pvs_cad_num` outside test is added.
   - The `msgcheck` inputs move to `tests/msg/`: `cad_msg_ex.pvs` holds 4 theories, against the
     one-theory-per-file rule.
   - `cad_bath` stays out (CC BY-SA), or a CC0 replacement sentence for the reduction path is written
     (Q9).
5. **Renames (Q7).** Six kept formula names clash with NASALib libraries we do not import:
   - `len1` (`cad_run`; 7 citing proofs);
   - `nth_cdr` (`earr_deriv`; 1);
   - `odd_even` (`cad_fibre`; 1);
   - `cont_const` (`cad_slab`; 1);
   - `left_zero`, `right_zero` (`sturm_sg`; 4 each).
   The type `Mat` (8 theories) clashes too. `len0` disappears with `cad_lift` in S9.
6. **Strategies:**
   - `[CAD]` docstrings without plan references (40 lines);
   - theory-qualified lemma citations, as NASALib's own strategies do (`"mpoly_embed.peval_padd"`);
   - PVS's portable `with-timeout` in `cad-eval-timed` and a small deterministic PRNG in
     `cadw-search`, which removes the SBCL requirement;
   - rename the `qe-*` helpers to `cad-*`.
7. **Comments:** remove the 141 plan/PROGRESS citations in 119 kept files, and the 12 mentions of
   dropped engines in 8 files. These edits are comment-only, followed by one replay.
8. **Redundant imports:** remove the 45 redundant IMPORTING entries left in the final graph
   (`redundant_imports.py`). The import paths from `pvs_cad` fall from about 2.9×10⁶ to about 1.1×10⁶.
9. **Packaging:** `prove-all -do=CAD,CAD/examples` and `dependency-all` in a **separate** NASALib clone
   at current master (never the installed `~/pvs-8.1/nasalib`); add the `nasalib.all` line, the root
   README rows and the summaries; make one commit. Generated files stay out (`*_adt.pvs`, `*.prf~`,
   logs, `pvsbin`).

### Phase 4. Docs (one commit, after the last library step)

- **README:** rewrite it (repo study §4, every passage by line number), with a "Full version" note
  pointing to `v1.0-full`.
- **`docs/`:**
  - rewrite `cad_overview.tex`, `collins_cad.tex` and `qe_capabilities.tex` (repo study §5) and
    rebuild them with Tectonic;
  - `cad_proof_traces` stays on the history branch (it was recorded with decide5);
  - point `qe_capabilities`' "proved" marks at `qe8_ex` (`q8_win` already exists there).
- **`NOTICE.md`:** the Bath block goes when the last Bath-derived file leaves `main` (Q9).
- **Also:** `HISTORY.md`, `CLAUDE.md`, and every number from `stats.py` on the final replay.

### Phase 5. Release and public export

1. The final replay with traces (`replay.sh`), `outside.sh`, `msgcheck.sh`; then the dev tag `v2.0`.
2. `export_public.sh` with the explicit tag, then the personal-information scan.
3. Show the owner the grouped file list and the commit message, and push only after an explicit OK
   (fast-forward on top of `2044e20`). Then the public tag `v2.0`.

### Phase 6. NASALib pull request (after the maintainers agree)

Fork `nasa/pvslib`; add `CAD/` and `CAD/examples/`; add the `nasalib.all` line, the summaries, the
graphs and the README rows; make one commit; the owner reviews it before it is opened.

**Effort overall.**
- Phase 2 (S1–S11): about 5–7 working days plus machine time.
- Phase 3: 1.5–2 days.
- Phase 4: about 1 day.

---

## 3. What is lost, and the coverage check

### 3.1 Results that go (they stay at `v1.0-full`)

- **The read-closure decision engines:**
  - `decide5_correct`/`decide5_complete` and `complete_all.decide5_decides`;
  - decide3, decide4, decide6 (`cad_decide6`, the `:complete?` safety net) and decide7
    (`decide7_correct`/`decides`);
  - `decide_u` (`decn_u`), `decn_complete`;
  - the read-closure fixpoint and its termination: `tower_univ`, `read_univ`, `read_fam`, `clos_ev`,
    `nclos_ok`;
  - `decn_ok.decn_correct`;
  - the 2- and 3-level methods `decw` (`cad_fast`) and `decw3` (`cad3`, `tower_def`);
  - the rational-sample decision `cad_pdec`;
  - the n-level lifting `cad_lift.decq2`/`decide2` and `svs_pt`.
- **The n-level engine's CAD:**
  - `cad_verified` (`cad_verified`, `cad_exists`, `cad_of?`);
  - `cad_found_ok.cad_found_cad`, `cad_sa.cad_cells_sa`;
  - `cad_run.cad_run`, `cad_out_ok.cad_out_ok`, `cad_fold_ok.cad_decides`;
  - `rcf_cells.rcell_ok`/`rcell_fod` and their `_le` forms, `cad_tower.tower_cad`.
  - The README claim "every cell of both CADs is semi-algebraic" becomes "of the Collins CAD".
- **QE engines:**
  - `qe_all` (`qe_correct`, `qe_isqf`, `qe_complete`);
  - `qe1_ok.qe1_correct`, `qe1_full.qe1_complete`;
  - `qe2_ok.qe2_correct`;
  - `qe2c_ok.qe2c_correct`, `qe2c_full.qe2c_bf`, `aug_ev.qe2c_ev`/`qe2c_complete`, `aug_univ`,
    `runT_ok`.
- **Phase 3 one-variable machinery and Tarski queries:**
  - `qe_formula.qe_sound`, `qe_tree`/`qe_ctx` (parametric QE);
  - `root_dec.qdec_sound`, `pos_dec.pdec_sound`, `sign_tree.sdec_sound`, `tarski_dec`, `exists_dec`;
  - the multi-polynomial Tarski queries `tarski_pair`/`two`/`multi`/`many`/`tree`, `many_ok`/`tree`,
    `ineq_*`, `sg_conj*`, `sg_svs`, `svs_tree`, `rsc_tree.rsc`, the `*_ctx` trees;
  - `sign_oracle`, `hutch_oracle`, `branch_map`/`branch_ctx`/`branch_sgn`, `btree_prune`, `mpoly_cst`,
    `poly_farinf`, `poly_rolle`, `far_sign`, `alg_count2`, `alg_lift`, `alg_sturm(2)`, `alg_bis`,
    `cad_proj`, `cad_delin`.
- **Continuity and local-constancy results of the n-level engine:** `cad_local`, `cells_local`,
  `root_cont`, `joint_cont`, `walk_same`, `mroot`, `mwalk`, `pt_local`, `inner_const`, `closed_pt`,
  `level_ok`, `tlc`, `sign_pers`, `cad_gpar`, `tower_sem`.
- **Research routes:**
  - Phase 6 (`cad_decn`, `cad_projc`, `projc_mem`);
  - item 1 / psc_det? (FALSE in general: `psc_det_ce`; `quad_*`, `psc_quad1`, `fib_quad`,
    `disc_quad`, `delin_bridge`, `spec_deg`, `sturm_habicht`);
  - item A (`alg_dec`, `alg_lift2`, `alg_meas`).
- **The mult_poly bridge** `mpoly_mono` (Q12).
- **Unused lemmas inside kept theories** (S11 and Appendix A).

### 3.2 Commands and options that go

- **Owner-listed:** `(alg-roots)`, `(poly-sign)`, `(poly-nosign)`; `cad-mx`, `cad-m3`, `cad-mn`,
  `cad-bench`; the profilers `cad-prof`, `cad-dprof`, `cad-fstr` (`tools/prof*`).
- **Default (Q1):** `(poly-pos)`, `(poly-nonzero)`, `(qe-exists)`; the inspection commands `cad-time`,
  `cad-qeshow` and `cad-showf`.
- **Default (Q2):** `(cad … :complete? t)` and `(cad-direct … DEC)`.
  - With decide8 they do nothing: it always passes its certificate.
  - No saved proof uses them.
  - Dropping them shifts `(cad)`'s positional arguments.
- **Implicit:**
  - `(cad)`, `(cad-direct)` and `(cad :cad-only? t)` no longer work in a theory that imports only
    `cad_decide5` or `cad_decide7`;
  - `(cad-qe)` no longer works with `qe_all`.
  - Such a theory gets the existing refusal "does not import cad_decide8", or the new one for `qe8`.

### 3.3 Examples, tools and documents that go

- **Examples:** the S1 lists in §1.4.
  - Fallback if Q1 keeps the corresponding commands: `pos_examples`, `qe_run` and `qe_symbolic` stay;
    `mpoly_examples` and `mpoly_showcase` go if `(mpoly-eq)` goes.
  - `cad_demo` (Q8), and the `cad_limits*` timings, which the README cites (keep the problems at
    `v1.0-full`, or add a proved "hard problems" theory under `pvs_cad`, about 60–80 s, Q8).
- **Tools:** the 12 of Phase 1. They stay on `full`.
- **Documents:** the plans, `cad/PROGRESS.md`, `cad/benchmarks/` and `cad_proof_traces.pdf` stay on
  history. The decide5 timing comparisons are kept as dated history at the tag (Q16).

### 3.4 Coverage check: every kept result and command

| kept | proved in | exercised by an example or test after the plan |
|---|---|---|
| `col_line.col_cells` | `col_line` | `col_found_ex` (the line's records); replay |
| `col_found_ok.col_found_cad`, `col_found_decides` | `col_found_ok` | `col_found_ex` (`circ_cad`, `circ_dec`) |
| `decb_run.decb_cad_run`, `decb_cad_input` | `decb_run` | replay only. Optional instance in `col_found_ex` (decide8's run is what every `(cad)` evaluates) |
| `col_verified.col_verified` | `col_verified` | replay; `col_found_ok` builds on it |
| `qe8.qe8_complete` (and `qe8_correct`, `qe8_isqf`) | `qe8` | every `(cad-qe)` proof: `qe8_ex` (8), `cad_showcase` Part IV (14), `cad_forms_ex` `fx_qe_*` (7), `use_pvs_cad.o_qe` |
| `qelim_ok.qelim_qf`, `qelim_ok`, `fod_qfd` | `qelim_ok` | indirectly, through `decide_g` and `qe_g` (66 `cad_forms_ex` proofs); replay |
| `cad_sa.col_cells_sa` | `cad_sa` | replay only (a theorem with no command) |
| `gform_ok.decide_g_ok` (and `qe_g_ok`, `gb_*`) | `gform_ok` | `cad_forms_ex`, `cad_showcase` Part I, `use_pvs_cad.o_gen` |
| `cad_decide8.decide8_correct`, `decide8_decides` | `cad_decide8` | every `(cad)` under `pvs_cad`; `cad_decide8_ex.c8_one` for decq1's one-quantifier branch |
| `(cad)`, full decision, 1–4 quantifiers | — | `cad_examples` to `cad_examples4` (32), `cad_endgame_ex` (18), `cad_showcase`, `cad_forms_ex`, `cad_terms_ex`, `o_cad` |
| `(cad)` witness search: model search | — | `cad_forms_ex.fx_h_grouped`, `cad_terms_ex.ub_abs_ex` (+ `bath_01/03/04` if added) |
| `(cad)` witness search: constant fold | — | `cad_examples.w_trivial`, `w_trivial_h` (only these) |
| `(cad)` witness search: budgeted decision, then one-variable reduction | — | `cad_bath.bath_02`, `bath_05_false` (only these; CC BY-SA; SBCL budgets) |
| `(cad n)`, `(cad -n)`, `(cad (m n))`, `(cad +)`, `(cad -)` | — | `cad_showcase` (`cube_roots`, `false_hyp`, `pick_two`, `together`, `goals_only`, `hyps_only`), `cad_forms_ex`, `cad_terms_ex.t_fail_keep` |
| grouped binders | — | `cad_examples.ex_grouped`, `cad_examples3.t_grouped`, `cad_forms_ex.fx_grouped`, `qe8_ex.q8_disc2g` |
| `(cad *)` | — | `cad_star_ex` (15), `cad_showcase` (27), `cad_forms_ex` (15), `cad_terms_ex` (11), `o_star` |
| `(cad-direct)` | — | `cad_showcase.box_plane_direct`, `cad_forms_ex.cd_general` (non-prenex), `cad_decide8_ex.c8_k3_lin`, `c8_l3_quad` |
| `(cad :cad-only? t)` | — | `cad_showcase.circle_cad_only`, `cad_decide8_ex.c8_circle`, `c8_one`, `c8_hyp`, `cad_terms_ex.cf_abs` |
| `(cad-qe)`: prenex, any shape, subtype binders, minimal import | — | `qe8_ex`, `cad_showcase` Part IV, `cad_forms_ex` (`fx_qe_and`, `fx_qe_sub`, `fx_qe_nz`, `fx_qe_syn`, `fx_qe_const`, `qe_alt_forms_ex`) |
| `(cad-num)` and options, `(cad-facts)`, T2–T5 | — | `cad_terms_ex` (`cn_star`, `cn_prec`, `cn_splits`, `cf_abs`, the T2–T5 groups); `msgcheck` `m_pi_*`, `m_t5_*`, `m_sqrt_false` |
| messages, refusals, hints | — | `msgcheck.sh` (17 checks after S1) |
| `cring` (internal) | — | 24 library proofs |
| `(mpoly-eq)`, `(mpoly-simp)` (if kept) | — | `mpoly_examples`, `mpoly_showcase` |

**Gaps, and how to close them:**

1. **`qe8`'s `qe2cd` fallback.** No example takes it, so `ctwd`, `twrun` and `cad_outw` are never
   evaluated. Check a candidate by one ground evaluation, for example QE_PLAN §5's
   `EXISTS t: 0 <= t <= T AND f(t) < D^2` with `T` and `D` free. Then add one `qe8_ex` lemma (Q17).
2. **decq1's null branch.** Confirm by a trace in S9's gate; if no example reaches it, add one lemma to
   `cad_decide8_ex`.
3. **`pvs_cad_num` imported from another directory.** It is untested; add an outside test (Phase 3).
4. **The reduction path.** It rests on `cad_bath` (CC BY-SA, SBCL budgets). A home-made CC0 sentence is
   needed before NASALib (Q9, Q10).
5. **`decb_cad_run`, `col_cells_sa` and `qelim_*`.** They have no worked instance. That is acceptable
   for theorems; `col_found_ex` can add instances cheaply.

---

## 4. Where the reports disagree, and which is right

| # | topic | what the reports say | evidence I checked | verdict |
|---|---|---|---|---|
| 1 | How much decq1 frees | strategies: 16 theories, 245 formulas, about 25 s. decide: 27, 383, 45 s | Decide's refined closure, re-run: 27 theories, 383 formulas, 45.3 s. Deps_lib's closure with `decq2` blocked keeps 11 theories through citation false positives: `tarski_pair.one` (the label `one` in `tower_ok.tower`); `tree_sel.T`, `branch_map.T`, `tarski_multi.T` (the name `T`); `conj_tree.ys`, `sgn_count.ys`, `tarski_count.ys` (VAR `ys`); `root_dec.c` (VAR `c`); `sign_tree.ctree` (overloaded `ctree`) | **decide is right.** The strategies' figure rests on an unfiltered citation closure, as its own caveat says. With S9's in-place deletions, 31 theories leave: the 27 plus `bbindc_ex`, `branch_ctx`, `qe_formula` and `tarski_dec`, which hang off them |
| 2 | `qelim_qf` needs `qe2_ok` through `twrun_ok` (task facts) | qe study: an artifact of the skolem name `TW` | `twrun_ok`'s saved non-skolem dependencies name no `qe2_ok` declaration. They name `cad_fold_ok`'s `fsinv?`, `reccov?`, `recin?` and `secr_mem` | **qe study is right.** `qe2_ok` stays anyway, for `qe2cc_ok` and `qe2cd_ok` (`secout_sem`, `part_sem`, ...). `twrun_ok` imports `cad_fold_ok` (S5) |
| 3 | The `qe2c` leftover | decide: keep `qe2c_def` and `qe2c_ok` trimmed in place, with `qe2cd_ok` importing `qe2c_ok`. qe: move `dclx?` and 3 lemmas into `ctwd_def`/`ctwd` and drop both theories | Both pass my visibility check. `qe2cd_ok` needs only `every_dclx` from `qe2c_ok` and nothing from `qe2cc_ok` | **the qe study's version.** It has 2 theories fewer and matches "move the few lemmas"; the cost is 3 re-proofs. Q-alternative: restate `ctwd_dcl` with `dcl?` |
| 4 | `cad_decide8` and `cad_endgame` | decide's import plan adds nothing (proof-driven). strategies: required | `cad_decide8` sees `cad_endgame` today only through `cad_decide7`. The strategies' endgame needs it visible wherever `(cad)` runs | **strategies is right.** Add the import in S4. It affects `cad_decide8_ex` and `cad_msg_d8`, not `pvs_cad` |
| 5 | Examples that import `cad_decide5`/`qe_all` | pvslib: "eight". examples: 7 + `cad_decide8_ex`, + outside `top` | `theories.json`: 8 replayed theories import `cad_decide5` (`cad_bath`, `cad_decide8_ex`, `cad_endgame_ex`, `cad_examples` 1–4, `cad_star_ex`), and `qe_cad_ex` imports `qe_all`. Outside `top`: `cad_demo`, `cad_limits` 1–3, `cad_msg_d5`, `cad_msg_qe` | **examples is right:** 9 replayed theories and 6 outside `top` |
| 6 | `cad_bath` | examples: migrate; it is the only replayed test of the reduction path. repo/pvslib: drop; CC BY-SA must not reach NASALib | No other example exercises `cadw-reduce` with a missed budget. NOTICE says CC BY-SA 4.0. NASALib forbids copyrighted contributions | **both, in sequence:** migrate on dev `main` (S2), keep it out of the NASALib directory, and replace it with an own CC0 sentence before the pull request (Q9) |
| 7 | "Add `q8_win`" (repo) | repo: add it if `qe_capabilities` keeps the "proved" mark | `qe8_ex.pvs` line 18 already declares `q8_win` | **no new lemma;** only the doc's citation changes |
| 8 | Is the witness search covered? | repo: by `cad_showcase`/`cad_forms_ex`. examples: constant fold only in `cad_examples`, reduction only in `cad_bath` | The saved lists of `w_trivial`/`w_trivial_h` name no decision theorem. The reduction needs three or more quantifiers and a missed budget | **examples is right.** `cad_examples` and `cad_bath` are migrated, not dropped |
| 9 | How many theories stay | pvslib 289–315; repo about 271; qe 315→305; decide 210 (+5) | They are different stages. Deletions only: 315. With S4/S5: 292. With the import-only cuts: 264. With decq1: 233. With the moves: 213 | **decide's end state is right for the full plan.** pvslib's 289 includes 19 strategy-support theories (`decide_u_def`, `cad_decide7_def`, `tower_univ`, ...) that serve only the fallbacks S3 removes. The 270-theory "key closure" includes the false positives of row 1 |
| 10 | Is `pvs-circular-deps.lisp` still needed? | repo: yes, 0.30–2.15×10⁹ paths, "hours" | Same measure on the planned graphs: 1.9×10⁹ after S1–S5; 8.4×10⁶ after S9; 2.9×10⁶ after S10 (1.1×10⁶ without redundant imports); 1.5×10⁷ from a `top` that imports all 213 | **repo's figure holds for deletions without the cuts.** With S6–S10 the check from `pvs_cad` takes about 1.5 min at the README's 32 µs per path, so the fix is helpful rather than essential. Re-measure with `import_paths.py`, and still offer the fix upstream |
| 11 | Decide's trim list marks `cad_decide8.decq8_correct` unneeded | — | It is an artifact of blocking `cad_decide8` in that closure; `decide8_correct` uses `decq8_correct` | **keep it** (re-proved in S9). My recomputed deletion lists exclude it |
| 12 | "Re-point `(cad :cad-only? t)` to the Collins engine" (task list) | strategies: it already runs decide8 wherever `cad_decide8` is imported | Line 3169 picks decide7 only without `cad_decide8`, which happens only in `cad_decide7_ex` | **no re-pointing is needed;** delete the alternative (S3). Keeping the witness search out of side decisions is a separate fix (Q3) |
| 13 | Plan citations in kept files | pvslib: 124 of 289 files, 146 places. repo: about 129 of about 281 files, 172 | Counted on the planned 213 files: 141 citations in 119 files; 12 mentions of dropped engines in 8 files; 40 lines in `pvs-strategies` | **differences of kept set only.** Clean them in each edited file, and the rest in Phase 3 |
| 14 | `complete1` | strategies: import `cad_lift`, keep `svs1ok_complete` and `decq2_complete1`. decide: dissolve into `cell1` | — | **both, in sequence:** S4, then S9 drops `decq2_complete1`, then S10 moves `svs1ok_complete` |

---

## 5. Consolidated risks

| risk | where | mitigation |
|---|---|---|
| Hidden uses: 498 dependency lists were saved without a rerun, and same-theory uses are never in saved lists | S6–S11 deletions | The closure follows every citation and every definition body. Each step's typecheck and gate catch the rest; milestone replays after S5 and S9 |
| Name resolution changes when imports are cut | S4–S10 | A cut removes names and never adds them, and the adds only restore existing visibility. Typecheck the whole `top` each step. In Phase 3, theory-qualify the lemma names the strategies cite |
| VAR clash in a move | S10, `cont_sign` | Rename the variable; adapt the script |
| Stale PVS state after deletions (`pvsbin`, `.pvscontext`, `orphaned-proofs.prf`; "binding stack exhausted") | every deleting step | Clear `pvsbin`, restart the pvs-cli server, one PVS at a time |
| Wall-clock budgets (SBCL only) | `bath_02`, `bath_05_false` | Accept; or raise their budget `(cad 1 30)`; or the portable timeout and deterministic PRNG (Phase 3) |
| `cad_star_ex` under the general route | S2 | Gate it. If a sequent changes route, adjust the comment, not the library |
| `msgcheck` texts drift | S1, S3 | Rerun `msgcheck.sh` in every strategy step. `m_nodec` changes with `cad-dec` |
| Deleting results the owner wants as mathematics | S11 | An explicit list (Q6) |
| Docs disagree with the library during Phase 2 | dev only | Each step fixes what it breaks; Phase 4 reconciles; nothing is exported in between |
| Public tag before the rewrite push; `export_public.sh` defaulting to HEAD | Phase 0, 5 | The order in Phase 0; a mandatory tag argument (Phase 1) |
| The NASALib cache races | everywhere | One replay at a time; `prove-all` only in a separate clone |

---

## 6. Questions for the owner (blocking first; the default is what this plan assumes)

**Blocking before S1 to S3:**

1. **Commands on neither list.**
   - `(mpoly-eq)`/`(mpoly-simp)`: default keep. That is 101 lines, no extra theory and 2 examples
     (11 s).
   - `(poly-pos)`/`(poly-nonzero)` and `(qe-exists)`: default drop, with `pos_examples`, `qe_run`,
     `qe_symbolic` and `msgcheck`'s `m_qe_nat`. They need `pos_dec`, `root_dec`, `qe_formula` and
     `qe_ctx`, which the slim removes.
   - `cad-time`, `cad-qeshow`, `cad-showf`: default drop with the measuring commands.
2. **`:complete?` and DEC.** Default: drop them; no saved proof uses them, and decide8 always answers.
   Note that `(cad 1 10 t)` would then mean `:cad-only? t`. The alternative is to keep them as
   accepted and ignored.
3. **Should `:cad-only?` also keep the witness search out of side decisions** (TCCs of type facts, T4
   sqrt leaves, the general route's `(cad *)` fallback; about 15 call sites, 1–2 h)? Default: yes, in
   S3, as a real fix.
4. **May decide8's internal one-variable branch change to `decq1` (S9)?** Statements and computation
   are unchanged. Default: yes; it frees 31 theories.
5. **Dissolve the 20 lending theories by moving 44 formulas (S10)**, or keep them trimmed under their
   old names? Default: move.
6. **S11's corollaries and "coherent mathematics":** `col_exists`, `col_found_ccad`, `decb_complete`,
   `decc_complete`, the Thom-encoding results, Sylvester's `res`/`disc`, the subresultant identities,
   `crit_exists`, `walk_transfer`'s `fib_local` family. Default: delete everything unused.

**Before S2 (the examples):**

7. Rename the 6 NASALib-clashing formula names and `Mat` (Phase 3)? Default: yes (about 15 kept
   proofs cite the six names; `Mat` appears in 8 theories).
8. `cad_demo`: drop (default), or keep it as a `pvs_cad` playground outside `top` and outside NASALib?
   `cad_limits*`: drop and cite `v1.0-full` (default), or add a *proved* "hard problems" theory under
   `pvs_cad` (60–80 s) to back the README numbers?
9. Bath data. Default: keep `cad_bath` migrated on dev `main` and outside the NASALib directory, drop
   `bench_*`, and write a CC0 sentence for the reduction path before the NASALib pull request.
10. The budget dependence of `bath_02`/`bath_05_false`: accept (default), raise their budgets, or the
    portable timeout (Phase 3)?
11. Examples layout: stay in `cad/` until Phase 3 (default), or move to `cad/examples/` (NASALib style,
    importing `cad@pvs_cad`) during S2, so they are rerun only once?
12. The mult_poly bridge `mpoly_mono` (and a possible `qfd?` → semi-algebraic link): drop (default) or
    keep for coherence with NASALib?

**NASALib and repository:**

13. The directory name: `CAD` (NASALib's acronym rule) or `cad` (existing `cad@pvs_cad` imports)?
14. `@poc` address, `@author` wording with the AI-generation statement, license framing (personal CC0
    as `co_structures` did, or LaRC FM-team work), and the circularity fix route (upstream PVS,
    `nasalib/pvs-patches`, both or neither)?
15. Milestone replays after S5 and S9, as well as the release replay? Default: yes, library-only
    (about 12–15 min each).
16. Names `full`, `v1.0-full`, `v2.0`; a public tag only; the pending public push first; `paper/` stays
    on dev `main`; delete `s5e-redesign`; `cad_proof_traces` history-only; decide5 timing claims kept
    as dated history at the tag. Defaults as stated.
17. Add an example that reaches `qe8`'s `qe2cd` fallback (after a candidate is checked by ground
    evaluation)? Default: yes.
18. Keep `qe2cc` as `qe8`'s fast first try (default), or `qe2cd` only (18 formulas fewer; the speed
    and printed answers of `(cad-qe)` change; measure first)?
19. `cad_terms_ex` (994 s, 38% of all replay): accept (default), or point the duplicated option tests
    (`cn_star`, `cn_splits`, `t5_star` on `exp(x) <= 1 + 2x`) at a cheaper formula after measuring?
20. Theory names that are historical but kept:
    - the QE answer layer `qe_def`, `qe1_ok`, `qe1_full`, `qe2_def`, `qe2_ok`. These carry `qe8`'s
      engine-independent answer construction, not the `qe1`/`qe2` engines, which go in S5;
    - `towern_def`/`towern_od` (the walk tables decide8 uses);
    - `cad_decide` (the semantics `sem`/`fsem`).

    Keep the names (default; no proof moves), or rename and merge them for NASALib readers (for example
    `qe_out_def`/`qe_sec`; about 100 proofs replayed through pvs-cli, QE study Q2)?

---

## Appendix A. Per-step edit lists (computed; closed under reverse references)

### A.S6

IMPORTING cuts: `cad_fast` drops `cad_fast_def`; `clos_ok` drops `tower_univ`; `innern_sem` drops `tower_sem`; `lev_ev` drops `nclos_ok`; `tower_def` drops `cad_fast_def`; `towern_def` drops `cad3_def`.

IMPORTING additions (visibility kept): `towern_def` adds `mpoly`; `tower_def` adds `alg_bis`, `sturm_sg`; `qsec_rd` adds `walk_rd`; `innern_sem` adds `tclf`; `lev_ev` adds `clos_ok`, `inner_const`; `tower_ev` adds `decn_ok`; `clos_ok` adds `towern_od`.

Theories that leave: `cad3_def`, `cad_fast_def`, `list_flat`, `nclos_ok`, `read_fam`, `read_univ`, `tower_sem`, `tower_univ`.

Declarations deleted in theories that stay (or stay until S10):

- `cad_fast`: 10 formulas (`cert_w`, `decw_correct`, `foldw_sem`, `inv_sect`, `mem_ok`, `sect_delin`, `sect_sem`, `sect_walk`, +2 TCCs); definitions and types: `sok2?`
- `cad_fold_ok`: 7 formulas (`cad_decides`, `sector_fold`, `sector_has`, `sector_of`, `sector_recs`, +2 TCCs)
- `cad_out`: 1 formula (1 TCC); definitions and types: `cad_out`
- `cad_out_ok`: 4 formulas (`cad_out_mem`, `cad_out_ok`, `sector_okt`, +1 TCC)
- `cad_run`: 7 formulas (`cad_run`, `run_ok`, `run_shape`, `sector_cad`, `sector_inv`, +2 TCCs); definitions and types: `rcell`, `runq`, `runsects`, `runtw`
- `cell_ok`: 1 formula (`sec_fib`)
- `clos_ok`: 17 formulas (`cellsr_has`, `clok_sub`, `fixp_clk`, `tsub_refl_clos_ok`, `tsub_trans_clos_ok`, `tsub_zsub`, `zipadd_zsub`, `zipapp_l`, `zipapp_r`, `zsub_clk`, +7 TCCs); definitions and types: `clk?`, `zsub?`
- `closed_pt`: 3 formulas (`cl_cells`, `rdin_pt`, `rdin_sec`)
- `cover`: 2 formulas (`cellok_adj`, `cellok_mem`)
- `decn_ok`: 10 formulas (`decn_correct`, `foldn_sem`, `inv_topreads`, `lvln_shape`, `memn_ok`, `sectn_sem`, `tclos_shape`, `tw0_shape`, `zipadd_last`, `zipadd_len`)
- `innern_sem`: 9 formulas (`clf_level`, `ia_sec`, `ia_sep`, `ia_step`, `innern_sem`, `rdz_cell`, +3 TCCs); definitions and types: `IA`, `ctxA?`
- `lev_ev`: 1 formula (`cells_valid`)
- `level_ok`: 15 formulas (`T_pt`, `T_same`, `T_sec`, `cellok_cdr`, `cellok_hd`, `cellok_last`, `cv_all`, `cv_gap`, `cv_hd`, `cv_last`, `cv_mid`, `cv_sec`, `cv_sound`, `cv_tl`, `inner2_sem`); definitions and types: `cv`
- `rcf_cells`: 4 formulas (`rcell_fod`, `rcell_fod_le`, `rcell_ok`, `rcell_ok_le`)
- `tower_def`: 8 formulas (8 TCCs); definitions and types: `cellok?`, `cellvals`, `dec3m`, `in2ok?`, `inner2`, `ok3m`, `ptok?`, `secok?`, `yclos`, `yreads`
- `tower_ev`: 1 formula (`okn_split`)
- `towern_def`: 0 formulas; definitions and types: `cellsf`, `cellsr`, `decnm`, `innern`, `lvln`, `nbads`, `nclos`, `tclos`, `topf`, `treads`, `tsize`, `tw0`, `zipadd`
- `towern_od`: 8 formulas (8 TCCs); definitions and types: `decn_o`, `lvln_o`, `nbads_o`, `nclos_o`, `scof`, `tclos_o`

### A.S7

IMPORTING cuts: `alg_bis` drops `alg_sturm2`; `alg_sturm` drops `alg_lift`; `cad_delin` drops `cad_pdec`; `cad_gpar` drops `mroot`; `cad_roots` drops `mwalk`; `cad_stack` drops `cad_local`; `inner_const` drops `cells_local`; `mpar` drops `walk_same`; `pt_local` drops `root_cont`; `tclf` drops `mroot`; `tclf` drops `mwalk`.

IMPORTING additions (visibility kept): `mpar` adds `mpoly_def`; `sturm_sg` adds `sg_chain2`; `cad_delin` adds `cad_decide`; `cad_stack` adds `cad_fibre`; `cad_roots` adds `zfam`; `inner_const` adds `cover`, `pt_local`; `tclf` adds `zfam`; `cad_out_ok` adds `cad_gpar`; `pt_local` adds `cover`.

Theories that leave: `alg_lift`, `alg_sturm2`, `cad_local`, `cad_pdec`, `cells_local`, `joint_cont`, `mpoly_swap`, `mroot`, `mwalk`, `root_cont`, `walk_same`.

Declarations deleted in theories that stay (or stay until S10):

- `alg_bis`: 14 formulas (14 TCCs); definitions and types: `bfuel`, `bint`, `bok?`, `bokF`, `bpick`, `bsec`, `bseps`, `bsg`, `bwalk`, `bwide`, `dec2c`, `ok2c`, `svs_bis`
- `alg_sturm`: 14 formulas (`achain_at`, `achain_entry`, `achain_len3`, `acount_nneg`, `acount_pos`, `acount_zero`, `alc_fok`, `alen_at`, `algsg_msg`, `aroot_char`, `asgn_sign`, `avar_nsc`, +2 TCCs); definitions and types: `achain`, `acount`, `aends?`, `alc?`, `alen`, `algsg`, `aroot?`, `avar`, `avarf`
- `cad_delin`: 6 formulas (`dec2_sem`, `fib_swap`, `inner_sem`, `sect_sem_delin`, `sem1_fib`, `svs_pt_fib`); definitions and types: `delin?`
- `cad_gpar`: 13 formulas (`close_len`, `close_nth`, `gr_cover`, `gr_len`, `gr_near`, `gr_nlt`, `gr_svl`, `samepat_cdr`, `sep_ge`, `sep_nz`, +3 TCCs); definitions and types: `close?`, `samepat?`
- `cad_stack`: 5 formulas (`loc_cont2`, `rdag_move`, `root_cont_on`, `stack_const`, `stack_same`); definitions and types: `rdag?`
- `cad_tower`: 2 formulas (`rdag_up`, `tower_cad`)
- `inner_const`: 6 formulas (`G_const`, `G_const_le`, `G_from`, `G_local`, `V_sub`, `cells_eq_sym`); definitions and types: `G`, `samegaps?`
- `mpar`: 2 formulas (`msg_mpers`, `msg_mpers1`)
- `pt_local`: 4 formulas (`T_same_r`, `pt_local`, `pwalk_local`, `rf_inv_r`)
- `tclf`: 21 formulas (`CLF_flat`, `cb_le`, `cb_step`, `ct_level`, `ct_step`, `exq_len`, `pre_car`, `pre_clf`, `pre_last`, `pre_len`, `pre_nth`, `sem_ex`, +9 TCCs); definitions and types: `CBh`, `CLL`, `CTh`, `LCh`, `exq`, `over?`, `pre`
- `tlc`: 8 formulas (`cell_sec`, `cell_sep`, `cells_near`, `lc_base`, `lc_step`, `rfc_tw`, `sem_cvl`, +1 TCC)

### A.S8

IMPORTING cuts: `cad_lift` drops `svs_pt`; `rsc_tree` drops `bbindc_ex`; `rsc_tree` drops `qe_ctx`.

IMPORTING additions (visibility kept): `rsc_tree` adds `conj_tree`, `sign_oracle`; `cad_lift` adds `sect_inv`.

Theories that leave: `btree_prune`, `hutch_oracle`, `ineq_ctx`, `prsp_ctx`, `qe_ctx`, `qe_tree`, `snorm_ctx`, `svs_pt`, `tarski_ctx`.

Declarations deleted in theories that stay (or stay until S9/S10):

- `cad_decide`: 6 formulas (`decide_correct`, `decide_correct_os`, `decq_correct`, `qfold_svs`, `sem_peel`, +1 TCC); definitions and types: `decide`, `decq`
- `cad_lift`: 13 formulas (`badl_at`, `decide2_correct`, `dedup1_every`, `every_cons_m`, `every_mem_m`, `inv_chk_at`, `len_cons_lift`, `lv_complete`, `over1_mem_inv`, `over_mem_inv`, `pts_ok_mem`, `qfold_same`, `sect_inv_at`); definitions and types: `decide2`, `lcomplete?`, `pts`, `pts_ok`, `svsec`
- `rsc_tree`: 2 formulas (`rsc_complete`, `rsc_sound`); definitions and types: `rsc`
- `svs_tree`: 4 formulas (`select_svs`, `svs_complete`, `svs_sound`, +1 TCC); definitions and types: `svs`

### A.S9

IMPORTING cuts: `branch_prs` drops `branch_map`; `branch_sgn` drops `branch_map`; `branch_sgn` drops `mpoly_cst`; `cad_decide` drops `svs_tree`; `cad_decide` drops `tree_sel`; `cad_lift` drops `sg_svs`; `far_sign` drops `ineq_ok`; `far_sign` drops `sign_oracle`; `pos_dec` drops `root_dec`; `rsc_tree` drops `branch_map`; `rsc_tree` drops `conj_tree`; `rsc_tree` drops `sign_oracle`; `sect_inv` drops `alg_count2`; `sector_rep` drops `poly_rolle`; `sg_chain` drops `tarski_many`; and `cad_decide8_def` drops `cad_lift` (decq1).

IMPORTING additions (visibility kept): `cad_decide` adds `rsc_tree`; `sector_rep` adds `mpoly_prod`, `pos_dec`; `cad_lift` adds `mpoly_eqd`; `pos_dec` adds `mpoly_univ`; `sg_chain` adds `tarski_chain`; `crit_pos` adds `earr_deriv`.

Theories that leave: `alg_count2`, `bbindc_ex`, `branch_ctx`, `branch_map`, `conj_tree`, `exists_dec`, `ineq_ok`, `ineq_tree`, `many_ok`, `many_tree`, `mpoly_cst`, `poly_farinf`, `poly_rolle`, `qe_conj`, `qe_formula`, `root_dec`, `sg_conj`, `sg_conj2`, `sg_svs`, `sgn_count`, `sign_oracle`, `sign_tree`, `svs_tree`, `tarski_count`, `tarski_dec`, `tarski_many`, `tarski_multi`, `tarski_pair`, `tarski_tree`, `tarski_two`, `tree_sel`.

Declarations deleted in theories that stay (or stay until S10):

- `branch_prs`: 4 formulas (`len_one`, `select_prs`, +2 TCCs); definitions and types: `prs`
- `branch_sgn`: 12 formulas (`select_prsp`, `sl_of_null`, `sl_of_slist`, `snormp_cons`, `snormp_cst`, `snormp_null`, `snormp_sel`, +5 TCCs); definitions and types: `prsp`, `sl_of`, `snormp`
- `cad_decide`: 2 formulas (`mem_map`, `polys_sub`); definitions and types: `polys`
- `cad_lift`: 59 formulas (`addnew_member`, `agree_dedup1`, `all_inv_mem`, `asgS_msg`, `cell2_eq`, `cell_complete`, `cell_eq`, `cell_sound`, `closed_sub`, `cpl_eval`, `decq2_correct`, `everyS_all`, `everyS_mem`, `len0`, `len1_lift`, `len_split`, `lv_sound`, `memb_member`, `new_reads_mem`, `over1_mem`, `over_mem`, `qfoldS_sem`, `qfold_cell`, `qfold_msg`, `reads_agree`, `sample_at`, `sem_peel2`, `sgnq_sgn`, `sgv_at`, `someS_intro`, `someS_mem`, +28 TCCs); definitions and types: `addnew`, `all_inv?`, `asg`, `asgS`, `badl`, `bads`, `cfuel`, `clos`, `clos1`, `closed?`, `cpl`, `decq2`, `good?`, `inv1?`, `lsound?`, `lv`, `new_reads`, `new_reads1`, `over`, `over1`, `qfoldS`, `ratpt?`, `ratval`, `reads1`, `reads_at`, `sect_inv?`, `sgv`, `sub_list`
- `chain_sturm`: 1 formula (`select_ftree`); definitions and types: `ftree`
- `complete1`: 1 formula (`decq2_complete1`)
- `decn_ok`: 1 formula (`rdn_msg`)
- `far_sign`: 12 formulas (`dg_lneg`, `far_sign_left`, `far_sign_right`, `far_vec_left`, `far_vec_right`, `infv_cons`, `infv_null`, `lcalt_lneg`, `lcpos_lneg`, `llast_lneg`, `lneg_cons?`, `lneg_len`); definitions and types: `inf_sgn`, `infv`
- `level_ok`: 2 formulas (`clok_mem`, `rf_inv`)
- `pos_dec`: 10 formulas (`big_neg`, `big_pos`, `no_root_pos`, `not_all_pos`, `pdec_sound`, `pos_branch`, `pos_iff`, `sl_of_ssign`, `snorm_all_pos`, `snorm_pf`); definitions and types: `pdec`
- `rsc_tree`: 16 formulas (`allgt_cons`, `at_cjt`, `eqs_at_cons`, `ladd_length`, `lneg_length`, `lsum_cons`, `mem_app3`, `rev_cons_app`, `rfuel_eq`, `rfuel_gt`, `rfuel_lt`, `rfuel_now`, `sqsum_len_cons`, `svec_cons_sign`, +2 TCCs); definitions and types: `at`, `lsum`, `rfuel`
- `sect_inv`: 45 formulas (`above_free_complete`, `above_free_sound`, `below_free_complete`, `below_free_sound`, `between_free_complete`, `between_free_sound`, `clr_free_lb`, `clr_free_ub`, `deg0_same`, `gsects_gaps`, `inv_chk_complete`, `inv_chk_sound`, `inv_free`, `nroots_two_sect_inv`, `sects_samples`, `sepcc_eq`, `sepf0_apart`, `sepf0_inv`, `sepf_apart`, `sepf_eq`, `sepf_inv`, `sepw_inv`, `sepx_apart`, `sepx_inv`, `sepx_ok`, `whole_free_complete`, `whole_free_sound`, +18 TCCs); definitions and types: `above_free`, `bdry`, `below_free`, `between_free`, `inv_chk`, `sepf`, `sepf0`, `sepw`, `sepx`, `whole_free`
- `sector_rep`: 3 formulas (`rolle_pf`, `sector_cases`, `svec_same`)
- `sg_chain`: 12 formulas (`lmn_det`, `lmn_sg_at`, `mts_det`, `mts_sg_at`, `slof_det`, `slof_sg_at`, `tq_det`, `tq_sg_at`, +4 TCCs); definitions and types: `lmn_rd`, `lmn_sg`, `mts_rd`, `mts_sg`, `slof_rd`, `slof_sg`, `tq_rd`, `tq_sg`
- `sg_chain2`: 10 formulas (`chprop_tqf`, `mts2_det`, `mts2_sg_at`, `slof_len`, `slof_nth`, `tq2_det`, `tq2_sg_at`, +3 TCCs); definitions and types: `mts2_rd`, `mts2_sg`, `tq2_rd`, `tq2_sg`
- `sg_norm`: 2 formulas (`sl_of_lcs`, `sl_sg_at`)
- `towern_od`: 0 formulas; definitions and types: `scok?`

Added: `decq1` (`cad_decide8_def`), `decq1_correct` (`cad_decide8`); edited: `decq8`, `decq8_correct`, `decq8_complete`.

### A.S10 moves

- into `cad_decide8`: `cad_lift.qfold_svs1`
- into `cad_out_ok`: `cad_gpar.gap_lt`, `cad_gpar.gr_nlt_hd`, `cad_gpar.wsep?`
- into `cad_run`: `cad_fast.in_conv`, `cad_fast.insec`
- into `cell1`: `complete1.svs1ok_complete`, `far_sign.len_pos`
- into `col_sem`: `tlc.Tv`
- into `cover`: `level_ok.bfold_mem`, `level_ok.rootfree?`
- into `innern_sem`: `cad_delin.qfold_fib`, `closed_pt.wok_cert`, `decn_ok.every_map_all`, `decn_ok.every_map_mem`, `decn_ok.odS_den`, `decn_ok.odS_wf`, `decn_ok.some_map_intro`, `decn_ok.some_map_mem`
- into `lev_ev`: `clos_ok.cells_o`, `clos_ok.cellsf_every`, `clos_ok.tables_len`, `inner_const.gap_sec`, `pt_local.adj_mem`, `pt_local.gap_lives`, `pt_local.sepok_adj`, `pt_local.sepok_hd_sg` (+4 TCCs)
- into `mpoly_eqd`: `cad_lift.dedup1`, `cad_lift.dedup1_member`, `cad_lift.memb`, `cad_lift.memb1`, `cad_lift.memb1_member` (+6 TCCs)
- into `mpoly_real`: `pos_dec.pf`, `pos_dec.pf_cont`
- into `sect_inv`: `cad_lift.rts`, `cad_lift.sval`, `cad_lift.sval_sample`
- into `sep_exist`: `sign_pers.cont_sign` (rename its VAR `f`)
- into `sg_norm`: `branch_sgn.SL`, `branch_sgn.msign_mnorm`
- into `sign_vec`: `rsc_tree.SV`, `rsc_tree.SVL`
- into `sturm_sg`: `alg_sturm.sign3_scale`
- into `tower_ev`: `decn_ok.tables_vtb`
- into `walk_def`: `alg_bis.bk`, `alg_bis.bprod`, `alg_bis.lives`, `alg_bis.lsumk`, `alg_bis.strip`, `alg_bis.zc?`, `cad_delin.fib`, `cad_proj.live?` (+4 TCCs)
- and, earlier: in S4, `cad_decide7.len_ge2` into `cad_decide8`; in S5, `qe2c_def.dclx?` into `ctwd_def` and `qe2c_ok.every_mem_l`, `dclx_dcl`, `every_dclx` into `ctwd`.

Deleted with the dissolved theories (not moved, not needed):

- `cad_proj`: 9 formulas (`proj_null`, +8 TCCs); definitions and types: `cofs`, `proj`, `proj1`, `projr`
- `closed_pt`: 5 formulas (`cl_transfer`, `rdin_agree`, `rdin_vec`, `rf_svec`, `svec_mem`); definitions and types: `CL?`, `rdin?`
- `decn_ok`: 7 formulas (`cellsr_len`, `lcdr`, `lcons`, `odS_exact`, `treads_len`, `wrs_top`, `zipapp_len`)
- `level_ok`: 3 formulas (`rf_conv`, `rf_refl`, `sem1_fibs`); definitions and types: `Srf`, `T`
- `pos_dec`: 3 formulas (3 TCCs)
- `sign_pers`: 6 formulas (`msg_pers`, `msg_pers1`, `msg_pers2`, `nz_append`, `nz_cons`, `nz_null`); definitions and types: `nz1?`, `nz?`
- `tlc`: 1 formula (`fin_near`)

### A.S11 unused declarations in the kept theories

- `alg_count`: 2 formulas (`ipoly_beyond`, `ipoly_wrap`)
- `alg_def`: 3 formulas (`refine_n_p`, `refine_n_sub`, `refine_n_width`)
- `alg_fast`: 1 formula (`nroots_hc_h`)
- `alg_isolate`: 3 formulas (`roots_alg`, `roots_h_closed`, `roots_increasing`)
- `alg_order`: 1 formula (`alg_lt_def`); definitions and types: `alg_lt`
- `alg_sign`: 2 formulas (`sep_p`, +1 TCC)
- `alg_sign2`: 1 formula (`alg_sign2_def`)
- `alg_sortc`: 1 formula (`nrc_eq`)
- `branch_tree`: 22 formulas (`add_cond_inv`, `add_cond_mem`, `branch_exists`, `branch_forall`, `branch_sound`, `branches_leaf`, `branches_node`, `branches_node_inv`, `conds_hold_cons`, `conds_hold_head`, `conds_hold_null`, `conds_hold_tail`, `mem_branch_neg`, `mem_branch_pos`, `mem_branch_zer`, `step_neg`, `step_pos`, `step_zer`, +4 TCCs); definitions and types: `Branch`, `SignCond`, `add_cond`, `branches`, `cond_holds`, `conds_hold`, `hasbranch`, `neg`, `pos`, `prefix`, `zer`
- `cad_out_ok`: 2 formulas (`ctree_cover`, `ctree_in`); definitions and types: `okt?`
- `cad_tower`: 5 formulas (`cad_empty`, `clf_up`, `stk_cons`, `stk_empty`, +1 TCC); definitions and types: `clfc?`
- `cell1`: 1 formula (`allroots_sound`)
- `cell_ok`: 2 formulas (`pt_fib`, `sg_pt_msg`)
- `col_found_ok`: 1 formula (`col_found_ccad`) (Q6)
- `col_verified`: 1 formula (`col_exists`) (Q6)
- `cpoly_der`: 1 formula (`cder_cpol`)
- `cpoly_unique`: 1 formula (`nat_points`)
- `crit_pos`: 6 formulas (`big_pos_left`, `crit_between`, `crit_exists`, `deriv_max_le`, `far_neg_left`, `far_neg_right`); `deriv_max_pf` stays (QE uses it)
- `croot_lsc`: 3 formulas (`dist_le`, `dist_same`, `psc_same_sym`)
- `croot_near`: 1 formula (`abs_cprod`)
- `cvl`: 1 formula (`cvl_eq`)
- `decb_ok`: 1 formula (`decb_complete`) (Q6)
- `decc_ok`: 1 formula (`decc_complete`) (Q6)
- `earr_ops`: 2 formulas (`lscal_null`, `prop_sign`)
- `ev_nat`: 2 formulas (`evc_const`, `evc_same`)
- `loc_const`: 2 formulas (`upto_a`, `upto_bd`)
- `mpoly_dom`: 1 formula (`zfun_mconst`)
- `mpoly_eqd`: 3 formulas (`posq_pos`, +2 TCCs); definitions and types: `posq`, `sgnq_of`
- `mpoly_norm`: 5 formulas (`normal_mnorm`, `normal_mnorm_x`, `normalx_cons`, `normalx_null`, `normalx_tail_mpol`)
- `mpoly_univ`: 1 formula (`coef_mpol`); definitions and types: `lc`
- `odreads`: 3 formulas (`mem_cons_odreads`, `we_sub`, `wi_sub`)
- `poly_unique`: 1 formula (`divide_unique`); definitions and types: `zerop`
- `qe1c_ok`: 1 formula (`qe1cc_ok_eq`)
- `qe_mrg`: 9 formulas (`ex_null`, `mrg_qf`, `qf_cls`, `qf_fand2`, `qf_lowX`, `qf_mrgX`, `qf_or`, `qf_sectX_h`, `qf_uppX`)
- `rd_norm`: 4 formulas (`llast_lrat`, `lrat_normalx`, `lrat_nz`, `rd_norm_eval`)
- `sg_chain2`: 1 formula (`tchain2_det`); definitions and types: `tchain2_rd`, `tchain2_sg`
- `sg_norm`: 2 formulas (`mem_cons_m`, `snorm_rd_lc`); definitions and types: `sl_sg`
- `sign_vec`: 3 formulas (`pos_mem`, +2 TCCs); definitions and types: `pos`
- `sres_rows`: 1 formula (`csum_scal`)
- `sturm_fast`: 1 formula (`chvals_fun`)
- `sturm_sg`: 1 formula (`captures`)
- `sturm_step2`: 2 formulas (`lexact_len`, `sstep2_length`)
- `subres`: 6 formulas (`psc0_res`, `sres0_syl`, +4 TCCs); definitions and types: `pscs` (Q6)
- `subres2`: 4 formulas (`psc_sres`, `sresm2_sresm`, +2 TCCs); definitions and types: `sres` (Q6)
- `sylvester`: 3 formulas (`disc_eval`, `res_eval`, `syl_ev`); definitions and types: `disc`, `res`, `rres`, `rsyl`, `syl` (Q6)
- `thom_enc`: 9 formulas (`polylist_arr`, `thom_encoding_distinct`, `thom_list_length`, `thom_list_nth`, `thom_nth`, `thom_same_p`, +3 TCCs); definitions and types: `thom`, `thom_list` (Q6)
- `thom_lemma`: 2 formulas (`sat_from_signs`, `thom_distinct`) (Q6)
- `towern_od`: 0 formulas; definitions and types: `topreads`
- `walk_def`: 1 formula (`wok_w_def`); definitions and types: `wok_w`
- `walk_fuel`: 1 formula (`seps_n_fuel`)
- `walk_od`: 3 formulas (`mkce_eq`, `opt_ok`, `wok_wt_eq`); definitions and types: `wok_wt`
- `walk_ok`: 2 formulas (`gap_beta`, `gap_none`)
- `walk_rd`: 1 formula (`wa_pairs`)
- `walk_transfer`: 29 formulas (`cert_det`, `ent_nz`, `ents_nz`, `fib_const`, `fib_const_le`, `fib_local`, `inv_cert`, `inv_pair`, `me_nz_nz`, `me_sh_agree`, `me_split`, `mi_det`, `mi_short`, `nzm_det`, `own_av`, `pairs_det`, `pairse_nz`, `pch_mem`, `pchs_mem`, `pe_nz`, `pi_det`, `short_ents`, `short_inv`, `wi_det`, `wnz_agree`, `wnz_nz`, +3 TCCs); definitions and types: `inv?`, `me_nz`, `me_sh`, `wnz`
- `zfam`: 13 formulas (`fib_constz`, `fib_invz`, `fib_zfeq`, `invz_inv`, `invz_pair`, `invz_wrs`, `rdz_agree`, `rdz_vec`, `rf_invz`, `rf_svecz`, `sign_rdn`, `wrs_det`, `zf_agree`); definitions and types: `invz?`
- `ztrunc`: 4 formulas (`crd_mem`, `tz_idem`, `tz_len`, `tz_mem`)

### A.final The final IMPORTING plan: 38 kept theories change

| theory | drops | adds |
|---|---|---|
| `branch_prs` | `branch_map` | — |
| `cad_decide` | `svs_tree`, `tree_sel` | — (`SV` now in `sign_vec`, already visible) |
| `cad_decide8` | `cad_decide7` | `cad_endgame` |
| `cad_decide8_def` | `cad_decide5_def` | — (`cad_lift` only between S4 and S9) |
| `cad_out` | — | `towern_od` |
| `cad_out_ok` | `clos_ok` | `innern_sem` |
| `cad_roots` | `mwalk` | `walk_transfer`, `zfam` |
| `cad_run` | `decn_ok` | `sect_inv` |
| `cad_sa` | `cad_verified` | — |
| `cad_stack` | `cad_local` | `cad_fibre` |
| `cell1` | `far_sign` | — |
| `col_sem` | `level_ok`, `tlc` | `cad_decide` |
| `cover` | `level_ok` | `cell_ok`, `walk_rd` |
| `crit_pos` | `pos_dec` | `earr_deriv` |
| `ctwd` | `qe2c_def` | `qe2_def` |
| `innern_sem` | `tower_sem` | `tclf` |
| `lev_ev` | `nclos_ok` | — |
| `mpar` | `walk_same` | `mpoly_def` |
| `qe2_ok` | `cad_sample` | — |
| `qe2cd_ok` | `qe2c_full`, `qe2cc_ok` | `qe1_full`, `qe2_sep` |
| `qe_def` | `decide_u_def` | — |
| `qsec_rd` | — | `walk_rd` |
| `sect_inv` | `alg_count2` | — |
| `sector_rep` | `poly_rolle` | `mpoly_prod` |
| `sep_exist` | `sign_pers` | — |
| `sg_chain` | `tarski_many` | `tarski_chain` |
| `sg_norm` | `branch_sgn` | `branch_norm` |
| `sturm_sg` | `alg_sturm` | `chain_sturm`, `nsc_scale`, `sg_chain2` |
| `tclf` | `inner_const`, `mroot`, `mwalk` | `zfam` |
| `tower_def` | `cad_fast_def` | `walk_def` |
| `tower_ev` | — | `innern_sem` |
| `tower_ok` | — | `tarski_chain` |
| `towern_def` | `cad3_def` | `mpoly` |
| `towern_od` | — | `cad_decide`, `sect_inv` |
| `twrun_ok` | `qe2_ok` | `cad_fold_ok` |
| `walk_def` | `alg_bis` | `sector_rep` |
| `walk_ok` | `cad_delin` | — |
| `zfam` | `closed_pt` | `walk_transfer` |

The final graph has no cycle. Of its entries, 45 are redundant by transitive reduction; Phase 3
removes them.

## Appendix B. Method, data and caveats

- **Inputs:** the `.pvs` and `.prf` files and `pvs-strategies` of `5700fd9`; the replay log of 5 October
  2026 (per-formula times, with traces); the saved dependency lists of the default proofs (498 of 5,612
  were saved without a rerun and are empty or partial) and every quoted name in the proof scripts.
- **Closure engine:** a declaration-level closure over the saved dependency lists (skolem constants
  dropped), the quoted citations in proof scripts (labels, VARs, formals and accessors removed),
  definition bodies and TCCs; overloads resolved by what the theory's own proofs use. Roots: the 14 kept
  results and every name the kept strategies cite, evaluate or check.
- **Step simulation:** each step's IMPORTING edits applied to the import graph, with checks of
  visibility, of deletions closed under reverse references, and of whole-datatype deletion. It did not
  model VAR declarations or NASALib visibility; the corrections above add what the adversarial checks
  found there.
- **Caveats:** the analysis is static. A use that no script names, such as an auto-rewrite installed by
  a strategy, would be missed; the per-step typecheck and gate catch it. Times are with traces; a plain
  replay is faster. Efforts are estimates. Path counts use `tools/import_paths.py`'s measure on the
  modelled graphs; re-measure them on the real files after each step.
