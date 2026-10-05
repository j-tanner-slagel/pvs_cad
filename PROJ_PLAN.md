# A smaller projection: what it would take

*2026-10-02. A deep dive: profiles of decide8 on the problems that do not finish, projection sizes of
nine operators on 30 benchmarks, the literature on every smaller operator, and what the library's
Collins proof can be reused for. Nothing here is proved yet; every number is a measurement or an
estimate, marked as such.*

**Status (2026-10-03).** P1, P2, P3 and P5 are done and proved (cad/PROGRESS.md, entries of
2026-10-02 and 2026-10-03).
- **P1's gate is met for g_root9:** over 400 s to 2.4 s (decc_o). g_amgm10 (= b10_amgm), the
  gate's other problem, stayed above 300 s until P3's squarefree basis (then 0.1 s with decq8,
  1.5 s with (cad)).
- **P2's gate is not met:** bath_04, 05 and 07 still take more than 300 s, and the profile puts
  the time in the lifting, not the projection.
- **P3's gate is met for b10_amgm and g_amgm10:** 0.1 s, where before they did not finish in
  300 s. It is not met for the L_n family: L_3 takes 0.6 s, but L_4 and L_5 still exceed 300 s.
  d_amgm4 still runs out of memory, as expected (P5).
- **P5 is done and proved (2026-10-03, NEXT_PLAN.md section 1):** the projection's determinants by
  fraction-free elimination (bareiss: mnorm(bdet) = mnorm(det)), and a faster unproved gcd whose
  results are checked as before. d_amgm4 no longer runs out of memory: its side-23 determinants
  take milliseconds. It still has no answer within 900 s; the time is now in the lifting (sign
  tables and Sturm chains at four-variable sample points). bath_04/05/07 and L_4, L_5 are
  unchanged (more than 300 s).
- **Next (NEXT_PLAN.md):** the thorough review (step 3), then a review and plan of P7 (step 4).
  P4 and P6 are not scheduled; P6 is weighed there as an alternative to P7.

## 0. Short answer

- **Two different things limit decide8 today, and only one of them is the projection.**
  - Two variables, degree 8 and up: 87% of decc_o's time on g_amgm8 is the determinant routine
    looking up minors (`det_fast_def.dlook`, a linear scan of a list). The projection is already
    tiny there (one or two polynomials). With a hashed lookup put in by hand in a scratch server,
    g_root7 went from 3.4 s to 0.2 s, g_amgm8 from 25 s to 1.2 s, and g_root9 from more than 400 s
    to 2.0 s.
  - Three variables (Bath): the bottom projection step is the blow-up. bath_04's bottom family
    has 569 polynomials and 2,490 roots, and isolating them (big-integer gcds inside NASALib's
    Sturm code) is about 80% of the time.
  - Four variables (bath_09, bath_12): no Collins-type operator finishes even the projection.
- **Provable with what the library already has, with no new mathematics:**
  1. a **minimal bottom step**: for each polynomial, its leading coefficient and the first
     principal subresultant coefficient psc_j(f, f') that is not identically zero; for each pair,
     the first psc_j(f, g) that is not identically zero. bath_04: 2,490 roots become 61.
  2. a **squarefree basis** before each projection, checked by a product certificate. It shrinks
     the determinants of perfect powers (b10_amgm: side 19 becomes 9; d_amgm4: 199 becomes 23).
  3. **Hong's operator** above the bottom step (one determinant lemma).
- **Not provable without a large new body of mathematics:** McCallum, Brown, Lazard and the
  equational-constraint operators. Already in three variables they need analytic geometry in
  several complex variables (Zariski's non-splitting theorem, or Puiseux expansions with
  parameters). NASALib has none of it, and as far as our searches of 2026-10-02 found, no proof
  assistant has a formal proof of any of these operators (NEXT_PLAN.md step 4 checks this before
  anything says "first").
- **Recommendation:** the indexed determinant lookup, then the minimal bottom step, then the
  squarefree basis: about 3 days at the Collins pace, then re-measure. That should take the
  two-variable degree 9–10 problems and the three-variable Bath bottom blow-up off the list. The
  four-variable problems need either Strzebonski's local projection (elementary, but a new
  engine) or McCallum's theory (research), plus a polynomial-time psc.

## 1. Measurements

### 1.1 Where decide8's time goes (PVS, scratch server, IMPORTING pvs_cad, decc_o at u = 0)

| problem | variables, degree | decc_o today | profile | with a hashed `dlook` (scratch only) |
|---|---|---|---|---|
| g_root7 | 2, 7 | 3.4 s | | 0.2 s |
| g_amgm8 | 2, 8 | 25.0 s | `dlook` + `dleq` 87%, arithmetic about 6% | 1.2 s |
| g_root9 | 2, 9 | > 400 s | | 2.0 s |
| b10_amgm | 2, 10 | > 400 s | | still not finished (side-19 determinants; the input is a perfect square) |
| bath_04 | 3, 4 | > 150 s | big-integer gcd 81%, inside the library's root isolation (`alg_fast`'s `isoc`) and the NASALib Sturm code it calls (`rat_poly_to_int`, `pseudo_div`) | |

The hashed lookup was a Lisp-level stand-in loaded into a scratch server to measure the
possible gain; it is not a proposal for the library. A proved indexed table (P1) gives O(n)
or O(log) lookups instead of O(1), so expect somewhat less than these gains.

### 1.2 Projection sizes (sympy/flint prototype mirroring `projn` term by term)

Each cell: bottom polynomials / bottom roots / largest determinant side. "dnf": not finished in
5 minutes. The full table (30 problems, 9 operators) was produced by a scratch prototype and is
not published.

| problem | (1) projn today | (2) minimal bottom | (3) = (2) + squarefree basis | Hong + minimal bottom | Brown (not provable) | McCallum (not provable) |
|---|---|---|---|---|---|---|
| bath_04 | 569 / 2490 / 13 | 47 / 61 / 13 | 35 / 61 / 11 | 47 / 61 / 13 | 6 / 11 / 11 | 14 / 38 / 11 |
| bath_05 | 29 / 20 / 8 | 17 / 13 / 8 | 9 / 13 / 8 | 17 / 13 / 8 | 9 / 10 / 8 | 13 / 14 / 8 |
| bath_07 | 97 / 120 / 11 | 42 / 42 / 11 | 34 / 42 / 11 | 26 / 28 / 11 | 21 / 26 / 11 | 24 / 29 / 11 |
| bath_09, 12 | dnf | dnf | dnf | dnf | 620 / 767 / 40; 211 / 213 / 40 | 753 / 1021 / 40; 471 / 581 / 40 |
| g_root9 | 2 / 2 / 17 | 1 / 1 / 17 | 1 / 1 / 17 | 1 / 1 / 17 | 2 / 1 / 17 | 3 / 2 / 17 |
| b10_amgm | 1 / 1 / 19 | 1 / 1 / 19 | 1 / 1 / 9 | 1 / 1 / 19 | 1 / 1 / 7 | 1 / 1 / 7 |
| d_amgm4 | dnf | 42 / 1 / 199 | 1 / 1 / 23 | 42 / 1 / 199 | 1 / 1 / 23 | 1 / 1 / 23 |
| c_schur | 39 / 1 / 9 | 9 / 1 / 9 | 1 / 1 / 5 | 9 / 1 / 9 | 1 / 1 / 5 | 1 / 1 / 5 |
| L_5 | 11 / 9 / 31 | 6 / 9 / 31 | 5 / 9 / 4 | 6 / 9 / 31 | 6 / 6 / 2 | 11 / 11 / 2 |

Findings:
- (2) removes almost all of the three-variable blow-up: bath_04 2,490 roots → 61, bath_07 120 → 42.
- (3) never changes a root count relative to (2), but it removes the large determinants that
  come from non-squarefree polynomials (perfect powers, AM–GM forms, L_n).
- Full irreducible factorization adds little over (3) on these benchmarks.
- In two variables every operator needs the same largest determinant (the j = 0 discriminant or
  resultant), so for them the determinant routine (P1, P5) matters more than the operator.
- On bath_09 and bath_12 the explosion is above the bottom step; only McCallum or Brown get
  through, and they still need side-40 resultants.
- **Correction to COLLINS_PLAN.md sections 1 and 1a:** those tables were measured with a
  prototype that keeps every coefficient and computes extra psc, so they overstate `projn`. The
  library's operator gives, for example, n + 1 roots on K_n (not 2n + 1), 5 / 7 / 9 on L_3 / L_4 /
  L_5 (not 11 / 41 / dnf), and 11 then 569 polynomials on bath_04 (not 14 then 702). The root
  count on bath_04 (2,490) is the same.

## 2. What the existing proof can be reused for

`collins_stack` uses its hypothesis `colh?` (every member of `projn(G)` sign-invariant on C) in
only three lemmas, all in col_eff:
- `col_edeg`: the effective degree is constant on C;
- `col_psc1`: psc_j(f, f') vanishes for the same j at every point (used by `ff_one` →
  `dist_same`);
- `col_psc2`: the same for psc_j(f, h) (used by `ff_pat`: κ(f, h) is constant).

The other lemmas of col_pair (38), col_loc (23) and col_stack (3) only carry `colh?` along.
So the proof really goes through "effective degree constant, κ(f, f') constant, κ(f, h)
constant", and any hypothesis that gives those three facts gives delineability.
- **Refactor:** state those three facts as one predicate (say `kconst?(G, C)`), prove
  `colh?(G, C) ⇒ kconst?(G, C)`, and restate col_pair, col_loc and col_stack over `kconst?`.
  About 59 of the 64 saved proofs should replay unchanged. `lv_C`, `ff_one`, `ff_pat`, `dead_val`
  and `rr_root` change, and `dist_same` needs a variant that takes the κ-equivalence directly.
- **The minimal bottom step gives `kconst?` on every base cell:**
  - On an open interval none of its polynomials vanish. So psc_i ≡ 0 for i < j₀ and psc_j₀ ≠ 0,
    and `sres_ccd` gives κ = j₀ at every point.
  - On a point every `cinv?` holds, so `collins_stack` applies as it is.
  - The same argument fails on positive-dimensional cells of R² and up. There psc_j₀ can vanish on
    the whole cell, which is exactly where McCallum needs analytic geometry. Example (checked with
    sympy): z³ + (y − 3x²)z + 2x³ on y = 0.
- **Literature:** the squarefree-basis form for the plane is standard (BPR §11.6; Kerber's thesis,
  Thm 2.2.10, with an elementary proof). The "first not-identically-zero psc" form is not written
  anywhere we found, but it follows at once. The same idea, applied at a sample point, is
  Strzebonski 2016's local Hong projection (Lemma 16).

## 3. The plan

Pace for calibration: the Collins work was 58 theories, 698 formulas and about 15 hours, roughly
47 formulas an hour. A whole-library replay is about 45 minutes (42-46 min, 2026-10-02/03), and a gate about 10–12 minutes
per theory.

### P1. An indexed determinant table (not a projection change; first because it is cheapest)
- **What:**
  - Replace `dlook`'s linear scan by a structure with O(n) or O(log) lookup: a binary trie on the
    column set, or rank-indexed levels, since `dsubs` lists the column sets in lexicographic order.
  - Keep `dlook` as the specification and prove that the new lookup returns the same entry
    (the QE speed round's pattern). `detf_det` then keeps its statement.
- **Size:** 20–40 formulas, half a day with gates and a replay.
- **Payoff (measured with the hashed stand-in):** g_root9 > 400 s → about 2 s, g_amgm8 25 s →
  about 1 s, and every psc in the library gets faster.
- **Gate:** g_root9 and g_amgm10 under 30 s with `(cad)`.

### P2. The minimal bottom step
- **What:**
  - A new operator for the step that produces the univariate family: for each member, the first
    coefficient that is not identically zero plus the first psc_j(f, f') that is not identically
    zero; for each pair, the first psc_j(f, g) that is not identically zero. Zero is checked with
    `mnorm`, which is a complete normal form, and constants are dropped as in `clean`.
  - The `kconst?` refactor of section 2, and "every member of the bottom family is nonzero on an
    open base interval".
  - Redefine `pbot` / `cbot`, and re-prove `ctw_car`, `ptower_cad`, `ctw_cad`, `pstower_cad`,
    `ctwd_cad`, `cbot_ctw` and `ctwd_scad` (about 8–10 proofs). Everything downstream goes through
    interface lemmas, and the strategies do not name these definitions.
- **Size:** 100–150 new or changed formulas plus about 70 replays: half a day to a day.
- **Payoff (measured sizes):**
  - bath_04 bottom family 569 → 47 polynomials and 2,490 → 61 roots;
  - bath_07 120 → 42 roots, bath_05 20 → 13;
  - fewer determinants in two variables (g_root9 8 → 1, b8_meet 16 → 3).
- **Gate:** bath_04, bath_05 and bath_07 decided by decc_o (not the witness search) within 120 s.
  If not, profile the lifting before going on.

### P3. A squarefree basis before each projection, checked by a product certificate
- **What:**
  - An executable, *unproved* gcd-based routine that splits a family into a squarefree, pairwise
    coprime basis. It needs no correctness proof: a proved check `pcert?` accepts the basis only
    if every member equals c·∏ bᵢ^eᵢ (by `mnorm` equality), and falls back to the unsplit family
    otherwise.
  - Collins' theorem holds for any family, so delineability of the basis gives delineability of
    the family. That needs a transfer lemma: the same roots, and signs that are products of signs.
  - Apply it to every family before projecting, including the input family. That is what fixes
    b10_amgm, whose input is (x⁵ − y⁵)².
- **Size:** 40–80 formulas plus a few hundred lines of executable code (multivariate gcd by
  primitive pseudo-remainder sequences; `mpoly_pdiv` exists): 1–1.5 days.
- **Payoff (measured sizes):**
  - largest determinant b10_amgm 19 → 9, g_amgm8 15 → 7, d_amgm4 199 → 23, L_5 31 → 4;
  - bath_04 bottom degree 68 → 22, bath_07 34 → 9.
- **Gate:** b10_amgm, g_amgm10 and the L_n family decided; d_amgm4 still needs P5.

### P4. Hong's operator above the bottom step (optional)
- **What:**
  - For pairs, psc_j(red f, g) with reducta of one polynomial only.
  - It needs one determinant lemma, the degree-drop identity
    psc_j(F, G)(α) = ±lc(F)(α)^(n−n')·psc_j(F(α), G(α)): the first n − n' columns of the Sylvester
    submatrix are triangular, with lc(F) on the diagonal.
  - It plugs into `kconst?`.
- **Size:** 40–80 formulas, about a day.
- **Payoff:**
  - bath_07 42 → 28 roots with P2;
  - in SMT-RAT's data (about 5,600 instances), Hong's level-2 sets are about 5× smaller than
    Collins' on average.
- **Do it only if** the Bath problems are still slow after P2 and P3.

### P5. A polynomial-time psc (needed for determinants of side 20 and up)
- **Why:** d_amgm4 needs side 23 even after P3, and bath_09/12 need side 40 under any operator.
  n·2ⁿ is hopeless there.
- **Options:**
  - fraction-free elimination: Bareiss, or division-free Sasaki–Murao (formalized in Rocq's
    CoqEAL);
  - the subresultant chain (formalized in Isabelle's AFP "Subresultants");
  - a shortcut seen in this survey but unproved: with the Sylvester rows interleaved, psc_j is ±
    a leading principal minor, so one elimination pass gives every psc_j of a pair (checked on 910
    random cases).
- **Size:** 150–300 formulas, 2–4 days, moderate risk.

### P6. Strzebonski's local projection (the elementary road to McCallum-sized sets)
- **What it is:** for the cell around a sample point, keep psc₀ … psc_l up to the first one that
  is nonzero *at that point*. On the cell where all of them keep their signs, κ is constant, by
  the same argument as P2. So the sets are usually just {lc, disc, res}, with Collins-style
  proofs and no analytic geometry.
- **What it costs:** a new engine that builds cells one at a time, with new correctness proofs
  for it. The walk and the stack theorem carry over.
- **Reported effect:** Strzebonski reports 523 cells in 0.95 s on a problem where the full CAD
  did not finish in 72 hours.
- **Plan:** prototype it in Python on bath_09 and bath_12 first (1–2 days). If it works there,
  it gets a plan of its own (my guess: one to three weeks).

### P7. McCallum, Brown, Lazard proper (research)
- **What they need (following McCallum–Parusiński–Paunescu 2019, the cleanest published route):**
  - analytic functions of several variables, with the analytic implicit and inverse function
    theorems;
  - cells as analytic submanifolds;
  - order of vanishing and its invariance;
  - the several-variable Cauchy integral, and Riemann extension across a hyperplane;
  - covering-space monodromy of roots, giving Puiseux with parameters;
  - then non-splitting of root clusters, and delineating derivatives at nullifying points.
- **Cost:** NASALib has none of it. As far as our searches found (to be confirmed by NEXT_PLAN.md
  step 4), this would be the first formal proof of any of these operators, in any prover. Months,
  and nothing in this project's history calibrates it.
- **Payoff:** the smallest sets (Brown: bath_04 11 roots) and the four-variable problems,
  together with P5.

## 4. Decisions for the user

1. Do P1 → P2 → P3 now (about 3 days at the Collins pace), then re-measure every hard benchmark?
2. After that: P4 if the Bath problems are still slow; P5 for d_amgm4 and anything with large
   determinants; a P6 prototype if the four-variable problems matter.
3. P7 only as a deliberate research project (and a paper), not as a speed fix.

## 5. Sources and files

- **Literature:**
  - Hong 1990, as restated by Viehmann–Kremer–Ábrahám 2017;
  - McCallum's thesis (UW TR 578, 1985; Thms 3.2.1, 3.2.3, 4.1.1);
  - Brown 2001 (JSC 32);
  - McCallum–Parusiński–Paunescu 2019 (JSC 92);
  - Strzebonski 2016 (local projections, arXiv 1405.4925);
  - BPR §11.6; Kerber's thesis (2009), Thm 2.2.10;
  - Vermande, CPP 2026 (Collins and CAD in Rocq, the only other formal Collins proof we found);
  - the AFP Subresultants entry; CoqEAL (Sasaki–Murao).
- **Scratch files (not in the repository, not published):** the projection-size prototype with
  its 30 benchmarks and results table; local copies of the Brown, McCallum and Strzebonski papers;
  the profiles.
