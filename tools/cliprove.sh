#!/bin/bash
# cliprove.sh <file> <theory> <cmds-file>
# Proves formulas on the running pvs-cli server (tools/pvscli.sh). The cmds
# file has lines "<formula> <one prover command>" (blank lines and # ignored).
# Each formula: --prove, then the command. Prints QED or OPEN per formula; an
# OPEN proof is abandoned (--quit-all-proofs) with its first open sequent
# written to $SCRATCH/<theory>_<formula>.seq so the batch can continue.
. "$(dirname "$0")/env.sh"
CLI="$CAD_TOOLS/pvscli.sh"
FILE=$1; T=$2; CMDS=$3
grep -v '^\s*#' "$CMDS" | grep -v '^\s*$' | while IFS= read -r line; do
  F=${line%% *}; C=${line#* }
  OUT="$SCRATCH/${T}_$F.out"
  "$CLI" --prove "$FILE#$T#$F" > "$OUT" 2>&1
  "$CAD_PY" "$CAD_TOOLS/pc.py" -t "${PC_TIMEOUT:-300}" "$C" >> "$OUT" 2>&1
  if grep -aq "Q.E.D" "$OUT"; then st=QED
  else
    st=OPEN
    "$CLI" --proof-command "(skip)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > "$SCRATCH/${T}_$F.seq"
    "$CLI" --quit-all-proofs > /dev/null 2>&1
  fi
  printf '%-28s %s\n' "$F" "$st"
done
