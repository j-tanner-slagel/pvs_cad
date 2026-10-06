#!/bin/bash
# ps.sh <command>: send command, show only the first line of each sequent formula of the final sequent
. "$(dirname "$0")/../env.sh"; cd "$CAD_WORK_DIR"
"$CAD_PY" "$CAD_TOOLS/pc.py" -t 600 "$1" 2>&1 > $SCRATCH/last.out
python3 - <<'PY'
import re, os
s=open(os.environ['SCRATCH']+'/last.out').read()
# last sequent: from the last line matching '^\S+ :\s*$'
ms=list(re.finditer(r'^[\w\.\?]+ :\s*$',s,re.M))
if 'Q.E.D' in s: print('Q.E.D.')
t=s[ms[-1].start():] if ms else s[-1500:]
out=[]
for l in t.split('\n'):
    if re.match(r'^(\{|\[)-?\d+',l) or l.startswith('  |---') or re.match(r'^[\w\.\?]+ :',l): out.append(l[:150])
print('\n'.join(out))
for l in s.split('\n'):
    if re.search(r'yields|completes|No change|Error|rror:|Ill-formed',l): print('  >>',l[:120])
PY
