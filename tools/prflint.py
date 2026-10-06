#!/usr/bin/env python3
"""prflint.py <library dir> [--summary <top.summary>]: checks the .prf files of a PVS library.

Every file must parse, every formula entry must hold exactly one proof, and no proof may
contain (POSTPONE).  With --summary (proveit's top.summary of a replay of the same library),
every entry must also name a formula that the replay has in that theory: an entry without
one is stale.  orphaned-proofs.prf, where PVS keeps the proofs of deleted formulas, is
skipped.  Prints each problem; exit status 1 if there is any."""
import sys, os, re, glob

def tokens(s):
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c.isspace(): i += 1; continue
        if c in '()': yield c; i += 1; continue
        if c == '"':
            j = i + 1
            while s[j] != '"':
                if s[j] == '\\': j += 1
                j += 1
            yield ('S', s[i+1:j]); i = j + 1; continue
        if c == '|':
            j = s.index('|', i + 1); yield ('A', s[i+1:j]); i = j + 1; continue
        j = i
        while j < n and not s[j].isspace() and s[j] not in '()"|': j += 1
        yield ('A', s[i:j]); i = j

def parse(s):
    stack = [[]]
    for t in tokens(s):
        if t == '(': stack.append([])
        elif t == ')':
            x = stack.pop(); stack[-1].append(x)
        else: stack[-1].append(t)
    if len(stack) != 1: raise ValueError('unbalanced parentheses')
    return stack[0]

def has_postpone(x):
    if isinstance(x, list): return any(has_postpone(y) for y in x)
    return x == ('A', 'POSTPONE')

def main():
    args = sys.argv[1:]
    summary = None
    if '--summary' in args:
        k = args.index('--summary'); summary = args[k+1]; del args[k:k+2]
    lib = args[0]
    replayed = None
    if summary:
        replayed = {}
        cur = None
        for line in open(summary, errors='replace'):
            m = re.match(r'\s*Proof summary for theory (\S+)', line)
            if m: cur = replayed.setdefault(m.group(1), set()); continue
            m = re.match(r'    (\S+?)\.{2,}', line)
            if m and cur is not None: cur.add(m.group(1))
    problems = []; entries = 0
    for f in sorted(glob.glob(os.path.join(lib, '*.prf'))):
        if os.path.basename(f) == 'orphaned-proofs.prf': continue
        try:
            top = parse(open(f, errors='replace').read())
        except Exception as e:
            problems.append(f'{os.path.basename(f)}: does not parse ({e})'); continue
        for th in top:
            if not isinstance(th, list) or not th: continue
            tname = th[0][1] if isinstance(th[0], tuple) else '?'
            if replayed is not None and tname not in replayed:
                problems.append(f'{tname}: has a .prf entry but is not in the replay')
            for ent in th[1:]:
                if not isinstance(ent, list) or len(ent) < 2: continue
                entries += 1
                fname = ent[0][1] if isinstance(ent[0], tuple) else '?'
                proofs = [p for p in ent[2:] if isinstance(p, list)]
                if len(proofs) != 1:
                    problems.append(f'{tname}.{fname}: {len(proofs)} proofs')
                if has_postpone(proofs):
                    problems.append(f'{tname}.{fname}: a proof contains (POSTPONE)')
                if replayed is not None and tname in replayed and fname not in replayed[tname]:
                    problems.append(f'{tname}.{fname}: stale (no such formula in the replay)')
    for p in problems: print('  !! ' + p)
    print(f'prflint: {entries} formula entries, {len(problems)} problems')
    sys.exit(1 if problems else 0)

main()
