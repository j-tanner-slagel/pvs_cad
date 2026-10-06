#!/bin/bash
# outside.sh: replays the theories in tests/ that import the library as cad@... from a directory
# outside cad/, the way a theory of one's own does: tests/outside/use_pvs_cad.pvs ((cad),
# (cad *), (cad-qe), a formula of any shape, and a proof that cites a NASALib lemma whose name
# the library must not hide) and tests/bath/cad_bath.pvs (problems of the Bath CAD example
# bank, kept outside the library because of their license).  Runs in a scratch copy (the
# library and the test directories side by side, the copy's root on PVS_LIBRARY_PATH), so it
# cannot clash with a pvs-cli server working in cad/.  Fails unless every formula is proved.
. "$(dirname "$0")/env.sh"
R="$SCRATCH/outside_$$"
trap 'rm -rf "$R"' EXIT
mkdir -p "$R"
rsync -a --exclude pvsbin --exclude '._*' --exclude '*.log' --exclude '*.summary' \
  "$CAD_LIB_DIR/" "$R/cad/" &&
  rsync -a --exclude pvsbin --exclude '._*' "$CAD_ROOT/tests/outside/" "$R/outside/" &&
  rsync -a --exclude pvsbin --exclude '._*' "$CAD_ROOT/tests/bath/" "$R/bath/" ||
  { echo "OUTSIDE ABORTED: cannot copy the library"; exit 1; }
export PVS_LIBRARY_PATH="$R:$PVS_LIBRARY_PATH"
ok=1
# run <dir> <file>: proveit -f on the file, then the totals
run() {
  cd "$R/$1" || { echo "  !! cannot cd to $R/$1"; ok=0; return; }
  local out="$SCRATCH/outside_$$_$1.log" rc line p s
  "$PROVEIT" -f "$2" > "$out" 2>&1; rc=$?
  line=$(grep -a "Grand Totals" "$out" | tail -1)
  p=$(printf '%s' "$line" | sed -n 's/.*Grand Totals: *\([0-9]*\) proofs.*/\1/p')
  s=$(printf '%s' "$line" | sed -n 's/.*, *\([0-9]*\) succeeded.*/\1/p')
  echo "$1/$2: ${line:-no Grand Totals line}"
  if [ "$rc" != 0 ] || [ -z "$p" ] || [ "$p" = 0 ] || [ "$p" != "$s" ]; then
    echo "  !! not every formula is proved (log: $out)"; ok=0
  fi
}
run outside use_pvs_cad.pvs
run bath cad_bath.pvs
[ "$ok" = 1 ] && echo "OUTSIDE PASSED" || { echo "OUTSIDE FAILED"; exit 1; }
