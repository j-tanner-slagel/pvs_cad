#!/bin/bash
# ev.sh <expr> [lines]: evaluate a ground expression in the active proof session; show formula -1 and the time
. "$(dirname "$0")/../env.sh"; cd "$CAD_LIB_DIR"
S=$(date +%s)
"$CAD_PY" "$CAD_TOOLS/pc.py" -t 1800 "(eval-expr \"$1\")" 2>&1 > $SCRATCH/ev.out
awk '/^\{-1\}/{p=1} /^\{-2\}/{p=0} /^  \|---/{p=0} p' $SCRATCH/ev.out | head -${2:-6}
echo "  [$(( $(date +%s) - S )) s]"
