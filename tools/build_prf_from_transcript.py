"""Hand-build a PVS .prf proof tree from a raw-session transcript + the authored
command script (save-all-proofs is broken in this PVS build).

Usage: python3 build_wsc_prf.py <script.txt> <transcript.txt> <theory> <formula> <out.prf>

Technique (see reference_pvs_tooling memory): split the transcript on `Rule?`
prompts; command i (1-indexed) was typed at the goal whose header is the LAST
goal header in parts[i-1]; its result is parts[i]. "yields N subgoals" => split
node; "This completes the proof of <label>." => leaf.
"""
import re, sys

script_path, transcript_path, theory, formula, out_path = sys.argv[1:6]
ENTRY_ONLY = len(sys.argv) > 6 and sys.argv[6] == "entry"

# ---- commands: after (prove-formula ...) up to save-all-proofs/quit/bye ----
cmds = []
started = False
buf, depth = '', 0
for line in open(script_path):
    s = line.rstrip('\n')
    if not started:
        if s.strip().startswith('(prove-formula'):
            started = True
        continue
    if depth == 0 and not s.strip():
        continue
    # commands may span several lines (spread/then blocks): join by paren balance
    buf += (('\n' if buf else '') + s)
    depth += s.count('(') - s.count(')')
    if depth > 0:
        continue
    c = buf.strip(); buf, depth = '', 0
    if c.startswith('(save-all-proofs') or c in ('(quit)', 'y', '(bye)'):
        break
    if c:
        cmds.append(c)

txt = open(transcript_path).read()
parts = re.split(r'Rule\?\s*', txt)
if len(cmds) > len(parts) - 1 and 'Q.E.D.' in parts[-1]:
    # Q.E.D. was reached before the script ran out: trailing commands were
    # never consumed by the prover (fed to the Lisp REPL instead). Drop them.
    print("DROPPING unconsumed trailing commands after Q.E.D.:", cmds[len(parts)-1:])
    cmds = cmds[:len(parts)-1]
if len(parts) != len(cmds) + 1:
    sys.exit(f"MISMATCH: {len(parts)-1} prompts vs {len(cmds)} commands")

lab_re = re.compile(re.escape(formula) + r'((?:\.[0-9]+T?)*)\s*(?:\(TCC\))?\s*:')

def last_label(chunk):
    ms = lab_re.findall(chunk)
    if not ms:
        return None
    s = ms[-1]
    return tuple(s.strip('.').split('.')) if s else ()

nodes = {}          # label tuple -> list of (cmd, kind, N)
rejected = []
for i, cmd in enumerate(cmds, start=1):
    lab = last_label(parts[i - 1])
    if lab is None:
        sys.exit(f"no goal label before command {i}: {cmd}")
    res = parts[i]
    if 'Restoring the state' in res:
        rejected.append((i, cmd))
        continue
    labstr = formula + ('.' + '.'.join(lab) if lab else '')
    m = re.search(r'yields\s+(\d+)\s+subgoals', res)
    closed = re.search(re.escape(f'This completes the proof of {labstr}.') + r'\s*$', res, re.M)
    if closed or 'Q.E.D.' in res:
        # a compound step (spread/then) may split internally and still close
        # the whole goal: it is a leaf of the saved tree
        kind, N = 'close', 0
    elif m:
        kind, N = 'split', int(m.group(1))
    else:
        kind, N = 'cont', 0
    nodes.setdefault(lab, []).append((cmd, kind, N))

if rejected:
    print("EXCLUDED rejected commands:", rejected)

def labkey(l):
    return tuple(int(c.rstrip('T')) for c in l)

def children_of(label):
    kids = [l for l in nodes if len(l) == len(label) + 1 and l[:-1] == label]
    return sorted(kids, key=lambda l: int(l[-1].rstrip('T')))

def minimal_descendants(label):
    # labels strictly extending LABEL with no other node label strictly between:
    # the goals a compound step (spread/then) left open, in PVS's own order
    desc = [l for l in nodes if len(l) > len(label) and l[:len(label)] == label]
    mins = [l for l in desc if not any(len(m) < len(l) and l[:len(m)] == m for m in desc)]
    return sorted(mins, key=labkey)

def strategy_of(label):
    # the proof subtree rooted at LABEL as one strategy expression
    seq = nodes[label]
    def rec(k):
        cmd, kind, N = seq[k]
        if k < len(seq) - 1:
            return '(then ' + cmd + ' ' + rec(k + 1) + ')'
        if kind != 'split':
            return cmd
        kids = children_of(label)
        if cmd.lstrip('(').split()[0].lower() in ('spread', 'then', 'then@', 'try', 'branch'):
            kids = minimal_descendants(label)
            closers = ' '.join('(try (try ' + strategy_of(c) + ' (fail) (skip)) (skip) (skip))' for c in kids)
            return '(then ' + cmd + ' (then ' + closers + '))'
        parts = []
        for j in range(1, N + 1):
            c = next((c for c in kids if c[-1].rstrip('T') == str(j)), None)
            parts.append(strategy_of(c) if c else '(assert)')
        return '(spread ' + cmd + ' (' + ' '.join(parts) + '))'
    return rec(0)

def render(label):
    seq = nodes[label]
    comp = label[-1] if label else ''
    def rec(k):
        cmd, kind, N = seq[k]
        if k < len(seq) - 1:
            if kind == 'split':
                sys.exit(f"split mid-chain at {label} cmd {cmd}")
            ch = '(' + rec(k + 1) + ')'
        elif kind == 'split' and cmd.lstrip('(').split()[0].lower() in ('spread', 'then', 'then@', 'try', 'branch'):
            # compound step: it split internally; whatever it left open got the
            # later top-level commands, keyed by deeper labels. PVS pairs saved
            # subtrees with a step's IMMEDIATE subgoals, which for a compound
            # step are not the leaves it left open -- so fold the follow-up
            # commands into the step itself: (spread <step> (s1 ... sk)) with
            # one strategy per leftover leaf, in PVS's own goal order.
            kids = minimal_descendants(label)
            if not kids:
                sys.exit(f"compound step at {label} left subgoals but none got commands: {cmd[:60]}")
            print(f"NOTE: compound step at {label} left {len(kids)} open goals, folded: {kids}")
            # each leftover strategy is applied to every remaining leaf, but
            # only kept when it closes the leaf: (try (try S (fail) (skip)) (skip) (skip))
            closers = ' '.join('(try (try ' + strategy_of(c) + ' (fail) (skip)) (skip) (skip))' for c in kids)
            folded = '(then ' + cmd + ' (then ' + closers + '))'
            return f'("{comp}" {folded} NIL NIL)'
        elif kind == 'split':
            kids = children_of(label)
            if len(kids) > N:
                sys.exit(f"at {label}: split yields {N} but saw MORE children {kids}")
            if len(kids) < N:
                # some subgoals auto-closed during the split's own simplification
                # ("which is trivially true") and never got a prompt. On replay
                # PVS pairs saved subtrees with subgoals POSITIONALLY, so a
                # missing child must be filled with a synthetic (ASSERT) leaf
                # (see reference_pvs_proof_tactics memory, Piece 4 refinement).
                seen = {k[-1] for k in kids}
                print(f"NOTE: at {label} split yields {N}, only {sorted(seen)} got commands; synthesizing (ASSERT) for the rest")
                rendered = []
                for j in range(1, N + 1):
                    k = next((k for k in kids if k[-1].rstrip('T') == str(j)), None)
                    rendered.append(render(k) if k else f'("{j}" (ASSERT) NIL NIL)')
                ch = '(' + ' '.join(rendered) + ')'
            else:
                ch = '(' + ' '.join(render(c) for c in kids) + ')'
        else:
            if kind != 'close':
                print(f"WARNING: chain at {label} ends without closure: {cmd}")
            ch = 'NIL'
        return f'("{comp}" {cmd} {ch} NIL)'
    return rec(0)

tree = render(())

# paren balance check (ignoring string literals)
depth, in_str, prev = 0, False, ''
for c in tree:
    if in_str:
        if c == '"' and prev != '\\':
            in_str = False
    elif c == '"':
        in_str = True
    elif c == '(':
        depth += 1
    elif c == ')':
        depth -= 1
    prev = c
if depth != 0 or in_str:
    sys.exit(f"paren/string imbalance: depth={depth} in_str={in_str}")

total = sum(len(v) for v in nodes.values())
print(f"commands={len(cmds)} placed={total} nodes={len(nodes)}")

entry = f" (|{formula}| 0\n  (|{formula}-1| NIL 1414213562\n   {tree}\n   NIL SHOSTAK))"
out = entry + "\n" if ENTRY_ONLY else f"(|{theory}|\n{entry})\n"
open(out_path, 'w').write(out)
print("wrote", out_path, len(out), "bytes")
