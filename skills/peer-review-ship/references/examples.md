# Examples — peer-review ship

## Full pipeline

```
/peer-review-ship this plan
```

Runs `/peer-review-plan` → Gate Apply (if needed) → Gate Build → `/peer-review-execution` → Gate Fix if gaps.

## Stop after plan review

```
/peer-review-ship ~/.cursor/plans/foo.plan.md from=plan loops=2
```

Prints next steps; user can later `/peer-review-ship … from=execution` or run `/peer-review-execution` alone.

## Resume at execution

```
/peer-review-ship this plan from=execution
```

Requires prior plan review `LATEST.md` when possible; skips plan phase; still waits for Build-done if this chat has not already confirmed Build.

## Natural language

```
Ship the example feature plan through peer review and execution
```

Orchestrator resolves the plan, then follows the gated phases.
