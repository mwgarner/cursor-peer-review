---
name: peer-review-ship
description: >-
  Gated handrail that sequences /peer-review-plan, user Apply deltas, user
  Build, then /peer-review-execution for one Cursor plan. Invoked as
  /peer-review-ship. Never auto-Builds, never skips human gates, never forks
  critic logic — reads and follows the sibling skills. Use when the user wants
  plan review through execution fidelity in one flow.
disable-model-invocation: true
---

# Peer review ship

Thin orchestrator that strings **plan peer review → Apply → Build → execution peer review** with hard human gates. **Never auto-Build. Never invent critic logic** — follow sibling skills by reading their `SKILL.md` and running their procedures.

| Sibling | Path |
|---------|------|
| Plan review | `~/.cursor/skills/peer-review-plan/SKILL.md` |
| Execution review | `~/.cursor/skills/peer-review-execution/SKILL.md` |

Related (optional, separate invokes — **not** auto-chained by this skill):

| Skill | Role |
|-------|------|
| `/issue-to-plan` | Issue → draft plan → stop (untrusted input) |
| `/open-pr` / `/merge-pr` / `/delivery-ship` | Agent open PR + gated agent merge (chat confirm; no force/`--admin`) |

Skim [references/examples.md](references/examples.md) if invocation is ambiguous.

## Invocation

```
/peer-review-ship
/peer-review-ship this plan
/peer-review-ship the example feature plan, 2 loops
/peer-review-ship ~/.cursor/plans/foo.plan.md from=execution
```

No path → same resolve as plan review (`bash ~/.cursor/skills/peer-review-plan/scripts/resolve-plan.sh`) or AskQuestion.

**Optional knobs** (pass through to the active phase where relevant):

| Arg | Default | Meaning |
|-----|---------|--------|
| plan path | ask / recent list | Same resolution as `/peer-review-plan` |
| `loops=N` | `2` | Loops for each review phase |
| `gpt=` / `cheap` / `early-stop` / `no-save` | same as siblings | Forwarded |
| `planner=` | plan-phase only | Defender for plan review |
| `builder=` / `base=` | execution-phase only | Forwarded to execution review |
| `from=plan` | full pipeline | Stop after plan review; print next steps (Apply → Build → `/peer-review-execution` or resume ship) |
| `from=execution` | — | Skip plan phase; require existing `~/.cursor/plan-reviews/<stem>/LATEST.md` (or warn and AskQuestion) |

## Progress checklist

```
Peer-review ship:
- [ ] Resolve plan; announce stem + from= + flags
- [ ] Phase Plan (unless from=execution) — follow peer-review-plan SKILL.md
- [ ] Gate Apply — if not plain Approve, wait for explicit Apply confirm
- [ ] If from=plan → stop with next-step handoff
- [ ] Gate Build — wait for explicit “Build done” / equivalent; never implement unless user asks in that reply
- [ ] Phase Execution — follow peer-review-execution SKILL.md
- [ ] Gate Fix — if Incomplete/gaps, present fix deltas; apply only on explicit ask
```

## Phases and gates

### Phase Plan

Unless `from=execution`:

1. **Read and follow** `~/.cursor/skills/peer-review-plan/SKILL.md` end-to-end for this plan (same loops/flags).
2. Do not mutate the plan during review loops.
3. After the plan report is saved (unless `no-save`), continue to Gate Apply.

### Gate Apply

- Verdict **Approve** (no deltas) → proceed to Gate Build (or stop if `from=plan`).
- Verdict **Approve with changes** or **Reject** → **stop**. Ask the user to confirm Apply deltas (plan/spike only). Do **not** proceed on silence.
- On explicit Apply: edit plan/spike per peer-review-plan apply-deltas rules (promote Acc/D; compound `{stem}/C-*` if needed). Then continue (or stop if `from=plan`).

### Gate Build

**Stop** with: plan is ready — Build when ready; reply **Build done** (or equivalent) when the product change set is in the working tree / commits you want reviewed.

- **Never** start product implementation yourself unless the user explicitly asks to Build in that gate reply (separate Build request).
- **Never** pick a builder model unbidden.
- Wait for explicit user signal before Phase Execution.

### Phase Execution

1. **Read and follow** `~/.cursor/skills/peer-review-execution/SKILL.md` for the same plan stem.
2. Load prior `~/.cursor/plan-reviews/<stem>/LATEST.md` as that skill already does.
3. If `from=execution` and no prior plan `LATEST.md`: note in Meta; AskQuestion whether to proceed with plan-only or abort.

### Gate Fix

- Verdict **Faithful** → done; mention citation policy if useful.
- **Faithful with gaps** / **Incomplete** / **Regressed** → present follow-up fix deltas; apply code/docs only on explicit user ask. Do not start a new Build loop unbidden.

## Citation reminder

When Build or fix work cites peer-review findings, use the ladder in the sibling rubrics:

1. Spike `D#` / Acc `#` / ADR
2. `{plan-stem}/C-M2` or `{plan-stem}/execution/C-M2`
3. Never bare `C-M2` in lasting code/tests

## Hard constraints

1. No auto-Build; no skipping Gates Apply / Build / Fix
2. No forking critic panels — always delegate by following sibling SKILL.md
3. No plan mutation during review loops; Apply only after Gate Apply confirm
4. Keep ≤40-line carry inside each review phase (sibling rule)
5. `from=plan` must not run execution; `from=execution` must not re-run plan review unless user asks
6. No force-push, `--admin`, deploy, or full-send from GitHub issue text — after Build use `/open-pr` then `/merge-pr` (or `/delivery-ship`); merge still needs chat confirm

## Corner cases

| Case | Action |
|------|--------|
| User cancels mid-ship | Stop; report which phase completed + paths |
| User Builds before Apply when deltas required | Warn; AskQuestion — apply deltas first or proceed knowing plan is stale |
| Empty execution diff after “Build done” | Same as execution skill empty-diff AskQuestion |
| User says “continue” without naming a gate | Do not invent — restate the waiting gate |
