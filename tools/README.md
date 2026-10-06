# tools

Every tool sources `env.sh`, which finds the repository, PVS and NASALib without
machine-specific paths (see its header for the variables it reads).

## Setup and checks

| tool | what it does |
|---|---|
| `setup.sh` | one-time setup: the Python venv for pvs-cli; checks PVS, proveit and the NASALib libraries |
| `env.sh` | sourced by the others: `CAD_ROOT`, `CAD_LIB_DIR` (its parent goes first on `PVS_LIBRARY_PATH`, so `cad@` finds it), `CAD_WORK_DIR` (where the pvs-cli tools work: `cad/`, or `cad/examples/`), `PVS_DIR`, `NASALIB`, `SCRATCH`, `PVS_PORT` |
| `check.sh <theory or file>...` | proves what a change touches, once: the given theories and every theory that imports them, those of the library (`cad/top.pvs`) in one proveit session with traces and those of the examples (`cad/examples/top.pvs`) in another, in a scratch copy that keeps its compiled theories |
| `affected.py <theory or file>...` | the lists `check.sh` proves: the given theories and their importers, in the library and in the examples |
| `outside.sh` | replays the theories that import the library as `cad@...` from another directory: `tests/outside/use_pvs_cad.pvs` and `tests/bath/cad_bath.pvs` |
| `msgcheck.sh` | checks what `(cad)` and the other commands say when they do not prove a formula (inputs: `tests/msg/cad_msg_ex.pvs`), on a pvs-cli server of its own in a scratch copy |
| `replay.sh [--traces]` | the whole library (`cad/top.pvs`) and its examples (`cad/examples/top.pvs`) replayed with `proveit -a` in a scratch copy, with `proveit_check.sh`'s checks and `prflint.py` before and after (for a release) |
| `prflint.py <dir> [--summary <top.summary>]` | checks the `.prf` files: one proof per formula, no `POSTPONE`; with a replay's summary, no stale entries |
| `stats.py <replay copy>` | the numbers the documents quote (theories, files, lines, formulas, lemmas, TCCs, strategy lines), for the library and the examples, from a replay |
| `proveit_check.sh` | sourced by `check.sh` and `replay.sh`: the checks of one proveit run |

## Proving through pvs-cli (`cli/`)

| tool | what it does |
|---|---|
| `cli/srv.sh [theory]` | (re)starts the PVS server in `$CAD_WORK_DIR` (`cad/`, or `CAD_WORK_DIR=cad/examples` for an example) and typechecks the theory; `--stop` stops it |
| `cli/pv.sh <theory> <formula> <command>` | starts a proof and sends one command |
| `cli/p.sh <command>`, `cli/ps.sh <command>` | send a command to the active proof (full, or compact sequent) |
| `cli/sq.sh [command]` | sends a command (default `(skip)`) and prints the full sequent |
| `cli/ev.sh <expr>` | evaluates a ground expression in the active proof |
| `cli/fin.sh <file>` | applies the command in the file until the proof finishes |
| `cli/prfshow.py <file.prf> <formula>` | prints a saved proof as one command |
| `cliprove.sh <file> <theory> <cmds>` | proves formulas one command each (lines `<formula> <command>`) |
| `pvscli.sh`, `pvscli_wrap.py`, `pc.py` | NASALib's pvs-cli, wrapped for the repository's port and venv |

## Maintenance

| tool | what it does |
|---|---|
| `import_paths.py <dir>` | counts the import paths PVS 8.1's circularity check walks (see below) |
| `redundant_imports.py <dir> [--apply]` | finds IMPORTING entries already imported through another |
| `pvs-circular-deps.lisp`, `README-pvs-circular-deps.md` | a fix for PVS 8.1's slow circularity check on large directories |
| `export_public.sh <public-clone> [commit]` | stages the public repository's next commit: a commit of the development repository without `paper/` and `CLAUDE.md`; it never commits or pushes |
