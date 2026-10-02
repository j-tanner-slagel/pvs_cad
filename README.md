# pvs_cad — a verified CAD algorithm and a verified, complete decision procedure for PVS

pvs_cad is a [PVS](https://pvs.csl.sri.com) library that decides the first-order theory of the real
numbers: prenex sentences built from polynomial equations and inequalities with rational
coefficients, the connectives AND, OR, NOT, IMPLIES and IFF, and quantifiers over real variables.
Its n-level engine is an executable PVS function that computes a **cylindrical algebraic
decomposition** (CAD) for problems in two or more variables, and the library proves:

- **it computes a CAD adapted to the input polynomials** (Basu–Pollack–Roy, Def. 5.1) whenever its
  run-time certificate holds, which some value of its search-effort parameter always achieves: the
  cells of R^n cover it and are
  disjoint; the cells of every level are connected; they are stacked in cylinders over finitely
  many continuous, strictly ordered root functions, each family delineable over the cells below it;
  every input polynomial has one sign on every cell of R^n; and every cell, at every level, and the
  graph of every root function over a cell, is semi-algebraic in the sense of being defined by a
  first-order formula over the reals (`cad/cad_verified.pvs`);
- **a companion executable function, `cad_out`, returns that CAD as data** — at least one record
  for every nonempty cell and none for any other (a band can get several), each with an exact
  sample point in its cell and the polynomials' signs there — and that one computed CAD decides
  every sentence in the same variables, in the same order, over the same polynomials, whatever the
  quantifiers and the Boolean combination (`cad/cad_fold_ok.pvs`);
- the decision procedure `(cad)` runs, `decide5` (this engine for three or more variables and as
  the fallback at two, a two-level method first at two, the sectors of the line at one), is
  **sound** (every answer is the truth) and **complete** (it always answers, given enough time).

The proof strategy `(cad)` evaluates the procedure inside a proof and turns its answer into a PVS
proof that the kernel checks.

**What is proved, and what is not.**
- "Semi-algebraic" is used in the sense of definable by a first-order formula over the reals, a
  standard definition. That it agrees with the quantifier-free definition (Boolean combinations of
  polynomial sign conditions, as in Basu–Pollack–Roy) is the Tarski–Seidenberg theorem, which is
  not formalized here. General quantifier elimination with free variables (any quantifier prefix), which gives
  quantifier-free cell descriptions directly, is the next stage of the plan (GAP_PLAN.md, Tier 2);
  today one
  existential quantifier is eliminated with any number of free parameters (`qe_tree.qtree_sound`,
  strategy `qe-exists`).
- Delineability is proved for the families the run itself builds and checks, not for a named
  projection operator (Collins, McCallum, Brown–McCallum). It is delineability in the
  sign-invariant sense (`delin_cl?`): root multiplicities are not tracked.
- The CAD theorem is stated for two or more variables. One-variable problems are decided on the
  sectors of the line; that those sectors form a CAD of the line is proved piece by piece (they
  cover and are disjoint, connected, definable and sign-invariant) but not yet stated as one theorem.
- The CAD theorem covers the n-level engine. `(cad)` also has shortcuts that answer without a
  decomposition (a witness search, a two-level method for two variables); their answers are
  proved correct too. `(cad :cad-only? t)` uses neither: with two or more variables it answers only
  through the verified CAD engine, with one on the sectors of the line.

**Author:** J. Tanner Slagel.

**How it was made.** Everything in this repository — the PVS specifications, every proof, the
strategies, the tools and the documents — was generated with Claude models through
[Claude Code](https://claude.com/claude-code): Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5,
with J. Tanner Slagel directing the work. No line of PVS and no proof step was written by hand.
PVS checks every step of every proof; what remains to trust is the specification (that the theorems
state what is intended), PVS itself, and NASALib's saved proofs of the theorems it imports.

An overview for readers who know theorem proving: [`docs/cad_overview.pdf`](docs/cad_overview.pdf)
(6 pages). Real transcripts of `(cad)` and `(cad *)` proofs, with three proofs expanded step by
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
The trusted base is the PVS kernel and PVS's ground evaluator, which runs `decide5` (`decide7` under
`(cad :cad-only? t)`), as for NASALib's Sturm and Tarski strategies, together with the NASALib theorems
the library imports, whose proofs are NASALib's and were not replayed here. `(cad :cad-only? t)`
instantiates `decide7_correct` (`cad/cad_decide7.pvs`); it and `decide7_decides` have the statements
above with `decide7` in place of `decide5`.

The CAD that the n-level engine computes (`cad/cad_verified.pvs`):

```
cad_verified: THEOREM decn_o(u, qs, F, Psi)`ok AND length(qs) >= 2 IMPLIES cad_of?(u, qs, F)
cad_exists:   THEOREM length(qs) >= 2 IMPLIES EXISTS u: cad_of?(u, qs, F)
```

`cad_of?(u, qs, F)` states the conditions of a CAD adapted to `F` in n = `length(qs)` variables for the
run's cells `rcell(s, A)` (outer sector `s`, stack indices `A`; `A` ranges over all lists of indices,
so most `rcell(s, A)` are empty, and the nonempty cells of R^n are finitely many because each has a
record in the finite list `cad_out`): the cells of R^n cover it and are pairwise disjoint; every cell,
at every level, is connected (`conn?`: every property locally constant on the cell is constant on it)
and first-order definable (`fod?`); over each sector the tower is cylindrical and every level
delineable (`cad_over?`, `delin_cl?`: the real roots of the members not identically zero on the fibre
are a constant number of continuous, strictly ordered functions, and every member has one sign on each
section and band); the graph of every such root function over a cell is first-order definable; every
polynomial of `F` has one sign on every cell of R^n; and `cad_out` lists every nonempty cell of R^n at
least once and nothing else, each record with a sample point in its cell and `F`'s signs there. That one
computed CAD decides every sentence over `F` in the same `length(qs)` variables, in the same order
(`cad_decides`, `cad/cad_fold_ok.pvs`).

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
| `(cad :cad-only? t)` | the decision only through the verified CAD engine for two or more variables (the sectors of the line for one): no witness search, no two-variable shortcut (also import `cad_decide7`) |

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

- `cad/` — the PVS library; `cad/top.pvs` imports every theory of the library, with a description of
  each (the timing and playground files `cad_limits*`, `cad_meas*`, `bench_*` and `cad_demo` stay
  outside it: some of their goals are FALSE or do not finish).
  `cad/pvs-strategies` holds the strategies. `cad/PROGRESS.md` is the development log.
- `docs/` — the overview and the proof-trace document (LaTeX sources alongside).
- `tools/` — scripts for batch runs, the pvs-cli workflow, verification gates and measurements.
- `*_PLAN.md` — the plans the work followed: `CAD_PLAN.md` (survey, prior art, design),
  `FINISH_PLAN.md`, `COMPLETENESS_PLAN.md` (the completeness proof), `GAP_PLAN.md` (from the decision
  procedure to a verified CAD, and what remains), `CADSTAR_PLAN.md`
  (`(cad *)`), `ENDGAME_PLAN.md` (proof reconstruction), and others.

## Contact and license

Questions and bug reports: open an issue on this repository.

To the extent possible under law, J. Tanner Slagel has waived all copyright and related rights to
this work ([CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/); the full text is in
[`LICENSE`](LICENSE)). The waiver does not cover the third-party material listed in
[`NOTICE.md`](NOTICE.md), which keeps its own licenses.

## How to cite

If you use pvs_cad in your work, please cite it. This is a request, not a condition: under the CC0
waiver anyone may use it without credit.

J. Tanner Slagel. *pvs_cad: Verified Cylindrical Algebraic Decomposition and Quantifier Elimination
in PVS.* PVS specifications and proofs, 2026. https://github.com/j-tanner-slagel/pvs_cad

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
- A. Narkawicz, C. Muñoz, A. Dutle, "Formally-verified decision procedures for univariate
  polynomial computation based on Sturm's and Tarski's theorems", Journal of Automated
  Reasoning 54(4), 2015.
- R. Bradford, J. H. Davenport, D. Wilson, "A repository for CAD examples", ACM Communications
  in Computer Algebra 46(3), 2012 (the Bath benchmark bank used in `cad/cad_bath.pvs`).
