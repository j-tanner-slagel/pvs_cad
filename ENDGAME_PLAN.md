# Endgame plan — (cad) builds its proof without a case explosion

Written 2026-09-28 after the overnight run of `m_cover20` (one variable, 42
atoms) exhausted the 6 GB SBCL heap: the decision answers in 0.8 s, the
proof is never built.

## 1. The cause

`cad-strategy` (cad/pvs-strategies) proves the sentence from `decide5_correct`.
After unfolding `fsem` and `bfeval` and replacing each `meval(...)` by its
polynomial, the formula from the theorem (call it B) is a Boolean combination
of leaves `sign3(P) = s`, and the goal (M) is the original matrix.  The last
step is

    (expand "sign3" !cfs) (repeat (lift-if !cfs)) (ground)
    (then (lift-if) (ground)) (then (lift-if) (ground))

Expanding `sign3` puts an IF at every leaf; lifting them all builds one term
with a branch for every combination of leaf conditions -- exponential in the
number of atoms -- before `ground` can prune.  m_cover10 (22 atoms) spends
32 s here; m_cover20 (42 atoms) runs out of memory.

## 2. The change

Make B and M share their atoms, then close B => M (or M => B, for a refuted
hypothesis) propositionally, with no case split on signs.

1. **New theory `cad_endgame`** (imported by `cad_decide5`, so every theory
   that uses (cad) has it): three rewrite lemmas
   `sign3(x) = 1 IFF x > 0`, `sign3(x) = 0 IFF x = 0`, `sign3(x) = -1 IFF x < 0`.
2. **Atom equations on the goal side.**  For each distinct atom `lhs OP rhs`
   of M the strategy knows, from the translation, its polynomial text P
   (the same text the reflection equation used) and its encoding.  It proves
   `(lhs OP rhs) = ENC` by `case` -- ENC is `sign3(P) = 0 / 1 / -1` for `= > <`,
   `sign3(P) = 1 OR sign3(P) = 0` for `>=`, `sign3(P) = -1 OR sign3(P) = 0`
   for `<=`, `NOT sign3(P) = 0` for `/=` -- by the rewrite lemmas and a small
   arithmetic step (one atom, constant size), then `replace`s it in M only.
3. **Close with `bddsimp`** on the two formulas: they are now propositional
   combinations of the same leaves, and B is the translation of M, so the
   implication is a tautology; BDDs decide it without enumerating sign cases.
4. **Keep the old endgame as the fallback.**  The new endgame runs inside
   `finalize` (it either closes the goal or changes nothing); if it does not
   close, the strategy prints `cad: case-split endgame` and runs the old
   steps unchanged.  So nothing that proves today can stop proving; the
   message makes any fallback visible in the tests below.
5. Restrict the `(assert)` steps of the fsem/bfeval unfolding to the formula
   being unfolded (`!cfs`), so that M reaches the endgame exactly as written
   and the atom equations match it.  (Only if a test shows the unrestricted
   assert changes M; otherwise leave it.)

Trusted base unchanged: the new steps are ordinary proof steps checked by PVS.

## 3. Verification

Scratch copies of the repo, so the repository's .prf files do not change
until the end.

1. **Baseline, before any change:** `proveit` on every theory with (cad)
   proofs -- cad_examples, cad_examples2, cad_examples3, cad_examples4,
   cad_bath, cad_star_ex, cad_demo -- per-proof times; plus the benchmark
   playground (cad_limits, cad_limits2, cad_limits3) under a fixed time
   limit, recording which prove and how long each takes.
2. **Gate** the new theory (`tools/gate.sh cad_endgame`) and the changed
   `cad_decide5`.
3. **After:** the same runs.  Acceptance:
   - every proof that passed before passes; nothing that was proved fails;
   - no `cad: case-split endgame` message in any run (the new endgame is
     taken everywhere), or each one explained;
   - per-proof times within noise of the baseline (about +-20% or 0.3 s on
     short proofs), with any exception explained; m_cover10 and m_cover20
     much faster;
   - the traces document's examples still give the same results.
4. **Whole library** replay: all formulas (3479 plus the new lemmas) proved.
5. PROGRESS.md, memory, commit, push.

## 4. Status

2026-09-28 (evening):

- cad_endgame (three lemmas) and cad_endgame_ex (18 tests) proved through
  pvs-cli; the strategy change is in cad/pvs-strategies.
- Development runs (raw sessions, where the fallback's message is visible;
  the pvs-cli server log does not show strategy messages): 31 proofs, zero
  fallbacks, the two FALSE sentences reported as before; m_cover10 32 s ->
  10-12 s; m_cover20 heap exhaustion -> 42 s.
- Found on the way, and fixed:
  1. a whole-sequent `assert` rewrites the goal (reorders sums, moves a
     disequality to the other side), so the atom equations stop matching.
     The unfolding's asserts now name their formulas by fresh labels -- the
     lemma formula and the two case facts -- and the goal is untouched;
     `(^ label)` does NOT mean "all but label" (it asserted only the goal).
     The fallback begins with the whole-sequent assert it used to get.
  2. bddsimp reads a real `a /= b` as its own variable, not NOT (a = b)
     (src/BDD/bdd.lisp: only boolean disequations are expanded); the
     encoding uses NOT (sign3(P) = 0) on both sides.
  3. two members with the same coefficient list (0 - x ^ 2 and
     1 - (x ^ 2 + 1)) are both replaced by the FIRST member's text, since
     its reflection equation comes first; the atom equations use that text.
- Side by side with the old strategy, same load, same session order:
  h_wilk12_gap 2.31 -> 2.07 s, h_wilk16_gap 2.96 -> 2.59, h_wilk20_gap
  4.56 -> 3.54, h_wilk20 3.49 -> 3.04, h_cheb20 5.35 -> 3.79,
  m_quad_signs 2.14 -> 2.06, d_quad_suf 3.16 -> 2.78.  (The first proof of
  a session costs about 5.7 s either way: strategy files and rewrite rules.)
- proveit's per-proof times read 0.00 s in this build, so its comparison is
  per theory (wall clock) plus pass/fail per formula.

2026-09-28 (night), results before/after (scratch copies of the repository, same machine load):

- pvs-cli timing suite, 50 lemmas of cad_limits{,2,3} with a 150 s limit: the same result for
  every lemma (48 proved, the same 2 FALSE reported); total 335.4 s -> 305.9 s.  Largest
  changes: m_cover10 36.7 -> 11.2 s, h_cheb30 14.0 -> 9.5 s, h_cheb20 5.6 -> 4.2 s,
  h_wilk20_gap 5.0 -> 3.8 s; m_cover20 (not in the baseline: heap exhaustion) 40.7 s.
- Repeated side by side (median of 3): small implications pay the atom equations,
  m_impossible 1.50 -> 1.68 s, b_disc_cubes 1.56 -> 1.67 s, b_lemniscate 1.72 -> 1.87 s;
  b_sqrt_cases 1.91 -> 1.76 s, u_wilk8 2.08 -> 2.06 s.  bath_08_false (the (cad -1)
  refutation) 6.20 -> 6.14 s.
- proveit on the seven theories with (cad) proofs: the same status for all 55 formulas.
  Per-theory wall clock is dominated by loading the library and varied with machine load
  (+-60 s either way); the side-by-side runs above are the timing evidence.
