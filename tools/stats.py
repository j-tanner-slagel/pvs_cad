#!/usr/bin/env python3
"""stats.py <replay copy>: the numbers the documents quote, read from a whole replay (the
directory replay.sh leaves: cad/top.summary for the library, cad/examples/top.summary for the
examples): theories, files (theory files and the generated datatype files), lines of PVS,
formulas, lemmas, TCCs, and the lines of strategy code."""
import sys, re, os, glob

R = sys.argv[1]
parts = [('library', os.path.join(R, 'cad')), ('examples', os.path.join(R, 'cad', 'examples'))]

def numbers(D):
    s = open(os.path.join(D, 'top.summary'), errors='replace').read()
    thys = [t for t in re.findall(r'Proof summary for theory (\S+)', s) if t != 'top']
    rows = re.findall(r'^    (\S+?)\.{2,}', s, re.M)
    tccs = [r for r in rows if re.search(r'_TCC\d+$', r)]
    where = {}
    for f in glob.glob(os.path.join(D, '*.pvs')):
        for m in re.finditer(r'^\s*([A-Za-z][A-Za-z0-9_?]*)\s*(\[[^\]]*\])?\s*:\s*THEORY\b',
                             open(f, errors='replace').read(), re.M):
            where.setdefault(m.group(1), f)
    files = sorted({where[t] for t in thys if t in where})
    missing = [t for t in thys if t not in where]
    adt = sorted(glob.glob(os.path.join(D, '*_adt.pvs')))
    allf = sorted(set(files) | set(adt))
    lines = sum(sum(1 for _ in open(f, errors='replace')) for f in allf)
    return len(thys), len(files), len(adt), lines, len(rows), len(rows) - len(tccs), len(tccs), missing

tot = [0] * 7
for label, D in parts:
    if not os.path.exists(os.path.join(D, 'top.summary')):
        print(f"{label}: no top.summary in {D}"); continue
    t, nf, na, ln, fo, le, tc, missing = numbers(D)
    for i, v in enumerate((t, nf, na, ln, fo, le, tc)): tot[i] += v
    print(f"{label}: theories {t}  files {nf + na} (theory files {nf}, datatype files {na})  lines of PVS {ln}"
          f"  formulas {fo}  lemmas and theorems {le}  TCCs {tc}")
    if missing: print(f"  {label}: theories without a file:", ' '.join(missing[:10]))
print(f"all: theories {tot[0]}  files {tot[1] + tot[2]}  lines of PVS {tot[3]}  formulas {tot[4]}"
      f"  lemmas and theorems {tot[5]}  TCCs {tot[6]}")
strat = sum(1 for _ in open(os.path.join(R, 'cad', 'pvs-strategies'), errors='replace'))
print(f"lines of strategy code {strat}")
