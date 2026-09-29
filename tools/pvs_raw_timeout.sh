#!/bin/bash
# Usage: pvs_raw_timeout.sh <input> <output> <timeout_seconds>
# Watchdog wrapper for `pvs -raw` since macOS lacks GNU timeout/gtimeout.
# The kill is UNCONDITIONAL (no liveness check) -- if a raw session's script
# ends while a proof is still open, PVS loops printing "No change on: (SKIP)"
# forever instead of exiting, burning CPU/disk until killed.
. "$(dirname "$0")/env.sh"
PVSBIN="$PVS"
INPUT="$1"
OUTPUT="$2"
TIMEOUT="${3:-60}"

"$PVSBIN" -raw < "$INPUT" > "$OUTPUT" 2>&1 &
PVSPID=$!

(
  sleep "$TIMEOUT"
  # kill only this session's process tree (not a running pvs-cli server)
  kids() { for c in $(pgrep -P "$1"); do kids "$c"; echo "$c"; done; }
  kill -9 $(kids "$PVSPID") "$PVSPID" 2>/dev/null
) &
WATCHDOG=$!

wait "$PVSPID" 2>/dev/null
EXIT_CODE=$?

kill "$WATCHDOG" 2>/dev/null
wait "$WATCHDOG" 2>/dev/null

echo "PVS_EXIT_CODE: $EXIT_CODE"
