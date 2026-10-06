#!/bin/bash
# export_public.sh <public-clone> <commit or tag>: prepares the public repository's next commit
# from a commit of this development repository (named explicitly, so a half-done state on
# main is never exported by accident).  The clone's tracked files are
# replaced by `git archive <commit>` without paper/ (the paper draft) and CLAUDE.md (the
# working instructions for Claude Code sessions), so deletions carry over and untracked or
# ignored files never travel.  It stages the result, shows what changed per directory, and
# scans the staged files for personal information (paths with the machine's account name or
# home directory, scratch paths, e-mail addresses other than noreply ones, LinkedIn, travel
# and family words); it does not commit or push: the owner reviews the files, the scan and
# the commit message first, and the commit is made as
# J. Tanner Slagel <132794991+j-tanner-slagel@users.noreply.github.com>.
set -e
. "$(dirname "$0")/env.sh"
CLONE=${1:?usage: export_public.sh <public-clone> <commit or tag>}
REV=${2:?usage: export_public.sh <public-clone> <commit or tag>}
git -C "$CAD_ROOT" rev-parse --verify --quiet "$REV^{commit}" > /dev/null ||
  { echo "export_public.sh: $REV is not a commit of $CAD_ROOT" >&2; exit 1; }
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
echo "changes per directory (added / modified / deleted):"
git -C "$CLONE" diff --cached --name-status | awk '
  { d = ($2 ~ /\//) ? substr($2, 1, index($2, "/") - 1) "/" : "(top)"; n[d, $1]++; seen[d] = 1 }
  END { for (d in seen) printf "  %-12s %4d / %4d / %4d\n", d, n[d, "A"], n[d, "M"], n[d, "D"] }' | sort
echo "personal-information scan of the staged files:"
# plain grep: git grep's -E has no \b on every platform
hits=$(cd "$CLONE" && git ls-files -z | xargs -0 grep -n -I -i -E \
  "$(id -un)|$HOME|/private/|/tmp/claude|/Users/|linkedin|\btrip\b|\bvacation\b|\bflight\b|\bwife\b|\bdad\b|\bmy (son|daughter|kid)\b|splash|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" |
  grep -v -i -E 'users\.noreply\.github\.com|noreply@anthropic\.com')
if [ -n "$hits" ]; then
  printf '%s\n' "$hits" | head -40 | sed 's/^/  ?? /'
  echo "  $(printf '%s\n' "$hits" | wc -l | tr -d ' ') hits: review each before pushing"
else
  echo "  no hits"
fi
