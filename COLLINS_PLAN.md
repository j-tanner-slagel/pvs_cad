# COLLINS_PLAN: a proved Collins projection for the CAD and QE engine (GAP_PLAN Tier 4)

> **Finished 2026-10-01 (note of 2026-10-03).** Every milestone below is done. Later work:
> P5 computes the psc by fraction-free elimination (`bdet`, with `detf` as the fallback when a
> check fails); the smaller projection continued as PROJ_PLAN.md P1-P3 and P5, and since P2
> `decide8` runs `decb_u` (a smaller bottom-step projection over the checked basis of P3,
> `decc_o` as its fallback). McCallum / Brown is PROJ_PLAN.md P7, under review (NEXT_PLAN.md
> step 4); the witness search on top of decide8 is in (cad).
>
> **Status (2026-10-01).** Gate measured (section 1): passed.  User decision: "if it seems good make
> a plan to prove it and do it completely".  Milestones in section 4; progress in cad/PROGRESS.md
> and in the lines below.
> - M-A (determinants: kernels, column linearity): done 2026-10-01 (rdet_nl, rdet_lin; 35 formulas).
> - M-B core (cpoly_alg, cpoly_div; 45 formulas) and M-C rows (sres_rows; 39): done 2026-10-01.
> - M-C done 2026-10-01: sres_thm (sres_ccd, the subresultant theorem), sres_gcd (Sk, sres_roots),
>   sres_eval (psc_ev, sresc_ev); 48 formulas.
> - M-B2 done 2026-10-01: cpoly_der, cpoly_ord, cpoly_dist (dist_lo, dist_hi); 47 formulas.
> - M-D done 2026-10-01: croot_lsc (rp_near, rp_lsc, dist_same), croot_disc (disc_one), ev_near; 39 formulas.
> - M-E and M-F done 2026-10-01: col_def, col_eff, col_real, col_pair, col_loc (collins_loc),
>   col_stack (collins_stack: conn?(C) and colh?(G, C) imply delin_cl?(G, C)); 126 formulas.
> - M-G done 2026-10-01: cad_projn_def (projn), cad_projn (projn_ok: projn sign-invariant on C
>   gives colh?); 45 formulas.  colh? refined (psc only for reducta not identically zero).
> - M-H core done 2026-10-01: col_tower_def (ctw, pbot), col_tower (ctw_cad: the tower of Collins
>   projections is a CAD over every connected set on which pbot(F, k) is sign-invariant).
> - M-I decision done 2026-10-01: decc_def (decc_o), col_sem (sem_cad, rfc_cad, sinv_sect),
>   decc_walk (innern_cad), decc_ok (decc_correct, decc_complete); 23 formulas plus 6 TCCs.
> - M-H done 2026-10-01: col_run (col_cad_run: THE COLLINS PROJECTIONS FORM A CAD adapted to F, no
>   certificate), col_out / col_out_ok / col_verified (records; ccad_of?, col_verified, col_exists).
> - M-J done 2026-10-01: det_fast_def / det_fast (detf_det: each minor once, n 2^n products); the
>   projection's psc uses it.  Also fixed: clean de-duplicates with meq (pmem), which the ground
>   evaluator can run.
> - decide8 done 2026-10-01: decc_u, cad_decide8 (decide8_correct, decide8_decides); (cad) uses it in
>   a theory that imports cad_decide8.  Benchmark (decision alone): Collins far faster with several
>   quantifiers (k3_lin 0.5 s / 11.5 s, l3_quad 0.7 s / > 600 s, bath_01 0.2 s / > 90 s), slower on
>   e4_above (2.1 s / 0.9 s); the Bath problems' cost is the projection SIZE (bath_04: 569
>   polynomials at level 1, i.e. its second projection, in the first variable), not psc.
> - M-I QE done 2026-10-01: qe1c_def / qe1c_ok (one free variable, Collins, always QF), qe2cc_def /
>   qe2cc_ok (m >= 2, Collins; QF when its flag says so), ctwd_def / ctwd (the Collins tower with
>   derivative-closed free levels; pstower_cad), twrun_def / twrun_ok (the run over any tower),
>   qe2cd_def / qe2cd_ok (m >= 2 over ctwd: always QF), qe8_def / qe8 (qe8_complete: always a QF
>   equivalent, every branch the Collins run); (cad-qe) uses qe8 in a theory that imports qe8.
> - K measured 2026-10-01: all 68 (cad) / (cad-qe) proofs of the example theories pass through the
>   Collins run too (244 s against 191 s: about 0.8 s more each on these small examples); the
>   multi-quantifier benchmarks are faster by orders of magnitude.  [Corrected 2026-10-01: some
>   of them (l3_quad, bath_01; k3_lin by a factor of about 23); e4_above is slower, as the
>   decide8 line above says.]  docs/collins_cad.tex.
> - Default 2026-10-01: the README recommends IMPORTING cad_decide8 (and qe8 for (cad-qe)); the
>   example theories keep their imports (read closure) and all pass either way.  [Superseded the
>   same day: the default is now IMPORTING pvs_cad, which imports cad_decide8, qe8 and gform_ok
>   (FORMS_PLAN.md).]
> - After K, 2026-10-01 (user: "do 1 and 3", "do 2 as well"): col_line (col_cells: the Collins CAD
>   in EVERY number of variables, one included), col_found_def / col_found_ok (col_found_cad: the
>   CAD as data with the search for u built in; col_found_decides), qelim_def / qelim_ok (fod_qfd:
>   first-order definable = quantifier-free definable, Tarski-Seidenberg for every formula, qelim
>   from the inside out), cad_sa (every cell of both CADs semi-algebraic in the quantifier-free sense).
> - Next: the witness search (user: keep it, improve it -- CAD sample points, partial CAD, numeric
>   search) and a smaller projection (McCallum / Brown) for the Bath problems.

## 0. Why

The engine decides where to cut each axis by a *read closure*: it adds every polynomial whose sign
its Sturm walk reads, until nothing new appears, and `stack_const` turns sign-invariance of those
reads into delineability.  The closure is what makes the engine total and proved, but it cuts far
more than needed: on the quadratic three-variable benchmark (∃x1 ∃x2 ∃x3: xi² ≤ 1 ∧
x1 + x2 + x3 ≥ c) it cuts the c-axis at 179 points (343 cells), where the problem has 7 critical
values.  After the 2026-10-01 speed fixes (QE_PLAN.md section 12) the remaining time is the normal
per-cell work times the number of cells.  A projection operator with a delineability theorem fixes
the cells once, with no closure.

## 1. The gate: measured, before any proof

Cut points on the c-axis (free variable c) for the benchmark families: linear K_n (−1 ≤ xi ≤ 1,
Σ xi ≥ c) and quadratic L_n (xi² ≤ 1, Σ xi ≥ c).  Scratch prototypes only: proj_meas.pvs (PVS,
the library's own psc and root isolation) and a sympy script; they agree where both ran.
"N-reducta" = Collins' operator keeping a reductum only while the leading coefficient above it is
not a nonzero constant (the dropped reducta can never be the effective polynomial).  "raw" = the
operator's members as computed; "factored" = split into irreducible factors (untrusted
factorizer, for comparison only).

*[2026-10-02: the "Collins" columns here and in 1a, and the "7 critical values" of section 0 and
"2n + 1" below, came from the prototype, which keeps every coefficient and computes extra psc, so
they overstate the library's `projn`.  Measured with a term-by-term mirror of `projn`: K_n has
n + 1 cuts, L_3 / L_4 / L_5 have 5 / 7 / 9, factored L_n has n + 1, and bath_04 has 11 then 569
polynomials (the same 2,490 cuts).  PROJ_PLAN.md section 1.2.]*

| family | read closure (today) | McCallum shape, raw | Collins, all reducta, raw | Collins, N-reducta, raw | Collins, N-reducta, factored |
|---|---|---|---|---|---|
| K_3 | 15 | 7 | 7 | 7 | 7 |
| L_3 | 179 | 11 | 181 | **11** | 7 |
| K_4 | did not finish (1 h) | 9 | – | **9** | 9 |
| L_4 | did not finish (2 h) | 39 | – | **41** | 9 |
| K_5 | – | – | – | **11** | 11 |
| L_5 | – | – | – | did not finish (15 min, sympy) | 11 |

Findings:
- With N-reducta Collins cuts 15× fewer c-cells than the read closure on L_3, and makes n = 4
  reachable at all.  Collins with every reductum is no better than the closure (181 vs 179): the
  N-reducta refinement is essential.
- Factoring into irreducibles (untrusted factorizer, product checked) brings every family down to
  the 2n + 1 true critical values.  Optional, later (GAP_PLAN 3B's `pcert?` idea).
- The library's psc are determinants by Laplace expansion (ring_det): fine to degree about 6,
  hopeless at L_4's bottom level (15 × 15).  A fast psc proved equal to the determinant is needed
  before L_4 (M-J).
- Bath problems: section 1a.  Collins is small where the problem is small and explodes on the dense
  random quartic bath_04; it is not a replacement for the read closure everywhere, so the engine
  keeps the closure as its fallback (M-I).  [As built, 2026-10-01: decide8 and qe8 use the
  Collins run alone, with no read-closure fallback; the read closure stays available as decide5
  and qe, chosen by the import.]

### 1a. Bath problems (Collins, N-reducta; bottom variable = outermost quantifier)

| problem | polys per level (raw) | bottom cuts (raw) | polys per level (factored) | bottom cuts (factored) |
|---|---|---|---|---|
| bath_01 ball and cylinder | 6, 19 | 5 | 6, 8 | 5 |
| bath_02 term rewrite | 9, 22 | 8 | 7, 7 | 8 |
| bath_03 circle and square | 24, 124 | 57 | 23, 91 | 57 |
| bath_04 McCallum quartic | 14, 702 | 2490 | 10, 330 | 1452 |
| bath_05 Buchberger-Hong A | 8, 41 | 23 | 8, 18 | 23 |
| bath_07 Buchberger-Hong B | 14, 137 | 126 | 12, 77 | 126 |
| bath_08 B, Gröbner form | 3, 4 | 7 | 4, 4 | 7 |
| bath_09/10, 12 (4 variables) | – | did not finish (10 min, sympy) | – | did not finish |

## 2. The theorem

For a family G of polynomials in (y; x), x ∈ R^k, and a connected set C ⊆ R^k (cad_conn's
`conn?`): if every member of Collins' N-reducta projection of G is sign-invariant on C, then G is
classically delineable on C (cad_stack's `delin_cl?`).

`delin_cl?` has four parts.  The first (the root list exists) holds at every point (cert_all's
`certz_all` with cad_roots' `rtl_ok`), and the fourth (one sign vector per stack index) follows
from rsvl and bsvl being constant on C (cad_fibre's `sidx_root` / `sidx_band`, as in
`stack_const`).  So, exactly as for the read closure, everything reduces to a LOCAL statement at
each p1 ∈ C — for p ∈ C near p1, rsvl(G, p) = rsvl(G, p1), bsvl(G, p) = bsvl(G, p1) and every
root within η of its partner — which cad_conn globalizes (`stack_same`, `root_cont_on`).

### 2.1 The local statement, mathematically

Fix p1 ∈ C.  On C every member g has a constant effective degree e_g (the projection holds the
leading coefficients of its N-reducta), so g_p is the effective reductum f_p, of degree e_g with
nonzero leading coefficient, or identically zero on all of C, or a nonzero constant on all of C.
Let A be the distinct complex roots of all f_p1, and ε small: below half of every distance in A,
below |Im α| for non-real α ∈ A, below η, and small enough for the sign persistence of (4).
For p ∈ C near p1:

1. Every root of f_p is within ε of a root of f_p1 (croot_near's `croot_root_near`), and every root of
   f_p1 has a root of f_p within ε (lower semicontinuity: |f_p(α)| = |lc| Π|α − s_i| ≥ |lc| ε^e
   otherwise, `cprod_far`, while f_p(α) → f_p1(α) = 0).
2. #dist(f_p) = #dist(f_p1): the number of distinct complex roots is e − κ(f_p, f_p′), where κ is
   the largest degree of a common divisor, and κ is determined by which psc_j(f, f′) vanish (the
   subresultant theorem, 3.2), which is the same at p and p1.  With 1 and the disjoint discs:
   each root α of f_p1 has exactly ONE root β_f(α, p) of f_p within ε (pigeonhole).
3. For two members, each common root α of f_p1 and f̃_p1 is within ε of a common root of f_p and
   f̃_p, so β_f(α, p) = β_f̃(α, p).  Proof: with κ = κ(f, f̃) (constant on C, by the psc), the
   subresultant S_κ(f, f̃) has degree κ in y and leading coefficient psc_κ ≠ 0 on C; it is
   u·f + v·f̃ (linearity of the determinant in its last column), so the common divisor of degree κ
   divides it and S_κ,p = psc_κ(p) · that divisor: its roots are exactly the common roots of f_p
   and f̃_p.  Apply the lower semicontinuity of 1 to S_κ.  (No multiplicities are needed here.)
4. A real α keeps a real β (its conjugate is a root in the same disc, so equal to it), a non-real
   α keeps a non-real one (ε < |Im α|).  So the distinct real roots of G over p are
   β(α_1, p) < ... < β(α_m, p) for the real roots α_1 < ... < α_m over p1, member g vanishes at
   β(α_i, p) iff it vanishes at α_i, and where it does not vanish its sign is that at α_i (sign
   persistence: mpar's `mev_mcont`); the same at the band points (midpoints, ±1).  Hence
   rtl(G, p) is that list (rl_unique), and rsvl, bsvl are those of p1.

### 2.2 What the algebra needs (and what it avoids)

- κ(f, g) is defined as the largest k such that f and g have a common monic divisor of degree k
  (`cd?`), not through multiplicities.  The subresultant theorem in the form needed:
  cd?(f, g, k) ⟺ psc_j(f, g) = 0 for every j < k.  (⟹: a divisor h gives the kernel vector
  (g/h, −f/h) of the j-th Sylvester-type matrix, so its determinant vanishes. ⟸: if
  cd?(k) and not cd?(k + 1), the cofactors f/h and g/h have no common root, and a kernel vector
  of the k-th matrix would give u·(f/h) = −v·(g/h) with deg u < deg(g/h), impossible.)
- Multiplicities only for 2.1(2): ord(P, α) with P = (z − α)^ord · Q, Q(α) ≠ 0; ord of a product
  is the sum; ord(P′, α) = ord(P, α) − 1 at a root (product rule for linear factors only);
  Σ_α ord(P, α) = deg P over the distinct roots.  Then e − #dist(f) is the largest common
  divisor degree of f and f′.
- All polynomial algebra is over C, value-based (functions with coefficient witnesses), using
  croots' `cfact` (every polynomial splits) instead of convolution formulas.

### 2.3 Proof design for D, E, F (written 2026-10-01, after B2)

Everything is phrased with real coefficient arrays A: [nat -> real] and sres_rows' rp(A, n) (the
complex polynomial with coefficients A(0..n)), the form sres_thm and cpoly_dist already use.

D (analysis of one polynomial of fixed degree n, A(n) /= 0):
- rp_near (upper semicontinuity, from croot_near's croot_root_near): for eps > 0 there is delta > 0 such
  that every root of rp(B, n), B within delta of A coefficientwise, is within eps of a root of
  rp(A, n).
- rp_lsc (lower semicontinuity): every root w of rp(A, n) has a root of rp(B, n) within eps, for
  B near A (rp(B, n) = B(n) cprod(s, n) by cfact; if every s_i were eps away,
  |rp(B, n)(w)| >= |B(n)| eps^n by cprod_far, but rp(B, n)(w) -> rp(A, n)(w) = 0 by
  cpoly_diff_bound).
- rp_list: the distinct roots form a list (dist?); rp_conj: conjugates of roots are roots
  (cpolynomial_real_root_conjugate); rp_real: at a real point rp is the real polynomial.
- rp_cder: rp(poly_deriv(A), n - 1) is the derivative of rp(A, n); dist_same: two arrays of degree n
  whose psc(A, A') vanish for the same j < n - 1 have equally many distinct roots (sres_ccd with
  dist_lo / dist_hi).
- disc_one (pigeonhole): discs of radius eps around the m distinct roots of one polynomial are
  disjoint; if another polynomial has m distinct roots, each within eps of one of them, and every
  disc holds one, then every disc holds exactly one (cover_len: a list covering a distinct list of
  length m through a functional relation has length at least m).
- "eventually" combinators: ev?(C, p1, P) (P holds on C near p1) is closed under AND and under
  bounded nat / list quantifiers; sm?(Q) (Q holds for every small eps) likewise; mev_mcont gives
  ev? for each mpoly's value.

E (local Collins, at p1 in C, from colh?(G, C) = sign-invariance on C of: the coefficients of the
kept reducta (N-reducta rule: a reductum is kept unless a coefficient above it is a nonzero
constant), psc_j(f, f') for j < deg f - 1 and psc_j(f, h) for j < min(deg f, deg h), over the kept
reducta f, h of members at positions i1 < i2):
- col_eff: each member has one effective degree e_g on C; for e_g >= 1 its fibre polynomial is
  rp(earr(rdc(g, e_g), p), e_g) with nonzero leading coefficient; e_g = 0: a nonzero constant of
  constant sign; e_g = -1: identically zero (no roots, sign 0).
- col_local: choose eps (half the least distance between distinct complex roots of the members at
  p1, below eta and below the sign-persistence radii at the roots and band points of p1), then d:
  for p in C within d, each disc around a root of f_g(p1) holds exactly one root beta_g of f_g(p)
  (rp_near, rp_lsc, dist_same with the psc of (f, f'), disc_one); a real root keeps a real one
  (its conjugate is in the same disc); a member not vanishing at alpha has no root in alpha's
  disc; two members vanishing at alpha share beta: kappa = the common-divisor degree (constant on
  C by the psc of (f, h), sres_ccd) and, if kappa < min(deg), the roots of S_kappa are the common
  roots at p1 and at p (sres_roots, sres_common; leading coefficient psc_kappa /= 0), so rp_lsc on
  S_kappa's coefficients (sresc_ev, continuous) gives a common root in the disc; if kappa = min(deg),
  the smaller polynomial divides the other at every p in C.
- col_real / col_loc: beta(alpha) = the unique root of G over p within eps of alpha; map(beta) of
  rtl(G, p1) is strictly increasing and lists the roots over p, so it is rtl(G, p) (rtl_eq); signs
  at beta(alpha) and at the moved band points are those at p1 (sign persistence, mev_mcont).
  collins_loc: for eta > 0 there is d > 0 such that for p in C within d, rsvl and bsvl are those of
  p1 and every root moves less than eta.

F (col_stack): as cad_stack's stack_same / root_cont_on / stack_const, with collins_loc in place of
loc_stack / loc_cont: conn?(C), C(p0), colh?(G, C) imply delin_cl?(G, C).

## 3. What exists and what is missing

Exists: ring_det (det, rdet, det_eval), sylvester, subres (sresm, psc, psc_eval), subres2 (sresc,
sres: the subresultant polynomial), croots (cfact), croot_near (croot_root_near, cprod_far,
cpoly_diff_bound), cpoly_unique (coefs_eq, roots_bound, shift_poly), complex@cpolynomial_real
(conjugate roots), NASALib matrices (det_transpose, det_rows_eq_0, det_replace_row_sum/scal,
invertible_det, matrix_diag's diag_det_zero_row, det_mult), mpar (mev_mcont, msg_mpers),
cad_conn, cad_stack (delin_cl?, stack_same / root_cont_on / stack_const as the template),
cad_fibre (sidx_root, sidx_band, bpts), cad_roots (rl?, rl_unique, rtl_eq), cert_all
(certz_all), cad_run / cad_verified (the tower for the read closure), the walk and OD samples.

Missing: everything in section 4.

## 4. Milestones (each: definitions, proofs, gate, top.pvs, PROGRESS.md, commit)

| M | content | theories (planned) | rough size |
|---|---|---|---|
| A | rdet = NASALib det (n ≥ 1); transpose; linearity in a row and in the last column; two equal columns give 0; rdet ≠ 0 kills every left-kernel vector; rdet = 0 gives a nonzero one (diag_det_zero_row) | rdet_nl, rdet_lin, rdet_ker | 40–70 |
| B | complex polynomials by values: closure (sum, product through cfact, linear factors), exact degree, cprod monic, factor theorem, cancellation, common divisors cd? (downward closed), coprime cancellation | cpoly_alg, cpoly_div | 60–100 |
| B2 | ord and distinct roots: existence, uniqueness, ord of products, of the derivative at a root, Σ ord = degree; e − #dist(f) = largest cd? degree of (f, f′) | cpoly_ord, cpoly_dist | 50–90 |
| C | Sylvester-type rows as shifted coefficients; row combinations = coefficients of u·f + v·g; subresultant theorem cd?(f, g, k) ⟺ ∀ j < k: psc_j = 0; S_k = u·f + v·g; roots of S_κ = common roots | sres_rows, sres_thm, sres_gcd | 60–110 |
| D | analysis: coefficient continuity in p, lower semicontinuity of roots, conjugation, disc isolation, pigeonhole on distinct-root lists | croot_lsc, croot_disc | 40–70 |
| E | local Collins: effective reducta from sign-invariant leading coefficients; one root per disc; shared roots; the real picture (rtl at p, rl?); sign persistence at roots and band points; collins_loc | col_eff, col_local, col_real, col_loc | 80–150 |
| F | collins_stack: conn? + sign-invariant projection ⟹ delin_cl? | col_stack | 15–30 |
| G | executable N-reducta projection (own theory), membership lemmas | cad_projn_def, cad_projn | 20–40 |
| H | the projection CAD: tower, cells over cells, cylindrical and adapted (cad_run / cad_verified analog) | design at H | 60–120 |
| I | engine over the fixed tower (walk, OD samples), decision and QE correctness; (cad) / (cad-qe) try it first, read closure as fallback (as built: no fallback; the import chooses, see section 1) | design at I | 60–120 |
| J | fast psc (fraction-free elimination) proved equal to the determinant psc | design at J | 40–80 |
| K | measurements, limits table, PDF section | – | – |

Order: A, B, B2, C (algebra), D (analysis), E, F (delineability), G, H, I (engine), J before
L_4, K.  About 600–1000 formulas.

## 5. Rules

CLAUDE.md applies throughout: proofs in pvs-cli in the main conversation, no hand-edited .prf,
never weaken a lemma, executable functions in their own theories, gate (three fresh runs plus
traces) per changed theory, whole-library replay before each commit, push only to the private
dev repository; public updates only after review with the user.
