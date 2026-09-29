#!/bin/bash
# multi.sh <name> <theory> <strategy-or-'-'> formula1 [formula2 ...]
# One raw session proving several formulas of ONE theory in sequence (one
# typecheck).  With strategy '-', commands for formula k are read from
# $SCRATCH/<name>_<formula>.cmds.  Reports Q.E.D. per formula.
. "$(dirname "$0")/env.sh"; DIR=$CAD_LIB_DIR
name=$1; T=$2; STRAT=$3; shift 3
S="$SCRATCH/$name"
{ printf '(setq *proceed-without-asking* t)\n(change-context "%s")\n(typecheck-file "%s")\n' "$DIR" "$T"
  for F in "$@"; do
    echo "(prove-formula (quote ((\"theory\" . \"$T\") (\"formula\" . \"$F\"))))"
    if [ "$STRAT" = "-" ]; then cat "$SCRATCH/${name}_$F.cmds"; else echo "$STRAT"; fi
    echo "(postpone)"; echo "(postpone)"
  done
  printf '(quit)\n(bye)\n'; } > "$S.txt"
for attempt in 1 2 3 4; do bash "$CAD_TOOLS/pvs_raw_timeout.sh" "$S.txt" "${S}_out.txt" 600 >/dev/null; grep -q "exhausted" "${S}_out.txt" || break; sleep 8; done
python3 - "$S.txt" "${S}_out.txt" "$@" << 'PY'
import sys,re
sess,out=sys.argv[1],sys.argv[2]; forms=sys.argv[3:]
txt=open(out).read()
# split transcript at each "(prove-formula" echo? PVS does not echo; use the goal headers: a proof starts when a line "<formula> :" appears right after a prompt-less area. Simpler: split on 'Q.E.D.' and on the text 'Formula '.
chunks=re.split(r'(?m)^(?=\S+ :  \s*$)', txt)  # lines like "formula :  " start a goal display
res={}
for f in forms:
    # find the segment starting at the first "f :" header and ending at next Q.E.D. or next formula header
    m=re.search(r'(?m)^'+re.escape(f)+r' :  \s*$', txt)
    if not m: res[f]='NOTSTARTED'; continue
    seg=txt[m.start():]
    nxt=[re.search(r'(?m)^'+re.escape(g)+r' :  \s*$', seg[1:]) for g in forms if g!=f]
    ends=[x.start()+1 for x in nxt if x]
    end=min(ends) if ends else len(seg)
    seg=seg[:end]
    res[f]='QED' if 'Q.E.D.' in seg else 'open'
    open(out.replace('_out.txt','')+'__'+f+'_out.txt','w').write(seg)
print(' '.join(f'{f}:{res[f]}' for f in forms))
PY
