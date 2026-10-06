#!/bin/bash
# srv.sh [theory]: (re)start the PVS server for pvs-cli on $PVS_PORT in $CAD_WORK_DIR (the
# library directory, or examples/ in it), change workspace, then typecheck <theory> if
# given.  srv.sh --stop stops the server this script started on $PVS_PORT.
. "$(dirname "$0")/../env.sh"
PIDF="$SCRATCH/pvs_server_$PVS_PORT.pid"
# stop the server this script started on this port (its whole process tree:
# sh, pvs, sbcl), and nothing else
kill_tree() { local c; for c in $(pgrep -P "$1"); do kill_tree "$c"; done; kill -9 "$1" 2>/dev/null; }
if [ -f "$PIDF" ]; then kill_tree "$(cat "$PIDF")"; rm -f "$PIDF"; fi
[ "$1" = --stop ] && exit 0
sleep 1
H=$(lsof -ti "tcp:$PVS_PORT" -sTCP:LISTEN 2>/dev/null)
if [ -n "$H" ]; then
  echo "srv.sh: port $PVS_PORT is held by another process ($H), not one this script started; set PVS_PORT to a free port"
  exit 1
fi
cd "$CAD_WORK_DIR" || exit 1
# PVS's raw mode exits at end of stdin, so keep stdin open with tail -f.
nohup sh -c "echo \$\$ > '$PIDF'; tail -f /dev/null | '$PVS' -raw -port $PVS_PORT" \
  > "$SCRATCH/pvs_server_$PVS_PORT.log" 2>&1 &
for i in $(seq 1 180); do
  "$CAD_TOOLS/pvscli.sh" --change-workspace "$CAD_WORK_DIR" 2>&1 | grep -q "Could not connect" || break
  sleep 1
done
[ -n "$1" ] && "$CAD_TOOLS/pvscli.sh" --typecheck "$1.pvs" 2>&1 | tail -5
exit 0
