#!/bin/bash
# tools/setup.sh -- one-time setup on a new machine: create the repo's Python
# venv (for pvs-cli) and check that PVS, proveit and NASALib are found.
. "$(dirname "$0")/env.sh"
set -e
if [ ! -x "$CAD_ROOT/.venv/bin/python3" ]; then
  echo "creating $CAD_ROOT/.venv"
  python3 -m venv "$CAD_ROOT/.venv"
fi
"$CAD_ROOT/.venv/bin/pip" install -q --upgrade pip websockets
set +e
. "$(dirname "$0")/env.sh"
fail=0
miss() { echo "MISSING: $*"; fail=$((fail + 1)); }
echo "CAD_ROOT    $CAD_ROOT"
echo "PVS_DIR     $PVS_DIR"
echo "NASALIB     $NASALIB  ($("$NASALIB/nasalib-version" 2>/dev/null))"
echo "SCRATCH     $SCRATCH"
[ -x "$PVS" ] || miss "PVS ($PVS); put pvs on PATH or set PVS_DIR"
if [ -x "$PROVEIT" ]; then "$PROVEIT" --version 2>&1 | head -1; else miss "proveit ($PROVEIT)"; fi
if [ -n "$NASALIB" ] && [ -d "$NASALIB" ]; then
  # the NASALib libraries the library imports (T5's trans_bounds imports trig and lnexp)
  for lib in reals Sturm Tarski structures analysis complex matrices interval_arith trig lnexp; do
    [ -d "$NASALIB/$lib" ] || miss "NASALib library $lib"
  done
  [ -f "$NASALIB/pvs-scripts/pvs-cli/pvs-cli.py" ] || miss "NASALib's pvs-scripts/pvs-cli/pvs-cli.py (tools/pvscli.sh runs it)"
else
  miss "NASALib; set NASALIB"
fi
if v=$("$CAD_PY" -c 'import websockets; print("websockets", websockets.__version__)' 2>/dev/null); then
  echo "python      $CAD_PY ($v)"
else
  miss "the websockets module for $CAD_PY"
fi
if [ "$fail" = 0 ]; then echo "setup OK"; else echo "setup FAILED: $fail missing"; exit 1; fi
