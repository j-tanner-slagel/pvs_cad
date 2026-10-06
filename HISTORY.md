# History: the full version of pvs_cad

The library on `main` is the slim library prepared for inclusion in NASALib (`SLIM_PLAN.md` says
how it was planned, `PROGRESS.md` how each step was done and checked). The full development stays
available, unchanged:

- **Where:** branch `full` and tag `v1.0-full`, the state of 5 October 2026 (315 commits since
  9 September 2026). The whole library replayed there: 375 theories, 5,628 formulas (3,843 lemmas
  and theorems, 1,785 TCCs), 29,335 lines of PVS, 4,769 lines of strategies.
- **What it has that the slim library does not:**
  - the read-closure decision engines decide3, decide4, decide5, decide6 and decide7, with
    `decide5_correct`, `decide5_complete` and `complete_all.decide5_decides`;
  - the n-level engine's CAD theorems (`cad_verified`, `cad_exists`, `cad_found_ok.cad_found_cad`,
    `cad_sa.cad_cells_sa`, `cad_fold_ok.cad_decides`) and its quantifier elimination
    (`qe_all.qe_complete`);
  - the early one-variable machinery (multi-polynomial Tarski queries, sign-condition trees) and the
    research routes that were superseded or refuted (Phase 6, item 1 with `psc_det?`, item A);
  - the commands `(alg-roots)`, `(poly-sign)`, `(poly-nosign)`, `(poly-pos)`, `(poly-nonzero)`,
    `(qe-exists)`, `(mpoly-eq)`, `(mpoly-simp)`, and the measuring commands (`cad-mx`, `cad-mn`,
    `cad-m3`, `cad-bench`, `cad-time`) with the profilers;
  - the benchmark and playground theories (`cad_limits*`, `bench_*`, `cad_meas*`, `cad_demo`);
  - the raw-session tools, `docs/cad_proof_traces.pdf` (transcripts recorded with decide5), the
    development log `cad/PROGRESS.md` and the plans below.

Comments in `cad/` that cite a plan or a PROGRESS entry refer to these files at the tag.

## The plans

Each is at `https://github.com/j-tanner-slagel/pvs_cad/blob/v1.0-full/<NAME>.md`.

| Plan | What it covers |
|---|---|
| `CAD_PLAN` | the survey, prior art and the design decisions |
| `PHASE6_PLAN` | the projection route of Phase 6 |
| `ITEM1_PLAN` | `psc_det?`, proved false in general |
| `ITEMA_PLAN` | algebraic sample points without Q(alpha); superseded |
| `FINISH_PLAN` | the completion plan of September |
| `PERF_PLAN` | the speed of the n-level decision |
| `COMPLETENESS_PLAN` | the completeness of the decision (decide5) |
| `CADSTAR_PLAN` | `(cad *)`: the polynomial content of a whole sequent |
| `ENDGAME_PLAN` | proof reconstruction without a case explosion |
| `GAP_PLAN` | from the decision procedure to a verified CAD: Tiers 0-4 and what remains |
| `QE_PLAN` | the stages of quantifier elimination |
| `COLLINS_PLAN` | Collins's projection, milestones M-A to M-K |
| `FORMS_PLAN` | formulas as people write them |
| `PROJ_PLAN` | a smaller projection, P1-P7 |
| `TERMS_PLAN` | constants and algebraic operators, T1-T4 |
| `NEXT_PLAN` | fast determinants (P5), functions of bounded constants (T5), the review, P7 |

The items these plans left open are carried in `SLIM_PLAN.md`.
