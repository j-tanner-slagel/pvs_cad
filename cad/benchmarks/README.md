# Benchmarks

The benchmark theories of the library are in `cad/`, outside `top.pvs`, because they hold
FALSE statements, slow ones, or measurement commands rather than proofs:

- `bench_pdec.pvs`, `bench_n.pvs`, `bench_c.pvs`: the closed problems of the Bath CAD example bank
  (source and license in `bench_pdec.pvs` and `NOTICE.md`) and four-quantifier examples, measured
  with `(cad-mn)`, `(cad-mx)` or `(cad-bench)`;
- `cad_limits.pvs`, `cad_limits2.pvs`, `cad_limits3.pvs`: where the decision stops scaling, each
  lemma annotated with its time;
- `cad_meas2.pvs` to `cad_meas5.pvs`: measurements of the projection and the lifting;
- `cad_msg_ex.pvs`: the inputs of `tools/msgcheck.sh` (what `(cad)` says when it does not prove a
  formula).

`baseline.md` records the timings of NASALib's own strategies (September 2026) that the work
started from.

The plan of September 2026 (CAD_PLAN.md section 11.4) also named external targets: NASA's
WellClear / DAIDALUS development and NASALib's ACCoRD (conflict and band lemmas with many
parameters). They were not attempted; nothing from them is in this repository.
