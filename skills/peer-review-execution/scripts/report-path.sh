#!/usr/bin/env bash
# report-path.sh — paths for /peer-review-execution reports
#
# Usage: report-path.sh <resolved-plan-path>
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
stem="${base%.plan.md}"
stem="${stem%.md}"

ts="$(date -u +%Y-%m-%dT%H%M%SZ)"
review_dir="${REVIEWS_ROOT}/${stem}/execution"
report_path="${review_dir}/${ts}.md"
latest_path="${review_dir}/LATEST.md"
prior_plan_review="${REVIEWS_ROOT}/${stem}/LATEST.md"

mkdir -p "$review_dir"

index="${REVIEWS_ROOT}/README.md"
README_BODY='# Plan peer reviews

Created by `/peer-review-plan`, `/peer-review-execution`, and `/peer-review-ship`.

```
~/.cursor/plan-reviews/
  <plan-stem>/
    LATEST.md                 # plan peer review (before Build)
    <timestamp>.md
    execution/
      LATEST.md               # execution peer review (after Build)
      <timestamp>.md
```

## Citation ids (outside review transcripts)

`C-M*` / `C-B*` inside a report are session-local. When citing from code/tests/plan locks:

- Plan finding: `{plan-stem}/C-M2`
- Execution finding: `{plan-stem}/execution/C-M2`
- Prefer spike `D#` / Acc `#` / ADR when the lock graduated.
- Never bare `C-M2` in lasting product code.
'

if [[ ! -f "$index" ]]; then
  printf '%s\n' "$README_BODY" >"$index"
fi

# Refresh README if missing execution/ layout or citation section
if ! grep -q 'execution/' "$index" 2>/dev/null || ! grep -q 'Citation ids' "$index" 2>/dev/null; then
  printf '%s\n' "$README_BODY" >"$index"
fi

echo "STEM:$stem"
echo "REVIEW_DIR:$review_dir"
echo "REPORT_PATH:$report_path"
echo "LATEST_PATH:$latest_path"
echo "PRIOR_PLAN_REVIEW:$prior_plan_review"
if [[ -f "$prior_plan_review" ]]; then
  echo "PRIOR_PLAN_REVIEW_EXISTS:yes"
else
  echo "PRIOR_PLAN_REVIEW_EXISTS:no"
fi
echo "PLAN_PATH:$(cd "$(dirname "$plan")" && pwd)/$(basename "$plan")"
