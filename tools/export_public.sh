#!/bin/bash
# export_public.sh <public-clone> [commit]: prepares the public repository's next commit from
# a commit of this development repository (default HEAD).  The clone's tracked files are
# replaced by `git archive <commit>` without paper/ (the paper draft) and CLAUDE.md (the
# working instructions for Claude Code sessions), so deletions carry over and untracked or
# ignored files never travel.  It stages the result and shows what changed; it does not
# commit or push: the owner reviews the files and the commit message first, and the commit
# is made as J. Tanner Slagel <132794991+j-tanner-slagel@users.noreply.github.com>.
set -e
. "$(dirname "$0")/env.sh"
CLONE=${1:?usage: export_public.sh <public-clone> [commit]}
REV=${2:-HEAD}
git -C "$CLONE" rev-parse --git-dir > /dev/null
if [ -n "$(git -C "$CLONE" status --porcelain)" ]; then
  echo "export_public.sh: $CLONE has uncommitted changes; nothing done" >&2
  exit 1
fi
git -C "$CLONE" rm -rq --ignore-unmatch -- .
git -C "$CAD_ROOT" archive "$REV" -- . ':(exclude)paper' ':(exclude)CLAUDE.md' | tar -x -C "$CLONE"
git -C "$CLONE" add -A
echo "export of $(git -C "$CAD_ROOT" rev-parse --short "$REV") staged in $CLONE:"
git -C "$CLONE" diff --cached --stat | tail -1
git -C "$CLONE" diff --cached --name-status | head -50
