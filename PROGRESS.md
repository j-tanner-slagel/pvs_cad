# PROGRESS: slimming pvs_cad for NASALib

The log of the slim (`SLIM_PLAN.md`), one entry per gated step, newest at the end. The log of the
full development is `cad/PROGRESS.md` at tag `v1.0-full` (`HISTORY.md`).

## 2026-10-05 — the split: `full` and `v1.0-full`; Phase 1

- **Asked.** The development should go into NASALib (pvslib); the current state is historical. The
  current dev line becomes a historical branch and `main` the slim library: all the fixes, nothing
  redundant. Kept: `(cad)`, `(cad *)`, `(cad-qe)`, `(cad-direct)`, `(cad :cad-only? t)`, the constants
  and functions support (`pvs_cad_num`, `trans_bounds`); the Collins CAD theorems, QE and
  semi-algebraicity, the completeness of `(cad)`; an example for each.
- **The study.** A multi-agent study of what can go without losing them, verified by two adversarial
  checks: `SLIM_PLAN.md`, with the owner's decisions. A scratch library of the import closure of
  `pvs_cad_num`, the theorem theories and 11 example theories (329 theories) replayed 5,105/5,105.
- **Phase 0.** Dev branch `full` and annotated tag `v1.0-full` at `5700fd9` (the full library,
  5,628/5,628 replayed).
- **Phase 1** (no theory changed):
  - off `main`, kept at the tag: the 16 plans, `cad/PROGRESS.md`, `cad/benchmarks/`, and the tools of
    the profiling and raw-session era (`prof.sh` and `prof/*.lisp`, `multi.sh`, `prove_each.sh`,
    `pvs_raw_timeout.sh`, `cmds.py`, `seqs.py`, `showlab.py`, `openstates.py`, `effective.py`);
  - new: `HISTORY.md`, this log, `tools/replay.sh` (the whole library replayed in a scratch copy with
    `gate.sh`'s checks), `tools/prflint.py` (one proof per formula, no POSTPONE, no stale entries),
    `tools/stats.py` (the numbers the documents quote) and `tools/proveit_check.sh` (the checks of
    one proveit run, now shared by `gate.sh` and `replay.sh`);
  - `tools/export_public.sh` needs an explicit commit or tag, summarizes the change per directory, and
    scans the staged files for personal information;
  - `CLAUDE.md`, `tools/README.md`, `README.md` (a note that the slim is under way) and `SLIM_PLAN.md`
    (the open items of the old plans) updated.

## 2026-10-05 — S1: the dropped leaves and the dropped commands

- **Theories deleted (59; 110 files):** the examples of dropped engines and commands
  (`cad_decide7_ex`, `cad_diag_ex`, `cad_out_ex`, `alg_strategy_examples`, `sgn_examples`,
  `pos_examples`, `qe_run`, `qe_symbolic`, `qe_examples`, `tarski_examples`, `mpoly_mono_examples`,
  `alg_examples`, `mpoly_examples`, `mpoly_showcase`); the measurement theories (`cad_meas`,
  `alg_bis_ex`, `alg_dec_ex`, `alg_lift2_ex`, `cad_fast_ex`, `cad_pdec_ex`, `alg_meas`); the
  `psc_det?`, Phase 6 and item 1/A routes (`psc_det_ce`, `psc_det_quad`, `quad_sign`, `quad_set`,
  `quad_det`, `psc_quad1`, `fib_quad`, `disc_quad`, `delin_bridge`, `spec_deg`, `sturm_habicht`,
  `cad_decn`, `cad_projc`, `projc_mem`, `alg_dec`, `alg_lift2`); the support of the dropped commands
  (`alg_strategy`, `sgn_dec`, `sgn_prune`); the mult_poly bridge `mpoly_mono`; the read-closure
  results that are not kept (`complete_all`, `cad_found_def`, `cad_found_ok`, `cad_decide6`,
  `cad_decide6_def`, `decc_u`); and outside `top`: `cad_demo`, `cad_limits`, `cad_limits2`,
  `cad_limits3`, `bench_c`, `bench_n`, `bench_pdec`, `cad_meas2` to `cad_meas5`, `eval_probe`. No
  kept theory imported any of them.
- **Strategies:** 52 forms deleted (1,065 lines): `(alg-roots)`, `(poly-sign)`, `(poly-nosign)`,
  `(poly-pos)`, `(poly-nonzero)`, `(qe-exists)`, `(mpoly-eq)`, `(mpoly-simp)` and the measuring and
  inspection commands (`cad-bench`, `cad-m3`, `cad-mn`, `cad-time`, `cad-qeshow`, `cad-showf`,
  `cad-mx`). A reader of the file's top-level forms checked that every cut removed whole forms and
  that no kept code names a deleted one; the comments that described them were rewritten. The
  helpers `(cad)` borrows from the old commands (`qe-sub-e`, `qe-sub-p`, `qe-atom-parts`,
  `qe-list-str`) stay. 3,700 lines remain.
- **Other files:** `top.pvs` (46 IMPORTING entries and 47 description blocks; the passages that
  named dropped commands), `pvs_cad.pvs`'s header, `cad_msg_ex.pvs` and `tools/msgcheck.sh` (the
  `qe-exists` check), `tools/setup.sh`, `CLAUDE.md` and the README (no `mult_poly`: its only
  importer is gone), `NOTICE.md` (only `cad_bath` carries Bath data now), the README's import
  sentence and layout.
- **Verified:** `tools/replay.sh` 5,146 of 5,146 formulas, 328 theories, `prflint` 0 problems before
  and after (61 minutes, on a loaded machine); `tools/msgcheck.sh` 17 of 17; `tools/outside.sh` 6 of
  6. `stats.py`: 26,580 lines of PVS, 3,523 lemmas, 1,623 TCCs.

## 2026-10-05 — S2: the examples on `pvs_cad`; new examples; a fix for ambiguous names

- **Migrated:** `cad_examples`, `cad_examples2`, `cad_examples3`, `cad_examples4`, `cad_endgame_ex`,
  `cad_star_ex` and `cad_bath` import `pvs_cad` instead of `cad_decide5`; `cad_decide8_ex` no longer
  imports `cad_decide5`. Their headers describe the Collins run. Every proof was rerun on the
  pvs-cli server under the new import (101 proofs, all closed by the same one-command scripts), so
  the saved dependency lists name `decide8_correct`.
- **New:**
  - `cad_hard_ex`: 13 problems hard for CAD that `(cad)` proves under `pvs_cad` (Wilkinson's
    polynomial of degree 20, Chebyshev's of degree 30, AM-GM and Schur's inequality in three
    variables, two squares and Cauchy-Schwarz in four, seven two-variable problems of degree 7 to
    10), 1.4-8.9 s each through pvs-cli on a loaded machine. The README's timings now point to it.
  - `cad_results_ex`: the kept results on data. The Collins CAD of the unit circle as records
    (`col_found` stops at u = 0 with 15 records; `col_found_cad`), the records deciding
    FORALL x: EXISTS y: x^2 + y^2 - 1 = 0 OR x^2 - 1 > 0 (`col_found_decides`), the run a CAD
    (`col_verified`), decide8's run covering the plane (`decb_cad_run`), the cells quantifier-free
    definable (`col_cells_sa`), the line; `qelim` on EXISTS y: x^2 + y^2 - 1 = 0 (answer
    4x^2 - 4 < 0 OR 4x^2 - 4 = 0; `qelim_qf`, `qelim_ok`) and the set it defines (`fod_qfd`).
    15 lemmas, by evaluation and instances of the theorems.
  - `qe8_ex`: `q8_disc2g` (grouped binders through `(cad-qe)` with the minimal import), and
    `q8_win_cc`, `q8_win_cd`: on EXISTS t: 0 <= t <= T AND (5 - t)^2 + (t/2)^2 < D^2 with T the
    outer free variable, Collins's answer (`qe2cc`) is not quantifier-free and `qe8` falls back to
    `qe2cd`, whose answer is. No example reached that fallback before.
- **A fix (strategies), found by the window example:** `(cad-qe)` failed ("does not have a unique
  type") when a free variable had the name of a declaration it could be confused with, as T is
  with a NASALib function that pointwise function arithmetic admits in `5/2 * T`. The commands
  print their formulas as text and typecheck them again; an atom whose name resolves to more than
  one declaration is now printed `(T::real)` (`cad-atom-str`), and the readers look through such
  ascriptions (`cad-strip`), so a following `(cad *)` reads `(T::real)` and `T` as one unknown;
  `cadstar-key-text` does the same for skolem constants, which have no full name. Regression:
  `cad_forms_ex.qe_name_T`.
- **`cad_terms_ex` (Q19):** five lemmas proved exp(x) <= 1 + 2x on [0, 1], about 50 s each; the two
  that test the halving (`t5_exp_pieces`, `cn_splits`) keep it, and `t5_star`, `t5_posreal` and
  `cn_star`, which test the entry points, now prove exp(x) <= 3 (one enclosure, about 5 s each).
- **The fix's own regression, caught:** its first version also wrote bound variables as `(e::real)`
  when their names were ambiguous (lnexp's e), so `cad_forms_ex`'s `fx_eps` and `fx_s_eps`, which
  bind a variable named e, no longer matched their prefix; a bound variable now keeps its name
  (it shadows the others inside its binder).
- **Checking (the owner's rule, 6 October 2026):** a step is checked once, by the new
  `tools/check.sh`: the changed theories and every theory of `top.pvs` that imports them
  (`tools/affected.py`), proved in one proveit session with traces, in a scratch copy that keeps
  its compiled library. No per-theory runs, no three-run gates, no full replay per step; one
  full replay for the release. `CLAUDE.md`, `tools/README.md` and `SLIM_PLAN.md` say so.
- **Verified:** `tools/replay.sh` 5,226 of 5,226 formulas (330 theories; `prflint` 0 problems
  before and after); `tools/msgcheck.sh` 17 of 17; `tools/outside.sh` 6 of 6. Timing: the 14
  example theories (466 proofs) on the full version (`v1.0-full`, its strategies) and on this
  state, the same files: 1,660 s of cpu against 1,465 s (-12%), no proof slower than 1.25 times
  its time plus 0.3 s. `stats.py`: 26,764 lines of PVS, 3,555 lemmas, 1,671 TCCs, 3,727 lines of
  strategies.

## 2026-10-06 — S3a: the strategies use only the Collins engine; `qe_all` goes

- **Strategies:** `(cad)`, `(cad-direct)` and `(cad :cad-only? t)` decide by `decide8` and
  `(cad-qe)` eliminates by `qe8`, with no fallback to `decide5`, `decide7` or `qe` (`qe_all_def`); a
  theory that does not import the engine gets a refusal that says so (`(cad-qe)`'s is new). The
  options `:complete?` and DEC go with every call site that passed them (the internal calls of
  `(cad)`, `cad-main__`, `cadt__`, `cad-nest__`, `cad-direct`, `(cad *)` and the general route), so
  no positional argument moves into the `cad-only?` slot; `cad-finish__` keeps only `decide8`'s path
  (its certificate always passes, `decq8_complete`); the docstrings and comments say so.
- **Theories deleted:** `qe_all`, `qe_all_def` (the read-closure QE, `qe_complete`) and `qe_cad_ex`
  (its grouped-binder example is `qe8_ex.q8_disc2g` since S2). No kept theory imported them.
- **Message tests:** `cad_msg_d5` is `cad_msg_d8` (imports `cad_decide8`, `mpoly_embed`), with the new
  check `m_noqe` ((cad-qe) without `qe8`); `cad_msg_qe` imports `qe8`; `m_nodec` expects
  "does not import cad_decide8".
- **README** and `top.pvs`: the passages about `qe_all` and `decide5`.
- **Checked:** `tools/check.sh` on the 13 example theories whose proofs use the commands, one
  session: 452 of 452; `tools/msgcheck.sh` 18 of 18; `tools/outside.sh` 6 of 6.

## 2026-10-06 — S4: decide5 and decide7 cut out of `cad_decide8`

- `cad_decide8_def` imports `cad_lift` (for `decq2`, decide8's one-quantifier branch) instead of
  `cad_decide5_def`; `cad_decide8` imports `complete1` and `cad_endgame` instead of `cad_decide7`
  (`cad_endgame` on purpose: a theory that imports `cad_decide8` without `pvs_cad` needs the
  endgame's rewrites) and takes the one lemma it used from `cad_decide7`, `len_ge2` (its proof
  rerun through pvs-cli); `complete1` imports `cad_lift` instead of `cad_decide5` and keeps
  `svs1ok_complete` and `decq2_complete1` (`decq5_complete1` and `decide5_complete1` go).
  Both theories' proofs were rerun on the server and saved by PVS.
- **Theories deleted (10):** `cad_decide3`, `cad_decide3_def`, `cad_decide4`, `cad_decide4_def`,
  `cad_decide5`, `cad_decide5_def`, `cad_decide7`, `cad_decide7_def`, `cad3`, `decide_u`. The
  read-closure decision engines are out of `pvs_cad`'s import closure.
- **Checked:** `tools/check.sh` on the three edited theories and their 20 importers (the examples
  among them), one session: 519 of 519; `tools/msgcheck.sh` 18 of 18; `tools/outside.sh` 6 of 6;
  `prflint` 0 problems.

## 2026-10-06 — S5: the QE engines go

- **Moves:** `dclx?` from `qe2c_def` into `ctwd_def`, and `every_mem_l`, `dclx_dcl`, `every_dclx`
  from `qe2c_ok` into `ctwd` (their proofs rerun through pvs-cli and saved by PVS). `ctwd` imports
  `qe2_def` instead of `qe2c_def`, and `structures@list2set_props`: the cut had hidden NASALib's
  `member_append` rewrite that `dflat_mem`'s saved proof used.
- **Import cuts:** `qe2cd_ok` imports `qe2_sep` and `qe1_full` instead of `qe2c_full` and
  `qe2cc_ok`; `twrun_ok` imports `cad_fold_ok` instead of `qe2_ok`; `qe_def` drops `decide_u_def`,
  `qe2_ok` drops `cad_sample`, `cad_sa` drops `cad_verified`.
- **Deleted in kept theories:** the read-closure engine's quantifier elimination: `qe_def`'s `qe1_c`,
  `qe1_o`, `qe1_u`, `qe1`; 14 lemmas of `qe1_ok` (`qe1_correct`, `qe1_qf`, `qe1_u_ok`, `qe1_bf`,
  ...); `qe1_full`'s `qe1_isqf`, `qe1_complete`; `qe2_def`'s `runok`, `qe2_c`, `qe2_o`, `qe2_u`,
  `qe2`; 11 lemmas of `qe2_ok` (`qe2_correct`, `qe2_qf`, `qe2_u_ok`, `qe2_bf`, ...); `cad_sa`'s
  `cad_cells_sa`; and the variables the deletions left unused. What stays of these theories is the
  answer layer that the Collins QE (`qe1c`, `qe2cc`, `qe2cd`, so `qe8`) uses: `qe1_sm` and `secout`
  and their correctness.
- **Theories deleted (13):** `qe2c_def`, `qe2c_ok`, `qe2c_u_def`, `qe2c_full`, `aug_univ`, `aug_ev`,
  `runT_def`, `runT_ok`, `cad_sample`, `cad_verified` (the read-closure run's CAD theorem;
  `col_verified` is the Collins run's), `decide_u_def`, `decn_complete`, `clos_ev`.
- **Comments:** the headers of `qe_def`, `qe1_ok`, `qe1_full`, `qe2_def` and `qe2_ok` say what they
  hold now, and those of `qe1c_def`, `qe1c_ok`, `qe2cc_def`, `col_verified` and `ctwd` no longer cite
  the deleted engines; `top.pvs`'s blocks likewise. Its `pvs_cad` block now names the theorem
  theories outside `pvs_cad`'s import closure correctly (`col_line`, `col_found_ok`, `decb_run`,
  `cad_sa`; it had listed `qelim_ok`, which is inside). The README still describes the removed
  engines; Phase 4 rewrites it.
- **Checked:** `tools/check.sh` on the ten edited theories and their 27 importers (the examples
  among them), one session: 731 of 731 (2,225 s); the comment and variable edits made after it
  typecheck, and the five theories that lost variables were rerun on the server (12, 16, 4, 21
  and 54 of the same, their `.prf` files unchanged); `tools/msgcheck.sh` 18 of 18;
  `tools/outside.sh` 6 of 6; `prflint` 0 problems.

## 2026-10-06 — S6: the n-level read-closure engine leaves

- **Import cuts and the imports that keep visibility:** `tower_def` and `cad_fast` drop
  `cad_fast_def` (`tower_def` imports `alg_bis` and `sturm_sg` instead), `towern_def` drops
  `cad3_def` (imports `mpoly`), `lev_ev` drops `nclos_ok` (imports `clos_ok` and `inner_const`),
  `clos_ok` drops `tower_univ` (imports `towern_od`), `innern_sem` drops `tower_sem` (imports
  `tclf`); `qsec_rd` adds `walk_rd`, `tower_ev` adds `decn_ok`.
- **Deleted in kept theories** (Appendix A.S6, 108 formulas with their definitions): the n-level
  decision `decn_o` and its closures (`nclos_o`, `lvln_o`, `tclos_o`, `nbads_o`, `scof`), the run
  (`runq`, `runsects`, `runtw`, `rcell`) and the n-level `cad_out`; the two- and three-level
  decisions (`decw`'s correctness, `inner2`, `dec3m`, `ok3m`, `cellvals`, `yclos`, ...); and the
  theorems about them: `cad_run`, `run_ok`, `sector_cad`, `sector_inv`, `cad_out_ok`,
  `cad_out_mem`, `cad_decides`, `sector_*`, `rcell_ok`, `rcell_fod` (and their `_le` forms),
  `decn_correct`, `decw_correct`, `innern_sem`, `ia_*`, `inner2_sem`, `cv_*`, `fixp_clk`,
  `okn_split`, `cells_valid`, `sec_fib`, `cl_cells`. `towern_def` keeps only `Tower` and `zipapp`;
  the variables nothing uses any more go too (VAR declarations are not exported, and none of them
  appears in a kept proof).
- **Theories deleted (8):** `cad3_def`, `cad_fast_def`, `list_flat`, `nclos_ok`, `read_fam`,
  `read_univ`, `tower_sem`, `tower_univ`.
- **A parse trap:** `cad_out_ok`'s `o: VAR ORec` used to follow another VAR; after a formula, PVS
  reads `... = A o` as the composition operator ("May need a ';' before declaring an infix
  operator"), so the declaration joined the VARs at the top of the theory.
- **Comments:** the headers and `top.pvs` blocks of the edited theories say what they hold now
  (the descriptor walk of `towern_od`, the records of `cad_out`, the definability lemmas of
  `rcf_cells` that `col_run` applies, ...), and those of `cad_fold`, `decc_def`, `decc_walk`,
  `col_out_ok`, `col_run`, `pt_local` and `tclf` no longer cite the deleted engine.
- **Checked** (S6 to S9 together, the owner's rule: once): each step's edited theories were rerun on a
  pvs-cli server and the whole library typechecked after each step; then `tools/check.sh` on the 56
  theories the four steps edited and every theory of `top.pvs` that imports one of them, one session
  (159 theories, the examples among them): 2,437 of 2,437 (2,434 s); `prflint` 0 problems.

## 2026-10-06 — S7: the walk side's import-only imports

- **Import cuts and the imports that keep visibility:** `cad_roots` and `tclf` drop `mwalk` (both
  import `zfam`), `tclf` and `cad_gpar` drop `mroot`, `mpar` drops `walk_same` (it imports
  `mpoly_def` and NASALib's `reals@abs_lems`, `reals@real_orders`, `structures@listn`, whose
  auto-rewrites its kept proofs `near_refl` and `near_hd` used), `pt_local` drops `root_cont`
  (imports `cover`), `inner_const` drops `cells_local` (imports `cover`, `pt_local`), `cad_stack`
  drops `cad_local` (imports `cad_fibre`), `cad_delin` drops `cad_pdec` (imports `cad_decide`),
  `alg_sturm` drops `alg_lift` (imports NASALib's `reals@sign3` for `sign3`: a fix, the plan had
  not listed it), `alg_bis` drops `alg_sturm2`; `sturm_sg` adds `sg_chain2`, `cad_out_ok` adds
  `cad_gpar`.
- **Deleted in kept theories** (Appendix A.S7, 95 formulas, with `tlc.fin_near`, `alg_sturm`'s `a`
  and `cad_delin`'s `s`): `tclf`'s prefix and height statements (`CBh`, `LCh`, `CTh`, `cb_step`,
  `ct_step`, `sem_ex`, `pre`, ...), keeping `tlast` and `CLF`; `tlc`'s local constancy (`lc_base`,
  `lc_step`, `cells_near`, ...); `cad_stack`'s `stack_const` and its lemmas (`delin_cl?` stays);
  `cad_tower`'s `tower_cad` and `rdag_up`; `alg_sturm`'s algebraic Sturm counts; `alg_bis`'s
  bisection lifting; `cad_delin`'s `dec2_sem` and `delin?`; `cad_gpar`'s gap-pattern lemmas;
  `inner_const`'s `G_const` family; `mpar`'s `msg_mpers`; `pt_local`'s `pt_local`, `pwalk_local`,
  `T_same_r`, `rf_inv_r`; and the variables left unused.
- **Theories deleted (11):** `alg_lift`, `alg_sturm2`, `mpoly_swap`, `cad_local`, `cad_pdec`,
  `cells_local`, `joint_cont`, `mroot`, `mwalk`, `root_cont`, `walk_same`.
- Headers and `top.pvs` blocks of the edited theories say what they hold now. PVS wrote empty
  `.prf` files for `cad_stack` and `tlc`, which keep no formula; they are removed.
- **Checked:** with S6, S8 and S9 (the S6 entry).

## 2026-10-06 — S8: the Phase 3/5 context trees

- `rsc_tree` drops `bbindc_ex` and `qe_ctx` (imports `conj_tree`, `sign_oracle`); `cad_lift` drops
  `svs_pt` (imports `sect_inv`).
- **Deleted in kept theories:** `cad_decide`'s `decide`, `decq` and their correctness
  (`decq_correct`, `decide_correct`, `decide_correct_os`, `qfold_svs`, `sem_peel`); `cad_lift`'s
  `decide2`, `decide2_correct` and eleven helpers; `rsc_tree`'s `rsc`, `rsc_sound`, `rsc_complete`;
  `svs_tree`'s `svs`, `svs_sound`, `svs_complete`, `select_svs`, `infvs`, `select_infvs`; and the
  variables left unused. `cad_decide`'s VAR `t` stays until S9 (`polys` uses it), not S8 as the
  corrections said.
- **Theories deleted (9):** `qe_ctx`, `qe_tree`, `btree_prune`, `ineq_ctx`, `tarski_ctx`,
  `prsp_ctx`, `snorm_ctx`, `hutch_oracle`, `svs_pt`.
- **A tool fix:** the helper that edits `top.pvs` compared whole IMPORTING entries, so it missed
  `btree_prune[bool]`; it now compares theory names, and it writes an entry with several actual
  parameters on one line again (S1 to S5 had split such entries over two lines, which PVS accepts).
- **Checked:** with S6, S7 and S9 (the S6 entry).

## 2026-10-06 — S9: decq1, decide8's one-variable branch without the read closure

- **New definition:** `cad_decide8_def.decq1` is the two branches of `cad_lift.decq2` that decide8
  ran: no quantifier, `Psi` of the constants' sign vector; one, the fold over `cell1`'s `svs1` with
  the certificate `svs1ok`. `decq8` calls it, and `cad_decide8_def` imports `cell1` instead of
  `cad_lift`. **New lemma** `cad_decide8.decq1_correct` (`length(qs) <= 1`), proved through pvs-cli
  from `sem_null` and `qfold_svs1`; `decq8_correct` and `decq8_complete` re-proved through pvs-cli
  with `decq1_correct` and `svs1ok_complete` in place of `decq2_correct` and `decq2_complete1`.
  The statements of `decide8_correct` and `decide8_decides`, the computation and the strategies do
  not change. No example reaches the null branch: `(cad)` refuses a quantifier-free formula without
  `pvs_cad`, and under it `qelim` calls decide8 with one quantifier; `decq1_correct` covers it.
- **Import cuts and adds** as in Appendix A.S9 (`cad_decide` drops `svs_tree` and `tree_sel` and
  imports `rsc_tree`; `sect_inv` drops `alg_count2`; `sg_chain` drops `tarski_many` for
  `tarski_chain`; `sector_rep` drops `poly_rolle` for `mpoly_prod`, `pos_dec`; `pos_dec` drops
  `root_dec` for `mpoly_univ`; `far_sign`, `rsc_tree`, `branch_prs`, `branch_sgn` lose the
  Tarski-tree theories; `cad_lift` imports `mpoly_eqd` for `sg_svs`; `crit_pos` adds `earr_deriv`).
- **Deleted in kept theories** (Appendix A.S9, 192 formulas, and the corrections): `cad_lift` keeps
  only what qe8 and decide8 evaluate (`memb`, `memb1`, `dedup1`, `rts`, `sval`) and `qfold_svs1`;
  `sect_inv` loses `inv_chk` and the `*_free_*` and `sep*` families; `sg_chain`/`sg_chain2` lose the
  Tarski-query readers; `chain_sturm` loses `ftree`; `complete1` loses `decq2_complete1`;
  `cad_proj`'s projection with read closures (its TCC proofs cited `sg_svs`); `crit_pos`'s
  critical-point lemmas (`big_pos_left`, `far_neg_left`, `far_neg_right` cite a deleted lemma, and
  with them `crit_between`, `crit_exists`, `deriv_max_le`, which nothing uses, from S11's list;
  `deriv_max_pf` stays, `qe_ep_ok` uses it); `cad_decide`'s `polys` with its VAR `t`; the
  variables left unused. `cad_decide`'s `every_all` and `some_mem` had saved proofs that used a
  NASALib rewrite the cut hid; they were re-proved through pvs-cli with explicit expansions.
- **Theories deleted (31):** `alg_count2`, `bbindc_ex`, `branch_ctx`, `branch_map`, `conj_tree`,
  `exists_dec`, `ineq_ok`, `ineq_tree`, `many_ok`, `many_tree`, `mpoly_cst`, `poly_farinf`,
  `poly_rolle`, `qe_conj`, `qe_formula`, `root_dec`, `sg_conj`, `sg_conj2`, `sg_svs`, `sgn_count`,
  `sign_oracle`, `sign_tree`, `svs_tree`, `tarski_count`, `tarski_dec`, `tarski_many`,
  `tarski_multi`, `tarski_pair`, `tarski_tree`, `tarski_two`, `tree_sel`. Empty `.prf` files PVS
  wrote for `cad_proj` and `rsc_tree` (no formulas left) are removed.
- **Checked:** with S6 to S8 (the S6 entry); after this step `tools/msgcheck.sh` 18 of 18,
  `tools/outside.sh` 6 of 6.

## 2026-10-06 — S10: the 20 theories that only lent declarations are dissolved

- **Moves** (Appendix A.S10; a script moves each declaration with its comment
  lines and the VARs it uses, after everything it depends on in the destination, text and saved
  proof, and before everything there that uses it):
  - `rsc_tree`'s `SV`, `SVL` → `sign_vec`;
  - `alg_bis`'s `lives`, `zc?`, `strip`, `bprod`, `lsumk`, `bk`, `cad_proj`'s `live?` and
    `cad_delin`'s `fib` → `walk_def`;
  - `cad_lift`'s `rts`, `sval`, `sval_sample` → `sect_inv`; `memb`, `memb1`, `dedup1` and their
    lemmas → `mpoly_eqd`; `qfold_svs1` → `cad_decide8`;
  - `complete1`'s `svs1ok_complete` and `far_sign`'s `len_pos` → `cell1`;
  - `decn_ok`'s list and descriptor lemmas, `cad_delin`'s `qfold_fib` and `closed_pt`'s `wok_cert` →
    `innern_sem`; `decn_ok`'s `tables_vtb` → `tower_ev`;
  - `pt_local`'s separator lemmas, `inner_const`'s `gap_sec` and `clos_ok`'s `cells_o`,
    `cellsf_every`, `tables_len` → `lev_ev`;
  - `level_ok`'s `bfold_mem`, `rootfree?` → `cover`; `tlc`'s `Tv` → `col_sem`; `cad_fast`'s `insec`,
    `in_conv` → `cad_run`; `alg_sturm`'s `sign3_scale` → `sturm_sg`; `pos_dec`'s `pf`, `pf_cont` →
    `mpoly_real`; `branch_sgn`'s `SL`, `msign_mnorm` → `sg_norm` (with the `branch_tree[SL]`
    instance after `SL`); `cad_gpar`'s `gap_lt`, `gr_nlt_hd`, `wsep?` → `cad_out_ok`;
  - `sign_pers`'s `cont_sign` → `sep_exist`, its function variable renamed `fr` (`sep_exist`'s `f`
    is a `list[mpoly]`).
  The moved formulas' saved proofs were replayed in their new theories through pvs-cli, each as one
  command from the old `.prf`; three needed more: `dedup1_member` (a NASALib rewrite of `member`
  over `cons` no longer visible, re-proved with explicit expansions), `pf_cont` (`mpoly_real` now
  imports NASALib's `analysis@derivatives[real]`, as `pos_dec` did, with that import's two TCCs
  replayed from `pos_dec`), and `walk_def`'s `coin?_TCC3`, a termination TCC the new context
  generates and the TCC strategy did not prove (proved by expanding `length`).
- **Deleted with the dissolved theories** (not moved, not needed): `decn_ok`'s list shapes,
  `level_ok`'s `T`, `sem1_fibs`, `Srf`, `rf_conv`, `rf_refl`, `closed_pt`'s `cl_transfer` and
  `rdin?` family, `sign_pers`'s `msg_pers*`; and, as the corrections say, S11's deletions in
  `walk_transfer` (the transfer theorem's `fib_local` family, 29 formulas) and `zfam` (13).
- **The final imports** (Appendix A.final) for the theories that imported a dissolved one; 20 theory
  files go: `rsc_tree`, `alg_bis`, `cad_proj`, `cad_delin`, `cad_lift`, `complete1`, `far_sign`,
  `decn_ok`, `clos_ok`, `inner_const`, `pt_local`, `level_ok`, `tlc`, `cad_fast`, `alg_sturm`,
  `sign_pers`, `pos_dec`, `branch_sgn`, `cad_gpar`, `closed_pt`.
- **Comments:** the headers of `walk_def`, `walk_transfer`, `zfam`, `sturm_sg`, `mpoly_eqd` and the
  moved declarations' comments no longer cite the dissolved theories; `top.pvs` likewise.
- **A trap:** the scratch server's compiled library went stale after the moves (`sector_rep` could
  not see `pf`, which `mpoly_real` declared); clearing `pvsbin` fixed it, and the check below
  starts from an empty `pvsbin`.
- **Checked:** with S11 (the S11 entry).

## 2026-10-06 — S11: the remaining unused declarations

- **Deleted** (Appendix A.S11, 53 theories): the declarations nothing in the slim library uses,
  among them `branch_tree`'s `branches` and its soundness and completeness (with the VARs of the
  types `SignCond` and `Branch` and the `list2set_props[Branch]` instance, as the corrections say),
  `cad_out_ok`'s `ctree_in`, `ctree_cover` and `okt?`, `cell_ok`'s `pt_fib`, `subres`'s
  `psc0_res` and `subres2`'s `psc_sres` (with `sylvester`'s `syl`, `res`, `disc` and their
  evaluation lemmas: Q6), `thom_enc`'s `thom` and `thom_lemma`'s `thom_distinct`, `decb_ok`'s
  `decb_complete` and `decc_ok`'s `decc_complete` (`decb_u_complete` is what decide8's
  completeness uses), `col_verified`'s `col_exists`, `col_found_ok`'s `col_found_ccad`,
  `croot_lsc`'s `dist_same`, `cvl`'s `cvl_eq`, `qe_mrg`'s `qf_mrgX`, `towern_od`'s `topreads`;
  and the VARs left unused. (`walk_transfer`'s and `zfam`'s items went in S10, `crit_pos`'s in
  S9.)
- **Comments:** the headers of `branch_tree`, `subres`, `sylvester`, `thom_enc` and the comments
  and `top.pvs` blocks that named a deleted declaration say what the theories hold now.
- **Checked** (S10 and S11 together, from an empty `pvsbin`): every edited theory rerun on a
  pvs-cli server and the library typechecked after each step; then `tools/check.sh` on the 77
  theories the two steps edited and every theory of `top.pvs` that imports one of them, one
  session (207 theories): 3,381 of 3,381 (2,501 s); `prflint` 0 problems.

## 2026-10-06 — Phase 3: comments without the plans and the removed engines

- The comments' 220 citations of the development plans (`X_PLAN.md` sections), which are not part
  of the library (they are at `v1.0-full`), go: a parenthesis that only cited plans is removed, one
  with a date keeps the date, and 56 citations inside sentences are reworded by hand. The comments
  that still named a declaration or theory the slim removed (`inv_chk`, `sepf`, `cad_local`,
  `decide5_correct`, `cad_lift`, `stack_const`, `decide_u_def`, `qe_all`, `delin?`, `svec_same`,
  ...) are reworded, so that a scan against the full version finds none left. Comment-only; the
  library typechecks, and the release replay checks it.

## 2026-10-06 — Phase 3: the redundant imports

- 36 IMPORTING entries that another entry of the same clause already brings in go (transitive
  reduction; a scratch script follows the local imports and NASALib's own, and does not follow an
  instance with actual parameters, which gives that instance only). The entry points (`pvs_cad`,
  `pvs_cad_num`) and the examples keep their explicit lists, which say what they use. The import
  closures do not change; the library typechecks, and the 26 theories whose clause changed were
  rerun on a server (all proofs succeed; PVS rewrote 14 of their `.prf` files' dependency lists).

## 2026-10-06 — Phase 3: names that clash with NASALib (Q7)

- Six formula names and a type that NASALib libraries also declare are renamed: `len1` →
  `len1_run` (`cad_run`), `nth_cdr` → `nth_cdr_earr` (`earr_deriv`), `odd_even` → `odd_even_sidx`
  (`cad_fibre`), `cont_const` → `cont_const_slab` (`cad_slab`), `left_zero` / `right_zero` →
  `left_zero_sg` / `right_zero_sg` (`sturm_sg`), and the type `Mat` → `MMat` (`ring_det`, beside its
  `RMat`). The renamed lemmas' proofs and the 30 proofs that cited the old names were replayed through
  pvs-cli, each as one command from the old `.prf` with the names changed, and the 24 theories
  involved were rerun on a server and saved by PVS; `prflint` 0 problems.

## 2026-10-06 — S3b: `:cad-only? t` keeps the witness search out of the side decisions too

- **Strategies:** the CAD-ONLY? flag now reaches every decision a `(cad)` run makes: the TCCs of the
  type facts and exact facts (`cadstar-tcc__`, `cadstar-typepred__`, `cadf-add__`, `cadf-loop__`), the
  leaves of the mirror walk of the term readings (`cadt-sqrt__`, `cadt-div__`, `cadt-cases__`), the
  general route (`cadg__`, `cadg-finish__`) and `(cad-direct)`. The code that writes these steps
  reads the flag from a variable bound only while it writes them (`*cad-only-gen*`), so no flag
  outlives its command. Without the flag nothing changes. Before, `(cad :cad-only? t)` on a formula
  with a square root under a binder started a witness search in a side decision.
- **A regression check:** the strategies count the witness searches they start (`*cadw-plans*`), and
  `tools/msgcheck.sh` has five new rows (`cad_msg_ex`'s `m_only_*`): under `:cad-only? t` the count
  must not grow, for `(cad)`, a square-root reading, `(cad *)` and `(cad-num)`; the control, plain
  `(cad)` on the reading, must make it grow. With the strategies before this step the reading row
  fails (two searches). The proofs of these rows close, and `msgcheck` puts `cad_msg_ex.prf` back as it
  was.
- **Phase 3, the strategies (same commit):** the docstrings and comments no longer cite the
  development plans (36 places); the library lemmas the strategies cite are qualified with their
  theories, as NASALib's own strategies do (`"mpoly_embed.peval_pnorm"`, `"gform_ok.decide_g_ok"`,
  `"cad_decide8.decide8_correct"`, `"qe8.qe8_correct"`, the `gb_*` and `cadz_s3_*` rewrites, ...), so a
  user's lemma of the same name cannot be picked up; the witness search's time budgets use PVS's own
  `with-timeout` (SBCL and Allegro) and its random numbers come from `cadw-rng` (SBCL's generator
  seeded with a constant, as before, and a linear congruential one on another Lisp), which removes
  the SBCL requirement; the helpers `qe-sub-e`, `qe-sub-p`, `qe-atom-parts`, `qe-list-str` are
  `cad-sub-e`, `cad-sub-p`, `cad-atom-parts`, `cad-list-str`.
- **Checked:** msgcheck 23 of 23 (the five new rows included); the release replay below.

## 2026-10-06 — the release replay; Phase 4: the docs

- **Release replay** (`tools/replay.sh --traces`, a fresh copy of the state after S3b and Phase 3):
  3,642 of 3,642 formulas in 225 theories, no "fewer subproofs" warning, `prflint` 0 problems
  before and after (3,609 `.prf` entries), 41 minutes. `tools/msgcheck.sh` 23 of 23;
  `tools/outside.sh` 6 of 6.
- **Numbers** (`stats.py` on that replay): 225 theories in 228 files (3 of them generated datatype
  files), 17,452 lines of PVS, 3,642 formulas (2,361 lemmas and theorems, 1,281 TCCs), 3,715 lines
  of strategies. `v1.0-full` has 375 theories, 5,628 formulas (3,843 and 1,785) and 4,769 lines of
  strategies.
- **Timing** (the owner's requirement that the examples stay as fast): the 14 example theories
  (467 proofs) in one `proveit` session on the replay's compiled copy, against the same proofs on
  `v1.0-full` (its library and strategies, measured on 5 October): 1,032 s of cpu against 1,660 s
  for the 466 proofs both have (-38%). Every theory is faster; 6 proofs are slower at all, by at
  most 0.02 s (TCCs of a few hundredths of a second). The QE examples' elimination steps take
  1.7-4.2 s (3-7 s on 4 October), with the same answers.
- **Docs:**
  - `README.md` rewritten for this library: the main results, what is and is not proved, how it
    was made, the commands, constants and terms, timings, the layout, and a note on `v1.0-full`;
  - `docs/cad_overview.tex`, `docs/collins_cad.tex`, `docs/qe_capabilities.tex` describe the one
    engine that is left (the Collins run), its decisions and its quantifier elimination. The earlier
    engines are one history item of the overview, and the decision-alone comparison of
    `collins_cad` says it was measured in the full development. `decc_ev` and `decb_ev` (every
    large enough effort parameter certifies the run) are cited where the docs cited
    `decc_complete` and `decb_complete`, which follow from them and went in S11. The timing tables
    are this session's, the numbers this replay's, and `qe_capabilities`' examples and transcripts
    were captured again on this library (the overview's four sessions keep their text of 1
    October, which the commands still print, without their old times); the PDFs are rebuilt with
    Tectonic;
  - `docs/cad_proof_traces.{tex,pdf}` (recorded with decide5) leave `main`; they stay at
    `v1.0-full`;
  - `HISTORY.md` and the status of `SLIM_PLAN.md` say the slim is done.

## 2026-10-06 — the library in NASALib's layout

- **Asked (owner):** NASALib takes one folder of `.pvs` files with a README; make `cad/` that
  folder (a README in NASALib's style that covers what the library does, how to use it and the
  important theorems; `top.pvs`'s tags; the examples in `examples/`; the message-test inputs and
  the Bath problems out of it), and no Bath problem in it, nor anything like one.
- **The folder:**
  - `cad/README.md` in the form of NASALib's library READMEs: an introduction, Highlights, a
    Major-theorems table (location and PVS name), the strategies with their syntax, getting
    started, examples, trust and limits, how it was made, license, contributors, dependencies.
    The root `README.md` is now a short page that points to it;
  - `cad/top.pvs` has the six tags NASALib asks for (`@library cad`, `@description`, `@author`,
    `@poc`, `@date`, `@copyleft` CC0) and its descriptions grouped by topic, not by development
    phase;
  - the 13 example theories are in `cad/examples/` with their own `top.pvs`, importing the
    library as `cad@...`, as NASALib's examples do;
  - `cad_msg_ex` (the message-check inputs, four theories in one file) is in `tests/msg/`, and
    `cad_bath` (the Bath problems, CC BY-SA) in `tests/bath/`;
  - `cad/examples/cad_reduce_ex` (new, CC0) shows the path the Bath problems were the only test
    of, the witness search's one-variable reduction, on a sentence of another form: a polynomial
    plus a constant c is positive on the unit disc (the full decision does not finish in 40 s;
    with c fixed to 2, about 15 s), proved by `(cad)` and, negated as a hypothesis, refuted by
    `(cad -1)`. A first draft had the form of Bath 02 (positive on a quadrant beyond r) and was
    replaced before any commit.
  - No Bath problem, part of one or name is left in `cad/`: a search for fragments of all ten
    finds none, and four performance comments that named them now say "one benchmark".
- **Comments:** the theories' remaining development-phase labels ("(Phase 2)", "Stage C of item
  1", "(C8)", ...) are removed or reworded (58 files), and three in `pvs-strategies`. Compared
  with the comments removed, no code changed but the moved theories' IMPORTING lines and
  `top.pvs`'s import list (the 14 example theories out).
- **Tools:** `env.sh` puts the library's parent directory first on `PVS_LIBRARY_PATH` (so
  `cad@` finds it) and has `CAD_WORK_DIR`, where the pvs-cli tools work (`cad/examples` for an
  example); `replay.sh` and `check.sh` prove the library and the examples, each in one session;
  `affected.py` follows `cad@` imports; `stats.py` reports the library and the examples;
  `msgcheck.sh` and `outside.sh` run in scratch copies (msgcheck on a server of its own,
  `outside.sh` also replays `tests/bath`); `srv.sh --stop`; `gate.sh` (three runs per theory,
  replaced by `check.sh`) is gone. `tools/README.md`, `CLAUDE.md`, `NOTICE.md`, the notes'
  paths and numbers follow.
- **Checked:** the library's theories changed only in comments since the release replay above
  (3,175 of its formulas; 210 theories): `top.pvs` typechecks (149 s). The examples, from their
  new place: `tools/check.sh` on the 14 example theories, in one session, 456
  of 456 (with the first draft of `cad_reduce_ex`), then `cad_reduce_ex` alone, 5 of 5. `tools/outside.sh`: `use_pvs_cad` 6 of 6, `cad_bath` 15 of 15.
  `tools/msgcheck.sh` 23 of 23.
