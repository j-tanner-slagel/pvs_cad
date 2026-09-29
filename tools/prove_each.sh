#!/bin/bash
# prove_each.sh <theory> <cmds-file>
# The cmds file has lines "<formula> <one prover command>" (blank lines and # ignored).
# Each formula is proved in its own raw pvs session (so an open proof cannot swallow
# later commands), and the proof is saved with save-all-proofs immediately.
# Prints one status line per formula: QED, OPEN, or ERROR.
. "$(dirname "$0")/env.sh"; DIR=$CAD_LIB_DIR
TOOLS=$(cd "$(dirname "$0")" && pwd)
T=$1; CMDS=$2
grep -v '^\s*#' "$CMDS" | grep -v '^\s*$' | while IFS= read -r line; do
  F=${line%% *}; C=${line#* }
  IN="$SCRATCH/${T}_$F.in"; OUT="$SCRATCH/${T}_$F.out"
  { printf '(setq *proceed-without-asking* t)\n(change-context "%s")\n(typecheck-file "%s")\n' "$DIR" "$T"
    printf '(prove-formula (quote (("theory" . "%s") ("formula" . "%s"))))\n' "$T" "$F"
    printf '%s\n(postpone)\n(postpone)\n(save-all-proofs (get-theory "%s") t)\n(quit)\ny\n(bye)\n' "$C" "$T"; } > "$IN"
  bash "$TOOLS/pvs_raw_timeout.sh" "$IN" "$OUT" "${PVS_TIMEOUT:-300}" > /dev/null
  if grep -aq "Q.E.D" "$OUT"; then st=QED
  elif grep -aq "Postponing" "$OUT"; then st=OPEN
  else st=ERROR; fi
  printf '%-24s %s\n' "$F" "$st"
done
