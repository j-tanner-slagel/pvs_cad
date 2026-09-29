#!/bin/bash
# gate.sh <file> [...]   verification gate: three fresh proveit -f runs plus a
# traces run.  Runs one PVS at a time.
#
# A run FAILS on any of:
#   - no "Grand Totals" line at all             (crash, kill, or the library
#                                                volume disappeared mid-run)
#   - nonzero proveit exit status
#   - counts that disagree: proofs / attempted / succeeded must be equal and
#                                                nonzero
#   - "unfinished" / "unproved" / "missing"      (formula not closed)
#   - "proved - incomplete"                      (closed but depends on an
#                                                 incomplete subproof)
#   - "*** Error occurred while rerunning"       (rerun aborted)
#   - "fewer subproofs" (traces run only)        (proof script shrank)
#
# History of this script's own blind spots, each found the hard way:
#   1. the last three patterns above were invisible, so a killed or partially
#      reconstructed run could report "GATE PASSED";
#   2. checking only for failure PATTERNS meant a run with NO output passed --
#      the T7 volume unmounted mid-gate on 2026-09-17 and runs 3 and traces
#      produced nothing at all, yet the gate said PASSED.  Absence of evidence
#      was being read as evidence of success.  Hence the count checks and the
#      volume guard below.
. "$(dirname "$0")/env.sh"
# proveit runs in a fresh copy of the library, so it cannot clobber the
# .pvscontext / .prf / pvsbin files of a pvs-cli server working in cad/, and
# the gate never changes the working tree.  GATE_IN_PLACE=1 runs in cad/.
if [ "${GATE_IN_PLACE:-0}" = 1 ]; then DIR=$CAD_LIB_DIR
else
  DIR="$SCRATCH/gate_lib_$$"   # one directory per gate run: gates can run side by side
  trap 'rm -rf "$DIR"' EXIT
  rsync -a --delete --exclude pvsbin --exclude '._*' "$CAD_LIB_DIR/" "$DIR/" ||
    { echo "GATE ABORTED: cannot copy $CAD_LIB_DIR"; exit 1; }
fi
cd "$DIR" || { echo "GATE ABORTED: cannot cd to $DIR"; exit 1; }

check() { # check <log> <exitcode> ; echoes problems, returns 1 if any
  local out=$1 rc=$2 bad=0 n line p a s
  if [ "$rc" != 0 ]; then echo "  !! proveit exit status $rc ($out)"; bad=1; fi
  line=$(grep -a "Grand Totals" "$out" | tail -1)
  if [ -z "$line" ]; then
    echo "  !! NO 'Grand Totals' line in $out -- run produced no result at all"
    bad=1
  else
    p=$(printf '%s' "$line" | sed -n 's/.*Grand Totals: *\([0-9]*\) proofs.*/\1/p')
    a=$(printf '%s' "$line" | sed -n 's/.*, *\([0-9]*\) attempted.*/\1/p')
    s=$(printf '%s' "$line" | sed -n 's/.*, *\([0-9]*\) succeeded.*/\1/p')
    if [ -z "$p" ] || [ -z "$a" ] || [ -z "$s" ]; then
      echo "  !! unparsable totals in $out: $line"; bad=1
    elif [ "$p" = 0 ]; then
      echo "  !! zero proofs in $out"; bad=1
    elif [ "$p" != "$a" ] || [ "$a" != "$s" ]; then
      echo "  !! counts differ in $out: $p proofs / $a attempted / $s succeeded"; bad=1
    fi
  fi
  if grep -aqi "unfinished\|unproved\|missing" "$out"; then
    echo "  !! unfinished/unproved/missing in $out"; bad=1; fi
  n=$(grep -ac "proved - incomplete" "$out")
  if [ "$n" != 0 ]; then echo "  !! $n 'proved - incomplete' in $out"; bad=1; fi
  n=$(grep -ac '\*\*\* Error occurred while rerunning' "$out")
  if [ "$n" != 0 ]; then echo "  !! $n rerun errors in $out"; bad=1; fi
  return $bad
}

for f in "$@"; do
  ok=1
  for i in 1 2 3; do
    [ -d "$DIR" ] || { echo "  !! $DIR vanished before run $i"; ok=0; break; }
    rm -rf pvsbin
    out="$SCRATCH/gate_${f}_$i.log"
    "$PROVEIT" -f "$f.pvs" > "$out" 2>&1; rc=$?
    printf '%-16s run %d  %s\n' "$f" "$i" "$(grep -a 'Grand Totals\|Totals for' "$out" | tail -1)"
    check "$out" "$rc" || ok=0
  done
  if [ -d "$DIR" ]; then
    rm -rf pvsbin
    out="$SCRATCH/gate_${f}_traces.log"
    "$PROVEIT" -l --traces -f "$f.pvs" > "$out" 2>&1; rc=$?
    n=$(grep -ac "fewer subproofs" "$out")
    printf '%-16s traces  fewer-subproofs warnings: %s  %s\n' "$f" "$n" "$(grep -a 'Grand Totals' "$out" | tail -1)"
    [ "$n" = "0" ] || ok=0
    check "$out" "$rc" || ok=0
  else
    echo "  !! $DIR vanished before the traces run"; ok=0
  fi
  [ "$ok" = 1 ] && echo "$f GATE PASSED" || echo "$f GATE FAILED"
done
