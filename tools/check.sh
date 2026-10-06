#!/bin/bash
# check.sh <theory or file.pvs> ...: proves what a change touches, once.  affected.py lists the
# given theories and every theory that imports one of them, directly or not: those of the
# library (cad/top.pvs) and those of the examples (cad/examples/top.pvs).  One proveit session
# proves the library's list (proveit -l --traces @thy1,...) and one the examples' list, so the
# rest of the library is loaded, not proved again.  It runs in $SCRATCH/check_tree/cad, a copy of
# cad/ that keeps its compiled theories between runs (only the changed ones are typechecked
# again), so a pvs-cli server in cad/ is not disturbed.  The checks are proveit_check.sh's and no
# "has fewer subproofs" / "has fewer subgoals" warning in the traces.  Prints CHECK PASSED or
# CHECK FAILED with the totals and the wall time.
. "$(dirname "$0")/env.sh"
. "$CAD_TOOLS/proveit_check.sh"
LISTS=$(python3 "$CAD_TOOLS/affected.py" "$@") || exit 1
LIBL=$(printf '%s\n' "$LISTS" | sed -n 1p); EXL=$(printf '%s\n' "$LISTS" | sed -n 2p)
[ -n "$LIBL$EXL" ] || { echo "check.sh: nothing in top.pvs or examples/top.pvs depends on $*"; exit 0; }
R="$SCRATCH/check_tree"; DIR="$R/cad"
mkdir -p "$DIR"
# --delete leaves the excluded pvsbin directories alone: the compiled theories stay
rsync -a --delete --exclude pvsbin --exclude '._*' --exclude orphaned-proofs.prf \
  --exclude '*.log' --exclude '*.summary' "$CAD_LIB_DIR/" "$DIR/" ||
  { echo "CHECK ABORTED: cannot copy $CAD_LIB_DIR"; exit 1; }
export PVS_LIBRARY_PATH="$R:$PVS_LIBRARY_PATH"
ok=1
start=$(date +%s)
# run <dir> <list> <label>: one proveit session on the list, in <dir>
run() {
  [ -n "$2" ] || return
  cd "$1" || { echo "  !! cannot cd to $1"; ok=0; return; }
  echo "check.sh: proving $(printf '%s\n' "$2" | tr ',' '\n' | wc -l | tr -d ' ') theories of the $3: $2"
  rm -f check.log check.summary
  local out="$1/check.out" rc w
  "$PROVEIT" -l --traces -o check "@$2" > "$out" 2>&1; rc=$?
  check "$out" "$rc" || ok=0
  if [ -f check.log ]; then
    w=$(grep -ac "has fewer sub" check.log)
    [ "$w" = 0 ] || { grep -a "has fewer sub" check.log | head -5 | sed 's/^/  !! /'; ok=0; }
  else
    echo "  !! no check.log in $1, so the traces cannot be read"; ok=0
  fi
  echo "$3: $(grep -a 'Grand Totals' "$out" | tail -1)"
}
run "$DIR" "$LIBL" library
run "$DIR/examples" "$EXL" examples
secs=$(( $(date +%s) - start ))
echo "wall ${secs} s"
[ "$ok" = 1 ] && echo "CHECK PASSED" || { echo "CHECK FAILED (logs: $DIR/check.log, $DIR/examples/check.log)"; exit 1; }
