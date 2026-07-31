#!/usr/bin/env bash
# install.sh — install peer-review (+ helper) skills into ~/.cursor/skills/
#
# Usage:
#   ./install.sh              # symlink all skills (default)
#   ./install.sh --copy       # copy trees
#   ./install.sh --core       # only peer-review-plan|execution|ship
#   ./install.sh --force      # replace an existing non-matching destination
#   ./install.sh --help
set -euo pipefail

MODE="symlink"
SET="all"
FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --symlink | -s) MODE="symlink" ;;
    --copy | -c) MODE="copy" ;;
    --core) SET="core" ;;
    --all) SET="all" ;;
    --force | -f) FORCE=1 ;;
    -h | --help)
      cat <<'EOF'
Install Cursor skills from this repo into ~/.cursor/skills/<name>.

  ./install.sh           symlink all skills (default)
  ./install.sh --copy    copy instead of symlink
  ./install.sh --core    only peer-review-plan, execution, ship
  ./install.sh --force   replace destinations that are not links to this clone

Skills:
  peer-review-plan, peer-review-execution, peer-review-ship
  issue-to-plan   (issue → draft plan; stops; untrusted input)
  open-pr         (validate → commit → open PR)
  merge-pr        (checks + chat confirm → squash merge)
  delivery-ship   (open-pr then merge-pr)

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
  NAMES=(peer-review-plan peer-review-execution peer-review-ship issue-to-plan open-pr merge-pr delivery-ship)
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

abs_path() {
  local f="$1"
  (cd "$(dirname "$f")" && printf '%s/%s\n' "$(pwd)" "$(basename "$f")")
}

# True if $dst is a symlink whose ultimate target equals $src.
same_target() {
  local src="$1" dst="$2"
  [[ -L "$dst" ]] || return 1
  local link parent resolved
  link="$(readlink "$dst")"
  parent="$(cd "$(dirname "$dst")" && pwd)"
  if [[ "$link" == /* ]]; then
    resolved="$(abs_path "$link")"
  else
    resolved="$(abs_path "$parent/$link")"
  fi
  [[ "$resolved" == "$(abs_path "$src")" ]]
}

for name in "${NAMES[@]}"; do
  src="$REPO/skills/$name"
  dst="$DEST/$name"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if same_target "$src" "$dst"; then
      echo "OK      $dst already → $src"
      continue
    fi
    if [[ "$FORCE" -ne 1 ]]; then
      echo "EXISTS: $dst (not a symlink to this clone). Re-run with --force to replace, or remove it." >&2
      exit 1
    fi
    rm -rf "$dst"
  fi

  if [[ "$MODE" == "copy" ]]; then
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
echo "Done ($MODE, set=$SET). Try in Cursor (slash-invoke; reload window if skills are not listed):"
echo "  /peer-review-plan | /peer-review-execution | /peer-review-ship"
echo "  /issue-to-plan | /open-pr | /merge-pr | /delivery-ship"
echo
echo "No full-send from issue text. Agent merge uses /merge-pr chat confirm. See SECURITY.md."
