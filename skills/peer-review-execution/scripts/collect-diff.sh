#!/usr/bin/env bash
# collect-diff.sh — summarize git changes for /peer-review-execution
#
# Usage:
#   collect-diff.sh <workspace> [base-ref]
#
# Prints DIFF_MODE, FILE_COUNT, and a truncated diff summary to stdout.
# Also writes full patch to a temp file and prints DIFF_FILE:<path>.
set -euo pipefail

WS="${1:-.}"
BASE_ARG="${2:-}"
cd "$WS"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "NOT_GIT_REPO:$WS" >&2
  exit 1
fi

default_base() {
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
  {
    echo "### git log --oneline ${BASE}..HEAD"
    git log --oneline "${BASE}..HEAD" | head -n 50
    echo
    echo "### git diff ${BASE}...HEAD"
    git diff "${BASE}...HEAD"
  } >"$OUT"
else
  MODE="range"
  BASE="$(default_base)"
  {
    echo "### git log --oneline ${BASE}..HEAD"
    git log --oneline "${BASE}..HEAD" | head -n 50
    echo
    echo "### git diff ${BASE}...HEAD"
    git diff "${BASE}...HEAD"
  } >"$OUT"
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
