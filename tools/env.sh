# tools/env.sh -- sourced by every tool script; locates the repo and PVS
# without machine-specific paths.  Override any variable in the environment.
#   CAD_ROOT      repo root (default: parent of this tools/ directory)
#   CAD_LIB_DIR   the PVS library (default: $CAD_ROOT/cad)
#   PVS_DIR       PVS installation (default: directory of `pvs` on PATH)
#   NASALIB       NASALib checkout (default: $PVS_DIR/nasalib or $PVS_DIR/pvslib)
#   SCRATCH       scratch directory (default: /tmp/cad_scratch)
#   PVS_PORT      pvs-cli server port (default: 23456)
_env_src=${BASH_SOURCE[0]:-$0}
CAD_ROOT=${CAD_ROOT:-$(cd "$(dirname "$_env_src")/.." && pwd -P)}
CAD_TOOLS="$CAD_ROOT/tools"
CAD_LIB_DIR=${CAD_LIB_DIR:-$CAD_ROOT/cad}
if [ -z "$PVS_DIR" ]; then
  _pvs=$(command -v pvs 2>/dev/null) && PVS_DIR=$(cd "$(dirname "$_pvs")" && pwd -P)
fi
if [ -z "$NASALIB" ] && [ -n "$PVS_DIR" ]; then
  for _d in "$PVS_DIR/nasalib" "$PVS_DIR/pvslib"; do
    [ -d "$_d/Sturm" ] && { NASALIB=$_d; break; }
  done
fi
PVS=${PVS:-$PVS_DIR/pvs}
PROVEIT=${PROVEIT:-$PVS_DIR/proveit}
SCRATCH=${SCRATCH:-/tmp/cad_scratch}
PVS_PORT=${PVS_PORT:-23456}
CAD_PY="$CAD_ROOT/.venv/bin/python3"
[ -x "$CAD_PY" ] || CAD_PY=python3
case ":$PVS_LIBRARY_PATH:" in *":$NASALIB:"*) ;; *)
  [ -n "$NASALIB" ] && PVS_LIBRARY_PATH="$NASALIB${PVS_LIBRARY_PATH:+:$PVS_LIBRARY_PATH}";; esac
mkdir -p "$SCRATCH"
export CAD_ROOT CAD_TOOLS CAD_LIB_DIR PVS_DIR NASALIB PVS PROVEIT SCRATCH PVS_PORT CAD_PY PVS_LIBRARY_PATH
if [ ! -x "$PVS" ]; then
  echo "tools/env.sh: PVS not found; put pvs on PATH or set PVS_DIR" >&2
fi
