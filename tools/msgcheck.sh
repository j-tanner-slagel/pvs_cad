#!/bin/bash
# msgcheck.sh: checks what (cad), (cad *), (cad-num), (cad-qe) and qe-exists
# say when they do not prove a formula (FALSE reports, refusals, hints, the
# label cad on the formula that stays).  The inputs are cad/cad_msg_ex.pvs,
# which is not in top.pvs; each check starts a proof on the running pvs-cli
# server (tools/cli/srv.sh), runs one command, looks for the expected texts
# in what it prints, and quits the proof without saving it.
#
# Each check below: theory | formula | command | text | text ...
# Prints PASS or FAIL per check, then the count; exits 1 if any failed.
. "$(dirname "$0")/env.sh"
cd "$CAD_LIB_DIR" || exit 1
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
cad_msg_ex | m_qe_nat     | (qe-exists -1)             | qe-exists: formula -1 is not a quantified formula in one real variable
cad_msg_pc | m_hint       | (cad)                      | cad: pi is a constant that interval arithmetic can enclose between two rationals | {1, cad}
cad_msg_d5 | m_shape      | (cad)                      | has quantifiers inside its connectives; formulas of any shape need IMPORTING pvs_cad
cad_msg_qe | m_nodec      | (cad)                      | cad: this theory does not import cad_decide5, the decision (cad) uses here
EOF
rm -f "$OUT"
echo "msgcheck: $((n - fails)) of $n passed"
[ "$fails" = 0 ]
