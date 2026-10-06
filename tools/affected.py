#!/usr/bin/env python3
"""affected.py <theory or file.pvs> ...: the theories a change to these touches, for check.sh.

Reads the IMPORTING clauses of the library's .pvs files (cad/, or $CAD_LIB_DIR) and of its
examples (cad/examples/, which import the library as cad@<theory>) and prints the given
theories and every theory that imports one of them, directly or not, comma-separated: on the
first line those that the library's top.pvs reaches, on the second those that the examples'
top.pvs reaches (theories outside both, such as the message-test inputs in tests/, have no
proofs to check).  A file name stands for every theory it declares."""
import os, re, sys

LIB = os.environ.get('CAD_LIB_DIR') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'cad')
LIBNAME = os.path.basename(os.path.normpath(os.path.abspath(LIB)))
EXD = os.path.join(LIB, 'examples')
HDR = re.compile(r'^([A-Za-z][A-Za-z0-9_]*)\s*(\[(?:[^\[\]]|\[[^\[\]]*\])*\])?\s*:\s*(THEORY|DATATYPE|CODATATYPE)\b', re.M | re.S)
ENTRY = re.compile(r'\s*((?:[A-Za-z][A-Za-z0-9_]*@)?)([A-Za-z][A-Za-z0-9_?]*)')

def strip_comments(s):
    out = []; i = 0; n = len(s); instr = False
    while i < n:
        c = s[i]
        if instr:
            out.append(c)
            if c == '"': instr = False
            i += 1; continue
        if c == '"': instr = True; out.append(c); i += 1; continue
        if c == '%':
            j = s.find('\n', i); i = n if j < 0 else j; continue
        out.append(c); i += 1
    return ''.join(out)

def entries(text, i):
    # the entries of an IMPORTING clause: the library's own theories, named plainly or as
    # LIBNAME@theory; entries of other libraries (NASALib) are left out
    out = []; n = len(text)
    while True:
        m = ENTRY.match(text, i)
        if not m: break
        lib = m.group(1); name = m.group(2); i = m.end()
        j = i
        while j < n and text[j] in ' \t\n': j += 1
        if j < n and text[j] == '[':
            d = 0; k = j
            while k < n:
                if text[k] == '[': d += 1
                elif text[k] == ']':
                    d -= 1
                    if d == 0: k += 1; break
                k += 1
            i = k
        if not lib or lib == LIBNAME + '@': out.append(name)
        m2 = re.compile(r'\s*,').match(text, i)
        if not m2: break
        i = m2.end()
    return out

theories = {}; files = {}
def read_dir(d, top_key):
    if not os.path.isdir(d): return
    for f in sorted(os.listdir(d)):
        if not f.endswith('.pvs') or f.endswith('_adt.pvs'): continue
        s = strip_comments(open(os.path.join(d, f), errors='ignore').read())
        hs = list(HDR.finditer(s))
        for k, h in enumerate(hs):
            body = s[h.start():(hs[k + 1].start() if k + 1 < len(hs) else len(s))]
            imps = []
            for m in re.finditer(r'\bIMPORTING\b', body):
                imps += entries(body, m.end())
            name = top_key if h.group(1) == 'top' else h.group(1)
            theories[name] = imps
            files.setdefault(f, []).append(name)
read_dir(LIB, 'top')
read_dir(EXD, 'examples/top')

def closure(roots, edges):
    seen = set(); st = list(roots)
    while st:
        t = st.pop()
        if t in seen: continue
        seen.add(t); st += edges.get(t, [])
    return seen

reached_lib = closure(['top'], theories) - {'top'}
reached_ex = closure(['examples/top'], theories) - {'examples/top'} - reached_lib
users = {}
for t, imps in theories.items():
    for u in imps:
        users.setdefault(u, []).append(t)
changed = []
for a in sys.argv[1:]:
    a = os.path.basename(a)
    changed += files.get(a, []) if a.endswith('.pvs') else [a]
unknown = [t for t in changed if t not in theories]
if unknown:
    sys.exit('affected.py: not a theory of the library or its examples: ' + ' '.join(unknown))
hit = closure(changed, users)
print(','.join(sorted(hit & reached_lib)))
print(','.join(sorted(hit & reached_ex)))
