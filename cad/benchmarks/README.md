# Benchmarks

External developments used as benchmark sources (not copied into this repository):

- NASA WellClear / DAIDALUS PVS development: sparse clone of `nasa/WellClear` (only
  `PVS/`) at `$WELLCLEAR` (a local checkout), commit 5912c27 (2020-11-19, "Updated to
  PVS7.1"). Replays on PVS 8.1 + NASALib 8.1: `WellClear` library 209/209 via
  `proveit -i -f WCV_inclusion.pvs` (2026-09-09). To use it:
  `export PVS_LIBRARY_PATH=$NASALIB:$WELLCLEAR/PVS`.
- NASALib `ACCoRD` (`cd2d`, `horizontal_criterion`, `trk_bands_2D`, `trk_line`,
  `trk_circle`, `tangent_line`) and `Sturm`/`Tarski` examples.

Target statements for the decision procedure (plan section 11.4):

| Source | Formula | Shape |
|---|---|---|
| `WellClear@WCV_inclusion` | `tcpa_le_tau`, `taumod_le_tcpa`, `tep_le_taumod` | universal over `s`, `v : Vect3`, thresholds symbolic; quotients |
| `WellClear@WCV_inclusion` | `WCV_taumod_inclusion`, `WCV_tcpa_inclusion`, `WCV_tau_inclusion` | universal, Boolean combinations |
| `WellClear@horizontal_WCV_taumod` | `horizontal_WCV_taumod_rew`, `horizontal_WCV_taumod_interval_def` | exists-`t` over an interval, quadratics |
| `ACCoRD@cd2d` etc. | conflict/band lemmas with `D`, `T`, `B` free | one quantified `t`, many parameters |
| literature | Kahan ellipse-in-circle, Collins–Johnson, `x^2+y^2<1 AND y>x` | comparison with QEPCAD/Redlog |

Benchmark theories are added here only once the strategy that proves them exists;
this directory never holds unproved lemmas (standing rule: prove everything).

Baseline timings of the existing NASALib strategies: `baseline.md`.
