#!/usr/bin/env python3
import re, os, sys, functools
sys.setrecursionlimit(1000000)
def theories_in(d):
    th = {}   # theory name -> set of in-directory imports
    for f in os.listdir(d):
        if not f.endswith('.pvs'): continue
        s = open(os.path.join(d, f), errors='ignore').read()
        s = re.sub(r'%[^\n]*', '', s)
        # split into theory blocks
        for m in re.finditer(r'(?m)^\s*([A-Za-z][A-Za-z0-9_?]*)\s*(\[[^\]]*\])?\s*:\s*(THEORY|DATATYPE|CODATATYPE)\b(.*?)(?=^\s*END\s+\1\b)', s, re.S):
            th[m.group(1)] = m.group(4)
    names = set(th)
    g = {}
    for t, body in th.items():
        imps = set()
        for m in re.finditer(r'\bIMPORTING\b', body):
            i = m.end(); n = len(body)
            while True:
                mm = re.compile(r'\s*((?:[A-Za-z][A-Za-z0-9_]*@)?)([A-Za-z][A-Za-z0-9_?]*)').match(body, i)
                if not mm: break
                lib, name = mm.group(1), mm.group(2)
                i = mm.end()
                if not lib and name in names and name != t: imps.add(name)
                # skip actuals [ ... ] and {{ ... }} with nesting
                while True:
                    mw = re.compile(r'\s*').match(body, i); i = mw.end()
                    if i < n and body[i] in '[{(':
                        depth = 0
                        while i < n:
                            if body[i] in '[{(': depth += 1
                            elif body[i] in ']})': depth -= 1
                            i += 1
                            if depth == 0: break
                    elif body.startswith(':->', i) or body.startswith('AS ', i):
                        break
                    else: break
                mc = re.compile(r'\s*,').match(body, i)
                if not mc: break
                i = mc.end()
        g[t] = sorted(imps)
    return g
def stats(d):
    g = theories_in(d)
    @functools.lru_cache(None)
    def reach(t):
        r = set()
        for c in g.get(t, []): r |= {c} | reach(c)
        return frozenset(r)
    @functools.lru_cache(None)
    def paths(t): return 1 + sum(paths(c) for c in g.get(t, []))
    edges = sum(len(v) for v in g.values())
    red = sum(1 for t, cs in g.items() for c in cs if any(c in reach(o) for o in cs if o != c))
    top = max(g, key=paths) if g else None
    return len(g), edges, red, top, (len(reach(top)) + 1 if top else 0), (paths(top) if top else 0)
for d in sys.argv[1:]:
    n, e, r, top, dep, p = stats(d)
    print(f"{os.path.basename(d.rstrip('/')):9s} theories {n:4d}  import edges {e:5d}  redundant {r:4d} ({100*r//max(e,1):2d}%)  worst theory {top} depends on {dep:4d} theories, paths walked {p:,}")
