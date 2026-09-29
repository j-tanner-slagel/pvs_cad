# Phase 0 baseline (PVS 8.1 built 2026-09-09, NASALib 8.1 of 2026-07-23, SBCL 2.4.11)

Machine: Apple Silicon Mac, 8 GB RAM. Times are `proveit -f` wall clock on a cold
cache (the imported libraries are re-typechecked in the same run), so they are
upper bounds on strategy time; the per-proof CPU reported by proveit is in the
summaries. All caches were cleared before each run.

| Library / file | Proofs | Wall clock | Notes |
|---|---|---|---|
| Sturm/examples/sturm_examples.pvs | 81/81 | 2 min 47 s | `sturm`, `mono-poly` on Legendre and degree-120 polynomials |
| Tarski/examples/tarski_examples.pvs | 39/39 | 4 min 46 s | `tarski` on systems, incl. degree 22 |
| Tarski/examples/hutch_examples.pvs | 35/35 | 1 min 45 s | `hutch` Boolean combinations |
| Bernstein/examples/bernstein_examples.pvs | 94/94 | 2 min 34 s | `bernstein` numeric strategy |
| mult_poly (library, `proveit -i top.pvs`) | all CAD-relevant theories replayed | killed at 30 min | stuck in a `grind` in `smooth_not_analytic`, not on the CAD path |
| cad/eval_probe.pvs | 28/28 | seconds | recursive mpoly datatype under `eval-expr`; `(x+y+1)^8` evaluates in 0.24 ms |

Function-handle probe (scratch theory `fprobe`, 2026-09-09): `sturm`, `tarski`,
`mono-poly` reject `f(x)` for a defined `f(x:real): real = x^5 + 50*x - 2`
("doesn't appear to be a polynomial"); after `(expand "f")` all five test lemmas
prove, including a `LAMBDA`-defined handle `g: [real -> real]`.
