# Example walkthrough

A minimal, anonymized run of the gated pipeline so you can see the shape of
artifacts without reading every skill file.

This is **teaching fiction** — not a real product review. Paths use `~` and
neutral stems.

## Story

You want to publish a small OSS snapshot. You write a Cursor plan, peer-review
it, Apply deltas, Build, then execution-review the diff.

```text
/peer-review-ship ~/.cursor/plans/example_feature_aabbccdd.plan.md
```

## Files in this folder

| File | What it is |
|------|------------|
| [example_feature_aabbccdd.plan.md](example_feature_aabbccdd.plan.md) | Plan after Apply (locks graduated to Acc/D) |
| [plan-review.LATEST.md](plan-review.LATEST.md) | Condensed `/peer-review-plan` report (Reject → Apply) |
| [execution-review.LATEST.md](execution-review.LATEST.md) | Condensed `/peer-review-execution` report (Faithful with gaps) |

In a live Cursor session these live under:

```text
~/.cursor/plans/example_feature_aabbccdd.plan.md
~/.cursor/plan-reviews/example_feature_aabbccdd/LATEST.md
~/.cursor/plan-reviews/example_feature_aabbccdd/execution/LATEST.md
```

## Pipeline shape

```text
peer-review-plan
    → Gate Apply (if not plain Approve)
    → Gate Build  (human implements; never auto-Build)
    → peer-review-execution
    → Gate Fix    (optional polish)
```

## Citation ladder (steal this)

1. Promote locks to **Acc #** / **D #** / ADR in the plan before Build.
2. If you must cite a review finding in code/tests: `example_feature_aabbccdd/C-M2` or `example_feature_aabbccdd/execution/C-M2`.
3. Never leave bare `C-M2` as the durable label.

## What “good” looks like here

- Plan review found **real** blockers (scrub/acceptance under-scoped) → plan text fixed before Build.
- Build satisfied Acc/D locks; execution review only found doc polish.
- Human gates were not skipped.

## Related skills (not shown as artifacts)

- `/issue-to-plan` — optional intake from a GitHub issue; **stops** at a draft plan (issue text is untrusted).
- `/open-pr` → `/merge-pr` (or `/delivery-ship`) — agent opens then lands the PR with **chat confirm** after checks; no force-push / `--admin`.

There is still **no** issue-body→merge full-send path. See [SECURITY.md](../SECURITY.md).
