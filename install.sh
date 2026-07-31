#!/usr/bin/env bash
# install.sh — install peer-review (+ optional helper) skills into ~/.cursor/skills/
#
# Usage:
#   ./install.sh              # symlink all skills (default)
#   ./install.sh --copy       # copy trees
#   ./install.sh --core       # only peer-review-plan|execution|ship
#   ./install.sh --help
set -euo pipefail

MODE="symlink"
SET="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --symlink | -s) MODE="symlink" ;;
    --copy | -c) MODE="copy" ;;
    --core) SET="core" ;;
    --all) SET="all" ;;
    -h | --help)
      cat <<'EOF'
Install Cursor skills from this repo into ~/.cursor/skills/<name>.

  ./install.sh           symlink all skills (default)
  ./install.sh --copy    copy instead of symlink
  ./install.sh --core    only peer-review-plan, execution, ship

Skills:
  peer-review-plan, peer-review-execution, peer-review-ship
  issue-to-plan   (issue → draft plan; stops; untrusted input)
  open-pr         (validate → commit → open PR; never merges)

Does not symlink the repo root or the parent skills/ directory.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try --help)" >&2
      exit 2
      ;;
  esac
  shift
done

REPO="$(cd "$(dirname "$0")" && pwd)"
DEST="${CURSOR_SKILLS_DIR:-${HOME}/.cursor/skills}"

if [[ "$SET" == "core" ]]; then
  NAMES=(peer-review-plan peer-review-execution peer-review-ship)
else
  NAMES=(peer-review-plan peer-review-execution peer-review-ship issue-to-plan open-pr)
fi

mkdir -p "$DEST"

missing=0
for name in "${NAMES[@]}"; do
  if [[ ! -d "$REPO/skills/$name" ]]; then
    echo "MISSING: $REPO/skills/$name" >&2
    missing=1
  fi
done
if [[ "$missing" -ne 0 ]]; then
  echo "Abort: need skill folders under $REPO/skills/" >&2
  exit 1
fi

for name in "${NAMES[@]}"; do
  src="$REPO/skills/$name"
  dst="$DEST/$name"
  if [[ "$MODE" == "copy" ]]; then
    rm -rf "$dst"
    cp -R "$src" "$dst"
    if [[ -d "$dst/scripts" ]]; then
      chmod +x "$dst"/scripts/*.sh 2>/dev/null || true
    fi
    echo "Copied  $src → $dst"
  else
    ln -sfn "$src" "$dst"
    echo "Linked  $dst → $src"
  fi
done

echo
echo "Done ($MODE, set=$SET). Try in Cursor:"
echo "  /peer-review-plan | /peer-review-execution | /peer-review-ship"
echo "  /issue-to-plan | /open-pr"
echo
echo "There is no full-send skill. Human gates stay on."
