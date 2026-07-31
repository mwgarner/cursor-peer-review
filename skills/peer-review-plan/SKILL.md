---
name: peer-review-plan
description: >-
  Multi-model peer review of a Cursor plan before Build. Invoked as
  /peer-review-plan with a plan path and optional loops=N. Runs Composer 2.5,
  Grok 4.5 High, and GPT-5.6 Sol High critics in parallel, debates them in an
  isolated synthesizer, stress-tests consensus with a planner defender, and
  repeats for N loops. Use when the user wants deep plan critique. Does not
  implement code or choose the builder model.
disable-model-invocation: true
---

# Peer review plan

Production peer review for Cursor plans. Orchestrate diverse-model critics, isolate debate, defend, loop, report. **Never Build. Never implement. Never pick the builder model.**

Read [references/critique-rubric.md](references/critique-rubric.md), [references/prompts.md](references/prompts.md), and [references/fallbacks.md](references/fallbacks.md) before launching subagents. Skim [references/examples.md](references/examples.md) if invocation is ambiguous.

## Invocation

**Easy (preferred):** plain English. Defaults fill the rest — you do **not** need flags for a normal run.

```
/peer-review-plan
/peer-review-plan this plan
/peer-review-plan the example feature plan, 2 loops
```

No path → list recent `~/.cursor/plans/` (via `bash ~/.cursor/skills/peer-review-plan/scripts/resolve-plan.sh`) and AskQuestion. “This plan” → use the plan already in the conversation / open editor if unambiguous.

**Optional knobs** (only when you want them):

| Arg | Default | Meaning |
|-----|---------|--------|
| plan path | ask / recent list | Absolute, `~/…`, workspace-relative, or bare name under `~/.cursor/plans/` |
| `loops=N` or “N loops” | `2` | Integer **1–4** |
| `gpt=high\|medium\|terra` | `high` → `gpt-5.6-sol-high` | Critic C; `medium` tries Sol Medium then falls back; `terra` = cheaper/weaker |
| `planner=<model>` | `cursor-grok-4.5-high` | Defender model |
| `early-stop` | off | Stop after a clean loop (no blockers/majors) |
| `no-save` | off | Skip writing the review file (chat-only) |
| `cheap` | off | Weaker/cheaper Critic C (+ cheaper defender) |

**Reports are saved by default** under `~/.cursor/plan-reviews/<plan-stem>/` (see Artifacts). Pass `no-save` for chat-only.

Precision form still works:

```
/peer-review-plan ~/.cursor/plans/foo.plan.md loops=3 early-stop
```

## Roles

| Role | Actor | Model | Context duty |
|------|--------|--------|--------------|
| **Orchestrator** | This chat (parent) | User’s picker model | Inputs, launches, short carry state, final report only |
| **Critic A** | Task `generalPurpose` | `composer-2.5` | Isolated critique |
| **Critic B** | Task `generalPurpose` | `cursor-grok-4.5-high` | Isolated critique |
| **Critic C** | Task `generalPurpose` | `gpt-5.6-sol-high` (default) | Isolated critique |
| **Synthesizer** | Task `generalPurpose` | Prefer `composer-2.5` (avoids GPT quota); else parent-class / `claude-sonnet-5-thinking-high` | Debate → consensus only |
| **Defender** | Task `generalPurpose` | `planner=` or `cursor-grok-4.5-high` | Defend / concede → deltas |
| **Revisor** | Task `generalPurpose` (or synthesizer resume) | Same as synthesizer | Sustained/withdrawn/amended + ≤40-line carry summary |

**Context hard rule:** Parent must **not** retain raw critic bodies across loops. Pass raw critiques only into the synthesizer prompt. Between loops, keep only the **carry summary** (≤40 lines) + recommended deltas.

## Progress checklist

```
Peer review:
- [ ] Parse args; resolve + validate plan
- [ ] Read plan once; note size / linked docs
- [ ] Announce panel (models, loops, flags) in one line
- [ ] Loop k=1..N:
- [ ]   Launch critics A/B/C in parallel
- [ ]   Handle critic failures per fallbacks.md
- [ ]   Synthesizer → consensus
- [ ]   Defender → defense
- [ ]   Revisor → carry summary; early-stop check
- [ ] Final report + save under ~/.cursor/plan-reviews/ (unless no-save) / ADR offer
```

## Phase 0 — Setup (orchestrator)

1. **Parse args** from the user message (path, loops, gpt, planner, early-stop, no-save, cheap).
2. **Resolve path:**
   - Expand `~`
   - If relative: try workspace root, then `~/.cursor/plans/<name>`
   - If bare name: `~/.cursor/plans/<name>` (append `.plan.md` if missing and file exists)
   - Prefer `bash ~/.cursor/skills/peer-review-plan/scripts/resolve-plan.sh <path-or-query>` when available (prints `RESOLVED:…`, `SIZE_CLASS:small|large`)
3. **Validate plan file:**
   - Exists, is a regular file, readable, non-empty
   - Prefer `.md` / `.plan.md`; warn (AskQuestion continue?) for other extensions
   - If `> 80KB` or `> 2k` lines: do **not** inline full plan into every prompt — pass **absolute path** and instruct agents to `Read` the file (and only cite excerpts)
4. **Read plan once** (orchestrator). Extract title/overview/todos if present. Note cited ADRs/spikes; agents may read those for evidence.
5. **Refuse to start** if the file is empty, binary, or unreadable — ask for another path.
6. One-line kickoff: `Reviewing <path> | loops=N | critics=composer-2.5, cursor-grok-4.5-high, gpt-5.6-sol-high | early-stop=…` then proceed (no extra approval unless path was ambiguous).

## Phase 1 — Loop body

### 1a. Critics (exactly 3, parallel, one message)

**Hard requirement:** launch **all three** Task calls in the **same** assistant turn. Never launch Critic A alone then B/C later (that happened in the first live test and slows the run).

Use `subagent_type: generalPurpose`, `run_in_background: false` unless user asked async. Prompt template **Critic** from [references/prompts.md](references/prompts.md).

Include for each: absolute plan path, workspace root, loop `k`, prior carry summary (if `k>1`), rubric path, critic id (A/B/C), model.

**Failure handling:** see [references/fallbacks.md](references/fallbacks.md). On **provider quota / API usage limit** for a family (e.g. all GPT slugs), skip remaining GPT fallbacks and jump to a **different family** immediately. Minimum to continue a loop: **2 usable critiques**. If fewer than 2 after one retry round → abort loop, report partial, ask user.

### 1b. Synthesizer (mandatory isolation)

Launch one Task with template **Synthesizer**. Inputs: plan path (+ inline only if small), three critiques, prior carry summary, rubric.

Output: **Consensus (loop k)** only — no transcript. Deferred decisions → usually Blockers.

If `k>1` and the plan file is **unchanged** since loop 1: prefer reaffirm/escalate prior sustained findings; do **not** reopen a resolution the prior defender **Accepted** unless new contradictory evidence appears. Seek **new** findings only.

### 1c. Defender

Launch one Task with template **Defender**. Inputs: plan path, consensus.

**Hard ban:** defender must **not** Write, StrReplace, Delete, or otherwise mutate the plan file, spike, ADR, or any product code. “Minimal plan edits” means **markdown bullets in the defense reply only**. Orchestrator reports deltas; user must say “apply deltas” before any plan edit.

If a subagent mutates the plan anyway: note **Process miss** in the final report Artifacts; do not silently treat that as user-approved.

### 1d. Revisor → carry

Launch Task with template **Revisor** (or resume synthesizer with defense attached). Same **no file mutation** ban. Output:

- Finding dispositions: Sustained / Withdrawn / Amended
- Recommended plan deltas
- **Carry summary ≤40 lines** for loop `k+1`
- `needs-ADR: yes|no` with one-line reason if yes
- `early-stop-eligible: yes` iff zero sustained blockers **and** zero sustained majors

If `early-stop` flag set and `early-stop-eligible: yes` after loop 1 (or any loop), stop looping and go to final report.

If `loops>1`, plan **unchanged**, and loop-1 carry already has sustained blockers that are **only plan-doc refresh** (defender accepted all): still run loop 2 critics, but instruct them to hunt for **new** product/correctness issues; if none, synthesizer may keep the same blockers and note “no new findings.”

## Phase 2 — Final report

Emit exactly this structure (fill all sections; use `None` rather than omitting):

```markdown
# Plan peer review

**Plan:** <absolute path>
**Loops completed:** <k of N>
**Critics:** composer-2.5 / cursor-grok-4.5-high / <gpt slug used>
**Synthesizer / defender:** <models used>
**Orchestrator:** <parent model if known, else "chat picker">
**Builder:** not chosen — user builds manually
**Flags:** early-stop=<on|off> no-save=<on|off>

## Verdict
<Approve | Approve with changes | Reject> — one paragraph grounded in sustained findings

## Sustained findings
### Blockers
- …
### Majors
- …
### Minors / nits
- …

## Withdrawn after defense
- <id>: <why withdrawn>

## Recommended plan deltas
1. …

## ADR
<None | Propose: path + 3–6 bullets — wait for user confirm before writing>

## Artifacts
- Chat report (this message)
- Archive: <REPORT_PATH>
- Latest: <LATEST_PATH>
- Raw critiques: subagent transcripts only (paste on request)
- Process misses: <None | e.g. defender mutated plan file; critics not launched in one turn; Critic C quota>

## Loop history
- Loop 1: verdict lean / blocker count / major count / early-stop?
- Loop 2: …
```

**Verdict rules:**
- Any sustained **Blocker** → `Reject` or `Approve with changes` (never plain Approve)
- No blockers, some majors → `Approve with changes`
- Only minors/nits or none → `Approve`

### Save report (default on)

Unless the user passed `no-save`:

1. Run `bash ~/.cursor/skills/peer-review-plan/scripts/report-path.sh <absolute-plan-path>` (or create the same layout manually).
2. Write the **full** final report to `REPORT_PATH` (timestamped, never overwrite).
3. Copy/write the same content to `LATEST_PATH` (always the newest for that plan stem).
4. Layout:

```text
~/.cursor/plan-reviews/
  README.md
  <plan-stem>/
    LATEST.md
    2026-07-30T124500Z.md
    …
```

5. Include absolute plan path + review timestamp in the report header.
6. Mention both file paths in the chat Artifacts section.

Do **not** drop reviews into `~/.cursor/plans/` (keeps plans clean). Do not ask before first write of a new timestamped file; only `LATEST.md` is replaced in place.

### ADR

Follow [references/critique-rubric.md](references/critique-rubric.md) ADR policy. Propose only; write only on explicit user confirm.

## Citation (when locks leave the review)

`C-*` ids are **review-session local** (plan vs execution reuse numbers). See [references/critique-rubric.md](references/critique-rubric.md) **Code / plan citation policy**. Greppable form outside transcripts: `{plan-stem}/C-M2`. Prefer promoting locks to spike `D#` / Acc `#` / ADR when applying deltas. Pipeline handrail: `/peer-review-ship`.

## Hard constraints

1. No product/code implementation; no commits; no Build; no builder model selection
2. **No plan/spike/ADR file mutations** during review — propose deltas only; apply only after user explicitly asks
3. Never skip the three-critic launch to “save turns”; always launch A/B/C in **one** turn (unless fallbacks.md documents a reduced panel after failures)
4. Never park raw critiques in orchestrator carry state
5. Never invent plan text — cite sections / line-ish anchors / file paths
6. Never write/amend ADRs unless the user explicitly asks after the report
7. If the user asks to “apply deltas”, that is a **new** request: edit the plan (and linked spike if needed) only, still no implementation. **Promote** durable locks to Acc/D (or keep compound `{stem}/C-*` in plan/spike text) — never leave bare “fix C-M2” as the only long-term label if code/tests will cite it.

## Corner cases (quick index)

| Case | Action |
|------|--------|
| No / ambiguous path | List recent plans; AskQuestion |
| Path in workspace uploads vs `~/.cursor/plans` | Prefer the path the user named; if both exist, AskQuestion |
| Plan is a spike/ADR not a `.plan.md` | Allowed — review as planning artifact; note in report |
| Critic returns empty / wrong shape | One retry; then mark failed for that slot |
| Provider API usage limit (family) | Skip same-family fallbacks; jump to different family (see fallbacks.md) |
| Two critics agree on false claim | Synthesizer must demand code/plan evidence; drop if none |
| Defender rejects everything without evidence | Revisor treats unevidenced rejects as non-binding; sustain critique |
| Defender/subagent mutates plan file | Process miss in report; deltas remain proposals until user says apply |
| User changes plan mid-review | Abort; ask to restart on new path/content |
| Model slug rejected by Task | Apply fallbacks.md chain once per slot |
| User says cancel | Stop; deliver partial report of completed loops |
| Loop 2+ with plan unchanged | Critics hunt for NEW issues; don’t reopen Accepted locks without evidence |
