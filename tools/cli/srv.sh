#!/bin/bash
# srv.sh [theory]: (re)start the PVS server for pvs-cli on $PVS_PORT in the
# library directory, change workspace, then typecheck <theory> if given.
. "$(dirname "$0")/../env.sh"
PIDF="$SCRATCH/pvs_server_$PVS_PORT.pid"
if [ -f "$PIDF" ]; then
  P=$(cat "$PIDF"); pkill -9 -P "$P" 2>/dev/null; kill -9 "$P" 2>/dev/null; rm -f "$PIDF"
fi
for p in $(lsof -ti "tcp:$PVS_PORT" -sTCP:LISTEN 2>/dev/null); do kill -9 "$p"; done
sleep 1
cd "$CAD_LIB_DIR"
# PVS's raw mode exits at end of stdin, so keep stdin open with tail -f.
nohup sh -c "echo \$\$ > '$PIDF'; tail -f /dev/null | '$PVS' -raw -port $PVS_PORT" \
  > "$SCRATCH/pvs_server_$PVS_PORT.log" 2>&1 &
for i in $(seq 1 180); do
  "$CAD_TOOLS/pvscli.sh" --change-workspace "$CAD_LIB_DIR" 2>&1 | grep -q "Could not connect" || break
  sleep 1
done
[ -n "$1" ] && "$CAD_TOOLS/pvscli.sh" --typecheck "$1.pvs" 2>&1 | tail -5
exit 0
