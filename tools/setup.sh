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
. "$(dirname "$0")/env.sh"
echo "CAD_ROOT    $CAD_ROOT"
echo "PVS_DIR     $PVS_DIR"
echo "NASALIB     $NASALIB  ($("$NASALIB/nasalib-version" 2>/dev/null))"
echo "SCRATCH     $SCRATCH"
echo "python      $CAD_PY ($("$CAD_PY" -c 'import websockets; print("websockets", websockets.__version__)'))"
"$PROVEIT" --version 2>&1 | head -1
for lib in Sturm Tarski mult_poly Bernstein reals analysis structures complex; do
  [ -d "$NASALIB/$lib" ] || echo "MISSING NASALib library: $lib"
done
echo "setup OK"
