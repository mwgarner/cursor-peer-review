# Examples

## Happy path

User:

```
/peer-review-plan
```

or:

```
/peer-review-plan this plan
```

Orchestrator picks/asks for the plan, uses `loops=2`, runs the default panel, reports in chat. No flags required.

## Default GPT critic (Sol High)

```
/peer-review-plan ~/.cursor/plans/foo.plan.md loops=3
```

Critic C uses `gpt-5.6-sol-high` (Task-allowlisted). Pass `gpt=medium` to prefer Sol Medium when available, or `gpt=terra` / `cheap` for Terra Medium.

## Early stop

```
/peer-review-plan ./docs/spikes/example-spike.md loops=3 early-stop
```

Spike docs are allowed. If loop 1 ends with zero sustained blockers and majors, stop; report `Loops completed: 1 of 3`.

## Named planner defender

```
/peer-review-plan ~/.cursor/plans/foo.plan.md planner=claude-opus-5-thinking-max
```

Defender uses the named model; critics stay on the default panel.

## Save location (default)

Reviews are written automatically to:

```
~/.cursor/plan-reviews/<plan-stem>/LATEST.md
~/.cursor/plan-reviews/<plan-stem>/<timestamp>Z.md
```

Pass `no-save` for chat-only.

## No path

User: `/peer-review-plan`

Orchestrator runs `scripts/resolve-plan.sh` or lists recent plans → AskQuestion → then starts.

## Natural language

User: `Peer review the example feature plan with 2 loops`

Orchestrator finds the matching plan under `~/.cursor/plans/` or workspace; if multiple, AskQuestion.

## After review — apply deltas (separate step)

User: `Apply the recommended plan deltas`

Orchestrator edits the **plan file only** (and linked spike if needed), still no Build. When rewriting locks: prefer Acc/D / ADR ids; if a finding id must remain, use compound form e.g. `example_plan_aabbccdd/C-M8` — never bare `C-M8` as the durable label.

## After review — ADR

Report says `needs-ADR: yes`. User: `Write the ADR amendment`.

Only then create/amend `docs/decisions/…`.

## Compound citation (code / tests after Build)

```
// example_plan_aabbccdd/execution/C-M2 — clear pending state on dialog affirm
```

Plan-phase finding (not yet Acc/D): `example_plan_aabbccdd/C-M8`.

## After Build — execution review (separate skill)

```
/peer-review-execution this plan
```

Uses `/peer-review-execution` (sibling skill) to critique the diff against locked plan decisions. Not part of this skill.

## Full pipeline (gated handrail)

```
/peer-review-ship this plan
```

Runs plan review → stops for Apply deltas / Build-done → execution review. Never auto-Builds. See `/peer-review-ship`.
