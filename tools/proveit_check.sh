# proveit_check.sh -- sourced by check.sh and replay.sh: the checks of one proveit run.
# check <proveit stdout> <exit status>: echoes each problem and returns 1 if any.
# A run fails on: a nonzero exit status; no "Grand Totals" line (a crash, a kill, or a
# run that produced nothing); totals that do not parse, are zero, or differ (proofs /
# attempted / succeeded); "unfinished", "unproved" or "missing"; a rerun error.
check() {
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
  n=$(grep -ac '\*\*\* Error occurred while rerunning' "$out")
  if [ "$n" != 0 ]; then echo "  !! $n rerun errors in $out"; bad=1; fi
  return $bad
}
