# (cad *) -- deciding the polynomial content of a whole sequent

## Goal
`(cad)` decides ONE closed prenex formula.  In the middle of a proof the
facts are spread over the sequent, with free (skolem) constants, next to
formulas that are not about polynomials at all.  `(cad *)` collects every
usable formula of the sequent, forms

    FORALL (constants): (A1 AND ... AND An) IMPLIES (C1 OR ... OR Cm)

and decides it.  `(cad (-1 2 3))`, `(cad -)`, `(cad +)` restrict the
formulas used.

## What is usable
A sequent formula is used when it is a quantifier prefix over `real`
variables followed by a Boolean combination (AND, OR, NOT, IMPLIES, IFF,
TRUE, FALSE) of comparisons (=, /=, <, <=, >, >=) between real-valued
terms that are polynomial in the bound variables (+, -, *, ^ numeral,
/ numeral, sq, numerals).  Every other real-valued subterm that contains
no bound variable -- a constant, a skolem constant, sqrt(x), f(a, b), a
nat or int variable, length(l) -- is treated as an unknown real (one
variable per distinct term, shared between formulas).  Everything else
(predicates, non-real equalities, quantifiers under connectives, bound
variables of other types, bound variables inside non-polynomial terms) is
skipped.

## Why it is sound
Dropping an antecedent or a consequent only makes the claim stronger, and
so does replacing terms by universally quantified reals.  Nothing is
trusted: the new formula G is introduced by `case`, and PVS checks both
branches.
- G assumed: instantiate its outer variables with the abstracted terms;
  walk its quantifiers -- a universal of G comes from an EXISTS in the
  antecedent or a FORALL in the consequent: skolemize that sequent formula
  and instantiate G with the constant; an existential of G is skolemized
  and the constant instantiates the sequent formula; then the matrices
  match and propositional reasoning closes the goal.
- G to prove: `(cad)` decides it (G is closed and prenex by construction:
  an antecedent's quantifiers flip, a consequent's stay, all bound
  variables renamed apart).
Types: abstracted terms of subtypes of real carry their facts (posreal:
> 0, nonneg_real (nat, sqrt, abs): >= 0, negreal, nonpos_real, nzreal,
posnat/posint: >= 1), proved by typepred.  Integrality is NOT used: over
the reals n*n = 2 has a solution.

If G is FALSE, `(cad *)` says so and leaves the sequent unchanged (the
whole attempt is wrapped in `finalize`).

## Tests (cad_star_ex.pvs) -- planned
1. skolemized facts: x > 0, y > 0 |- x*y > 0
2. several consequents: |- x < 0, x >= 0
3. abstraction: a = sqrt(x), a*a = x, a > 1 |- x > 1
4. uninterpreted function and non-real formulas: f(x) > x^2, member(x, l),
   length(l) = 3 |- f(x) > -1 (the list formulas are skipped)
5. quantified hypothesis: FORALL (z: real): z^2 + b*z + c > 0 |- b^2 < 4*c
6. quantified goal: x > 0 |- EXISTS (y: real): y*y = x
7. alternation inside a hypothesis: FORALL (z: real): EXISTS (w: real):
   w > z + a |- a < 5 ... (and a mix of everything)
8. subtype facts: x: posreal |- x + 1 > 1; sqrt(y) >= 0 is used
9. skipped formulas: a non-prenex formula, a bound variable under g(.)
10. FALSE: x > 0 |- x > 1 -- reported, sequent unchanged
11. integrality is lost: n: nat |- n*n /= 2 -- FALSE over the reals

## Results (2026-09-28)
Implemented in cad/pvs-strategies (cadstar-* functions, cad-seq__; `(cad)`
dispatches on `*`, `+`, `-` or a list).  cad_star_ex.pvs: 15 lemmas, each
proved by `(then (skeep) (flatten))` and `(cad *)`, 1-5 s each; proveit
16/16.  Covered: facts over skolem constants, several consequents, sqrt and
an uninterpreted f as unknown reals, list formulas and a predicate skipped,
a quantified hypothesis (discriminant), a quantified goal, FORALL-EXISTS in
the goal and in a hypothesis, posreal and sqrt range facts, a bound variable
under g and a non-prenex formula skipped, IFF / NOT / division / sq, two
variables in one binding.

Expected failures, run by hand (not in the theory, since they are false):
- x > 0 |- x > 1: "cad: the sentence is FALSE", "cad*: not proved; the
  sequent is unchanged".
- n: nat, n*n = 2 |- : FALSE over the reals (integrality is not used); same
  messages, sequent unchanged.

Limit met: u^2 + v^2 = a AND u*v = b |- a >= 2b (four variables) does not
finish; neither does plain (cad) on its closed form -- the cost of the
decision, not of (cad *).  The test uses a two-variable version.

Bug found and fixed during testing: PVS types `x * y` as `numfield` (the
prelude declares the operators there), so the real-type check applies only
to the leaves that become unknown reals, not to arithmetic nodes.
