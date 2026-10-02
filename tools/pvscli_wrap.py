#!/usr/bin/env python3
"""pvscli_wrap.py: runs NASALib's pvs-cli ($NASALIB/pvs-scripts/pvs-cli/pvs-cli.py,
part of NASALib and not included here) with two settings changed:

- its state file is $PVS_CLI_STATE when that is set (tools/pvscli.sh keeps one per
  server port in $SCRATCH), instead of ~/.pvs-cli-state.pkl;
- its websocket connections have no keepalive timeout and no message size limit,
  so a long strategy run or a big sequent does not drop the connection.

Nothing of pvs-cli is copied here: its file is loaded from NASALib and run as is.
"""
import asyncio
import importlib.util
import os
import sys

import websockets

NASALIB = os.environ.get("NASALIB", "")
CLI = os.path.join(NASALIB, "pvs-scripts", "pvs-cli", "pvs-cli.py")
if not NASALIB or not os.path.isfile(CLI):
    sys.exit(f"pvscli_wrap: NASALib's pvs-cli not found at {CLI} (set NASALIB; see tools/env.sh)")

_connect = websockets.connect


def _connect_no_limits(*args, **kwargs):
    kwargs.setdefault("ping_timeout", None)
    kwargs.setdefault("max_size", None)
    return _connect(*args, **kwargs)


websockets.connect = _connect_no_limits

_spec = importlib.util.spec_from_file_location("nasalib_pvs_cli", CLI)
cli = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cli)
if os.environ.get("PVS_CLI_STATE"):
    cli.STATE_FILE = os.environ["PVS_CLI_STATE"]

sys.argv[0] = CLI
asyncio.run(cli.main())
