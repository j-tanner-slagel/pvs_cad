#!/bin/bash
# prof.sh <theory> <formula> [seconds] [det|flat]
#   Profile the n-level decision decn_o on a closed prenex formula (as (cad-mn)
#   would evaluate it) in the running pvs-cli server: det (default) times the
#   functions listed in tools/prof/cad_dprof.lisp (sb-profile); flat is SBCL's
#   statistical profiler (sb-sprof).  Stops after [seconds] (default 120).
#   Start the server first: tools/cli/srv.sh <theory>.  Dev tooling only.
. "$(dirname "$0")/env.sh"
TH=$1; FM=$2; SECS=${3:-120}; MODE=${4:-det}
cd "$CAD_LIB_DIR"
FASL=$(find "$PVS_DIR/bin" -name sb-sprof.fasl 2>/dev/null | head -1)
L() { "$CAD_TOOLS/pvscli.sh" --lisp "$1" >/dev/null 2>&1; }
L "(progn (defvar *cad-scratch* \"$SCRATCH\") (setq *cad-scratch* \"$SCRATCH\") (defvar *cad-sprof-fasl* \"$FASL\") (setq *cad-sprof-fasl* \"$FASL\"))"
for f in cad_fstr cad_prof cad_dprof; do L "(load \"$CAD_TOOLS/prof/$f.lisp\")"; done
"$CAD_TOOLS/pvscli.sh" --quit-all-proofs >/dev/null 2>&1
"$CAD_TOOLS/pvscli.sh" --prove "$TH#$TH#$FM" >/dev/null 2>&1
"$CAD_PY" "$CAD_TOOLS/pc.py" -t 600 '(cad-fstr)' >/dev/null 2>&1
EXPR=$("$CAD_PY" - "$SCRATCH/cad_fstr.out" <<'PY'
import sys
s=open(sys.argv[1]).read()
F=' '.join(s.split('F=',1)[1].split('\nQS=')[0].split())
QS=s.split('QS=',1)[1].split('\n')[0].strip()
PHI=s.split('PHI=',1)[1].strip()
print('decn_o(%s, %s, LAMBDA (v: SV): bfsv(%s, v))' % (QS, F, PHI))
PY
)
L "(setq *cad-prof-expr* \"$EXPR\")"; L "(setq *cad-prof-secs* $SECS)"
if [ "$MODE" = flat ]; then
  "$CAD_PY" "$CAD_TOOLS/pc.py" -t $((SECS + 300)) '(cad-prof)' >/dev/null 2>&1; head -60 "$SCRATCH/cad_prof.txt"
else
  "$CAD_PY" "$CAD_TOOLS/pc.py" -t $((SECS + 300)) '(cad-dprof)' >/dev/null 2>&1; head -40 "$SCRATCH/cad_dprof.txt"
fi
