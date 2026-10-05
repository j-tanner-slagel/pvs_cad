# Constants and algebraic operators in (cad)

*2026-10-02. The user: "Do P1 through P3 and then the pi strategy. It really should work for
whatever the interval arithmetic library can handle. And then also with the square root operators
and such I like turning that into algebraic equations." Order of work: PROJ_PLAN.md P1 → P2 → P3,
then this plan, T1 → T2 → T3 → T4 (T5 optional).*

**Status (2026-10-03).**
- **T1:** done in a simpler form than designed. The facts are proved hypotheses added to the sequent
  before the decision, and `(cad *)` already reads every hypothesis (`cad-num`, `cad-facts`). No
  fact list is threaded through G or through the general route.
- **T2:** done (`cad-num`; `(cad)` falls back to it).
- **T3:** done for sqrt, abs, max, min and quotients by a non-number. n-th roots and the quadratic
  roots of `reals@quadratic` are not done.
- **T4:** done for sqrt, abs, max, min and quotients, as in section 1a, in any order and
  nesting. abs, max and min are expanded and split at once when their cases hold no sqrt or
  quotient, and case by case otherwise (sqrt(abs(x))).
- **T5:** done (2026-10-03), as planned in NEXT_PLAN.md section 2, with three changes
  (cad/PROGRESS.md): the pieces are decided each in its own branch rather than as one tube; the
  pieces use one precision (the first of PRECISIONS) instead of a rising one, since halving is
  what tightens their enclosures; and the ranges of sin, cos and atan come before the bounds of
  degree 3, as their own rung. sin, cos, exp, ln and atan of terms with constants of the sequent
  get trans_bounds's bounds, then enclosures over pieces of the ranges the hypotheses give; a
  goal's leading FORALL is skolemized first.
- **Tests:** `cad/cad_terms_ex.pvs`, 66 lemmas; the examples are there, not in cad_showcase.

## 0. Where we start

- `(cad *)` (cadstar) and the general route (cadg) turn every real term that does not mention a
  bound variable into an unknown, universally quantified, carrying only the comparisons with
  numbers that its type gives (pi gets 2 < pi < 4, sqrt(c) gets ≥ 0). A term that mentions a bound
  variable outside + − × ^, sq and division by a number is refused.
- **Tested by hand on 2026-10-02 (scratch theory):**
  - with NASALib's proved bound 3.1405 < pi < 3.1833 as a hypothesis, `(cad *)` proves
    FORALL x: x² − pi·x + 3 > 0 and EXISTS x: x² = pi;
  - pi² < 10 and pi² < 9.87 are FALSE somewhere in that interval, so `(cad)` says so and changes
    nothing;
  - with the tighter bound 3.1415926 < pi < 3.1415927 both are proved.
  - So the idea works; what is missing is doing it automatically, for every expression the
    interval library handles, with refinement, and exact equations for algebraic operators.
- **NASALib interval_arith** (`numerical`, `interval`) encloses ground expressions built from
  rationals, + − × / ^, sq, abs, sqrt, pi, e, exp, ln, sin, cos, tan and atan, with a precision
  argument. **NASALib reals** has `sqrt_def` (sqrt(t)·sqrt(t) = t), the abs and min/max
  definitions, n-th roots (reals@root, power@nn_root) and the quadratic-formula roots
  (reals@quadratic).

## 1. Design

**T1. Facts about unknowns (the common mechanism).**
- Today each unknown carries *type facts*, proved by `typepred`. Generalize this to a list of
  facts per unknown, each with its own proof step:
  - type facts, as now;
  - *algebraic facts*: exact polynomial equations and comparisons, proved from NASALib lemmas
    (T3);
  - *interval facts*: lb ≤ t ≤ ub with rational lb and ub, proved by NASALib interval
    arithmetic (T2).
- Both routes take them:
  - in cadstar they join the hypotheses of the sentence G, and the use-steps prove each one when
    the unknown is instantiated by its term;
  - in cadg they generalize the guard mechanism (`cadg-guard-steps`), which today handles only
    "u op number".
- Nothing new is trusted: every fact is a PVS-proved formula about the actual term.

**T2. Constants by interval arithmetic (the pi strategy).**
- **Which terms:** an unknown whose term is *ground* (no free variables or Skolem constants)
  and built only from what interval_arith evaluates.
- **The fact:** an enclosure lb ≤ t ≤ ub obtained with `numerical` at precision k (or bounds
  proved by `interval`), turned into a fact with rational bounds.
- **Refinement:**
  1. Decide G with the facts.
  2. If G is FALSE, decide the sentence with the matrix negated on the same intervals. If that
     holds, the statement is FALSE at the constant: report it and stop.
  3. Otherwise the interval straddles a critical value: raise k and retry, up to a budget
     (default to be measured; precision is cheap, bignum size is not).
- **Termination:**
  - With one transcendental constant (pi, e, ln 2, sin 1, …) this always stops. After the
    quantifiers are eliminated, the truth of the sentence as a function of the constant changes
    only at finitely many algebraic numbers, and a transcendental number is none of them
    (Lindemann for pi and e).
  - With two or more constants it may not stop (whether p(pi, e) = 0 for some p is open), but it
    is sound whenever it answers.
- **What is not covered:** an algebraic constant such as sqrt(2) gets its exact equation (T3)
  instead, since an interval can never settle sqrt(2)² = 2.

**T3. Algebraic operators as equations (exact).** For an unknown whose term is:

| term | fact | source |
|---|---|---|
| sqrt(t) | s ≥ 0 ∧ s·s = t | `sqrt_def` and the type |
| abs(t) | a ≥ 0 ∧ (a = t ∨ a = −t) | `abs` definition |
| max(a, b), min(a, b) | m ≥ a ∧ m ≥ b ∧ (m = a ∨ m = b) (and dually) | prelude `max`, `min` |
| t / u (u not a number) | q·u = t | u ≠ 0 from u's type |
| n-th root (if defined in reals@root or power@nn_root) | r^n = t ∧ r ≥ 0 | its definition |
| quadratic root(a, b, c, eps) | a·r² + b·r + c = 0, plus which root (eps) | reals@quadratic |

- t, u, a and b are themselves read by cadstar-term, so nested terms are abstracted from the inside
  out: sqrt(1 + sqrt(2)) gives s1² = 2 and s2² = 1 + s1.
- With these facts the decision is exact, so `(cad)` is complete on such terms, not only
  sound.

**T4. Algebraic operators under binders.**
- **The example:** FORALL x: sqrt(x² + 1) > x, where the term mentions the bound x, so it cannot
  be an unknown.
- **The construction:** introduce a new variable s quantified right inside x's binder, with the
  defining condition: FORALL x: FORALL s: (s ≥ 0 ∧ s² = x² + 1) ⇒ s > x.
- **Why that is enough:** s is unique, so this is equivalent in either polarity. For a universal
  position the proof instantiates s with the term. For an existential position it skolemizes s
  and uses uniqueness (s ≥ 0 ∧ s² = t ⇒ s = sqrt(t)).
- **What changes:**
  - cadstar's sentence construction and use-steps;
  - the general route's mirror walk (a new node kind, "defined variable").
- **Risk:** the design risk is the highest of the four. It gets its own sub-plan after T3, once
  the fact mechanism exists.

**T5 (optional). Transcendental terms with free constants.**
- **The example:** sin(c), where the sequent bounds c, say 0 ≤ c ≤ 1.
- **The fact:** `numerical` with the variable ranges taken from the sequent encloses the term,
  which gives a sound but weaker fact.
- **Refinement** splits c's range (branch and bound across several `(cad)` calls).
- **Out of scope:** transcendental functions of *bound* variables (sin x under FORALL x). That is
  MetiTarski's territory (polynomial bounds for sin, exp, ln as functions), with much higher
  degrees.

## 1a. T4 sub-plan (after T3)

**Problem:** `FORALL x: sqrt(x^2 + 1) > x`. The term mentions the bound x, so it cannot be an
unknown.

**Atom rewriting.** An atom P(op(...)) whose term mentions bound variables is read, inside the
general route's formula reader (cadg-tree), as an equivalent formula with no such term:
- sqrt(t): P(sqrt(t)) becomes `FORALL s: (s >= 0 AND s * s = t) IMPLIES P(s)`, which is valid where
  t >= 0, and that is where sqrt(t) is defined (its TCC).
- t / u: P(t / u) becomes `FORALL q: q * u = t IMPLIES P(q)`, valid where u /= 0.
- abs(t): P(abs(t)) becomes `(t >= 0 AND P(t)) OR (t < 0 AND P(-t))`, with no new variable; max and
  min likewise.

**Why it fits.**
- The result is a formula of a shape the general route already decides: quantifiers inside
  connectives (FORMS_PLAN.md).
- No new datatype node, and no change to decide_g or its proof.

**What changes: the bridge in the proof walk (cadg-walk).**
- At a rewritten sqrt atom whose mirror is a goal, s is instantiated with the term itself.
  typepred gives s >= 0 and s * s = t, and P(s) is the original atom.
- Where the mirror is a hypothesis, s is skolemized. NASALib's sqrt_lem (sqrt(y) = z iff z * z = y,
  for nonnegative y and z) gives s = sqrt(t), and the atom follows by replacement.
- Quotients work the same way, with u /= 0 from the term's TCC context.
- abs, max and min are expanded and split on the condition (no new variable).

**Size and risk.**
- Strategy code only, plus at most one or two small lemmas: about a day.
- Risk: the walk's bookkeeping of which side each piece is on, the same as for FORMS_PLAN's F3.

**Tests:** `cad_terms_ex`, part 2: sqrt(x^2 + 1) > x, |x| >= x, max(x, y) >= x,
x / (x^2 + 1) <= 1/2, in both polarities and under each quantifier.

## 2. Tests, gates, documentation

- **A new regression theory, cad_terms_ex,** with every operator in both polarities, in both
  routes and in both kinds of command:
  - T2: pi, e, ln 2, sin 1 and sqrt(2) + pi;
  - refinement cases (pi² < 9.87) and FALSE cases (pi² > 10);
  - a budget exhaustion with two constants;
  - T3: nested roots, division, abs, max/min.
  - It is gated like cad_forms_ex. Showcase examples are added to cad_showcase.
- **The strategy-using theories are re-proved after each stage:** cad_showcase, cad_forms_ex,
  the example theories, and the whole-library replay at the end.
- **Documentation:** README ("Using it"), cad_overview (command table) and the help texts.

## 3. Estimates (Collins pace: about 47 formulas an hour; mostly strategy code here)

| stage | days | notes |
|---|---|---|
| T1 facts mechanism | 0.5 | cadstar and cadg |
| T2 constants by intervals, refinement, FALSE detection | 1 | plus measuring `numerical`'s cost |
| T3 algebraic facts (ground) | 0.5–1 | sqrt, abs, max/min, division, roots |
| T4 algebraic terms under binders | 1–2 | own sub-plan first |
| T5 ranges for transcendental terms (optional) | 0.5–1 | |

## 4. Decisions for the user (defaults chosen; change any)

1. **Precision budget for T2:** start at 2–3 decimals and stop after about 12. This is to be
   measured, because larger rationals make the CAD's root isolation slower. [As built: 3, 6, 10,
   16 and 24 decimals.]
2. **`(cad-qe)` with a constant:** keep the constant symbolic in the answer (the answer holds
   for the actual constant), rather than replacing it by an interval.
3. **The order T1 → T2 → T3 → T4**, as asked: pi first, then the equations.
