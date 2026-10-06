#!/bin/bash
# msgcheck.sh: checks what (cad), (cad *), (cad-num) and (cad-qe)
# say when they do not prove a formula (FALSE reports, refusals, hints, the
# label cad on the formula that stays).  The inputs are tests/msg/cad_msg_ex.pvs,
# which imports the library as cad@...  It runs in a scratch copy (the library
# as cad/ and the inputs as msg/ side by side) on a pvs-cli server of its own
# ($MSG_PORT, default 23459), so it cannot disturb a server working in cad/;
# each check starts a proof, runs one command, looks for the expected texts in
# what it prints, and quits the proof.  The copy and the server go at the end.
#
# Each check below: theory | formula | command | text | text ...
# Then the :cad-only? checks (formula | command | same or more: the count of witness searches).
# Prints PASS or FAIL per check, then the count; exits 1 if any failed.
. "$(dirname "$0")/env.sh"
R="$SCRATCH/msgcheck_$$"
mkdir -p "$R"
rsync -a --exclude pvsbin --exclude '._*' --exclude '*.log' --exclude '*.summary' \
  "$CAD_LIB_DIR/" "$R/cad/" && rsync -a --exclude pvsbin "$CAD_ROOT/tests/msg/" "$R/msg/" ||
  { echo "MSGCHECK ABORTED: cannot copy the library"; exit 1; }
export CAD_LIB_DIR="$R/cad" CAD_WORK_DIR="$R/msg" PVS_PORT=${MSG_PORT:-23459}
export PVS_LIBRARY_PATH="$R:$PVS_LIBRARY_PATH"
trap '"$CAD_TOOLS/cli/srv.sh" --stop > /dev/null 2>&1; rm -rf "$R"' EXIT
"$CAD_TOOLS/cli/srv.sh" cad_msg_ex > "$R/srv.out" 2>&1
grep -q 'cad_msg_ex typechecked' "$R/srv.out" ||
  { echo "MSGCHECK ABORTED: cad_msg_ex did not typecheck"; cat "$R/srv.out"; exit 1; }
cd "$R/msg" || exit 1
CLI="$CAD_TOOLS/pvscli.sh"
OUT="$SCRATCH/msgcheck_$$.out"
fails=0; n=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  IFS='|' read -r -a f <<< "$line"
  thy=$(echo "${f[0]}" | xargs); fml=$(echo "${f[1]}" | xargs); cmd=$(echo "${f[2]}" | sed 's/^ *//; s/ *$//')
  n=$((n + 1))
  "$CLI" --quit-all-proofs > /dev/null 2>&1
  "$CLI" --prove "cad_msg_ex#$thy#$fml" > "$OUT" 2>&1
  pid=$(sed -n 's/.*Proof ID: *\([^ ]*\).*/\1/p' "$OUT" | head -1)
  "$CAD_PY" "$CAD_TOOLS/pc.py" -t "${PC_TIMEOUT:-300}" "$cmd" >> "$OUT" 2>&1
  missing=""
  for ((i = 3; i < ${#f[@]}; i++)); do
    t=$(echo "${f[$i]}" | sed 's/^ *//; s/ *$//')
    [ -z "$t" ] && continue
    grep -qF -- "$t" "$OUT" || missing="$missing [$t]"
  done
  [ -n "$pid" ] && "$CLI" --fail-proof "$pid" > /dev/null 2>&1
  if [ -z "$missing" ]; then printf 'PASS  %-12s %s\n' "$fml" "$cmd"
  else printf 'FAIL  %-12s %s  missing:%s\n' "$fml" "$cmd" "$missing"; fails=$((fails + 1)); cp "$OUT" "$SCRATCH/msgcheck_$fml.out"; fi
done <<'EOF'
cad_msg_ex | m_false      | (cad)                      | cad: the sentence is FALSE; it stays as it is, labelled cad | {1, cad}
cad_msg_ex | m_true_hyp   | (then (flatten) (cad -1))  | cad: the sentence is TRUE; it stays as it is, labelled cad | {-1, cad}
cad_msg_ex | m_gen_false  | (cad)                      | cad: the formula is FALSE; it stays as it is, labelled cad | {1, cad}
cad_msg_ex | m_star       | (then (skeep) (cad *))     | cad*: not proved; the sequent is unchanged
cad_msg_ex | m_pi_false   | (cad)                      | cad-num: with 3 decimals the goal is FALSE wherever the hypotheses hold | {1, cad}
cad_msg_ex | m_pi_prec    | (cad)                      | cad-num: not decided at the highest precision tried | {1, cad}
cad_msg_ex | m_nat        | (cad)                      | cad: formula 1 is not a first-order formula over the reals whose atoms compare polynomials
cad_msg_ex | m_qe_closed  | (cad-qe)                   | cad-qe: formula 1 has no free real term to keep; (cad) decides it
cad_msg_ex | m_qe_closed2 | (cad-qe)                   | cad-qe: formula 1 has no free real term to keep; (cad) decides it
cad_msg_ex | m_t5_bound   | (cad)                      | cad: formula 1 applies sin, cos, tan, atan, exp or ln to variables bound inside it (sin(x))
cad_msg_ex | m_t5_false   | (cad)                      | cad-num: for x in [1/2, 33/64] the goal is FALSE wherever the hypotheses hold | labelled cad
cad_msg_ex | m_sqrt_false | (cad)                      | cad-num: the goal is FALSE wherever the hypotheses hold | {1, cad}
cad_msg_ex | m_t4_false   | (cad)                      | cad: the formula is FALSE; it stays as it is, labelled cad | {1, cad}
cad_msg_ex | m_one        | (cad 5)                    | cad: there is no formula 5
cad_msg_pc | m_hint       | (cad)                      | cad: pi is a constant that interval arithmetic can enclose between two rationals | {1, cad}
cad_msg_d8 | m_shape      | (cad)                      | has quantifiers inside its connectives; formulas of any shape need IMPORTING pvs_cad
cad_msg_d8 | m_noqe       | (cad-qe)                   | cad-qe: this theory does not import qe8, the elimination (cad-qe) uses
cad_msg_qe | m_nodec      | (cad)                      | cad: this theory does not import cad_decide8, the decision (cad) uses here
EOF
# :cad-only? t keeps the witness search out of every decision, the side decisions included
# (the TCCs of the readings and of the exact facts): the strategies count the witness searches
# they start (*cadw-plans*), and under :cad-only? t the count must not grow.  The last row is the
# control: plain (cad) on the same formula does start the search.  These proofs close; PVS saves
# them in the copy, which goes at the end.
plans() { "$CLI" --lisp '(format nil "~a" (if (boundp (quote *cadw-plans*)) *cadw-plans* 0))' 2>&1 | sed -n 's/.*"\([0-9]*\)".*/\1/p' | tail -1; }
while IFS='|' read -r fml cmd want; do
  fml=$(echo "$fml" | xargs); cmd=$(echo "$cmd" | sed 's/^ *//; s/ *$//'); want=$(echo "$want" | xargs)
  n=$((n + 1))
  "$CLI" --quit-all-proofs > /dev/null 2>&1
  "$CLI" --prove "cad_msg_ex#cad_msg_ex#$fml" > "$OUT" 2>&1
  pid=$(sed -n 's/.*Proof ID: *\([^ ]*\).*/\1/p' "$OUT" | head -1)
  b=$(plans)
  "$CAD_PY" "$CAD_TOOLS/pc.py" -t "${PC_TIMEOUT:-300}" "$cmd" >> "$OUT" 2>&1
  a=$(plans)
  [ -n "$pid" ] && "$CLI" --fail-proof "$pid" > /dev/null 2>&1
  if [ "$want" = same ] && [ -n "$a" ] && [ "$a" = "$b" ] || { [ "$want" = more ] && [ -n "$a" ] && [ "$a" -gt "${b:-0}" ]; }; then
    printf 'PASS  %-12s %s  (witness searches: %s -> %s)\n' "$fml" "$cmd" "${b:-?}" "${a:-?}"
  else
    printf 'FAIL  %-12s %s  (witness searches: %s -> %s, expected %s)\n' "$fml" "$cmd" "${b:-?}" "${a:-?}" "$want"
    fails=$((fails + 1)); cp "$OUT" "$SCRATCH/msgcheck_$fml.out"
  fi
done <<'EOF2'
m_only_main | (cad :cad-only? t)                       | same
m_only_sqrt | (cad :cad-only? t)                       | same
m_only_star | (then (skeep) (cad * :cad-only? t))      | same
m_only_num  | (cad-num :cad-only? t)                   | same
m_only_sqrt | (cad)                                    | more
EOF2
rm -f "$OUT"
echo "msgcheck: $((n - fails)) of $n passed"
[ "$fails" = 0 ]
