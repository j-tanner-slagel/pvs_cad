# tools

Every tool sources `env.sh`, which finds the repository, PVS and NASALib without
machine-specific paths (see its header for the variables it reads).

## Setup and checks

| tool | what it does |
|---|---|
| `setup.sh` | one-time setup: the Python venv for pvs-cli; checks PVS, proveit and the NASALib libraries |
| `env.sh` | sourced by the others: `CAD_ROOT`, `CAD_LIB_DIR`, `PVS_DIR`, `NASALIB`, `SCRATCH`, `PVS_PORT` |
| `gate.sh <theory>...` | the verification gate: three fresh `proveit -f` runs and a traces run, in a scratch copy |
| `outside.sh` | replays `tests/outside/use_pvs_cad.pvs`, which imports the library as `cad@pvs_cad` from another directory |
| `msgcheck.sh` | checks what `(cad)` and the other commands say when they do not prove a formula (inputs: `cad/cad_msg_ex.pvs`) |

## Proving through pvs-cli (`cli/`)

| tool | what it does |
|---|---|
| `cli/srv.sh [theory]` | (re)starts the PVS server in `cad/` and typechecks the theory |
| `cli/pv.sh <theory> <formula> <command>` | starts a proof and sends one command |
| `cli/p.sh <command>`, `cli/ps.sh <command>` | send a command to the active proof (full, or compact sequent) |
| `cli/sq.sh [command]` | sends a command (default `(skip)`) and prints the full sequent |
| `cli/ev.sh <expr>` | evaluates a ground expression in the active proof |
| `cli/fin.sh <file>` | applies the command in the file until the proof finishes |
| `cli/prfshow.py <file.prf> <formula>` | prints a saved proof as one command |
| `cliprove.sh <file> <theory> <cmds>` | proves formulas one command each (lines `<formula> <command>`) |
| `pvscli.sh`, `pvscli_wrap.py`, `pc.py` | NASALib's pvs-cli, wrapped for the repository's port and venv |

## Batch runs and transcripts of `pvs -raw`

| tool | what it does |
|---|---|
| `pvs_raw_timeout.sh <in> <out> <secs>` | a raw PVS session with a watchdog (macOS has no `timeout`) |
| `multi.sh`, `prove_each.sh` | prove several formulas in raw sessions |
| `cmds.py`, `seqs.py`, `showlab.py`, `openstates.py`, `effective.py` | read raw transcripts (split at the `Rule?` prompts): the commands, the sequents, a labelled formula, the open goals, the commands that had an effect |

## Measuring and maintenance

| tool | what it does |
|---|---|
| `prof.sh <theory> <formula> [secs] [det\|flat]`, `prof/*.lisp` | profiles the evaluator on the n-level decision (`decn_o`) |
| `import_paths.py <dir>` | counts the import paths PVS 8.1's circularity check walks (see below) |
| `redundant_imports.py <dir> [--apply]` | finds IMPORTING entries already imported through another |
| `pvs-circular-deps.lisp`, `README-pvs-circular-deps.md` | a fix for PVS 8.1's slow circularity check on large directories |
| `export_public.sh <public-clone> [commit]` | stages the public repository's next commit: a commit of the development repository without `paper/` and `CLAUDE.md`; it never commits or pushes |
