#!/bin/bash
# outside.sh: replays tests/outside/use_pvs_cad.pvs, which imports the library
# as cad@pvs_cad from a directory outside cad/, the way a theory of one's own
# does: (cad), (cad *), (cad-qe), a formula of any shape, and a proof that
# cites a NASALib lemma whose name the library must not hide.  Runs in a
# scratch copy (the library and the test directory side by side, the copy's
# root on PVS_LIBRARY_PATH), so it cannot clash with a pvs-cli server
# working in cad/.  Fails unless every formula is proved.
. "$(dirname "$0")/env.sh"
R="$SCRATCH/outside_$$"
trap 'rm -rf "$R"' EXIT
mkdir -p "$R"
rsync -a --exclude pvsbin --exclude '._*' "$CAD_LIB_DIR/" "$R/cad/" &&
  rsync -a --exclude pvsbin --exclude '._*' "$CAD_ROOT/tests/outside/" "$R/outside/" ||
  { echo "OUTSIDE ABORTED: cannot copy the library"; exit 1; }
cd "$R/outside" || exit 1
out="$SCRATCH/outside_$$.log"
PVS_LIBRARY_PATH="$R:$PVS_LIBRARY_PATH" "$PROVEIT" -f use_pvs_cad.pvs > "$out" 2>&1
rc=$?
line=$(grep -a "Grand Totals" "$out" | tail -1)
p=$(printf '%s' "$line" | sed -n 's/.*Grand Totals: *\([0-9]*\) proofs.*/\1/p')
s=$(printf '%s' "$line" | sed -n 's/.*, *\([0-9]*\) succeeded.*/\1/p')
echo "${line:-no Grand Totals line}"
if [ "$rc" = 0 ] && [ -n "$p" ] && [ "$p" != 0 ] && [ "$p" = "$s" ]; then
  echo "OUTSIDE PASSED"
else
  echo "OUTSIDE FAILED (log: $out)"
  exit 1
fi
