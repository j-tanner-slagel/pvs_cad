# PVS 8.1: the post-typecheck circular-dependency check on a large library

## Symptom
- Emacs: `M-x typecheck` prints "X typechecked in N s", but the mode line stays at `(PVS :tc)`,
  the PVS process runs at 100% CPU, and later commands (`M-x prove`, ...) wait forever.
- pvs-cli / JSON-RPC server: the client never gets the reply to a typecheck.
- Batch `proveit` is not affected, and nothing is wrong with the theories: typechecking has
  finished and the check finds no circularity. Clearing `pvsbin` does not help.

## Cause
After typechecking a file, `typecheck-theories` (PVS `src/pvs.lisp`) calls
`circular-file-dependencies` (`src/context.lisp`), which looks for a loop in the file-level import
graph. Its helper `circular-file-dependencies*` follows every import path from the file and never
records which theories it has already explored, so a theory reachable by k routes is explored k
times: the cost is the number of paths through the import graph, not the number of theories.
Only theories of the current directory count (library theories and the prelude are skipped). In a
layered library the number of paths grows multiplicatively with the depth of the layering.

Measured with PVS's original function on this library: about 32 µs per explored theory;
`sturm_sg` (97 theories below it) 174,157 explorations, 5.6 s; `towern_od` (114) 5.9 million,
186 s; a file importing the decision, about 280 million, roughly 2.5 hours. For comparison, the
worst-case path counts in NASALib directories range from 19 (`structures`) to 1,182 (`dL`); this
library's single directory had about 852 million from `top.pvs` before redundant imports were
removed, about 91 million after.

## Fix
`pvs-circular-deps.lisp` redefines `circular-file-dependencies` and `circular-file-dependencies*`
with a visited set, so each theory is explored once per check. It reports the same circularities:
the circularity test still runs, on every path, before the visited test, and whether a path from a
theory returns to the starting file does not depend on the route that reached the theory.

Install: copy it to `~/.pvs.lisp` (PVS loads that file at startup; `pvs -q` skips it). Undo: delete
`~/.pvs.lisp`. If PVS is upgraded, check whether `context.lisp` changed before keeping it.

The proper fix belongs in PVS itself (the same visited set in `src/context.lisp`). Large
developments can also avoid the problem by splitting into several directories, as NASALib does,
since imports from other libraries are not walked.
