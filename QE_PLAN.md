# QE_PLAN: verified quantifier elimination (GAP_PLAN.md Tier 2)

> **Status (2026-09-30).** User decision: do all of it -- stage 1, stage 2, epc_ok (decision 2) and
> 2C.  **Stage 1 (one free variable): done**, dev commit after 2c6f9c3 -- qe_ldd, qe_fm_def, qe_def,
> qe_ldd_ok, qe_fm, qe1_ok (46 formulas, gated) and (cad-qe) with qe_cad_ex.  As built, stage 1
> differs from the sketch below: the output builder qe1_s is a function of Q and the sector entries
> only (proved once, abstractly: qe1_s_sem), qe1_c takes the projection set as an argument, and
> (cad-qe) proves ORIG IFF TEXT by a case on fsem, walking the quantifiers in whichever direction the
> case leaves.  Measured: one bound variable, 2-6 s per (cad-qe) call; two bound variables (a
> three-level run) did not finish in 600 s -- the engine's three-level cost, not QE's.
> **EP and epc_ok: done** (qe_ep_def, qe_ep, qe_ep_ok, qe1_full; 2026-09-30): every real algebraic
> number has a quantifier-free description, so qe1's answer is always quantifier-free --
> qe1_complete: every prenex formula in one free variable has a computed, proved-equivalent
> quantifier-free form.
> **Stage 2 (any number of free variables): done 2026-09-30** -- qe2_def (24), qe2_ok (66),
> qe_all_def, qe_all (3): qe_correct -- for every m >= 1, qe's output holds at a point of R^m iff
> the prenex formula does; (cad-qe) takes any number of free variables (qe_eq2, qe_quad in qe_cad_ex:
> (EXISTS t: t^2 + a t + b = 0) IFF a^2 >= 4 b in 5 s).  For m >= 2 the output is quantifier-free
> when the free cells' signatures separate in every sector (sep2?, reported as qf); otherwise it is
> the proved-correct cell-formula form.
> **2C (always quantifier-free): done 2026-09-30** -- qe_thom, qe_tsep, qe2_sep (Thom separation),
> runT_def/runT_ok (the run from any certified initial tower), qe2c_def/qe2c_ok (the run with the
> free families closed under the derivative; correct and quantifier-free when it succeeds),
> aug_univ/aug_ev (the augmentation stays in a finite universe and succeeds for every large u),
> qe2c_u_def/qe2c_full, and qe_all's qe_complete: for every m >= 1 and prenex formula Q1 x1 ...
> Qn xn: phi (n >= 1, phi a Boolean combination of sign conditions on F), qe computes a
> quantifier-free formula equivalent to it at every point of R^m.  Section 11 is the design that was
> carried out.  Not done: prenex normal form for arbitrary rcf_fol formulas (needed to apply qe to
> the cell definitions of rcf_cells).  [Superseded 2026-10-01: not needed.  qelim (qelim_def,
> proved in qelim_ok: qelim_qf, qelim_ok) eliminates the quantifiers of every rcf_fol formula from
> the inside out, each existential by qe8 (or by decide8 in a sentence); fod_qfd follows, and
> cad_sa applies it to the cell definitions (col_cells_sa, cad_cells_sa).]
> **After this plan (2026-10-01):** qe8, the same elimination over the Collins run (qe8_complete;
> COLLINS_PLAN.md, M-I QE), which (cad-qe) uses in a theory that imports qe8; qelim for every
> formula, quantifiers anywhere, and fod_qfd (Tarski-Seidenberg for formulas over Q), as above;
> (cad-qe) on formulas of any shape through qe_g (gform_ok's qe_g_ok; FORMS_PLAN.md F4).
> **Speed and output (2026-09-30 / 10-01): section 12** -- rational sample points, merged answers in
> one free variable, Sturm chains computed once in refine, the root sort and sect_inv's separation;
> what is left is measured there.

This plan was written from the files before any QE code existed; paths are relative to `cad/`.

## 0. Verdict

**Build a merge, with Design B as the base.** From B:
- `rcf_fol.Fm` as the output type, plus a `qf?` predicate.
- One executable, `qe_o(u, m, qb, F, Psi)`, for any number m ≥ 1 of free variables.
- Each free-level cell is valued by `innern_o` at that cell's sample.
- For m ≥ 2, the `sep` check runs within each sector.
- When a check fails, the fallbacks are `cmpF`/`cellF`, whose correctness is already proved.

**Add from Design A:**
- The level-1 sign separation `sep1`. It turns the gate answer into one atom, 5D²−25 > 0, instead of about 30–40 witness atoms.
- The staging: prove m = 1 first, through `sectn_sem`/`memn_ok`.
- A conversion of the output to (G, BF), so that `(cad-qe)` can reuse cad-finish's reflection endgame.

**What both designs got right:**
- Free variables are outermost: the point is `(: y1 (innermost free), …, ym (sector variable) :)`, matching `sem` (cad_decide.pvs:61-67).
- `decn_o`'s `ok` depends only on u, k and F (towern_od.pvs:303-312).
- Strict comparisons against an algebraic number use a derivative plus `clrx`. They need neither a squarefree part nor an exact polynomial quotient.
- `x = value(b)` is already quantifier-free, by `value_char` (alg_def.pvs:32).

## 1. Errors found, checked against the files

**Design A**
1. **Wrong theorem.** `qe_correct` assumes only `m + length(qb) >= 2`, which allows `qb = null` with m ≥ 2.
   - Then `innern_o(u, null, …) = FALSE` (towern_od.pvs:173), so every free cell gets FALSE.
   - Counterexample: m = 2, qb = null, Psi = λv.TRUE. The meaning is TRUE and the output is FALSE.
   - Fix: require `cons?(qb)`.
2. **New `QF` datatype.** Its `rat`, `list[rat]` and `list[list[mpoly]]` fields carry the same positivity risk as the Sign3 crash (rcf_fol.pvs:9-11). It is also unnecessary: `Fm` exists with `fsem`, `f_or`, `shiftF`, `mins`, and the fallback lemmas `sectF_ok`/`cellF_ok` (rcf_cells.pvs:41-49).
3. **`qix` atoms are not usable output.** They have root-count semantics (`sidx`), so the printed result would be a ground `qsem(...)` term, not text. That is not QE in the user's sense.
4. **Wasted work during escalation.** `qe1_o` computes `cells` in the record even when `ok` is FALSE. PVS record fields are all evaluated, so every failed u pays for the valuation. Put the output under `IF ok`.
5. **`qe1_bf` is ill-typed.** `qe1` is a `QF` in `qe1_decides` but a record with a `tarski` field in `qe1_bf`, and it uses `P` for `Psi`.
6. **2B grouping needs a stronger condition.** Grouping by Q-signature is sound only if the whole Q-signature class shares one tower. It is an optimization, so defer it.
7. **`:vars` seeding order.** `*mpoly-atoms*` must hold the free variables innermost first after `reverse(prefix)`. The valuation is `(: bound inner..outer, y1..ym :)` (pvs-strategies:15-20, 48-51, 1203). A's `(y_outer … y_inner)` must therefore be reversed when seeding.
8. **Printer already exists.** A's "new mpoly→text printer (~60 lines)" is already there: `mpoly-term->str` (pvs-strategies:181-193, used by mpoly-simp).
9. **Outdated risk.** The "heap exhaustion at 42 atoms" was fixed by the bddsimp endgame (ENDGAME_PLAN, commit 2cef8da). What remains is only bddsimp time on large outputs.
10. **Line number.** `fsem_sem` is at cad_decide.pvs:98, not :100.

**Design B**
1. **Wrong theorem unless ok is guarded.** `qe_correct`'s only hypothesis is `ok`.
   - At m = 0, `j = m−1` is not a nat.
   - At `qsb = null`, the theorem is false for the same reason as A.1.
   - Fix: put `m >= 1 AND cons?(qb)` inside `qe_o`'s `ok`.
2. **No level-1 separation.** At m = 1 the output is an OR over the TRUE sectors of witness formulas. On the windowed gate that is 10 TRUE sectors, about 30–40 atoms. Add `sep1`.
3. **Two unneeded lemmas.** `sects_disj` and `secout_off` are not needed. Each disjunct is `liftF(sectX(s), j) ∧ …`, so the forward direction already holds disjunct by disjunct.
4. **Overstated: "QE must use decn_o at n = 2, since decw is not a proved CAD".** QE soundness needs only a per-sector lemma, and decw has one: `sect_sem` and `mem_ok` (cad_fast.pvs:48-52). decw is a legitimate fallback if decn_o is slow.
5. **Fallback cannot be printed.** The `fex` fallback is fine as a theorem, but `(cad-qe)` cannot print it or prove it through the Tarski endgame. The strategy should report the failure instead of printing.

**The input maps**
- The claim "q = b`p fails at even-multiplicity roots" is correct. cad_pdec.pvs:52-55 records (x−1)² in a projection.
- No map mentions that the printer exists, or that the 42-atom heap problem has been fixed.

## 2. Theorem statements (PVS; names are placeholders)

```
% qe_def (executable)
qsn(n): list[bool]                                    % n TRUEs
QR: TYPE = [# ok: bool, qf: bool, out: Fm #]
qe_o(u, m, qb, F, Psi): QR          % decn_o's LET with k = m-1+length(qb); ok := m >= 1 AND cons?(qb)
                                    % AND gaps_ok(rts(Q)) AND every(scok?(u))(cs); out/qf computed only IF ok
qe_u(m, qb, F, Psi, u): RECURSIVE QR = LET d = qe_o(u, m, qb, F, Psi) IN
  IF d`ok OR m = 0 OR null?(qb) THEN d ELSE qe_u(m, qb, F, Psi, u + 1) ENDIF
  MEASURE umeas(qsn(m + length(qb)), F, Psi, u)                      % decide_u_def.pvs:22-27
qe(m, os, F, phi): QR = qe_u(m, os, F, LAMBDA (v: SV): bfsv(phi, v), 0)

% proofs
qe_ok_eq:     LEMMA m >= 1 AND cons?(qb) IMPLIES
  qe_o(u, m, qb, F, Psi)`ok = decn_o(u, qsn(m + length(qb)), F, Psi)`ok
qe1_correct:  THEOREM qe_o(u, 1, qb, F, Psi)`ok IMPLIES
  (rcf_fol.fsem(qe_o(u, 1, qb, F, Psi)`out)((: x :)) IFF sem(qb, F, Psi, (: x :)))
qe_correct:   THEOREM qe_o(u, m, qb, F, Psi)`ok AND length(p) = m IMPLIES
  (rcf_fol.fsem(qe_o(u, m, qb, F, Psi)`out)(p) IFF sem(qb, F, Psi, p))
qe_qf:        THEOREM qe_o(u, m, qb, F, Psi)`qf IMPLIES qf?(qe_o(u, m, qb, F, Psi)`out)
qe_complete:  THEOREM m >= 1 AND cons?(qb) IMPLIES EXISTS u: qe_o(u, m, qb, F, Psi)`ok
qe_u_eq:      LEMMA EXISTS u2: qe_u(m, qb, F, Psi, u) = qe_o(u2, m, qb, F, Psi)
qe_u_ok:      THEOREM m >= 1 AND cons?(qb) IMPLIES qe_u(m, qb, F, Psi, u)`ok
qe_bf:        THEOREM m >= 1 AND cons?(os) AND length(p) = m IMPLIES
  qe(m, os, F, phi)`ok AND (rcf_fol.fsem(qe(m, os, F, phi)`out)(p) IFF cad_decide.fsem(os, F, phi, p))
tq_ok:        LEMMA qf?(phi) AND cons?(pt) IMPLIES
  (bfeval(tq(phi)`psi, tq(phi)`G, pt) IFF rcf_fol.fsem(phi)(pt))
qe1_qf [optional, decision 2]: THEOREM cons?(os) IMPLIES qe(1, os, F, phi)`qf
```

- `qe_u_eq` makes the escalation independent of m, so stage 1 does not need to be redone for stage 2.
- Use a wrapper alias `qfsem = rcf_fol.fsem` so that `(expand "fsem")` cannot hit `cad_decide.fsem`.

## 3. Theory files (executable code kept apart from proofs, rule 9)

| File | Contents |
|---|---|
| `qe_fm_def` | `qf?`, `ffalse`, `f_orl`/`f_andl`, `liftp(d, p)` (d times `mins(·, 0)`), `liftF(phi, d)` (d times `shiftF(·, 0)`), `xr(r)`, `qsn`, `ntake`/`ndrop` (no generic take/drop exists), `tq` |
| `qe_ep_def` | `EP`, `epc` (untrusted), `epok?`, `ltQ`/`gtQ`/`eqQ`, `cmpX` (falls back to `cmpF`), `sectX`, `sqf?` |
| `qe_def` | `QL`, `leaves`, `sv1`, `sep1?`, `minJ` (untrusted), `sig1F`, `atoms` (untrusted), `sigof`, `sep?`, `secout`, `qe_o`, `qe_u`, `qe` |
| `qe_fm`, `qe_ep`, `qe1_ok`, `qe_u` | proofs, stage 1 |
| `qe_cells`, `qe_const`, `qe_ok` | proofs, stage 2 |
| `qe_cad_ex` | demos |
| `(cad-qe)` | in pvs-strategies |

Each finished file is wired into top.pvs.

The witness check (only this needs proofs):

```
epok?(b, e) = IF e`ek = 0 THEN polylist(b`p)(e`er) = 0 AND b`lb <= e`er AND e`er <= b`ub
  ELSE deg(e`eq) > 0 AND e`elb < e`eub AND b`lb <= e`elb AND e`eub <= b`ub AND nroots(b`p, e`elb, e`eub) >= 1
   AND zero_at(b, e`eq) AND nroots(e`eq, e`elb, e`eub) = 1 AND polylist(e`eq)(e`elb) * polylist(e`eq)(e`eub) < 0 ENDIF
```

`epc`, the untrusted constructor, works in this order:
1. Try the rationals lb, ub, mid, the linear root and bisection. Copy rroot's logic rather than import cad_pdec.
2. Otherwise let mlt be the least j with `NOT zero_at(b, nderiv(b`p, j))`, and set q = `nderiv(b`p, mlt−1)` and c = `clrx(b, q, chain(q))`.
3. If an endpoint of c is a root of q, it is a rational root: use kind 0 (`clrx_free_lb/ub`).

## 4. Ordered lemmas, with what each reuses

**Stage 1 (m = 1)**
1. `meval_liftp`, `fsem_liftF`. Reuse `meval_mins` (rcf_fol.pvs:44), `fsem_shift` (:88) and `dropn` (cad_tower.pvs:77).
2. `fsem_orl`, `fsem_andl`, `fsem_ffalse`, the `qf?` closure lemmas, and `tq_ok`. Reuse `fsem_or` (:76), `bfeval` (bform.pvs:27), `meval_as_list` (mpoly_def.pvs:82) and `meval_mnorm` (mpoly_norm.pvs:48).
3. `ep_rat`. Reuses `value_unique` (alg_def.pvs:31).
4. `ep_iso`. Reuses `nroots_pos`/`nroots_one_elim`/`nroots_one_unique` (alg_count.pvs:74-89), `zero_at_def` (alg_zero.pvs:61) and `value_unique`.
5. `ep_side`, the only new mathematics: under `epok?` with ek = 1 and elb ≤ x ≤ eub, `x < value(b)` iff `sign3(q(x)) = sign3(q(elb))`, and symmetrically at eub. Reuses `same_sign` (sector_rep.pvs:26) and `pmc_eval` (sect_inv.pvs:252). Use sign3 lemmas, not grind.
6. `ltQ_ok`, `gtQ_ok`, `eqQ_ok`, `cmpX_ok`, `sectX_ok` (`fsem(sectX(s))(cons(x, ys)) IFF in?(s, x)`), `scellX_ok`, `qf_sectX`. Reuse `meval_pmc`, `cmpF_ok` and `scell_mem` (rcf_cells.pvs:40-43; cad_run.pvs:78).
7. `qe_ok_eq`, by expansion; also `tw0_shape` (decn_ok.pvs:52).
8. `leaves0`: at j = 0, `leaves` is the single record carrying `scval` (ctree with null TW, cad_out.pvs:54).
9. `qe1_val`. Reuses `memn_ok` (decn_ok.pvs:83), `sectn_sem` (:78) and `every_map_mem` (:64).
10. `sig1_inv`: `in?(s, x)` for a run sector implies `svec(Q, (: x :)) = osv_of(Q, odS(s))`. Reuses `osv_ok` (cad_out_ok.pvs:121), `odS_wf`/`odS_den` (decn_ok.pvs:58-59), `sect_svec` (sect_svec.pvs:72, whose second point is rational), `rat_alg_value` (alg_def.pvs:46) and `sortu_incr` (cell1.pvs:117).
11. `sep1_ok`, `qe1_correct` (with `sects_cover`, sect_inv.pvs:228), and the qf flag.
12. `qe_u_eq`, `qe_u_ok` (a copy of `decn_u`'s induction, with `decn_ev`, decn_complete.pvs:30), `qe_complete`, and `qe_bf` (with `fsem_sem`, cad_decide.pvs:98, and `bfsv_svec`, bform.pvs:45).

**Stage 2 (m ≥ 2)**
13. `ntake`/`ndrop` basics, `tlast_ndrop`, `vtb_ndrop`.
14. `tcell_take`; `cad_over_take`; `cad_over_desc` (from the definition of `cad_over?`, cad_tower.pvs:42-47).
15. `fcell_cover`. Reuses `tcell_cover` (cad_tower.pvs:84).
16. `sig_const`. Reuses `stk_sinv` (cad_stkc.pvs:62).
17. `okn_take`; `okn_desc` (for every leaf, `okt?` on the dropped tower). Reuse `cellsf_kids`/`every_kids`/`kids_lvl`/`ctree_mem` (cad_out_ok.pvs:43-95).
18. `leaf_in`/`leaf_cover`. Reuse `ctree_in`/`ctree_cover` (cad_out_ok.pvs:106-110) and `sector_okt` (:133).
19. `dnrs` with `recin_dnrs`/`reccov_dnrs`/`fsinv_dnrs`. Reuse cad_fold_ok.pvs:63-65.
20. `sem_fcell`. Reuses `sector_recs` (cad_fold_ok.pvs:86) and `afold_sem` (:80), applied at two points. `cad_out` appears only in this proof.
21. `leaf_val`. Reuses `innern_sem` (innern_sem.pvs:127) and `tables_vtb` (decn_ok.pvs:57).
22. `leaf_sig`. Reuses `wf_exact` (od_exact.pvs:29) and items 1 and 16.
23. `secout_ok`, in four cases: none TRUE, all TRUE, `sep`, and the `cellF` fallback (`cellF_ok`, rcf_cells.pvs:46).
24. `qe_correct`, `qe_qf`.

## 5. Gates: measure before proving

**G0 (today; a scratch theory in a copy of cad/, timed with `tools/pvs_raw_timeout.sh`).** In PolyExpr, t = pe_var(1) is bound and D = pe_var(2) is free, as `(cad)` would number them.

```
IMPORTING cad_out, mpoly_embed, cad_decide7_def
ft: list[mpoly] = as_list(pnorm(pe_var(1)))
fw: list[mpoly] = as_list(pnorm(pe_sub(pe_var(1), pe_const(10))))
fc: list[mpoly] = as_list(pnorm(pe_sub(pe_add(pe_pow(pe_sub(pe_const(5), pe_var(1)), 2),
                        pe_pow(pe_mul(pe_var(1), pe_const(1/2)), 2)), pe_pow(pe_var(2), 2))))
Fcw: list[list[mpoly]] = (: fc :)          phc: BF = batom(0, -1)
Fwin: list[list[mpoly]] = (: ft, fw, fc :)
phw: BF = band(bor(batom(0, 1), batom(0, 0)), band(bor(batom(1, -1), batom(1, 0)), batom(2, -1)))
Pw(v: SV): bool = bfsv(phw, v)             Pc(v: SV): bool = bfsv(phc, v)
```

Evaluate each of the following, for Fwin/Pw and for Fcw/Pc:
1. `decn_o(0, (: TRUE, FALSE :), Fwin, Pw)`ok`. If it is FALSE, repeat at u = 1, 2, …
2. `runq(0, 1, Fwin)` and `length(runsects(0, 1, Fwin))`. Expected: Q ⊇ {5D²−25, 25−D², 50−D²} and 13 sectors.
3. `map(LAMBDA (s: Sect): scval(0, (: FALSE :), Pw)(scof(0, tw0(1, Fwin), s)))(runsects(0, 1, Fwin))`. These are the per-sector QE values.
4. `map(LAMBDA (s: Sect): osv_of(runq(0, 1, Fwin), odS(s)))(runsects(0, 1, Fwin))`. These are the `sep1` signatures.
5. `decide5((: FALSE, TRUE :), Fwin, phw)` and `decide7((: FALSE, TRUE :), Fwin, phw)`. This is (cad) against (cad2) on the closed sentence ∀D ∃t, whose expected value is FALSE. It is the timing comparison the user asked for.
6. `length(cad_out(0, (: TRUE, FALSE :), Fwin))`, the cost of the B-fold alternative.

**Pass criteria for G0:**
- The windowed problem's items 1+3 take under 60 s, and cw1 about 10 s or less.
- Item 3 is TRUE exactly on the sectors with D² > 5.
- Item 4 has a member that is + on exactly the TRUE sectors.

**Plan B if decn_o fails G0 while decide5 is fast.** Add `qe1w` on decw: `sect_sem`/`mem_ok` (cad_fast.pvs:48-52) plus `sep1`, about 10–15 formulas.

**G1 (executables typechecked, no proofs):**
- `qe(1, (: FALSE :), Fwin, phw)`: expect `qf` TRUE and one atom.
- The straight-segment band with w free: under 10 min.
- Count `epc` results by kind (0, 1, fallback).

**G2 (m = 2, each under 5 min; `sep` must pass on at least 2 of 3):**
- (a) ∃z: x²+y²+z² < 1, with z = pe_var(1), y = 2, x = 3.
- (b) ∃t: 0 ≤ t ≤ T ∧ f(t) < D², with t = 1, T = 2, D = 3, and also with T and D swapped. Both designs predict that `sep` fails here without T−4.
- (c) ∃t: 0 ≤ t ≤ 10 ∧ (5−vt)² + (t/2)² < D².
- Evaluate `qe(2, (: FALSE :), F, phi)` for each.

**G3.** A prototype `(cad-qe)` on the G1 output closes `orig IFF text` in under 2 min.

## 6. `(cad-qe [fnum] [:vars])`

1. Parse with cad-direct's code, except the `closed` check (pvs-strategies:1203): allow m = number of atoms − length of the prefix, with m ≥ 1.
2. Evaluate `qe(m, os, F, phi)` once.
3. If `qf` is FALSE, report and change nothing.
4. Convert with `tq`. Print each member of G with `mpoly-term->str`, with `*mpoly-atoms*` set to the free names, innermost first.
5. Re-parse the printed text with `cad-bf` and check that the result equals `tq` on the ground. Normal forms are unique (mpoly_unique), so this is a syntactic check.
6. Add `orig IFF text`, labelled `qe`, proved from `qe_bf`. The F side is unfolded as `cad-strategy` does; the G side uses `unfold-bf`, `cad-mev` and bddsimp.
7. Size: about 200–300 lines.


## 7. Risks

- **decn_o's cost at n = 2.** It has never been measured, and there is no early exit. Bath problems at n ≥ 3 took 280 s or more.
- **`sep` failures for m ≥ 2.** The output is then not quantifier-free. Mitigations:
  - an untrusted retry that appends the derivatives of the offending level to F; it needs only one proved lemma, that bfsv is unchanged when F is extended and the atoms index below length(F), about 4–6 formulas;
  - root-index atoms;
  - Tier 2C.
- **Nonlinear friction in `ep_side`.**
- **Cost of signatures at deep `sec` descriptors** (m ≥ 2).
- **Canonical-form mismatch.** Lifted atoms against pnorm's output; `tq` must apply `mnorm`.
- **bddsimp time on large outputs.**
- **`epc_ok` (optional)** needs a NASALib lemma that a simple root is a sign change.

## 8. Estimate

| Stage | Formulas |
|---|---|
| Stage 1 (m = 1) | 60–90 |
| Stage 2 (m ≥ 2) | 45–70 |
| `epc_ok` (optional) | 15–25 |
| Augmentation lemma (optional) | 4–6 |
| **Core total** | **105–160**, plus about 250 lines of Lisp |

- **At GAP_PLAN's conservative 50 formulas a day:** about 2–3.2 days of proving, plus 0.5–1 day of Lisp and 0.25–0.5 day of gates: **3–4.5 days**.
- **At Tier 1's measured class-A pace (270–340 a day):** about **1.5–2.5 days**, dominated by the Lisp and the gates.
- **GAP_PLAN's figure for 2A+2B:** 3–5.5 days plus overheads.

## 9. Process

- Commit locally after each verified item, following the order of rule 10 (PROGRESS.md, top.pvs, memory).
- **Do not push.** Show the user the list of pending commits and their exact messages, and push only after the user reviews them. This overrides rule 10's "and push".
- Omit the Claude-Session line, per memory.

## 10. Decisions for the user

1. **When `sep` fails at m ≥ 2:**
   - (a) report "not quantifier-free" and keep the proved `fex` fallback (recommended to start with);
   - (b) add root-index atoms (QEPCAD-style), about 10–15 formulas;
   - (c) schedule 2C, derivative closure, 3–7 days. Decide after G2.
2. **Prove `epc_ok` now?** It makes "one free variable always gives a quantifier-free formula" a theorem rather than a run-time flag. 15–25 formulas, 0.5–1 day.

## 11. 2C: always quantifier-free (design, 2026-09-30, after stage 2)

**Goal.** qe_complete: for every m >= 1, prenex formula (os, F, phi) and point of R^m, qe's output is
quantifier-free AND holds exactly where the formula does (Tarski-Seidenberg, computed and proved).
m = 1 is qe1_complete.  For m >= 2 the only non-QF branch is secsig's cellF fallback, taken when
sep2? fails in a sector.  2C makes sep2? always hold.

**Why derivative closure.**  Over a sector s the free cells are the stack cells of the tower's free
families (levels 2..m).  If each free family G is closed under the formal derivative in its main
variable (every g in G has lderiv(g) in G), two distinct free cells always have distinct signatures:
- fiber lemma: at a base point, if y1 < y2 have the same sign vector on G, no root of G lies in
  [y1, y2] -- for a root r of g (g not identically zero on the fiber: rootat?), thom_lemma's
  sat_convex (real coefficients) keeps g's sign constant on [y1, y2], so g(y1) = g(y2) = 0 and
  then g vanishes on an interval; so sidx(G, p, y1) = sidx(G, p, y2);
- transfer: delin_cl? makes G sign-invariant on each stack cell, and sec_in gives every stack
  index a point over every base point, so two cells over the same base cell with the same
  signature have points on one fiber with the same signature -> same index;
- induction over the free levels (lower keys first: the lifted lower families are part of fpolys).
So equal signatures mean equal keys, and sep2? holds trivially.

**Where the closure goes.**  Not F: proj drops members constant in the main variable (live?), and
injecting through products does not terminate.  Not the engine's tclos_o (decide5's completeness
proofs expand it).  Instead the INITIAL tower: lvln_o(u, T0, s) and nclos_o already take T0, and
decn_ok's core (sectn_sem, memn_ok, foldn_sem) is already generic in T0 (it needs only
length(T0) = k and tlast(T0) = F; tw0 is used only through tw0_shape).  QE computes
T0* = T0 plus the derivatives of every free family of every sector's closed tower, repeated to a
fixpoint (untrusted, with fuel from u), and a run-time check dcl?(TW, m) on each sector's closed
tower (every free member's lderiv is a member).  At the fixpoint the closed families contain T0*,
which contains their derivatives.

**Work items.**
1. Executable (qe2c_def): decT (decn_o's body over a given T0), runqT / runsectsT / runtwT /
   cad_outT, the augmentation loop, dcl?.  qe2 uses them; decide5 is untouched.
2. Soundness in T0: restate cad_run -> cad_out_ok -> cad_fold_ok -> cad_sample -> qe2_ok for runT
   with hypotheses length(T0) = k, tlast(T0) = F (the old statements become instances at tw0).
   Mostly replays: export with editable-justification, (rerun) with names changed, fix branches.
3. Thom separation (qe_thom): lderiv on a fiber is poly_deriv of the fiber coefficients (bridge to
   thom_lemma's dk), the fiber lemma, the transfer, the induction; then dcl? -> sep2? of ents2.
4. Completeness of the augmentation: a universe per level from the top down, closed under lderiv
   at the free levels (V_j = dclos(init_j U rwall(V_(j+1)))), as tower_univ's tul does without
   dclos; the loop grows T0 inside V until it stops; so for large u the check passes (clos_ev's
   eventually-constant arguments with T0 depending on u).
5. qe_complete in qe_all; (cad-qe) unchanged (it already uses qe_correct); demos with m = 2, 3.
Size: items 2 and 4 dominate; the plan's 3-7 days.

## 12. Speed and output (2026-09-30 / 10-01, after 2C)

**The question (user):** is the slowdown at three bound variables normal, or is something wrong?
Measured, not assumed:
- The strategy is not the cost.  On the linear ∃∃∃ example (−1 ≤ xi ≤ 1, x1 + x2 + x3 ≥ c) one
  qe1_o run at u = 0 took 222 s and succeeded; the whole (cad-qe) step about 240 s.
- The engine's cost had identifiable defects (profiles: SBCL sb-sprof and sb-profile through
  tools/prof):
  1. every section sample was an algebraic number even when rational (c = −3), so every sign
     there and above was a Sturm sign-variation count (80% of the time on the linear example);
  2. alg_def's refine recomputed the Sturm chain of the polynomial at every bisection step,
     and cell1's sortu, sect_inv's sepf (inv_chk's separation of a sector's ends) and the
     comparison of equal roots all bisect in loops: on the quadratic ∃∃∃ example
     (xi^2 ≤ 1) 96% of the outer closure's time was one call of sortu (433 s, 611 GB
     allocated) rebuilding chains;
  3. answers listed every TRUE sector separately (30 cell conditions for c ≤ 3).
- What is structural, not a defect: the read closure cuts the line at many more points than a
  projection would (linear ∃∃∃: 15 roots where ±1, ±3 suffice; quadratic ∃∃∃: 179 roots, 359
  cells, from 107 polynomials).  Only a projection with a delineability proof removes those
  (GAP_PLAN Tier 4; Tier 3's open-cell projection would not help QE).

**Fix 1 (done): rational samples.**  alg_rat_def's ratx finds a rational value of an algebraic
number (the root of a linear polynomial; rationals with denominators up to 16 near the middle of
the interval refined 32 times), checked exactly (qroot); towern_od's odS and osec make such a
point a rational point (pt).  alg_rat (ratx_r, ratx_b), oddef (osec_val, osec_den), decn_ok
(odS_wf, odS_den, odS_exact).  Linear n = 3: 252.7 → 29.4 s (∃∃∃), 229.2 → 17.3 s (∀∀∀),
227.5 → 17.4 s (∃∀∃); answers identical.

**Fix 2 (done): merged answers (one free variable).**  qe_mrg_def's mrgX joins every run of
consecutive TRUE sectors into one interval (lowX of the first, uppX of the last; a one-sector run
is its sectX); qe_mrg proves it equal to the disjunction of the TRUE sectors (sects_chain,
mrg_sem, mrgX_sem) and quantifier-free (qf_mrgX); qe_def's qe1_sm takes it when it has fewer
sign atoms (qe1_ok's qe1_sm_sem / qe1_sm_qf, qe1_full's qe1_sm_isqf).  ∃∃∃ now prints
"((-3) + c < 0) OR ((-3) + c = 0)" (c ≤ 3).  Merging for two or more free variables is not done.

**Fix 3 (done): Sturm chains computed once.**
- alg_def's refine decides the half by a zero or a sign change at lb and mid first (lhalf?,
  half_one, lhalf_def; NASALib's poly_intermediate_value_inc/dec) and counts roots only when
  that fails (a root of even multiplicity).
- alg_sortc_def / alg_sortc: an algebraic number with its chain (CA), bisection with it (refc),
  comparison (cmpc: disjoint intervals, bisection, then equality by the gcd of the two
  polynomials, eqg / gcd_eq, then separation), the insertion sort with one comparison per step
  (sortf) and every two neighbours separated afterwards (sepall); cell1's sortu evaluates it
  (sortsep; sortu0 is the old insertion sort, sortf_eq and sortu_vl show the same values, so
  sortu_incr and sortu_vals are unchanged); sect_inv's sepf evaluates sepcc lazily (sepf_eq).
- Quadratic ∃∃∃, outer closure alone: more than 30 min before; 1555 s with the sort and refine
  fixes; 948 s with the separation as well (99 polynomials, 343 cells).
- alg_isign tries a second enclosure, of the query shifted to the middle of the interval
  (pl_shift_def / pl_shift: pshift, pshift_sem), before alg_sign2.  On this example it settles
  only 13% of the fallbacks: most of them are exact zeros (a query that is a multiple of the
  sample's own polynomial), which no enclosure decides; a zero test by the remainder modulo the
  sample's polynomial would catch those (not done).

**Left (measured, ranked; statistical profile of the quadratic closure after the fixes):** the
walk's own Sturm sign-variation counts, separator searches and coincidence tests (about half of
the time, overlapping: the algorithm's normal work at each cell); chain tables (about a sixth);
alg_isign's exact-zero fallbacks (under a tenth); and the number of cells, which multiplies all
of it -- the read closure cuts the line at 179 points where 4 suffice (Tier 4).
