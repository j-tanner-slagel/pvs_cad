# pvs_cad — a verified CAD algorithm and a verified, complete decision procedure for PVS

pvs_cad is a [PVS](https://pvs.csl.sri.com) library that decides the first-order theory of the real
numbers: sentences of any shape built from polynomial equations and inequalities with rational
coefficients, the connectives AND, OR, NOT, IMPLIES and IFF, and quantifiers over real variables
(prenex sentences directly by the decision procedures `decide8` or `decide5`, any other shape by
quantifier elimination from the inside out, `decide_g`).
Two executable PVS functions compute a **cylindrical algebraic decomposition** (CAD), the n-level
engine and the Collins run (built on Collins's projection operator), and the library proves:

- **the n-level engine computes a CAD adapted to the input polynomials** (Basu–Pollack–Roy,
  Def. 5.1) whenever its run-time certificate holds, which some value of its search-effort
  parameter always achieves: the cells of R^n cover it and are disjoint; the cells of every level
  are connected; they are stacked in cylinders over finitely many continuous, strictly ordered root
  functions, each family delineable over the cells below it; every input polynomial has one sign on
  every cell of R^n; and every cell, at every level, and the graph of every root function over a
  cell, is semi-algebraic in the sense of being defined by a first-order formula over the reals
  (`cad/cad_verified.pvs`);
- **a companion executable function, `cad_out`, returns that CAD as data** — at least one record
  for every nonempty cell and none for any other (a band can get several), each with an exact
  sample point in its cell and the polynomials' signs there — and that one computed CAD decides
  every sentence in the same variables, in the same order, over the same polynomials, whatever the
  quantifiers and the Boolean combination (`cad/cad_fold_ok.pvs`);
- **Collins's projection gives a CAD adapted to the input polynomials, for every input, in every
  number of variables, with no run-time certificate**: the cells built from the projections satisfy
  the same conditions (`cad/col_run.pvs`, `cad/col_line.pvs`); `col_found`, the Collins run with
  the search for its effort parameter built in, always returns that CAD as data — at least one
  record for every nonempty cell of R^n and none for any other (a band can get several), each with
  an exact sample point in its cell and the polynomials' signs there — and those records decide
  every sentence over the polynomials in the same variables, in the same order
  (`cad/col_found_ok.pvs`);
- the decision procedures `(cad)` runs are **sound** (every answer is the truth) and **complete**
  (they always answer, given enough time): `decide8` (the Collins run for two or more variables, the
  sectors of the line at one) in a theory that imports `cad_decide8`, and otherwise `decide5` (the
  n-level engine for three or more variables and as the fallback at two, a two-level method first
  at two, the sectors of the line at one); a formula of any other shape (quantifiers inside `NOT`,
  `AND`, `OR`, `IMPLIES` and `IFF`; binders over `posreal`, `nnreal`, `negreal`, `npreal` or
  `nzreal`; other real terms, generalized) is decided by `decide_g`, which is sound and complete
  too (`decide_g_ok`, `cad/gform_ok.pvs`: quantifier elimination from the inside out);
- **quantifier elimination**: for every prenex formula with at least one quantifier and m >= 1 free
  variables, `qe` and `qe8` (the Collins run) compute a quantifier-free formula that holds at
  exactly the same points of R^m (`qe_complete`, `cad/qe_all.pvs`; `qe8_complete`, `cad/qe8.pvs`),
  and `qelim` does the same for every first-order formula, quantifiers anywhere, and every number
  of free variables, 0 included (`qelim_qf`, `qelim_ok`, `cad/qelim_ok.pvs`); the strategy
  `(cad-qe)` uses `qe8` or `qe`, and for formulas of any other shape `qe_g`, which applies `qelim`
  to their translation (`qe_g_ok`, `cad/gform_ok.pvs`);
- **the cells are semi-algebraic in the textbook sense**: every set definable by a first-order
  formula over the reals with rational coefficients (no real parameters) is definable by a
  quantifier-free one, a Boolean combination of sign conditions on polynomials with rational
  coefficients (`fod_qfd`, the Tarski–Seidenberg theorem for such formulas), so every cell of both
  CADs, at every level, is semi-algebraic as in Basu–Pollack–Roy, indeed defined over Q
  (`col_cells_sa`, `cad_cells_sa`, `cad/cad_sa.pvs`).

The proof strategy `(cad)` evaluates the procedure inside a proof and turns its answer into a PVS
proof that the kernel checks.

**What is proved, and what is not.**
- "Semi-algebraic" holds in both standard senses. The CAD theorems state that every cell is
  defined by a first-order formula over the reals with rational coefficients; `fod_qfd`
  (`cad/qelim_ok.pvs`) proves that such sets are exactly those defined without quantifiers by sign
  conditions on polynomials with rational coefficients, and `cad/cad_sa.pvs` states it for the
  cells (`col_cells_sa`, `cad_cells_sa`). These are the semi-algebraic sets defined over Q;
  Basu–Pollack–Roy's definition allows real coefficients, a larger class.
- Basu–Pollack–Roy's Def. 5.1 asks for a finite partition of R^i at every level i. The theorems
  state cover and disjointness for the cells of R^n; at the lower levels the partition follows from
  the stack construction (`tcell_cover`, `tcell_disj`, `cad/cad_tower.pvs`) but is not restated as
  a theorem. That the nonempty cells are finitely many follows from the records (`cad_out`,
  `col_found`): finite lists with a record for each nonempty cell.
- For the n-level engine, delineability is proved for the families the run itself builds and
  checks. For Collins's projection operator it is proved for every input (`collins_stack`,
  `cad/col_stack.pvs`, tied to the executable operator by `projn_ok`); the smaller projections of
  McCallum and Brown are not proved delineating (`cad_proj` defines a McCallum-shaped operator; the
  n-level engine starts its read closures from it, and its answers rest on its run-time certificate,
  not on delineability), and Lazard's projection is not done.
  Delineability is in the sign-invariant sense (`delin_cl?`): root multiplicities are not tracked.
- The Collins CAD theorems cover every number of variables, one included (`col_cells`,
  `col_found_cad`); the n-level engine's are stated for two or more.
- The CAD theorems cover the n-level engine and the Collins run. `(cad)` also has shortcuts that
  answer without a decomposition (a witness search; with `decide5`, a two-level method for two
  variables); their answers are proved correct too. `(cad :cad-only? t)` uses neither: with two or
  more variables it answers only through a verified CAD engine (the Collins run in a theory that
  imports `cad_decide8`, otherwise the n-level engine), with one on the sectors of the line.

**Author:** J. Tanner Slagel.

**How it was made.** Everything in this repository — the PVS specifications, every proof, the
strategies, the tools and the documents — except the third-party material listed in
[`NOTICE.md`](NOTICE.md) (code derived from PVS's `context.lisp`, and the problems of the Bath CAD
example bank) was generated with Claude models through
[Claude Code](https://claude.com/claude-code): Claude Fable 5.1, Claude Opus 5 and Claude Opus 5.5,
with J. Tanner Slagel directing the work. No line of PVS and no proof step was written by hand.
PVS checks every step of every proof; what remains to trust is the specification (that the theorems
state what is intended), PVS itself, and NASALib's saved proofs of the theorems it imports.

An overview for readers who know theorem proving: [`docs/cad_overview.pdf`](docs/cad_overview.pdf)
(9 pages). Real transcripts of `(cad)` and `(cad *)` proofs, recorded on 28 September
2026 with `decide5` (before the Collins run existed), with three proofs expanded step by step:
[`docs/cad_proof_traces.pdf`](docs/cad_proof_traces.pdf). Collins's projection, the decision
procedure and quantifier elimination built on it, and what they cost:
[`docs/collins_cad.pdf`](docs/collins_cad.pdf). Quantifier elimination, with examples of the
answers `(cad-qe)` prints: [`docs/qe_capabilities.pdf`](docs/qe_capabilities.pdf).

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

`(cad *)` works on a whole sequent: it collects every hypothesis and goal that is a first-order
formula over the reals (prenex, or of any shape under `IMPORTING pvs_cad`), treats other real terms that
mention no bound variable (`sqrt(c)`, `f(c)`, `length(l)` for constants `c` and `l` of the
sequent) as unknown reals, each with the bounds its type gives (`sqrt(c) >= 0`, `c > 0` for a
`posreal` constant), skips formulas that are not about reals, and decides the
implication.

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
`decide8_correct` and `decide8_decides` (`cad/cad_decide8.pvs`), and `decide7_correct` and
`decide7_decides` (`cad/cad_decide7.pvs`), have the statements above with `decide8` or `decide7` in
place of `decide5`. `decide_g_ok: THEOREM decide_g(g) IFF gsem(g)(null)` (`cad/gform_ok.pvs`) does
the same for a formula `g` of any shape, whose meaning `gsem` is written with PVS's own connectives
and quantifiers.

The trusted base is the PVS kernel and PVS's ground evaluator, as for NASALib's Sturm and Tarski
strategies. The evaluator runs the decision — `decide8` in a theory that imports `cad_decide8` (as
`pvs_cad` does), otherwise `decide5`, or `decide7` under `(cad :cad-only? t)`; `decide_g` for a
formula of any other shape (it runs `qelim`, and through it `qe8` and `decide8`) — and, for
`(cad-qe)`, `qe8`, `qe` or `qe_g`. Beyond these, one trusts NASALib's saved proofs of the theorems
the library imports, which were not replayed here, and the reading of the statements: that `fsem`,
`gsem`, `qfsem` and the theorem statements say what is intended. The strategy code is not trusted:
it only chooses proof steps, and the kernel checks each of them.

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

The CAD built from Collins's projection (`cad/col_line.pvs`, `cad/col_found_ok.pvs`,
`cad/col_verified.pvs`), and semi-algebraicity (`cad/qelim_ok.pvs`):

```
col_cells:         THEOREM ccells?(k, F)    % the cells ccell(k, F)(s, A) form a CAD adapted to F
col_found_cad:     THEOREM cons?(qs) IMPLIES cfound?(qs, F, col_found(qs, F)`frecs)
col_found_decides: THEOREM cons?(qs) AND length(qs2) = length(qs) IMPLIES
                     (cfold(qs2, Psi2, col_found(qs, F)`frecs) IFF sem(qs2, F, Psi2, null[real]))
col_verified:      THEOREM decc_o(u, qs, F, Psi)`ok AND length(qs) >= 2 IMPLIES ccad_of?(u, qs, F)
fod_qfd:           THEOREM fod?(n)(S) IFF qfd?(n)(S)
```

For every family `F` in k + 1 variables, Collins's projection is applied k times:
`ctw(F, k)` = [P_1, ..., P_k] is the tower above the outermost variable (P_k = `F`, each P_(j-1) the
projection of P_j; empty when k = 0), the line of the outermost variable is cut at the real roots of
the k-th projection P_0 = `pbot(F, k)` (`F` itself when k = 0), and `ccell(k, F)(s, A)` is the cell
over the sector `s` with stack indices `A`. `col_cells` proves
`ccells?(k, F)` for every `k`, with no hypothesis: these cells cover R^(k+1) and are pairwise
disjoint, every cell at every level is connected and first-order definable, over each sector the
tower is cylindrical and every level delineable, the graph of every root function over a cell is
first-order definable, and every polynomial of `F` has one sign on every cell (`col_cad_run` is the
case k >= 1, `col_cad_line` the case k = 0). `cfound?(qs, F, L)` adds the records `L`: each lies in
the cell its sector and indices name and carries `F`'s signs at its sample, and every nonempty cell
of R^(k+1) has at least one. `col_found` computes them, raising the search-effort parameter until
the run's certificate holds (`col_found_ccad`: `ccad_of?`, which is `cad_of?` for these cells, at
the value found). `fod?(n)(S)` says that `S` is defined among the points of length `n` by a
first-order formula, `qfd?(n)(S)` by a quantifier-free one (both over the reals, with rational
coefficients and no real parameters).

## Using it

Requirements: PVS 8.1 and NASALib (the library uses `reals`, `Sturm`, `Tarski`, `structures`,
`analysis`, `complex`, `mult_poly`, `matrices` and `interval_arith`). `tools/setup.sh` checks that they are found (see
`tools/env.sh` for the environment variables it reads).

In a theory:

```
IMPORTING pvs_cad
```

(`cad/pvs_cad.pvs`: everything `(cad)` and `(cad-qe)` need in one import — `cad_decide8` and `qe8`, the
Collins run; `gform_ok`, formulas of any shape; `mpoly_embed` and `cad_endgame`. It does not bring
in every theorem: `col_cells`, `col_found_cad`, `cad_verified`, `cad_found_cad`, `col_cells_sa`,
`cad_cells_sa`, `qe_complete` and `decide5_decides` are in `col_line`, `col_found_ok`,
`cad_verified`, `cad_found_ok`, `cad_sa`, `qe_all` and `complete_all`; import those, or
`cad/top.pvs`.) Formulas are taken as they are written: grouped binders `FORALL (x, y: real)`;
quantifiers inside `NOT`, `AND`, `OR`, `IMPLIES` and `IFF`; the synonyms `&` and `∧`, `∨`, `=>`
and `⇒`, `<=>` and `⇔`, `¬`, `WHEN`, and `≠` for `/=`; binders over `real`, `posreal`, `nnreal`
(`nonneg_real`), `negreal`, `npreal` (`nonpos_real`) and `nzreal` (`nonzero_real`), and over no
other type (a binder over `nat`, `int`, `rat` or `{x: real | ...}` is refused). Other real terms
that mention no bound variable (`f(c)`, `sqrt(c)`, `length(l)` for constants `c` and `l` of the
sequent, for instance after `skeep`) are unknown reals: `(cad)` generalizes them (FORALL for a goal,
EXISTS for a hypothesis), each with the comparisons with numbers its type gives up its subtype
chain, the strongest lower and upper bound kept (`c > 0` for a `posreal` constant, `sqrt(c) >= 0`,
`n >= 1` for a `posnat`, `0 <= i <= 4` for an `i` of type `below(5)`; integrality itself is not
used), as `(cad *)` does; a term such as `f(x)` or `sqrt(x)` under a
binder for `x` is refused. `cad/cad_showcase.pvs` shows most of these on 43 examples (its Part I
has quantifiers inside each connective and binders over each of the five subtypes), and
`cad/cad_forms_ex.pvs` (64 regression lemmas) tests the rest: every connective on both
sides of the sequent, `NOT` over compound formulas, connective synonyms, subtype binders, typed
unknowns, comparisons of a term with itself, and `TRUE` or `FALSE` beside quantified parts. Then, in the prover:

| command | what it does |
|---|---|
| `(cad)` | decides the formula in consequent 1, or hypothesis -1 when there is no consequent (PVS shows a goal `NOT A` as the hypothesis `A`); a witness search first |
| `(cad 2)`, `(cad -1)` | the same for another formula: a TRUE goal is proved, a FALSE hypothesis closes the goal |
| `(cad *)` | decides the formulas over the reals of the whole sequent together |
| `(cad (-1 3))`, `(cad +)`, `(cad -)` | the same for the chosen formulas, the goals only, the hypotheses only |
| `(cad-direct)` | the decision alone, without the witness search |
| `(cad :cad-only? t)` | the decision only through a verified CAD engine: no witness search, no two-variable shortcut |
| `(cad-qe)`, `(cad-qe -1)` | replaces a goal or hypothesis with free variables by an equivalent quantifier-free formula |

With `cad_decide5` and `qe_all` imported instead (and `cad_decide7` for `:cad-only?`), the decision is
`decide5`, and a formula must be prenex over `real`, with a polynomial matrix (grouped binders and a
goal `NOT A` are fine); formulas of any other shape, and other real terms in a formula given to
`(cad)`, need `gform_ok`, which `pvs_cad` imports (`(cad *)` generalizes other real terms either
way). `gform_ok` itself imports `cad_decide8` and `qe8`, so with it the decision is `decide8` and the
elimination `qe8`.

A true goal is proved; a false hypothesis closes the goal; otherwise the formula stays as it was
written (with grouped binders too), labelled `cad`, with a message saying whether it is TRUE or
FALSE. CAD is doubly exponential in the worst case. Measured with `decide5` (`cad_decide5`),
September 2026, in `cad/cad_limits*.pvs` (which import it and record each time): one-variable
problems of degree 20–30 take seconds (Wilkinson's polynomial of degree 20 in about 3 s, Chebyshev's
of degree 30 in 12 s), and so do many problems in two to four variables of low degree, but several
do not finish within the 90–120 s limit: AM–GM and Schur's inequality in three variables (degree 3),
u^2 + v^2 = a, uv = b in four (degree 2), Cauchy–Schwarz in the plane (four variables, degree 4),
and two-variable problems of degree 7 to 10 (`g_root7`, `g_amgm8`, `g_meet8`, `g_root9` in
`cad_limits3`; `b7_root`, `b8_meet`, `b10_amgm`, `h_mignotte` in `cad_limits2`). With the default
import (`pvs_cad`, so `decide8`), 1–2 October 2026: Wilkinson's in 3.2 s and Chebyshev's of degree
30 in 8.3 s; AM–GM in three variables in 3.4 s, Schur's inequality in 4.0 s, u^2 + v^2 = a, uv = b
in 8.6 s, Cauchy–Schwarz in the plane in 2.2 s, and the two-variable problems of degree 7 and 8
(`g_root7`, `b7_root`, `g_amgm8`, `g_meet8`, `b8_meet`) in 2.7–30 s; the two-variable problems of
degree 9 and 10 (`g_root9`, `g_amgm10`, `b10_amgm`, `h_mignotte`) and AM–GM in four variables
(degree 4) still do not finish within 120 s. On some problems with several quantifiers the Collins
run is faster by more than an order of magnitude (23 to more than 450 times on the benchmarks of
`docs/collins_cad.pdf`) and on others slower; on the small examples of the library, proofs with
the Collins imports take 0.6–0.8 s longer on average (0.77 s in a first run, 0.59 s in a re-run
after the strategy fixes of this release), partly because of the larger imported context.

**PVS 8.1 and large directories.** After a typecheck, PVS 8.1 checks the file-import graph for
cycles by following every import path without remembering visited theories. On this library
that takes hours, and Emacs or the pvs-cli server appear to hang (batch `proveit` is not
affected). `tools/pvs-circular-deps.lisp` redefines that check with a visited set (same results, each
theory explored once); copy it to `~/.pvs.lisp`, which PVS loads at startup.
`tools/README-pvs-circular-deps.md` explains the problem and the measurements.

To replay the whole library: `proveit -a cad/top.pvs` (in a copy of `cad/`).

## Repository layout

- `cad/` — the PVS library; `cad/top.pvs` imports every theory of the library, with a description of
  each (the timing and playground files `cad_limits`, `cad_limits2`, `cad_limits3`,
  `cad_meas2`–`cad_meas5`, `bench_c`, `bench_n`, `bench_pdec` and `cad_demo` stay outside it: some
  of their goals are FALSE or do not finish; `cad_meas` is inside, imported by `alg_dec_ex` and
  `cad_pdec_ex`).
  `cad/pvs-strategies` holds the strategies. `cad/PROGRESS.md` is the development log.
- `docs/` — the overview, the proof-trace document, the Collins projection and quantifier-elimination
  notes (LaTeX sources alongside).
- `tools/` — scripts for batch runs, the pvs-cli workflow, verification gates and measurements.
- `*_PLAN.md` — the plans the work followed: `CAD_PLAN.md` (survey, prior art, design),
  `FINISH_PLAN.md`, `COMPLETENESS_PLAN.md` (the completeness proof), `GAP_PLAN.md` (from the decision
  procedure to a verified CAD, and what remains), `QE_PLAN.md` (quantifier elimination),
  `COLLINS_PLAN.md` (Collins's projection), `FORMS_PLAN.md` (formulas as people write them),
  `CADSTAR_PLAN.md` (`(cad *)`), `ENDGAME_PLAN.md` (proof reconstruction), and others.

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
- S. Basu, R. Pollack, M.-F. Roy, *Algorithms in Real Algebraic Geometry*, 2nd ed., Springer, 2006
  (Def. 5.1, cylindrical decomposition).
- A. Narkawicz, C. Muñoz, A. Dutle, "Formally-verified decision procedures for univariate
  polynomial computation based on Sturm's and Tarski's theorems", Journal of Automated
  Reasoning 54(4), 2015.
- R. Bradford, J. H. Davenport, D. Wilson, "A repository for CAD examples", ACM Communications
  in Computer Algebra 46(3), 2012 (the Bath benchmark bank used in `cad/cad_bath.pvs`).
