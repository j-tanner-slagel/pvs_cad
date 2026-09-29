#!/bin/bash
# pvscli.sh: NASALib's pvs-cli (vendored as tools/pvs-cli.py) with no keepalive
# timeout and no message size limit, so a long strategy run or a big sequent
# does not drop the connection.  Talks to the server on $PVS_PORT (tools/cli/srv.sh);
# its current-proof state is kept per port in $SCRATCH.  Needs tools/setup.sh once.
. "$(dirname "$0")/env.sh"
export PVS_CLI_STATE=${PVS_CLI_STATE:-$SCRATCH/pvs-cli-state-$PVS_PORT.pkl}
exec "$CAD_PY" "$CAD_TOOLS/pvs-cli.py" --port "$PVS_PORT" "$@"
