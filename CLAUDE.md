# CLAUDE.md — verified CAD / computer algebra for PVS

This directory is the `pvs_cad` library (public release: GitHub `j-tanner-slagel/pvs_cad`;
development repository: the private `pvs_cad-dev`, branch `main`). Nothing in the repo depends on where it is checked out (see
`tools/env.sh`); always `git pull` first, because work moves between machines (an old copy
on an external drive is stale). The goal and the phased plan are in
`CAD_PLAN.md` and the endgame in `FINISH_PLAN.md`; read them first in every session.
The CURRENT goal (set 2026-09-29) is `GAP_PLAN.md`: close the gap between decide5 and a
verified CAD in the classical sense. Its status header records what is done (Tiers 0, 1A-1C and
the cad_spec semi-algebraicity stage, 2026-09-30) -- read it before anything else. The previous
goal, verified completeness of (cad) (`COMPLETENESS_PLAN.md`), was reached 2026-09-28. The reference paper is
Narkawicz, Muñoz, Dutle, J. Automated Reasoning 54 (2015), doi 10.1007/s10817-015-9320-x
(Sturm/Tarski decision procedures in PVS).
The PVS library being built lives in `cad/` (one theory per concern, `top.pvs` with
description blocks); running history goes in `cad/PROGRESS.md`.

A matrix decomposition library that used to live here moved to a separate repository.
Do not recreate it here.

## PVS installation and tools (portable)

- `tools/env.sh` (sourced by every tool) finds everything without machine-specific paths:
  the repo from its own location, PVS from `pvs` on `PATH` (or `PVS_DIR`), NASALib at
  `$PVS_DIR/nasalib` or `$PVS_DIR/pvslib` (or `NASALIB`), scratch in `/tmp/cad_scratch`
  (or `SCRATCH`), the pvs-cli server port 23456 (or `PVS_PORT`).
- On a new machine run `tools/setup.sh` once: it creates the repo's `.venv` (websockets for
  pvs-cli; not committed) and checks that PVS, proveit and the NASALib libraries are found.
- Check `proveit --version` and `$NASALIB/nasalib-version` at the start of a phase.
- Libraries this work builds on: `Sturm`, `Tarski`, `mult_poly`, `Bernstein`, `reals`,
  `analysis`, `structures`, `complex`; strategy toolkit in `$PVS_DIR/src/Field/extrategies.lisp`.
- On a small-RAM machine watch `vm_stat | sed -n 2p`; below ~5000 free pages `proveit`
  hangs. Close other apps rather than fight it (the user has permitted this).

## How proofs are developed here (standing rules from the user)

1. **Proofs are developed with pvs-cli** against a PVS server, in the main conversation:
   `tools/cli/srv.sh <theory>` (re)starts the server in `cad/` and typechecks,
   `tools/cli/pv.sh <theory> <formula> <cmd>` starts a proof and sends a command,
   `tools/cli/p.sh <cmd>` / `tools/cli/ps.sh <cmd>` send further commands (full / compact
   sequent), `tools/cli/ev.sh <expr>` evaluates in the active proof, `tools/cliprove.sh`
   runs a batch of one-command proofs. PVS saves each finished proof in the `.prf` itself.
   **No background agents or forks for the actual proving** — small visible steps the user
   can interrupt. A long-lived server gets slow: restart it with `srv.sh`.
2. Raw `pvs -raw` sessions (`tools/pvs_raw_timeout.sh <in> <out> <timeout>`, a watchdog,
   since macOS has no `timeout`) are only for batch jobs such as timing an evaluation. Never
   prooflite `.prl` or `%|-` scripts.
3. **Prove everything. Never skip, defer, or weaken a lemma.** When stuck, decompose into
   smaller, isolated lemmas and prove those. Proof size and session length are not
   reasons to change scope.
4. **Small topic-scoped files**, one theory per concern; well under 300 formulas per file.
   Start a new file when a new property begins. Wire each finished file into `top.pvs`
   with an `IMPORTING` and a description block.
5. **Run only the file being worked on**: `proveit -f <file>.pvs`; installing proofs
   with proveit is fine. Do not run `top.pvs`
   after every step; whole-library checks only at the end of a phase or on request.
6. **Verification gate per file** (`tools/gate.sh <theory>...`, run in a scratch copy of
   `cad/` so it cannot clash with a running server): three consecutive fresh `proveit -f`
   runs plus `proveit -l --traces -f` with zero "fewer subproofs" warnings. A Q.E.D. or a `T` from
   `save-all-proofs` in a session is not evidence a proof is on disk.
7. Clear caches often: `rm -rf cad/pvsbin` before each batch and after any crash; delete
   `$NASALIB/structures/pvsbin/array2list.bin` if `proveit` fails typechecking
   `array2list`. `binding stack exhausted` means stale cache.
8. **`.prf` files are written only by PVS** (pvs-cli sessions and proveit). Editing a
   `.prf` by hand or generating one with a script (`tools/build_prf_from_transcript.py`,
   `tools/prf_from_cmds.py`) is a last resort, only with the user's say-so.
   `tools/openstates.py` shows open goals, `tools/effective.py` strips no-op commands.
9. Executable functions (the ones `eval-expr` will run) go in their own theories, separate
   from their correctness theorems. Strategies live in `cad/pvs-strategies`; write them
   with `with-fresh-labels`/`with-fresh-names`; renames can break proofs, so re-verify.
10. After each verified item: update `cad/PROGRESS.md`, `cad/top.pvs`, memory, then commit
    and push.

## Repository hygiene

- The repository came from the exFAT T7 volume: `git config core.fileMode false` is still
  set so mode bits are not reported as changes, and `._*` AppleDouble files are ignored.
