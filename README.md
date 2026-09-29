# pvs_cad — a verified, complete CAD decision procedure for PVS

pvs_cad is a [PVS](https://pvs.csl.sri.com) library that decides the first-order theory of the real
numbers: prenex sentences built from polynomial equations and inequalities with rational
coefficients, the connectives AND, OR, NOT, IMPLIES and IFF, and quantifiers over real variables.
The procedure is cylindrical algebraic decomposition (CAD), written as an executable PVS function,
and the library proves it **sound** (every answer is the truth) and **complete** (it always answers,
given enough time). The proof strategy `(cad)` evaluates the procedure inside a proof and turns its
answer into a PVS proof that the kernel checks.

**Author:** J. Tanner Slagel.

**How it was made.** Everything in this repository — the PVS specifications, every proof, the
strategies, the tools and the documents — was generated with Claude models through
[Claude Code](https://claude.com/claude-code): Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5,
with J. Tanner Slagel directing the work. No line of PVS and no proof step was written by hand.
PVS checks every step of every proof; what remains to trust is the specification (that the theorems
state what is intended) and PVS itself.

An overview for readers who know theorem proving: [`docs/cad_overview.pdf`](docs/cad_overview.pdf)
(4 pages). Real transcripts of `(cad)` and `(cad *)` proofs, with three proofs expanded step by
step: [`docs/cad_proof_traces.pdf`](docs/cad_proof_traces.pdf).

## What it looks like

```
  |-------
{1}   FORALL (a: real):
        FORALL (b: real):
          FORALL (c: real):
            EXISTS (x: real):
              a /= 0 AND b ^ 2 >= 4 * a * c IMPLIES
               a * x ^ 2 + b * x + c = 0

Rule? (cad)
Deciding 1 by cylindrical decision, witness first,
Q.E.D.
```

`(cad *)` works on a whole sequent: it collects every hypothesis and goal that is a polynomial
formula over the reals, treats other real terms (`sqrt(x)`, `f(x)`, `length(l)`) as unknown reals,
skips formulas that are not about reals, and decides the implication.

## The main theorems

A sentence is encoded as data: `os`, its quantifiers outermost first (`TRUE` for FORALL), `F`, its
polynomials, and `phi`, its Boolean skeleton. `fsem(os, F, phi, null)` (`cad/cad_decide.pvs`) is its
meaning, defined with PVS's own real quantifiers.

```
decide5_correct:  THEOREM decide5(reverse(os), F, phi)`ok IMPLIES
                    (decide5(reverse(os), F, phi)`val IFF fsem(os, F, phi, null))   % cad_decide5.pvs
decide5_complete: THEOREM decide5(reverse(os), F, phi)`ok                            % complete_all.pvs
decide5_decides:  THEOREM decide5(reverse(os), F, phi)`val IFF fsem(os, F, phi, null) % complete_all.pvs
```

No hypotheses: the result covers every closed prenex sentence, with any number of quantifiers.
The trusted base is the PVS kernel and PVS's ground evaluator, which runs `decide5`, as for NASALib's
Sturm and Tarski strategies.

## Using it

Requirements: PVS 8.1 and NASALib (the library uses `reals`, `Sturm`, `Tarski`, `structures`,
`analysis`, `complex`, `mult_poly`, `matrices` and `interval_arith`). `tools/setup.sh` checks that they are found (see
`tools/env.sh` for the environment variables it reads).

In a theory:

```
IMPORTING cad_decide5, mpoly_embed
```

then, in the prover:

| command | what it does |
|---|---|
| `(cad)` | decides the closed prenex formula in consequent 1 (a witness search first) |
| `(cad -1)` | the same for a hypothesis: a FALSE hypothesis closes the goal |
| `(cad *)` | decides the polynomial content of the whole sequent (also `(cad +)`, `(cad -)`, `(cad (-1 2))`) |
| `(cad-direct)` | the decision alone, without the witness search |

A true goal is proved; a false hypothesis closes the goal; otherwise the formula stays, labelled
`cad`, with a message saying whether it is TRUE or FALSE. CAD is doubly exponential in the worst
case: one-variable problems of degree 20–30, and two- to four-variable problems of low degree,
take seconds; `cad/cad_limits*.pvs` records measured times, including problems that do not finish.

**PVS 8.1 and large directories.** After a typecheck, PVS 8.1 checks the file-import graph for
cycles by following every import path without remembering visited theories. On this library
that takes hours, and Emacs or the pvs-cli server appear to hang (batch `proveit` is not
affected). `tools/pvs-circular-deps.lisp` redefines that check with a visited set (same results, each
theory explored once); copy it to `~/.pvs.lisp`, which PVS loads at startup.
`tools/README-pvs-circular-deps.md` explains the problem and the measurements.

To replay the whole library: `proveit -a cad/top.pvs` (in a copy of `cad/`).

## Repository layout

- `cad/` — the PVS library; `cad/top.pvs` imports every theory, with a description of each.
  `cad/pvs-strategies` holds the strategies. `cad/PROGRESS.md` is the development log.
- `docs/` — the overview and the proof-trace document (LaTeX sources alongside).
- `tools/` — scripts for batch runs, the pvs-cli workflow, verification gates and measurements.
- `*_PLAN.md` — the plans the work followed: `CAD_PLAN.md` (survey, prior art, design),
  `FINISH_PLAN.md`, `COMPLETENESS_PLAN.md` (the completeness proof), `CADSTAR_PLAN.md`
  (`(cad *)`), `ENDGAME_PLAN.md` (proof reconstruction), and others.

## Contact and copyright

Questions and bug reports: open an issue on this repository.

Copyright (c) 2026 J. Tanner Slagel. All rights reserved: no license is granted for the library as a
whole. Third-party material and its licenses are listed in [`NOTICE.md`](NOTICE.md).

## References

- A. Tarski, *A Decision Method for Elementary Algebra and Geometry*, RAND, 1948.
- G. E. Collins, "Quantifier elimination for real closed fields by cylindrical algebraic
  decomposition", LNCS 33, 1975.
- A. Narkawicz, C. Muñoz, A. Dutle, "Formally-verified decision procedures for univariate
  polynomial computation based on Sturm's and Tarski's theorems", Journal of Automated
  Reasoning 54(4), 2015.
- R. Bradford, J. H. Davenport, D. Wilson, "A repository for CAD examples", ACM Communications
  in Computer Algebra 46(3), 2012 (the Bath benchmark bank used in `cad/cad_bath.pvs`).
