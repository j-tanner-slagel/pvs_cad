#!/usr/bin/env python3
"""pc.py [-t SECS] <proof command>: send one proof command to the pvs-cli server
with a timeout; on timeout interrupt the active proof. Prints the stripped
output (completion lines and the new sequent)."""
import os, subprocess, sys, re, time
CLI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pvscli.sh")
args = sys.argv[1:]
tmo = 300
if args and args[0] == "-t":
    tmo = int(args[1]); args = args[2:]
cmd = " ".join(args)
def run(a, t):
    r = subprocess.run([CLI] + a, capture_output=True, text=True, timeout=t)
    return re.sub(r"\x1b\[[0-9;]*m", "", r.stdout + r.stderr)
try:
    out = run(["--proof-command", cmd], tmo)
except subprocess.TimeoutExpired:
    print("TIMEOUT after", tmo, "s; interrupting")
    ids = run(["--list-active-proofs"], 60)
    m = re.search(r"(\S+): .* \*", ids)
    if m:
        print(run(["--interrupt-proof", m.group(1)], 60))
        time.sleep(2)
    sys.exit(1)
lines = [l for l in out.splitlines() if l.strip()]
print("\n".join(lines))
