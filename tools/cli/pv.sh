#!/bin/bash
# pv.sh <theory> <formula> <command>  : start the proof, run the command, show the tail
. "$(dirname "$0")/../env.sh"; cd "$CAD_WORK_DIR"
"$CAD_TOOLS/pvscli.sh" --quit-all-proofs >/dev/null 2>&1
"$CAD_TOOLS/pvscli.sh" --prove "$1#$1#$2" 2>&1 | tail -1
"$CAD_PY" "$CAD_TOOLS/pc.py" -t 600 "$3" 2>&1 | tail -${4:-6}
