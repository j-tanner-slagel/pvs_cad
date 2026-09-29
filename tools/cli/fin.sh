#!/bin/bash
# fin.sh <tailfile>: keep applying the tail tactic until the proof finishes
. "$(dirname "$0")/../env.sh"; cd "$CAD_LIB_DIR"
for i in 1 2 3 4 5 6; do
  R=$("$CAD_PY" "$CAD_TOOLS/pc.py" -t 600 "$(cat $1)" 2>&1 | tail -3)
  case "$R" in *Q.E.D.*) echo "QED"; exit 0;; *"No active proof"*) echo "QED (session closed)"; exit 0;; esac
done
echo "NOT FINISHED:"; "$CAD_PY" "$CAD_TOOLS/pc.py" -t 300 '(assert)' 2>&1 | tail -12
