#!/usr/bin/env bash
# resolve-plan.sh — locate/validate a Cursor plan for /peer-review-execution
#
# Usage:
#   resolve-plan.sh                 # list recent plans
#   resolve-plan.sh <path-or-query> # resolve → RESOLVED:/abs/path + size meta
#
# Exit codes: 0 ok/list, 1 not found/empty, 2 ambiguous
set -euo pipefail

PLANS_DIR="${CURSOR_PLANS_DIR:-${HOME}/.cursor/plans}"
WORKSPACE="${CURSOR_WORKSPACE:-${PWD}}"
MAX_LIST="${MAX_LIST:-8}"

abs_path() {
  local f="$1"
  local dir base
  dir="$(cd "$(dirname "$f")" && pwd)"
  base="$(basename "$f")"
  printf '%s/%s\n' "$dir" "$base"
}

expand_tilde() {
  local p="$1"
  if [[ "$p" == "~" ]]; then
    printf '%s\n' "$HOME"
  elif [[ "$p" == ~/* ]]; then
    printf '%s/%s\n' "$HOME" "${p#~/}"
  else
    printf '%s\n' "$p"
  fi
}

validate_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "NOT_FOUND:$f" >&2
    return 1
  fi
  if [[ ! -r "$f" ]]; then
    echo "UNREADABLE:$f" >&2
    return 1
  fi
  if [[ ! -s "$f" ]]; then
    echo "EMPTY:$f" >&2
    return 1
  fi
  local bytes lines size_class
  bytes="$(wc -c <"$f" | tr -d ' ')"
  lines="$(wc -l <"$f" | tr -d ' ')"
  size_class="small"
  if (( bytes > 80000 || lines > 2000 )); then
    size_class="large"
  fi
  f="$(abs_path "$f")"
  echo "RESOLVED:$f"
  echo "BYTES:$bytes"
  echo "LINES:$lines"
  echo "SIZE_CLASS:$size_class"
}

list_recent() {
  if [[ ! -d "$PLANS_DIR" ]]; then
    echo "No plans directory: $PLANS_DIR" >&2
    return 1
  fi

  local -a files=()
  local f
  # Newest first; prefer *.plan.md then other *.md
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done < <(ls -t "$PLANS_DIR"/*.plan.md 2>/dev/null || true)

  if [[ ${#files[@]} -lt $MAX_LIST ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local already=0
      local e
      for e in "${files[@]+"${files[@]}"}"; do
        [[ "$e" == "$f" ]] && already=1 && break
      done
      if [[ $already -eq 0 ]]; then
        files+=("$f")
      fi
      [[ ${#files[@]} -ge $MAX_LIST ]] && break
    done < <(ls -t "$PLANS_DIR"/*.md 2>/dev/null || true)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No plan files found in $PLANS_DIR" >&2
    return 1
  fi

  echo "Recent plans in $PLANS_DIR:"
  local i=1 bytes lines
  for f in "${files[@]}"; do
    [[ $i -gt $MAX_LIST ]] && break
    bytes="$(wc -c <"$f" | tr -d ' ')"
    lines="$(wc -l <"$f" | tr -d ' ')"
    printf '%2d. %s (%s bytes, %s lines)\n' "$i" "$(abs_path "$f")" "$bytes" "$lines"
    i=$((i + 1))
  done
}

resolve_one() {
  local raw="$1"
  local p
  p="$(expand_tilde "$raw")"

  if [[ -f "$p" ]]; then
    validate_file "$p"
    return $?
  fi

  if [[ -f "$WORKSPACE/$raw" ]]; then
    validate_file "$WORKSPACE/$raw"
    return $?
  fi
  if [[ -f "$WORKSPACE/$p" ]]; then
    validate_file "$WORKSPACE/$p"
    return $?
  fi

  local base="${raw##*/}"
  local -a candidates=()
  [[ -f "$PLANS_DIR/$base" ]] && candidates+=("$PLANS_DIR/$base")
  [[ -f "$PLANS_DIR/${base}.plan.md" ]] && candidates+=("$PLANS_DIR/${base}.plan.md")
  [[ -f "$PLANS_DIR/${base}.md" ]] && candidates+=("$PLANS_DIR/${base}.md")

  if [[ ${#candidates[@]} -eq 0 && -d "$PLANS_DIR" ]]; then
    local f
    while IFS= read -r f; do
      [[ -n "$f" ]] && candidates+=("$f")
    done < <(ls -1 "$PLANS_DIR"/*"$base"*.plan.md 2>/dev/null || true)
  fi

  # Dedupe
  local -a uniq=()
  local c u seen
  for c in "${candidates[@]+"${candidates[@]}"}"; do
    seen=0
    for u in "${uniq[@]+"${uniq[@]}"}"; do
      [[ "$u" == "$c" ]] && seen=1 && break
    done
    [[ $seen -eq 0 ]] && uniq+=("$c")
  done
  candidates=("${uniq[@]+"${uniq[@]}"}")

  if [[ ${#candidates[@]} -eq 1 ]]; then
    validate_file "${candidates[0]}"
    return $?
  fi
  if [[ ${#candidates[@]} -gt 1 ]]; then
    echo "AMBIGUOUS:$raw" >&2
    for c in "${candidates[@]}"; do
      echo "  - $(abs_path "$c")" >&2
    done
    return 2
  fi

  echo "NOT_FOUND:$raw" >&2
  list_recent >&2 || true
  return 1
}

main() {
  if [[ $# -lt 1 ]]; then
    list_recent
    return $?
  fi
  resolve_one "$1"
}

main "$@"
