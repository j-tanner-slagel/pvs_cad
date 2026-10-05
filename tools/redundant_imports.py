#!/usr/bin/env python3
"""redundant_imports.py <dir> [--apply]: find (and optionally remove) IMPORTING entries that are
already imported through another import of the same theory.  Instance-aware and
conservative: an entry is redundant when the SAME entry (name, library, actuals text)
is reached through another direct import, following only non-parametric theories of
the directory.  top.pvs is left alone."""
import re, os, sys, functools
sys.setrecursionlimit(100000)
D = sys.argv[1]; APPLY = '--apply' in sys.argv
ENTRY = re.compile(r'\s*((?:[A-Za-z][A-Za-z0-9_]*@)?)([A-Za-z][A-Za-z0-9_?]*)')
def scan_entries(text, i):
    """parse an IMPORTING list starting at index i; return (entries, end), entries = (lib, name, actuals, start, end)"""
    out = []; n = len(text)
    while True:
        m = ENTRY.match(text, i)
        if not m: break
        s0 = m.start(1) if m.group(1) else m.start(2)
        lib, name = m.group(1)[:-1] if m.group(1) else '', m.group(2)
        i = m.end(); act = ''
        j = i
        while j < n and text[j] in ' \t\n': j += 1
        if j < n and text[j] == '[':
            depth = 0; k = j
            while k < n:
                if text[k] == '[': depth += 1
                elif text[k] == ']':
                    depth -= 1
                    if depth == 0: k += 1; break
                k += 1
            act = re.sub(r'\s+', '', text[j:k]); i = k
        out.append((lib, name, act, s0, i))
        mc = re.compile(r'[ \t]*\n?[ \t]*,|\s*,').match(text, i)
        if not mc: break
        i = mc.end()
    return out, i
files = {}; th = {}   # theory -> (file, formals?, [entries with clause info])
for f in sorted(os.listdir(D)):
    if not f.endswith('.pvs') or f == 'top.pvs': continue
    raw = open(os.path.join(D, f), errors='ignore').read()
    files[f] = raw
    code = re.sub(r'%[^\n]*', lambda m: ' ' * len(m.group(0)), raw)   # blank comments, keep offsets
    for m in re.finditer(r'(?m)^\s*([A-Za-z][A-Za-z0-9_?]*)\s*(\[[^\n]*?\])?\s*:\s*(THEORY|DATATYPE)\b', code):
        name, formals = m.group(1), bool(m.group(2))
        end = re.compile(r'(?m)^\s*END\s+' + re.escape(name) + r'\b').search(code, m.end())
        body_end = end.start() if end else len(code)
        clauses = []
        for im in re.finditer(r'\bIMPORTING\b', code[m.end():body_end]):
            st = m.end() + im.end()
            ents, e = scan_entries(code, st)
            clauses.append((m.end() + im.start(), e, ents))
        th[name] = (f, formals, clauses)
def direct(t): return [(l, n, a) for (_, _, ents) in th[t][2] for (l, n, a, _, _) in ents]
@functools.lru_cache(None)
def closure(t):
    """entries reachable from theory t (non-parametric in-dir theories followed)"""
    r = set()
    for (l, n, a) in direct(t):
        r.add((l, n, a))
        if not l and n in th and not th[n][1] and not a:
            r |= closure(n)
    return frozenset(r)
total = 0; red_list = {}
def positioned(t):
    """direct entries with the offset of their IMPORTING clause (visibility starts there)"""
    return [((l, n, a), cst) for (cst, _, ents) in th[t][2] for (l, n, a, _, _) in ents]
for t in th:
    ds = positioned(t)
    for idx, (e, pos) in enumerate(ds):
        dup = any(o == e for k, (o, p2) in enumerate(ds) if k < idx)
        # another import visible at or before this one's clause that already brings e
        via = any(k != idx and p2 <= pos and o != e and (not o[0]) and o[1] in th and not th[o[1]][1]
                  and not o[2] and e in closure(o[1]) for k, (o, p2) in enumerate(ds))
        if dup or via:
            red_list.setdefault(t, []).append((e, 'duplicate' if dup else 'via another import'))
    total += len(ds)
nred = sum(len(v) for v in red_list.values())
print(f"theories {len(th)}, importing entries {total}, redundant {nred}")
for t in sorted(red_list):
    print(f"  {t}: " + ", ".join(f"{(e[0]+'@' if e[0] else '')+e[1]+e[2]}" for e, why in red_list[t]))

if APPLY:
    edits = {}   # file -> list of (start, end, replacement)
    for t, v in red_list.items():
        via = {e for e, why in v if why == 'via another import'}
        f, _, clauses = th[t]
        raw = files[f]
        kept = set()
        for (cst, cend, ents) in clauses:
            keep = []
            for (l, n, a, s0, e0) in ents:
                k = (l, n, a)
                if k in via or k in kept: continue
                kept.add(k); keep.append(raw[s0:e0])
            if len(keep) == len(ents): continue
            line_start = raw.rfind('\n', 0, cst) + 1
            indent = raw[line_start:cst]
            if not keep:
                if indent.strip() == '' and raw[cend:cend+1] == '\n':
                    edits.setdefault(f, []).append((line_start, cend + 1, ''))
                else:
                    edits.setdefault(f, []).append((cst, cend, ''))
                continue
            lines = []; cur = 'IMPORTING '
            for j, tx in enumerate(keep):
                piece = tx + (',' if j < len(keep) - 1 else '')
                if len(indent) + len(cur) + len(piece) > 90 and cur.strip() != 'IMPORTING':
                    lines.append(cur.rstrip()); cur = '    ' + piece + ' '
                else:
                    cur += piece + ' '
            lines.append(cur.rstrip())
            edits.setdefault(f, []).append((cst, cend, ('\n' + indent).join(lines)))
    for f, es in edits.items():
        s2 = files[f]
        for (a, b, r) in sorted(es, reverse=True):
            s2 = s2[:a] + r + s2[b:]
        open(os.path.join(D, f), 'w').write(s2)
    print(f"edited {len(edits)} files")
