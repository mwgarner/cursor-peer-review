#!/usr/bin/env bash
# report-path.sh — compute organized peer-review report paths
#
# Usage:
#   report-path.sh <resolved-plan-path>
#
# Prints:
#   STEM:...
#   REVIEW_DIR:...
#   REPORT_PATH:...          # timestamped archive file
#   LATEST_PATH:...          # always-updated latest copy
set -euo pipefail

REVIEWS_ROOT="${CURSOR_PLAN_REVIEWS_DIR:-${HOME}/.cursor/plan-reviews}"

if [[ $# -lt 1 ]]; then
  echo "Usage: report-path.sh <resolved-plan-path>" >&2
  exit 1
fi

plan="$1"
if [[ "$plan" == ~* ]]; then
  plan="${plan/#\~/$HOME}"
fi
if [[ ! -f "$plan" ]]; then
  echo "NOT_FOUND:$plan" >&2
  exit 1
fi

base="$(basename "$plan")"
# Strip .plan.md first, then .md
stem="$base"
stem="${stem%.plan.md}"
stem="${stem%.md}"
# Keep a short stable id if Cursor appended _<hash>
# (leave full stem — uniqueness matters more than prettiness)

ts="$(date -u +%Y-%m-%dT%H%M%SZ)"
review_dir="${REVIEWS_ROOT}/${stem}"
report_path="${review_dir}/${ts}.md"
latest_path="${review_dir}/LATEST.md"

mkdir -p "$review_dir"

# Sidecar index for humans
index="${REVIEWS_ROOT}/README.md"
if [[ ! -f "$index" ]]; then
  cat >"$index" <<'EOF'
# Plan peer reviews

Created by `/peer-review-plan`, `/peer-review-execution`, and `/peer-review-ship`.

Layout:

```
~/.cursor/plan-reviews/
  README.md
  <plan-stem>/
    LATEST.md           # plan peer review (before Build)
    2026-07-30T124500Z.md
    execution/
      LATEST.md         # execution peer review (after Build)
      …
```

Each review links back to the source plan path in its header.

## Citation ids (outside review transcripts)

`C-M*` / `C-B*` inside a report are session-local. When citing from code/tests/plan locks:

- Plan finding: `{plan-stem}/C-M2`
- Execution finding: `{plan-stem}/execution/C-M2`
- Prefer spike `D#` / Acc `#` / ADR when the lock graduated.
- Never bare `C-M2` in lasting product code.
EOF
fi

echo "STEM:$stem"
echo "REVIEW_DIR:$review_dir"
echo "REPORT_PATH:$report_path"
echo "LATEST_PATH:$latest_path"
echo "PLAN_PATH:$(cd "$(dirname "$plan")" && pwd)/$(basename "$plan")"
