#!/usr/bin/env python3
"""prf_from_cmds.py <theory> <out.prf> <formula>=<cmdsfile> ...
Builds a .prf with one proof node per formula from single compound prover
commands (the way proofs are written here), so no transcript is needed."""
import sys, io
theory, out = sys.argv[1], sys.argv[2]
lines = [f"(|{theory}|"]
for spec in sys.argv[3:]:
    name, path = spec.split("=", 1)
    cmd = io.open(path).read().strip()
    if not cmd: raise SystemExit("empty " + path)
    lines.append(f' (|{name}| 0\n  (|{name}-1| NIL 3998330000 ("" {cmd} NIL NIL) NIL SHOSTAK))')
lines[-1] += ")"
io.open(out, "w").write("\n".join(lines) + "\n")
print(out, len(sys.argv) - 3)
