# Critique rubric (plan peer review)

Authoritative scoring rules for critics, synthesizer, defender, and revisor.

## Mission

Decide whether this plan is **safe to Build** without the implementer inventing product/architecture choices. Evidence over taste. Cite plan sections and code paths.

## Required checks (every critic)

1. **Deferred decisions (Blocker-class)** — TBD, “decide later/during implementation”, A-or-B, “optionally”, “implementation can pick”, vague “handle edge cases” when behavior/API/UX/architecture changes
2. **Goal / non-goals** — Clear outcome? Scope creep / missing exclusions?
3. **Correctness** — Matches cited code/ADRs? Wrong layer, file, or invariant?
4. **Completeness** — Missing steps, tests, call sites, migrations, analytics, copy, kill-switches, feature flags?
5. **Ordering / dependencies** — Steps race existing behavior or each other?
6. **Risks** — Regression, data loss, auth, billing, coach-visible copy≠behavior
7. **Acceptance** — Falsifiable checks present? Runnable commands named when relevant?
8. **Out of scope** — Honest parking vs smuggling critical work out?
9. **Todos / frontmatter** — Atomic, decision-free verbs+targets?
10. **Operability** — Rollout, monitoring, backward compat, migration of existing user data/profiles if touched

## Severity

| Severity | Meaning | Build implication |
|----------|---------|-------------------|
| **Blocker** | Build would guess, ship wrong behavior, or violate a hard invariant | Must fix plan first |
| **Major** | Likely miss or costly rework | Should fix before Build |
| **Minor** | Real improvement | Build can proceed |
| **Nit** | Wording/style only | Optional |

## Deferred-decision detection (non-exhaustive)

Flag phrases/patterns:
- `TBD`, `TODO: choose`, `decide later`, `during implementation`, `figure out when coding`
- `or optionally`, `we could also`, `either A or B`, `whichever is easier`
- `leave flexible`, `implementation can pick`, `open question` without locked answer
- Steps that say “clean up as needed”, “refactor appropriately”, “handle errors properly” with no specified behavior

**Not deferred:** mechanical naming, local test file placement matching repo patterns, exact import ordering — if behavior is already locked.

## Critic return shape (mandatory)

If the critic cannot fill a section, write `None` — do not omit headings.

```markdown
## Meta
- Critic: <A|B|C>
- Model: <slug>
- Loop: <k>
- Plan: <absolute path>

## Verdict
<Approve | Approve with changes | Reject> — one sentence

## Findings
### Blockers
- **[B1]** <title> — evidence: <plan section / file:symbol> — why blocks Build — suggested fix

### Majors
- **[M1]** …

### Minors
- **[m1]** …

### Nits
- **[N1]** …

## What the plan gets right
- 2–4 bullets

## Open disagreements with locked decisions
- None | **[D1]** <decision> — why wrong — evidence — alternative

## Confidence
- <low|medium|high> — one line (code read? plan-only?)
```

Ids are local to that critic report.

## Consensus shape (synthesizer, each loop)

```markdown
## Consensus (loop k)

### Meta
- Critics present: <A,B,C or subset>
- Discarded unevidenced claims: <count or list ids>

### Sustained blockers
- **[C-B1]** <title> — sources: <A-B2, C-B1> — evidence — fix — needs-ADR: <yes|no>

### Sustained majors
- **[C-M1]** …

### Sustained minors/nits
- **[C-m1]** …

### Disagreements among critics
- <topic>: A …; B …; C …; resolution: <keep/drop/amend + why>

### Recommended plan deltas
1. …

### early-stop-eligible
<yes|no>  # yes only if zero sustained blockers AND zero sustained majors
```

Merge rule: prefer findings with **≥2 critics** OR **1 critic + strong code/plan citation**. Drop taste-only single-critic nits unless synthesizer independently agrees from the plan text.

## Defender return shape

```markdown
## Defense
### Meta
- Model: <slug>
- Loop: <k>

### Accept
- <consensus id> — concede — minimal plan edit

### Reject
- <consensus id> — evidence from plan/code why already correct

### Amend
- <consensus id> — narrowed claim — edit

### Unevidenced (do not use)
- List any consensus ids you cannot address

## Minimal plan deltas
1. …
```

Unevidenced **Reject**s are non-binding for the revisor.

## Revisor / carry summary (≤40 lines)

```markdown
## Carry summary (loop k)
- Dispositions: <id → Sustained|Withdrawn|Amended> (compact)
- Sustained blockers: <n>
- Sustained majors: <n>
- Top deltas: <≤5 bullets>
- needs-ADR: <yes|no> — <one line if yes>
- early-stop-eligible: <yes|no>
- Open risks still in plan: <≤3 bullets or None>
```

## ADR policy

| `needs-ADR` | When |
|-------------|------|
| **no** (default) | Wording, step order, tests, copy, todos, local plan structure |
| **yes** | Sustained finding changes lasting architecture/product contract: public API, data model, auth/billing invariant, cross-cutting coach contract, or contradicts `docs/decisions/*` |

Orchestrator proposes ADR text; writes only on user confirm.

## Code / plan citation policy

Consensus ids (`C-B1`, `C-M1`, `C-m1`) and per-critic ids (`B1`, `M1`) are **review-session local**. Plan vs execution reviews on the same stem **reuse** those numbers — bare `C-M2` is ambiguous.

**Ladder when a lock will be cited outside the review transcript** (product code, tests, plan/spike lock tables meant to survive Build) — highest first:

1. **In-repo SoT** — spike `D#` / Acc `#` / ADR decision. Prefer when applying plan deltas (rewrite `C-*` locks into Acc/D before Build).
2. **Compound finding id** when the lock has not graduated:
   - Plan review: `{plan-stem}/C-M2` (e.g. `example_plan_aabbccdd/C-M8`)
   - Execution review: `{plan-stem}/execution/C-M2` (e.g. `example_plan_aabbccdd/execution/C-M2`)
3. **Forbidden in lasting code/tests:** bare `C-M2`, `C1`, `C-B1`, `Amended C-M1`.

Do **not** use UUIDs or date-only prefixes. Keep bare `C-*` **inside** review transcripts (session-local is correct there). Plan-stem (including Cursor’s `_hash` suffix) joins `~/.cursor/plans/<stem>.plan.md` and `~/.cursor/plan-reviews/<stem>/`.

## Anti-patterns for all roles

- Implementing code or editing the plan unbidden
- **Mutating any file** (Write/StrReplace/Delete) during review — deltas are reply text only
- Inventing files/APIs not in the repo or plan
- Softening blockers into majors to be “agreeable”
- Dumping full debate transcripts back to the orchestrator
- Rubber-stamp Approve when deferred decisions remain
- Reopening a prior-loop Accepted chip/verb lock without new evidence
