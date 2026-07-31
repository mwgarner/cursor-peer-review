---
name: peer-review-execution
description: >-
  Multi-model peer review of plan execution after Build. Invoked as
  /peer-review-execution with a plan path and optional loops=N. Compares the
  git diff (and tests) against locked plan decisions and any prior
  /peer-review-plan report. Use when the user wants critics to verify Build
  fidelity. Does not implement further code or choose models for a new Build.
disable-model-invocation: true
---

# Peer review execution

After Build: verify the working tree (or PR diff) **faithfully executed** the plan’s locked decisions. Multi-model critics → isolated synthesizer → builder defender → revisor → report.

**Never implement more product code. Never start a new Build. Never mutate the plan** unless the user later says to apply deltas.

Companion skill: `/peer-review-plan` (before Build). This skill is **after** Build. Gated pipeline: `/peer-review-ship`.

**Citations:** `C-*` ids are review-session local; plan vs execution reuse numbers. Outside transcripts use `{plan-stem}/execution/C-M2` (or spike `D#` / Acc `#` / ADR). See rubric **Code / plan citation policy**. Bare `C-M*` in new code = Nit.

Read [references/critique-rubric.md](references/critique-rubric.md), [references/prompts.md](references/prompts.md), and [references/fallbacks.md](references/fallbacks.md) before launching subagents. Skim [references/examples.md](references/examples.md) if needed.

## Invocation

**Easy (preferred):**

```
/peer-review-execution
/peer-review-execution this plan
/peer-review-execution the example feature plan, 2 loops
```

No path → resolve via `bash ~/.cursor/skills/peer-review-execution/scripts/resolve-plan.sh` (bundled; falls back to sibling `/peer-review-plan` script if missing) or list `~/.cursor/plans/`; AskQuestion. “This plan” → conversation / open editor if unambiguous.

**Optional knobs:**

| Arg | Default | Meaning |
|-----|---------|--------|
| plan path | ask / recent list | Same resolution rules as `/peer-review-plan` |
| `loops=N` or “N loops” | `2` | Integer **1–4** |
| `gpt=high\|medium\|terra` | `high` → `gpt-5.6-sol-high` | Critic C |
| `builder=<model>` | `cursor-grok-4.5-high` | Builder-defender model |
| `base=<ref>` | auto | Diff base when tree is clean: default branch (`main`/`master`) or given ref. If uncommitted changes exist, reviews **working tree** (staged+unstaged) and ignores `base`. |
| `early-stop` | off | Stop after a clean loop (no blockers/majors) |
| `no-save` | off | Chat-only (skip disk report) |
| `cheap` | off | Weaker Critic C (+ cheaper defender) |

**Reports default on** under `~/.cursor/plan-reviews/<plan-stem>/execution/`.

## Roles

| Role | Actor | Model | Duty |
|------|--------|--------|------|
| **Orchestrator** | This chat | User’s picker | Resolve inputs, collect diff, launch agents, final report |
| **Critic A/B/C** | Task `generalPurpose` | `composer-2.5` / `cursor-grok-4.5-high` / `gpt-5.6-sol-high` | Fidelity critique |
| **Synthesizer** | Task | Prefer `composer-2.5` | Consensus only |
| **Builder defender** | Task | `builder=` or `cursor-grok-4.5-high` | Defend implementation; concede gaps |
| **Revisor** | Task | Same as synthesizer | Dispositions + carry |

**Context hard rule:** Parent keeps only ≤40-line carry between loops — not raw critiques.

## Progress checklist

```
Execution peer review:
- [ ] Parse args; resolve plan
- [ ] Load prior plan peer-review LATEST.md if present (optional context)
- [ ] Collect diff (scripts/collect-diff.sh or git)
- [ ] Refuse if empty diff (ask: wrong base? uncommitted? already committed?)
- [ ] Announce panel + diff summary one line
- [ ] Loop k=1..N: 3 critics (one turn) → synthesizer → defender → revisor
- [ ] Final report + save under .../execution/ (unless no-save)
```

## Phase 0 — Setup

1. Parse args (`loops`, `gpt`, `builder`, `base`, `early-stop`, `no-save`, `cheap`).
2. Resolve plan path: prefer `bash ~/.cursor/skills/peer-review-execution/scripts/resolve-plan.sh`; else sibling `~/.cursor/skills/peer-review-plan/scripts/resolve-plan.sh`.
3. Read plan once. Extract **Locked decisions**, todos, acceptance gates, out of scope, Known residue.
4. Load `~/.cursor/plan-reviews/<stem>/LATEST.md` if it exists (prior `/peer-review-plan` report) — pass path to critics as optional context, not authority over the plan file.
5. **Collect execution evidence:**
   - Run `bash ~/.cursor/skills/peer-review-execution/scripts/collect-diff.sh <workspace> [base]`
   - Prefer uncommitted working tree when dirty; else commits since `base` (default branch)
6. If diff is empty: stop and AskQuestion (nothing to review / wrong base / already merged?).
7. Kickoff one-liner: `Execution review <plan> | loops=N | base=<…> | files=N | critics=…`

## Phase 1 — Loop body

### 1a. Critics (exactly 3, **one** assistant turn)

**Hard requirement:** launch **all three** Task calls in the **same** assistant turn. Never serialize A then B/C.

Use `subagent_type: generalPurpose`, templates in [references/prompts.md](references/prompts.md).

Each critic gets: plan path, prior review path (or None), workspace, **diff summary path or inline if small**, loop k, carry, rubric.

**Bans:** no Write/StrReplace/Delete; no further implementation. Read/Grep/test-run OK for evidence.

**Failures:** [references/fallbacks.md](references/fallbacks.md) — provider quota → jump family. Need ≥2 usable critiques.

### 1b. Synthesizer

Consensus only. Prefer ≥2-critic support or 1 + strong diff/plan citation. Do not reopen Accepted locks from prior loop without new evidence.

### 1c. Builder defender

Defends the **implementation** (diff) against consensus. Concedes real gaps; proposes **follow-up fix bullets** (text only). **Never mutates files.**

### 1d. Revisor → carry

Dispositions + ≤40-line carry + `early-stop-eligible`.

## Phase 2 — Final report

```markdown
# Plan execution peer review

**Plan:** <absolute path>
**Prior plan review:** <LATEST.md path or None>
**Diff base:** <ref / working tree>
**Loops completed:** <k of N>
**Critics:** …
**Orchestrator:** …
**Flags:** …

## Verdict
<Faithful | Faithful with gaps | Incomplete | Regressed> — one paragraph

## Sustained findings
### Blockers
- … (missing locked behavior, wrong verb/UX, broken acceptance)
### Majors
- …
### Minors / nits
- …

## Withdrawn after defense
- …

## Follow-up fix deltas (code/docs — not plan rewrite unless plan was wrong)
1. …

## Acceptance
- Ran: <commands> → <pass/fail/skip>
- Plan gates cited: <…>

## Scope check
- Extra work beyond plan: <None | list>
- Known residue correctly left alone: <Yes/No/partial>

## ADR
<None | Propose… — wait for user confirm>

## Artifacts
- Archive: <REPORT_PATH>
- Latest: <LATEST_PATH>
- Process misses: <None | …>

## Loop history
- …
```

**Verdict rules:**
- Missing locked behavior or failing named acceptance → **Incomplete** or **Regressed** (never Faithful)
- Locked behavior present with polish gaps → **Faithful with gaps**
- All locks + acceptance + no harmful extras → **Faithful**

### Save (default on)

Unless `no-save`:

```bash
bash ~/.cursor/skills/peer-review-execution/scripts/report-path.sh <plan-path>
```

Write full report to `REPORT_PATH` and `LATEST_PATH` under:

```text
~/.cursor/plan-reviews/<plan-stem>/execution/
  LATEST.md
  2026-07-30T120000Z.md
```

## Hard constraints

1. No product implementation; no commits; no new Build
2. No plan/spike/ADR mutation during review — propose follow-ups in text; apply only if user asks
3. Launch critics A/B/C in **one** turn
4. Never park raw critiques in orchestrator carry
5. Cite plan sections + diff files/hunks; do not invent shipped work
6. If prior plan review recommended deltas and Build ignored them, that is usually a **Blocker** or **Major**

## Corner cases

| Case | Action |
|------|--------|
| Empty diff | Ask: uncommitted? wrong `base`? already pushed elsewhere? |
| Diff huge | Write `collect-diff.sh` output to a temp file; critics Read path (don’t inline) |
| Plan says do not Build / tracker-only | Review only claimed shipped todos; flag extras as scope creep |
| No prior `/peer-review-plan` report | Proceed with plan alone; note in Meta |
| Provider quota | Jump family per fallbacks.md |
| Subagent mutates files | Process miss; do not treat as approved |
