#!/bin/bash
# replay.sh [--traces]: replays the whole library and its examples with proveit -a, in a fresh
# copy ($SCRATCH/replay_<pid>/cad), so a pvs-cli server working in cad/ is not disturbed and the
# working tree never changes: first cad/top.pvs (the library), then cad/examples/top.pvs (the
# examples, which import the library as cad@...; the copy's parent directory is first on
# PVS_LIBRARY_PATH, so they import the copy).  Before the runs, prflint.py checks the .prf files
# (each formula has exactly one proof; no proof contains POSTPONE); after each run, the checks of
# proveit_check.sh, and that no .prf entry names a formula the replay does not have.  With
# --traces the runs use -l --traces and also fail on any "has fewer subproofs" / "has fewer
# subgoals" warning in proveit's full logs.  Prints REPLAY PASSED or REPLAY FAILED with the
# totals and the wall time.  The copy stays; its two top.summary files are what stats.py reads.
. "$(dirname "$0")/env.sh"
. "$CAD_TOOLS/proveit_check.sh"
TRACES=0; [ "$1" = --traces ] && TRACES=1
R="$SCRATCH/replay_$$"; DIR="$R/cad"
mkdir -p "$R"
rsync -a --delete --exclude pvsbin --exclude '._*' --exclude orphaned-proofs.prf \
  --exclude '*.log' --exclude '*.summary' "$CAD_LIB_DIR/" "$DIR/" ||
  { echo "REPLAY ABORTED: cannot copy $CAD_LIB_DIR"; exit 1; }
export PVS_LIBRARY_PATH="$R:$PVS_LIBRARY_PATH"
ok=1
for d in "$DIR" "$DIR/examples"; do python3 "$CAD_TOOLS/prflint.py" "$d" || ok=0; done
start=$(date +%s)
# run <dir> <label>: proveit -a top.pvs in <dir>, then the checks
run() {
  cd "$1" || { echo "  !! cannot cd to $1"; ok=0; return; }
  local out="$1/replay.out" rc n
  if [ "$TRACES" = 1 ]; then "$PROVEIT" -l --traces -a top.pvs > "$out" 2>&1; rc=$?
  else "$PROVEIT" -a top.pvs > "$out" 2>&1; rc=$?; fi
  check "$out" "$rc" || ok=0
  if [ "$TRACES" = 1 ]; then
    if [ -f top.log ]; then
      n=$(grep -ac "has fewer sub" top.log)
      echo "$2: fewer-subproofs warnings: $n"
      [ "$n" = 0 ] || { grep -a "has fewer sub" top.log | head -5 | sed 's/^/  !! /'; ok=0; }
    else
      echo "  !! $2: the traces run wrote no top.log, so its warnings cannot be read"; ok=0
    fi
  fi
  if [ -f top.summary ]; then python3 "$CAD_TOOLS/prflint.py" "$1" --summary top.summary || ok=0
  else echo "  !! $2: no top.summary"; ok=0; fi
  echo "$2: $(grep -a 'Grand Totals' "$out" | tail -1)"
}
run "$DIR" library
run "$DIR/examples" examples
secs=$(( $(date +%s) - start ))
echo "wall ${secs} s  (copy: $R)"
[ "$ok" = 1 ] && echo "REPLAY PASSED" || { echo "REPLAY FAILED"; exit 1; }
