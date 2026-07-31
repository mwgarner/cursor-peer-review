#!/usr/bin/env bash
# collect-diff.sh — summarize git changes for /peer-review-execution
#
# Usage:
#   collect-diff.sh <workspace> [base-ref]
#
# Prints DIFF_MODE, FILE_COUNT, and a truncated diff summary to stdout.
# Also writes full patch to a temp file and prints DIFF_FILE:<path>.
#
# When the working tree is clean and base..HEAD is empty (e.g. you are on
# main after an initial commit), falls back to empty-tree...HEAD so the
# root commit is reviewable. Pass an explicit base-ref to override.
set -euo pipefail

WS="${1:-.}"
BASE_ARG="${2:-}"
cd "$WS"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "NOT_GIT_REPO:$WS" >&2
  exit 1
fi

default_base() {
  local remote_head
  if remote_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    # origin/main → main
    echo "${remote_head#origin/}"
    return 0
  fi
  if git show-ref --verify --quiet refs/heads/main; then
    echo main
  elif git show-ref --verify --quiet refs/heads/master; then
    echo master
  else
    git rev-parse --abbrev-ref HEAD
  fi
}

has_uncommitted() {
  ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]
}

empty_tree() {
  git hash-object -t tree /dev/null
}

write_range() {
  local base="$1"
  local label="$2"
  {
    echo "### git log --oneline ${label}"
    git log --oneline "${base}..HEAD" 2>/dev/null | head -n 50 || true
    echo
    echo "### git diff ${label}"
    git diff "${base}...HEAD"
  } >"$OUT"
}

OUT="$(mktemp -t peer-review-exec-diff.XXXXXX.patch)"
MODE=""
BASE=""

if has_uncommitted; then
  MODE="working-tree"
  {
    echo "### git status --short"
    git status --short
    echo
    echo "### git diff (unstaged)"
    git diff
    echo
    echo "### git diff --cached (staged)"
    git diff --cached
  } >"$OUT"
elif [[ -n "$BASE_ARG" ]]; then
  MODE="range"
  BASE="$BASE_ARG"
  write_range "$BASE" "${BASE}...HEAD"
else
  MODE="range"
  BASE="$(default_base)"
  write_range "$BASE" "${BASE}...HEAD"

  bytes_probe="$(wc -c <"$OUT" | tr -d ' ')"
  # Clean tip on default branch with nothing since BASE → empty. If HEAD is a
  # root commit (no parent), review the whole tree via empty-tree...HEAD.
  if [[ "$bytes_probe" -lt 80 ]] && ! git rev-parse --verify -q HEAD^ >/dev/null; then
    MODE="initial-commit"
    BASE="empty-tree"
    ET="$(empty_tree)"
    {
      echo "### BUILD: initial / root commit (empty-tree...HEAD)"
      echo "### git log --oneline -1"
      git log --oneline -1
      echo
      echo "### git diff empty-tree...HEAD"
      git diff "$ET" HEAD
    } >"$OUT"
  fi
fi

bytes="$(wc -c <"$OUT" | tr -d ' ')"
# Count files touched roughly
files="$(grep -E '^(diff --git|\?\?| M|A |D |R |MM|AM)' "$OUT" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

if [[ "$bytes" -lt 20 ]]; then
  echo "EMPTY_DIFF:yes"
else
  echo "EMPTY_DIFF:no"
fi

echo "DIFF_MODE:$MODE"
echo "DIFF_BASE:${BASE:-working-tree}"
echo "DIFF_BYTES:$bytes"
echo "DIFF_FILE_HINTS:$files"
echo "DIFF_FILE:$OUT"

# Short preview for orchestrator kickoff
echo "DIFF_PREVIEW_BEGIN"
head -n 80 "$OUT"
echo "DIFF_PREVIEW_END"
