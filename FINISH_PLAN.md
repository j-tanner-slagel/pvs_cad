# Completion plan — a (cad) that is proved, general, and fast

> **Finished 2026-09-27** (section 3i). Superseded by COMPLETENESS_PLAN.md, GAP_PLAN.md and now
> NEXT_PLAN.md.

Written 2026-09-21 after a full review of CAD_PLAN.md, PHASE6_PLAN.md,
ITEM1_PLAN.md, ITEMA_PLAN.md and PROGRESS.md. It supersedes their "what
next" sections; their history stands.

## 1. Where things actually are

**What (cad) is today.** The strategy evaluates `decide2` of `cad_lift` and
cites `decide2_correct`. That route is UNCONDITIONALLY correct and needs no
delineability: it builds the sectors from a READ CLOSURE (`clos1`), checks
`inv1?` (every polynomial the lifting read is sign-invariant on its sector),
and lifts with `svs_sg`. It proves ex_line 48 s, ex_circle 14 s, ex_disc 5 s,
and does not finish ex_three.

**Where its time goes — measured today on ex_line's family** (`fin_meas`,
ground evaluation, 21 root sectors / 43 sectors):

    clos1 + root isolation              ~ 8 s
    inv1? check                         ~ 8 s
    lifting 43 sectors with svs_sg      ~29 s      <- 3^|F| per sector
    lifting 43 sectors with svs_bis      <1 s      <- item A's bisection lifting

So the lifting, the dominant cost, is already replaceable by something 30x
faster. What is then left -- closure and inv check, ~16 s -- is the 3^|F|
DISCOVERY walk `svs_srd`, which exists only to find out which polynomials
`svs_sg` reads.

**What the fast harness routes are.** `pdecide`, `dec2a/b/c` decide on the
small projection in ~1 s, but their correctness (`decn_sem`, `dec2_sem`)
assumes sector invariance, i.e. delineability, which is proved only for one
member of degree <= 2 (`psc_det_quad1`). The general theorem
(McCallum/Collins) needs root-continuity analysis or full subresultant theory
and is NOT on the critical path below.

**What item A really produced.** Sturm counting at a parameter through a
SIGN ORACLE: `acount_zero/pos`, `acaptures` (proved), and the bisection
lifting `svs_bis` (measured, correctness in flight). It was built for
`a: Alg`, but nothing in it is specific to one algebraic coordinate -- the
underlying theorems (`fchain_sturm`, `rchain_sg_at`) hold at ANY real
valuation `ys` with oracle `msg(ys)`.

## 2. The key design decision

The unconditional route does not need delineability; it needs the lifting's
answer to be INVARIANT along each sector, and it gets that from DETERMINACY:
a computation that consults the parameters only through a sign oracle gives
the same answer at two points whose oracles agree on the polynomials it read
(`rchain_det`, `svs_det` are this, for `svs_sg`). `svs_sg`'s reads are
expensive to discover (3^|F|). The bisection walk's reads are not: they are
the Sturm chains' leading coefficients plus the chain entries and members
substituted at the rational separators -- polynomially many, and listed by a
simple function. So:

    sectors   :=  closure of proj(F) under the BISECTION WALK's reads
    lifting   :=  the bisection walk (polynomial)
    transfer  :=  determinacy of the walk on its reads + inv_chk on the sector

Every piece is polynomial in |F|, every theorem is finite and algebraic, and
no step is conditional. This is the architecture to finish on.

## 3. Stages

**S1. `sturm_sg` -- Sturm counting through an arbitrary sign oracle.**
Port `alg_sturm`/`alg_sturm2` from `a: Alg` to `sg: SG` with hypothesis
`sg = msg(ys)`. Chain entries at a rational y0 are read as
`sg(sub1(c, y0))`, where `sub1` substitutes the main variable inside the
mpoly ring (Horner over `madd`/`mscal`); this removes `mswap` and
`partial_eval` from the path. Theorems: `cnt_nneg`, `cnt_zero`, `cnt_pos`,
`captures`, with `algsg(a)` as the instance.

**S2. `walk_sg` -- the lifting with FIXED separators, and its correctness.**
`walk(F, Y, sg)`, `wok?(F, Y, sg)`; theorem: `sg = msg(ys)` and `wok?` imply
the walk lists exactly `fib(F, ys)` (via `svec_same`, `prodl_zero`,
`strip_eval`). `bseps` stays as the SEARCH for Y; only the walk needs proof.

**S3. Quick win, banked early: closure sectors + bisection lifting.**
`qfoldS_sem` generalized to any per-sector lifting that lists the fibre at
the sample; `decide3` = `decide2` with `svs_sg` replaced by the walk on the
final fold. Unconditional, reuses `inv1?`. Expected ex_line ~48 s -> ~17 s.
Rewire `(cad)` to it and re-gate `cad_examples`.

**S4. Reads and determinacy of the walk; the polynomial closure.**
`walk_rd(F, Y, sg)`, `walk_det` (agreement on reads gives the same walk and
the same `wok?`), certificate `binv?(F, s)` by `inv_chk`, closure `bclos`,
and `decide4_correct` for two quantifiers with NO svs_sg/svs_srd anywhere.
Rewire `(cad)`: two-quantifier formulas go to `decide4`, with `decide3` as
fallback. Measure on the examples and on 2-variable problems with larger
families.

**S5. n levels.** Oracle tower: the oracle for a point `cons(beta, ys)` with
beta a section is a bounded Tarski query through the oracle for `ys`
(`tarski_chain` has the chain, NASALib the theorem); for a rational
coordinate it is `sg o sub1`. Recursive decision, determinacy through the
levels, `(cad)` on ex_three and the Bath bank through the strategy.

**S6. Close-out.** Benchmarks table in PROGRESS.md, top.pvs descriptions,
memory, remove scratch theories, final whole-library run.

## 3b. S4 REVISED after measurement (2026-09-21)

S1 and S2 are done and gated. S4 as first written was measured and REFUTED
on ex_line, and the refutation is structural:

    dec4 (closure under ALL the walk's reads, constant separators)
      f_circle <1 s ok, f_disc 1 s ok, f_rad2 <1 s ok, controls right
      f_line   164 roots at fuel exhaustion, 79 s, ok = FALSE

A read `f(y_j, x)` at a CONSTANT rational separator `y_j` vanishes wherever a
root curve crosses the line `y = y_j`. A bounded curve crosses finitely many
such lines; an unbounded one (the line's root `(1-x)/2`), or two curves that
meet at a sector's end, force new separators in every subsector, for ever. No
finite certificate with constant separators exists near a collision point.

What survives is the split between two kinds of read:

  INTRINSIC   the chains' construction reads and leading coefficients (and
              the constant members themselves): sample-independent
  ENTRY       chain entries and members substituted at a separator

    dec5 (closure under the INTRINSIC reads only, lifting by the walk)
      f_line    1 root -- the same sectors as the projection -- ~1 s, ok, right
      f_circle, f_disc, f_rad2, f_meet: <= 2 s, ok, right; controls right

So the sectors come from the intrinsic reads, and the entry reads are handled
by ARGUMENT instead of by certificate:

  T1  sign persistence: finitely many polynomials nonzero at x0 keep their
      signs on a neighbourhood of x0
  T2  determinacy: the walk and wok? depend on the oracle only through
      walk_rd (rchain_det + nsc_scale)
  T3  existence: at EVERY point x0 of a sector whose intrinsic reads are
      invariant there are separators passing wok? with every entry read
      nonzero -- from NASALib's constructed_sturm_roots_between_enum (an
      increasing enumeration of all roots of all chain entries), density of
      the rationals, and a root bound
  T4  a function locally constant on a convex set is constant on it
  T5  assembly: the fibre set is constant on each open sector, hence the
      fold over sectors is the quantifier; `(cad)` rewired to it

T1-T4 give local constancy everywhere on the sector and T4 globalizes it. It
is a runtime-certified delineability theorem: elementary, no subresultants.
One correction found while planning: a member with NO main variable
contributes no chain, so its own coefficient must be added to the intrinsic
reads or its sign changes go unseen (F = {y, x} would be decided wrongly).

S3 (closure sectors + walk) stays available as the fallback.

## 3c. S4 DONE; S5 designed (2026-09-21)

S4 is proved and gated: `decw_correct` (cad_fast), wired into `(cad)` through
`decide3` (cad_decide3), which keeps `decide2` as the fallback and for every
number of quantifiers other than two.

What the S4 proof teaches about S5. Only the OUTERMOST variable needs
connectedness (its cells are intervals). Everything inside is a computation
at a FIXED real value of the outer variables, run through a sign oracle, and
its correctness at that fixed point is `walk_fib` again, one level at a time.
The transfer along the outer sector is again local constancy:

  reads of the whole inner computation split into
    INTRINSIC  chain constructions and leading coefficients at every level,
               with no separator in them -- certified invariant on the sector
    ENTRY      anything with a separator substituted -- never certified;
               nonzero at the point in hand for well-chosen separators
               (sep_exist, which is already stated for ys of any length),
               hence persistent nearby (sign_pers)

The shape of the three-quantifier decision (x outermost, z innermost):

  per x-sector s, oracle sg_x = asgS(s)
    P_y   := proj(F) closed under the z-walk's intrinsic reads at the
             y-separator cells (membership closure, as closed? in cad_lift;
             S4 measured that these reads are few)
    cells := the y-walk over P_y through sg_x: rational separators (one per
             open y-interval) and gaps holding a root (sections)
    oracle at a separator y_j:   sg_x o sub1(., y_j)
    oracle at a section:         TOWER -- a bounded Tarski query through sg_x
                                 (tchain_sturm + NASALib sturm_tarski: with a
                                 unique root in the gap it is the sign there)
    value := fold q2 over the cells of (fold q3 over the z-walk at the cell)
  x-family := closure under the INTRINSIC reads of all of the above

Two claims, as in S4.

  A (pointwise)  at any real x where the certificate holds, the value is the
     truth of Q2 y Q3 z.  The z-fibre set is constant on each open y-interval
     by fib_const in the y-direction at FIXED x, which needs walk_transfer
     generalized from parameters (: x :) to cons(y, xs); its hypothesis is
     that the z-intrinsic reads at the cell are members of P_y, hence have no
     root where P_y's product has none, hence keep their sign (IVT).
  B (transfer)  the certificate and the value at the sample hold at every
     point of the sector.  One subtlety that S4 did not have: equal SIGN
     VECTORS on P_y do not identify a y-cell (z - a and z - b: the chain reads
     see (a-b)^2, which has the same sign on both sides of a = b).  What
     transfers is the ORDERED list of P_y's cells: walk_det already gives the
     same list locally, so S4's argument is restated for the list with
     consecutive repeats removed (canonical, independent of the separators).
     Cell j at x then corresponds to cell j at the sample, their oracles agree
     on P_y, and wi_det moves the z-intrinsic reads -- and with them the
     certificate of claim A -- from the sample to x.

Stages:

  S5a  generalize sign_pers / walk_transfer / cad_fast to cons(x, xs)
       (mechanical; re-gate four files)
  S5b  the tower oracle and its theorem; the y-level walk with cells
  S5c  executable three-quantifier decision, MEASURED on ex_three and
       three-variable controls before anything is proved about it
  S5d  claim A, claim B (ordered-list transfer), `decw3_correct`, `(cad)`
  S5e  the recursion to n quantifiers

## 3d. S5d DONE; S5e (n quantifiers) designed (2026-09-21)

Three quantifiers are proved and wired: `decw3_correct` (cad3), reached by
`(cad)` through `decide4` (cad_decide4), `decide2` still the fallback and the
route for four or more. What the three-level proof teaches about n levels:

**What already generalizes as it stands.** `walk_same` compares ANY two
valuations. `cl_transfer`, `fib_const`, `sep_exist`, `cover`, `root_near` are
stated over `cons(x, xs)` with xs arbitrary. Nothing in claim B used a cell
correspondence or an ordering of roots across the sector -- only SETS of
values over a point. That is the property that lets the recursion go through.

**The tower.** Per outer sector s, ONE family per level, not one per cell:
TW = (F_2(s), ..., F_n = F), F_k in the variables x_1..x_k, where F_k contains
proj(F_{k+1}) and the intrinsic reads of the F_{k+1}-walk at EVERY cell of the
tree of cells over sample(s). Computed by a joint fixpoint (fuel; untrusted),
checked by the certificate. For n = 3 this is exactly lvl2(F, s).

**Executable.** `innern(qs, TW, Psi, sg)`: cells of car(TW) through sg
(rational separators with `sg_pt`, gaps with `sg_sec`), recursion on cdr(TW),
`bfold` at each level, `qfold` over `svs_w` at the bottom. `inner2` is n = 3.

**Claim A at n levels (pointwise).** By induction on TW, with the oracle only
APPROXIMATELY msg(ys) below the first section: a section oracle is right only
on the polynomials whose query came back ok. So the statement carries a read
list:

    agree(sg, msg(ys), RD(qs, TW, sg)) AND okn?(qs, TW, sg)
      IMPLIES (innern(qs, TW, Psi, sg) IFF sem(qs, F, Psi, ys))

RD = the level's own walk reads + for each cell the reads THROUGH sg that make
the cell's oracle right on the cell's RD (`sub1` for a separator; `q_rd`, the
reads of one tower query, for a section). New: `q_rd` and `qsec_det`
(snorm_sg, secp, tchain_sg, tlo/thi, nzall?, tq_b), in the style of walk_rd.
No determinacy of seps or of the closure is needed: both are untrusted, the
walk is re-checked by wok? at the true oracle through walk_det.

**Claim B at n levels (transfer).** Strong induction on the height of the
tower, and inside it a downward induction over levels.
 1. CLOSURE EVERYWHERE over the sector. "The intrinsic reads of the
    F_{k+1}-walk at a point are members of F_k" depends on the point only
    through its F_k sign vector (rdin_vec). The set of F_k sign vectors
    realized over x is  EX..EX: svec = v,  a sentence about the truncated tower
    (F_2..F_k): constant on the sector by THIS theorem at a smaller height.
    (n = 3: that was fib_const + cl_transfer.)
 2. LOCAL CONSTANCY, many parameters. LT_k(vs0): there is d such that for vs1
    within d of vs0 coordinatewise (over the sector) with the same F_k sign
    vector, sem(qs_k, F, Psi, vs1) IFF sem(qs_k, F, Psi, vs0). Bottom level:
    walk_same + joint persistence. Step: cells of F_{k+1} over vs0
    (wok_exist); the walk agrees at vs1 (walk_det); separator cells by LT_{k+1}
    at (y_j, vs0) and constancy along the root-free interval at fixed vs1
    (loc_const + LT_{k+1}, closure from 1); sections by root_near; then V_sub
    and G_from verbatim.
    This is pt_local -> cells_local -> inner_const with `x` replaced by a
    valuation and T replaced by sem at any depth.
 3. G_const at height n by loc_const, then the fold over sectors (fold3_sem).

**New analytic facts needed:** joint persistence and root_near in MANY
parameters (today: two and one). Both are inductions on the structure that is
already there (mev_cont, cnt_local).

Stages:

  S5e-1  `innern`, `okn?`, the tower closure, `decwn`; MEASURE on the three-
         variable sentences (must match decw3) and on a four-variable one
  S5e-2  q_rd / qsec_det; claim A at n levels
  S5e-3  many-parameter persistence and root_near
  S5e-4  LT_k, closure everywhere, G_const at height n, `decwn_correct`
  S5e-5  `(cad)` on decwn for every prefix; decide2 stays the fallback

## 3e. Why four quantifiers blew up, and the way out (2026-09-22)

Measured on ALL x ALL y ALL z EX w: w > x AND w > y AND w > z (three linear
members; ~105 bottom cells in the whole tower). Not the CAD exponent: with the
coordinates substituted a bottom walk takes 0 s. Two implementation causes.

1. Chains rebuilt inside every count. svar put schain inside the lambda handed
   to number_sign_changes, so a count rebuilt the chain ~6 times, a cnt ~12, the
   separator bisection ~15 cnts; tvar/tlo/thi/qsec likewise, and qsec also
   recomputed secp for every query. FIXED: svarc/sloc/shic/cntc/leftc/rightc
   take the chain; svar, slo, shi, cnt, left, right, tq_b, qsec, sg_sec, wok_w
   are stated through them with _def lemmas giving the old statements; wokc?
   and sepokc? (one product chain for the whole certificate) proved equal to
   wok?/sepok?; seps and tlo/thi share the chain. Same objects, before/after:
   cnt 19 s -> 2 s, seps 317 s -> 1 s, wok_w 12 s -> 2 s, a bottom walk at a
   section > 20 min -> 56 s.

2. Symbolic pseudo-remainder swell. The walk sees only a sign oracle, so
   chains are built with coefficients that are polynomials in EVERY variable
   not yet eliminated, and pseudo-remainder sequences without subresultant
   division swell exponentially in the main-variable degree, with term counts
   exponential in the number of free variables. Measured at the four-variable
   level: the chain of a degree-3 product 1 s, of a degree-4 product > 10 min.
   Each level adds one free variable to every coefficient and one nesting of
   Tarski queries (each building such a chain). THIS is the 3 -> 4 wall, and
   it is independent of the evaluator's speed.

The way out, in two steps.

  S5e-0  ORACLE DESCRIPTORS (no trusted definition changes).  The executable
         takes a descriptor instead of an opaque SG:
           OD = pt(ys: list[rat]) | alg(a: Alg) | sec(od: OD, P, lo, hi)
         with meaning osg(od): SG (pt -> msg(ys), alg -> alg_sign2 at a,
         sec -> sg_sec(osg(od), P, lo, hi)).  At a pt the sign of a chain
         entry is meval at the point (sent_sign, proved), no substitution
         arithmetic at all; sg_pt(msg(ys), y0) = msg(cons(y0, ys)) (sg_pt_msg,
         proved) so separator cells below rational cells stay pt.  Chains are
         built ONCE per level per sector and reused at every cell through a
         validated table: an entry (f, chain, reads, signs) is used at a cell
         iff the cell's oracle agrees with the recorded signs on the reads,
         which is rchain_det / wi_det (proved).  One lemma per walk function:
         the descriptor executable computes walk(F, osg(od), Y).
         Removes the per-cell symbolic cost entirely; the once-per-level
         symbolic chains remain.

  S5e-1  THE PRODUCT CHAIN.  The certificate needs the reads of bprod(F)'s
         chain symbolically (claim B transfers sepok?/left/right through
         them), and that chain swells with the product degree: >= 4 live
         members, or quadratic members, at a level hit the minutes-per-chain
         wall. Replacing it means per-member root isolation with a Tarski
         coincidence test for gaps holding roots of two members (chains of
         degree d and 3d instead of m*d), i.e. a change to the trusted sepok?
         (expanded in 22 proofs) and walk_ok. Decide with the user after S5e-0
         is measured.

## 3f. The structural wall, measured (2026-09-22)

S5e-0 done and measured (walk_od gated; towern_od executable): section
cells over rational points are exact and cheap (mix descriptors), chains are
built once per level, a closure round at four variables went 82 s -> 7 s,
three quantifiers with the full certificate 9 s -> 3 s. Four variables still
do not finish, and the reason is now precise:

  the READ CLOSURE materializes the coefficients of pseudo-remainder
  sequences -- unnormalized, carrying extraneous powers of leading
  coefficients -- as members of the level above; after one round the
  y-level has 10 live members whose own chains take 15 s EACH (one symbolic
  variable), and the walk's product of them has degree 24.

So it is not one function: the certificate design (S4: "the intrinsic reads,
certified invariant on the sector") is what does not scale, because the reads
are PRS coefficients. Three ways out, in increasing scope:

  A. PER-MEMBER WALK (no product chain).  Separators isolate the roots of
     each member; a gap with roots of two members is one distinct root iff a
     Tarski query of the pair (f against g^2) says so.  Reads: per-member
     chains and pair chains of degree 3d instead of a product of degree m*d.
     Changes the trusted sepok?/gap?/wok? (22 + 8 proof expansions) and so
     re-proves walk_ok, walk_rd, walk_transfer and their clients: 2-3 days.
     Helps linear/quadratic members at 4-5 variables; the reads are still PRS
     coefficients, so the bloat remains one level down.

  B. SUBRESULTANT CERTIFICATE.  Certify the chain structure by principal
     subresultant coefficients (determinants of Sylvester submatrices --
     sylvester.pvs already has res/disc as determinants with specialization
     theorems), degree-bounded, no extraneous factors: this is Collins'
     projection, and the reads become the classical projection set. Needs the
     fundamental theorem of PRS (chain entries are subresultants up to
     factors) formalized: weeks, but it is the scalable design.

  C. NUMERIC WALK EVERYWHERE and a delineability certificate instead of reads
     (McCallum): what section 4 excluded, for the same reason as B.

Recommendation: A now (it is bounded and unblocks four variables for the
linear examples), B as the design of record for generality.

## 3g. B, concretely (2026-09-22): the reduced chain is already there

sg_chain2 (Phase 6) has Collins's REDUCED pseudo-remainder sequence
rchain2_sg: each step divides by the previous leading coefficient to the
degree-drop power, the division checked exact at run time (sturm_step2), with
   rchain2_prop   at msg(ys) it is, element by element, a POSITIVE multiple of
                  the Phase 3 chain (chprop)
   rchain2_det    it depends on the oracle only through its reads
   tq2_sg_at      the Tarski query on it is Phase 3's
It was never wired into the walk: sturm_sg's schain uses the unreduced
rchain_sg, whose coefficients carry the extraneous powers that bloat the
read closure. Sign variations, leading signs and degrees are invariant under
positive scaling of the elements, so:

  B1  sturm_sg: schain := cons(f, rchain2_sg(k, f, lderiv(f), mconst(1), 0, sg));
      schain_at (equality with fchain) becomes bridge lemmas -- length
      equality, entry-wise proportionality, entry-sign equality, leading-sign
      equality -- and the ~16 proofs that rewrote with schain_at are redone
      through them (statements unchanged).  sturm_sg2 (3), walk_transfer (1).
  B2  walk_rd: i_rd through rchain2_rd; i_det through rchain2_det.
  B3  tower_def: tchain_sg := tchain2_sg; tower_ok (tlen_at, tvar_nsc,
      tower) and cell_ok (qsec_val) through tq2_sg_at / chprop.
  B4  whole-library run; re-measure the four-variable closure: the reads are
      now reduced-sequence coefficients (subresultants up to small factors).
  B5  if the product chain of a level is still the wall, the per-member walk
      (option A) on top of B1-B4.

B5 MEASURED FIRST (2026-09-22, before proving B1-B4; the executable does not
need the proofs): with schain on the reduced chain, the eight y-level member
chains after one closure round go 122 s -> 2 s, but the reduced chain of that
level's PRODUCT (degree 21, ten live members) takes 504 s. So B1-B4 are
necessary and not sufficient: the product chain is the wall, and option A is
required. Since A re-proves the same foundation (walk_ok, walk_rd,
walk_transfer), both changes go into ONE redesign of the trusted walk:

  A+B  per-member root isolation on the REDUCED chain; a gap holding roots of
       two members is one root iff the sign of f at g's root there is zero --
       the tower query (tower_ok: proved) at a general oracle, alg_sign2 at a
       rational cell.  Reads: per-member chain reads and pair-query reads.
       Order of work: the walk definition and the new lifting statement first
       (the risk), then the mechanical re-proofs.

## 3h. After the re-proof (2026-09-23): what is left for n quantifiers

Branch s5e-redesign: the per-member walk on the reduced chain is proved end
to end (whole library 2846/2846, cad3's decw3_correct unchanged). Two facts
worth keeping from the re-proof: (i) a member of length >= 2 that is
identically zero on the fibre defeats the per-member nzat? everywhere, and
the condition excluding it (nzm?) is DERIVABLE from the certificate
(cert_nzm: live? is syntactic, slc?(bprod) makes P a nonzero polynomial), so
no executable check was added; (ii) root_near now tracks the section root
through the MEMBER that owns it (own_root), because only member chain reads
are certified. B3 (tower_def on tchain2) is unnecessary: walk_od/towern_od
never touch the tower chain.

The executable of record is towern_od's decn_o (four quantifiers certified
in 2-37 s). Its correctness is S5e-2..S5e-4 of 3d, restated on descriptors:

  S5e-2  claim A on descriptors.  den(od) = the point a descriptor denotes
         (pt, mix exact; sec(od,P,lo,hi) = cons(beta, den(od)) with beta the
         section root; sp(od,y0) = cons(y0, den(od))).  innern_sem:
           okn_o(TW, TB, od) AND agree(osg(od), msg(den(od)), RDn(TW, TB, od))
             IMPLIES (innern_o(qs, TW, TB, Psi, od) IFF sem(qs, last(TW), Psi, den(od)))
         by induction on TW.  RDn = the level's walk reads (wi_rd_t, we_rd_t;
         walk_det) + per cell the reads through osg(od) that make the cell's
         oracle right on the cell's RDn: sub1 for a separator (sg_pt_msg2),
         q_rd for a section.  NEW: q_rd / qsec_det -- the reads of one
         section query (secp: member chain reads and the counts at lo, hi;
         snorm_sg: the coefficient signs; tchain_sg: tchain_rd (exists);
         tlo/thi: the entry reads at EVERY probe, accumulated like e_rd; the
         final nzall?/cntc reads) and qsec's ok/val depend on the oracle only
         through them, in the style of walk_rd.  Then allok_agree at an
         approximate base oracle: allok?(osg(od)) AND agree on q_rd IMPLIES
         agree(osg(sec(od,..)), msg(cons(beta, den od)), R).
         DONE 2026-09-23: qsec_rd (q_rd, qsec_det, qs_det) and qsec_lift
         (allok_agree2).  Still in S5e-2: (a) towern_od's read lists
         (wi_rd_t, we_rd_t) are SUPERSETS of walk_rd's at osg(od) (each
         member itself is read for the closure; zero-at members skipped,
         which is feff): prove wi_rd(feff(F,od), osg(od)) is included in
         wi_rd_t(F, od, tb) for a valid table (agree on a superset transports
         to the subset), and the same for we_rd; (b) den(od) and the
         pointwise claim innern_sem by induction on TW, with the reads of a
         section cell RDn = qs_rd of the queries the cell's walk makes plus
         the walk's own reads; (c) the sector level: odS(s) is exact (pt or
         mix, mix_exact), so the top level is claim A at an exact oracle.
  S5e-3  many-parameter persistence and root_near (inductions on mev_cont
         and the member cnt_local).
  S5e-4  LT_k, closure everywhere (rdin_vec at every level), G_const at
         height n, decn_correct; then (cad) on decn_o for every prefix.

## 3i. The plan to finish (2026-09-27, new machine, after a full review)

**A soundness gap in the n-level certificate, found while planning the proof.**
towern_od's `cellok_o` checked `allok?` only for the queries of the walk
DIRECTLY below a section cell.  Below that walk there are more cells: a
separator under a section (`sp(sec(..), z0)`) asks the section oracle
`sub1(r, z0)` for every read r of the walk at that separator, and a section
under a section asks it every read of its own Tarski queries (`qs_rd`).  None
of those answers was certified, so at four quantifiers (an `at?` outer sector,
a section, then a separator or a section, then the bottom walk) `decn_o` could
answer ok = TRUE with a wrong value.  Also, with ONE inner family (two
quantifiers) the top walk was never checked by `wok`.  FIXED in the
executable: `okqs(od, R)` certifies every answer the oracle of `od` gives on R,
recursively down the descriptor (a section: `allok?` on R, then `okqs` of the
queries' reads `qs_rd` at the oracle below; a separator: `okqs` of `sub1_rd`
below; `pt`/`mix` exact, nothing to check); `lvok_o` = `okqs` of the level's
walk reads (`wr_t`) and `wok_t`, at EVERY level of every cell including the
top; `cellok_o` keeps only the closure (`clok?`).  Re-measured on this
machine: ALL ALL ALL EX (w > x, y, z) ok TRUE val TRUE 17 s; its control
13 s; the other four- and three-quantifier examples 0-2 s.

**The semantic core (no executables).**  Valuations are innermost first; a
tower TW = (F_1, ..., F_h), outermost first, the last one the formula's
family; `sem(qs, last(TW), Psi, ws)` with length(qs) = h.  Members that vanish
identically at a point are handled by the EFFECTIVE family
`zf(P, ws)` (members not `zero_at?` there; the executable's `feff`), the reads
`wrs(P, ws)` = all member coefficients ++ `wi_rd(zf(P, ws), msg(ws))` (what
`wi_rd_t` contains), `certz?(P, ws)` = `cert?(zf(P, ws), msg(ws))`.

    rdz?(F, P, p)  certz?(F, p) and rd_norm of every read in wrs(F, p) is a
                   member of P (the executable's clok?)
    CLF(TW, ws)    closure everywhere over ws: certz?(car(TW), ws) and, if
                   there is a next family F, for EVERY y rdz?(F, car(TW), (y, ws))
                   and CLF(cdr(TW), (y, ws))
    invz?(P, S, q, xs)  wrs(P, (q, xs)) keeps its signs on S

Three statements, proved together by strong induction on h:

    CT(h)  closure transfer: conv?(S), S(q), S(x), invz?(car TW, S, q, xs),
           CLF(TW, (q, xs))  IMPLIES  CLF(TW, (x, xs)).  Level by level: the
           level-j condition at a point depends only on the sign vector of F_j
           there (rdz_vec), and "some point over x has sign vector v" is the
           all-EX sentence with Psi = (= v) about the PREFIX tower (F_1..F_j),
           constant on S by CB(j), j < h.
    LC(h)  local constancy in MANY parameters: CLF(TW, vs0) IMPLIES there is
           d > 0 with sem(qs, last TW, Psi, vs1) IFF sem(.., vs0) for every
           vs1 coordinatewise within d of vs0 with CLF(TW, vs1) and msg(vs1)
           agreeing with msg(vs0) on wrs(car TW, vs0).  h = 1: walk_same (the
           entry reads persist, joint continuity in all coordinates).  h > 1:
           the walk of F_1 agrees near vs0 (same separators, gaps, section
           vectors); at a separator y0 LC(h-1) at (y0, vs0), at a section LC(h-1)
           at (beta0, vs0) with root_near in many parameters; the sign vector of
           F_1 at the cells agrees (walk agreement), which gives the agreement
           hypothesis one level down (rdz?).  Then the CELL VALUE LISTS at vs1
           and vs0 are equal, and each list has exactly the values of the inner
           truth over its point (cover + root-free constancy = CB(h-1) along a
           root-free interval at a FIXED point), so the quantifier agrees.
    CB(h)  constancy on a sector: conv?(S), S(q), S(a), S(b), invz?, CLF at
           (q, xs) IMPLIES sem(.., (a, xs)) IFF sem(.., (b, xs)).  loc_const
           with LC(h) at every point of S; closure there by CT(h).

**Claim A on descriptors.**  `den(od)` is the point (sections by `secbeta`, the
unique root of the gap); `wf?(od)` says every section in the descriptor is a
certified level gap at the point below it; `okqs(od, R)` and `wf?(od)` IMPLY
`agree(osg(od), msg(den(od)), R)` (induction on od: `sub1` for a separator,
`allok_agree2` for a section, `mix_exact` / `pt` exact).  Then by induction on
TW: `okn_o(TW, TB, od)`, valid tables, `wf?(od)` IMPLY
`innern_o(qs, TW, TB, Psi, od) IFF sem(qs, last(TW), Psi, den(od))` and
`CLF(TW, den(od))`.  The level's walk at `osg(od)` is the walk at
`msg(den(od))` (odreads + walk_det), each cell's descriptor denotes the cell
point and is well formed (a section over a rational point becomes a `mix`
whose value is the gap's root), the IH gives each cell's value, and a generic
CELL VALUE LIST lemma (cover + root-free constancy by CB) turns the fold into
the quantifier.  CLF at den(od): at cells from the certificate (clok?, IH), in
between by rdz_vec and CT along the root-free interval.

**Stages.**

  N1  mpar: near?, continuity of meval in all coordinates, persistence of
      finitely many signs (pz?) in many parameters
  N2  zfam: zf, wrs, certz?, rdz?, invz?; fibres with identically-zero members;
      rdz_vec; wrs/certz? determined by agreement on wrs
  N3  mwalk: the walk of zf(F, vs0) agrees at every vs1 near vs0 (wok_exist +
      N1); the fibre is locally constant (LC base); section vectors are the
      sign vectors at the roots
  N4  mroot: root_near in many parameters (own_root, ends_exist, the member
      count near vs0)
  N5  cvl: the cell value list of a level at a point and its member set
  N6  tower_sem: CLF, prefixes, the all-EX sentence, CT/LC/CB by strong
      induction on the height
  N7  oddef (rework of the draft): den, secbeta, wf?, okqs_agree, the cells'
      descriptors
  N8  innern_sem: claim A
  N9  decn_ok: the tower of a sector (length, last family), topreads -> invz?
      on the sector, per-sector correctness, the fold, decn_correct
  N10 cad_decide5: (cad) on decn_o for three or more quantifiers, decw for two,
      decide2 as the fallback; four-quantifier examples by (cad)
  N11 S6 close-out: Bath bank through (cad), benchmark table, top.pvs,
      remove scratch theories, gates, whole-library run, memory

  STATUS 2026-09-27: N1-N10 DONE, every theory gated.  decn_correct (decn_ok)
  proves decn_o correct at every prefix; (cad) runs decide5 (cad_decide5:
  decn_o for three or more quantifiers, decide4's route as the fallback) and
  proves four-quantifier sentences (cad_examples4).  towern_od's open TCCs
  are closed (secp_n now skips a member constant at the point: nroots wants a
  positive degree).
  N11 DONE: whole-library replay 3118/3118; benchmark table in PROGRESS.md;
  of the Bath bank's ten closed problems, bath_08 is proved by (cad -1)
  (cad_bath, 274 s), the other nine run past 300 s (on bath_01 the outer
  closure nclos_o alone was unfinished after 22 minutes) -- speeding up the outer
  closure is the open item; foldn_sem holds for any outer family, so the
  proof carries over.

## 4. What is deliberately NOT on the path

General delineability (`sh_count`, McCallum). It would let the SMALL
projection be used without refinement, which means fewer sectors -- a
constant-factor gain over S4, not a capability. It stays recorded as open
mathematics; nothing above waits on it.

## 5. Standing rules (unchanged)

Prove everything; small topic-scoped files; one PVS process; gate = three
fresh `proveit -f` runs plus traces; measure before proving; after each
verified item update PROGRESS.md, top.pvs, memory, commit, push.
