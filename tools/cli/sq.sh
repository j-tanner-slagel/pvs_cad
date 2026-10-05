#!/bin/bash
# sq.sh [cmd]: send a proof command (default (skip)) and print the FULL current sequent
. "$(dirname "$0")/../env.sh"; cd "$CAD_LIB_DIR"
"$CAD_TOOLS/pvscli.sh" --proof-command "${1:-(skip)}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | awk '/^[a-z_0-9?]+(\.[0-9T]+)* :/{p=1} p'
