# pvs_cad — verified cylindrical algebraic decomposition and quantifier elimination for PVS

pvs_cad is a [PVS](https://pvs.csl.sri.com) library that decides the first-order theory of the
real numbers: sentences of any shape built from polynomial equations and inequalities with
rational coefficients, the connectives AND, OR, NOT, IMPLIES and IFF, and quantifiers over real
variables. Its core is an executable PVS function that computes a **cylindrical algebraic
decomposition** (CAD) with Collins's projection, and the library proves that it is one, for
every input and every number of variables. The decision procedure and the quantifier elimination
built on it are proved sound and complete, and the proof strategies `(cad)` and `(cad-qe)` use
them inside PVS proofs.

**The library is [`cad/`](cad/)**, in the form of a NASALib library: its theories and proofs,
`top.pvs`, the strategies in `pvs-strategies`, and examples in `cad/cad_examples/`. Its
[README](cad/README.md) lists the major theorems, the strategies with their syntax, and the
examples. The rest of this repository supports it: documents, tests and tools.

## What is proved, and what is not

- **A CAD in the textbook sense.** For every family `F` of polynomials in any number of
  variables, the cells built from Collins's projection satisfy Basu–Pollack–Roy's Defs. 5.1 and
  5.5, with no run-time certificate (`col_cells`): they cover R^n and are disjoint, the cells of
  every level are connected and stacked over continuous, strictly ordered root functions, `F`
  has one sign vector on every cell, and every cell and root graph is definable. The partition
  is stated for R^n; at the lower levels it follows from the stack construction (`tcell_cover`,
  `tcell_disj`) but is not restated as a theorem. Finiteness comes with the data: `col_found`
  returns at least one record for every nonempty cell and none for any other (`col_found_cad`).
- **Decision and quantifier elimination.** `decide8` (prenex sentences) and `decide_g` (any
  shape) always answer, and the answer is the truth (`decide8_decides`, `decide_g_ok`); `qe8`
  and `qelim` return quantifier-free equivalents (`qe8_complete`, `qelim_ok`).
- **Semi-algebraic in both standard senses.** Every cell is defined by a first-order formula,
  and `fod_qfd` (Tarski–Seidenberg) proves that such sets are exactly those defined without
  quantifiers by sign conditions on polynomials with rational coefficients (`col_cells_sa`).
  These are the semi-algebraic sets defined over Q; Basu–Pollack–Roy's definition allows real
  coefficients.
- **Delineability** is proved for Collins's projection, for every input (`collins_stack`), in
  the sign-invariant sense: root multiplicities are not tracked. The smaller projections of
  McCallum and Brown are not proved delineating, and Lazard's is not done.
- **Outside the CAD theorems:** the witness search of `(cad)`, which finds a point or fixes one
  variable before the full decision. Its answers are proved too; `(cad :cad-only? t)` does not
  use it.

What is trusted: the PVS kernel and its ground evaluator, which runs the procedures inside the
proof, as for NASALib's Sturm and Tarski strategies; NASALib's saved proofs of the theorems the
library imports; and the reading of the statements. The strategy code is not trusted.

## Quick start

Requirements: PVS 8.1 and NASALib 8.1 (the replays used NASALib's git commit 56dab197 of
2026-07-23). `tools/setup.sh` checks that they are found. Put this repository's root on
`PVS_LIBRARY_PATH`, with NASALib, and in a theory of your own:

```
IMPORTING cad@pvs_cad          % or cad@pvs_cad_num, for constants such as pi
```

```
{1}   FORALL (a, b, c: real):
        EXISTS (x: real):
          a /= 0 AND b ^ 2 >= 4 * a * c IMPLIES a * x ^ 2 + b * x + c = 0

Rule? (cad)
Deciding 1 by cylindrical decision, witness first,
Q.E.D.
```

`cad/README.md` describes `(cad)`, `(cad *)`, `(cad-direct)`, `(cad :cad-only? t)`,
`(cad-qe)`, `(cad-num)` and `(cad-facts)`.

## Documentation

- [`cad/README.md`](cad/README.md): the library, its theorems and its strategies.
- [`docs/cad_overview.pdf`](docs/cad_overview.pdf): an overview for readers who know theorem
  proving, with sessions, timings and related work.
- [`docs/collins_cad.pdf`](docs/collins_cad.pdf): Collins's projection, the decision procedure
  and quantifier elimination built on it, and what they cost.
- [`docs/qe_capabilities.pdf`](docs/qe_capabilities.pdf): quantifier elimination, with
  examples of the answers `(cad-qe)` prints.

## Repository layout

- `cad/` — the library (`top.pvs` imports and describes every theory); `cad/cad_examples/` — its
  examples (`cad_examples/top.pvs` describes them).
- `docs/` — the documents above, with their LaTeX sources.
- `tests/` — theories that import the library from another directory: `outside/` (the import
  itself), `msg/` (what the commands say when they do not prove a formula), `bath/` (problems
  of the Bath CAD example bank, under their own license, `NOTICE.md`).
- `tools/` — the checks and the pvs-cli workflow (`tools/README.md`).
- `HISTORY.md` — the full development (tag `v1.0-full`), with its earlier engines and plans;
  `SLIM_PLAN.md` and `PROGRESS.md` — how the library was reduced to this one.

## Checking it

`tools/replay.sh` replays the library and its examples from a fresh copy (6 October 2026: the
library's 3,175 formulas and the examples' 457). `tools/outside.sh` replays the theories in `tests/outside` and
`tests/bath`, and `tools/msgcheck.sh` checks the messages. The example proofs take 38% less time
than in the full development, and none is slower by more than 0.02 s
([`docs/collins_cad.pdf`](docs/collins_cad.pdf)).

**PVS 8.1 and large directories.** After a typecheck, PVS 8.1 checks the file-import graph for
cycles by following every import path without remembering visited theories. On a large library
that can take hours, and Emacs or the pvs-cli server appear to hang (batch `proveit` is not
affected). `tools/pvs-circular-deps.lisp` redefines that check with a visited set (same results,
each theory explored once); add the line `(load "<repo>/tools/pvs-circular-deps.lisp")` to
`~/.pvs.lisp`, with the repository's path for `<repo>`. `tools/README-pvs-circular-deps.md`
explains the problem and the measurements.

## How it was made

Everything in this repository — the PVS specifications, every proof, the strategies, the tools
and the documents — except the third-party material listed in [`NOTICE.md`](NOTICE.md) was
generated with Claude models through [Claude Code](https://claude.com/claude-code): Claude
Fable 5.1, Claude Opus 5 and Claude Opus 5.5, with J. Tanner Slagel directing the work. No line
of PVS and no proof step was written by hand. PVS checks every step of every proof.

## Contact and license

Questions and bug reports: open an issue on this repository.

To the extent possible under law, J. Tanner Slagel has waived all copyright and related rights to
this work ([CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/); the full text is in
[`LICENSE`](LICENSE)). The waiver does not cover the third-party material listed in
[`NOTICE.md`](NOTICE.md), which keeps its own licenses.

## How to cite

If you use pvs_cad in your work, please cite it. This is a request, not a condition: under the
CC0 waiver anyone may use it without credit.

J. Tanner Slagel. *pvs_cad: Verified Cylindrical Algebraic Decomposition and Quantifier
Elimination in PVS.* PVS specifications and proofs, 2026. https://github.com/j-tanner-slagel/pvs_cad

```bibtex
@misc{slagel_pvs_cad_2026,
  author       = {Slagel, J. Tanner},
  title        = {{pvs\_cad}: Verified Cylindrical Algebraic Decomposition and
                  Quantifier Elimination in {PVS}},
  howpublished = {PVS specifications and proofs,
                  \url{https://github.com/j-tanner-slagel/pvs_cad}},
  year         = {2026}
}
```

## References

- A. Tarski, *A Decision Method for Elementary Algebra and Geometry*, RAND, 1948.
- G. E. Collins, "Quantifier elimination for real closed fields by cylindrical algebraic
  decomposition", LNCS 33, 1975.
- S. Basu, R. Pollack, M.-F. Roy, *Algorithms in Real Algebraic Geometry*, 2nd ed., Springer, 2006
  (Def. 5.1, cylindrical decomposition; Def. 5.5, adapted to a family of polynomials).
- A. Narkawicz, C. Muñoz, A. Dutle, "Formally-verified decision procedures for univariate
  polynomial computation based on Sturm's and Tarski's theorems", Journal of Automated
  Reasoning 54(4), 2015.
- D. J. Wilson, R. J. Bradford, J. H. Davenport, "A repository for CAD examples", ACM Communications
  in Computer Algebra 46(3/4):67–69, 2012, doi 10.1145/2429135.2429137 (the Bath problems in
  `tests/bath/cad_bath.pvs`).
