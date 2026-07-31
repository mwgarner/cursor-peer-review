# Examples — execution review

## Happy path

```
/peer-review-execution this plan
```

After Build: resolves plan, collects working-tree diff, 2 loops, saves under `~/.cursor/plan-reviews/<stem>/execution/`.

## Explicit plan + base

```
/peer-review-execution ~/.cursor/plans/foo.plan.md base=main loops=2
```

Reviews commits/working tree vs `main`.

## After plan peer review

```
/peer-review-plan this plan
# … Build …
/peer-review-execution this plan
```

Orchestrator loads `.../LATEST.md` from the plan peer review as optional context.

## Compound citation (code / tests)

Execution findings cited outside the transcript:

```
example_plan_aabbccdd/execution/C-M2
```

Prefer spike `D#` / Acc `#` / ADR when the lock graduated. Bare `C-M2` is forbidden in lasting code. See rubric **Code / plan citation policy**.

## Full pipeline (gated handrail)

```
/peer-review-ship this plan
```

Or resume after a prior plan review:

```
/peer-review-ship this plan from=execution
```

## Chat-only

```
/peer-review-execution this plan no-save
```

## Natural language

```
Peer review the execution of the example feature plan against my uncommitted diff
```
