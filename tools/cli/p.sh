#!/bin/bash
# p.sh <command> [tail]: send one proof command
. "$(dirname "$0")/../env.sh"; cd "$CAD_WORK_DIR"
"$CAD_PY" "$CAD_TOOLS/pc.py" -t 600 "$1" 2>&1 | tail -${2:-12}
