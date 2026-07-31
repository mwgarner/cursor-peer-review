# Execution critique rubric

Authoritative rules for post-Build fidelity review.

## Mission

Decide whether the **diff / working tree faithfully executed** the plan’s locked decisions and acceptance gates — without inventing new product choices or leaving critical locks unfinished.

## Required checks (every critic)

1. **Locked decisions** — Each plan “Locked” / peer-decision / three-states row: present in code/copy or explicitly deferred as Known residue?
2. **Todos** — Completed todos actually reflected in diff? Pending/cancelled correctly left alone?
3. **Acceptance gates** — Named commands/tests run or clearly still pass? Missing gates called out?
4. **User-visible honesty** — Chip/button/assistant copy matches behavior (label vs outcome, never claim done until affirm, etc.)
5. **Wrong-layer / wrong-file** — Changes in the right modules per plan?
6. **Regressions** — Plan warned against behaviors that reappeared?
7. **Scope creep** — Diff includes work outside plan / out-of-scope without user ask?
8. **Known residue** — Correctly **not** “fixed” if plan said document-only? Or silently half-fixed worse?
9. **Prior plan peer-review deltas** — If `LATEST.md` exists, were sustained blockers addressed before/during Build?
10. **Tests / docs** — Plan-required tests and ADR/spike pointers updated when claimed?

## Severity

| Severity | Meaning |
|----------|---------|
| **Blocker** | Locked behavior missing, wrong, or acceptance fails — not ship-honest |
| **Major** | Likely user-visible gap or costly follow-up; Build incomplete vs plan |
| **Minor** | Real gap; ship tolerable |
| **Nit** | Naming/comments/style |

## Critic return shape (mandatory)

```markdown
## Meta
- Critic: <A|B|C>
- Model: <slug>
- Loop: <k>
- Plan: <path>
- Diff base: <ref>

## Verdict
<Faithful | Faithful with gaps | Incomplete | Regressed> — one sentence

## Findings
### Blockers
- **[B1]** <title> — plan lock: <…> — evidence: <file:symbol / test> — fix

### Majors
- **[M1]** …

### Minors
- **[m1]** …

### Nits
- **[N1]** …

## What execution got right
- 2–4 bullets (files/behaviors that match locks)

## Scope creep / residue
- Extra beyond plan: None | …
- Residue correctly parked: Yes | No | Partial — …

## Confidence
- <low|medium|high> — diff read? tests run?
```

## Consensus shape

```markdown
## Consensus (loop k)

### Meta
- Critics present: …
- Diff base: …
- Prior plan review used: <yes|no>

### Sustained blockers
- **[C-B1]** … — needs-ADR: <yes|no>

### Sustained majors
- …

### Sustained minors/nits
- …

### Disagreements among critics
- …

### Follow-up fix deltas
1. …

### early-stop-eligible
<yes|no>  # yes only if zero sustained blockers AND zero sustained majors
```

## Builder defender shape

```markdown
## Defense
### Meta
- Model: <slug>
- Loop: <k>

### Accept
- <id> — concede — follow-up fix bullet

### Reject
- <id> — evidence in diff/tests why already satisfied

### Amend
- <id> — narrowed claim — fix bullet

### Unevidenced
- …

## Follow-up fix deltas
1. …
```

Unevidenced Rejects are non-binding.

## Revisor / carry (≤40 lines)

```markdown
## Carry summary (loop k)
- Dispositions: <id → Sustained|Withdrawn|Amended>
- Sustained blockers: <n>
- Sustained majors: <n>
- Top fix deltas: <≤5 bullets>
- needs-ADR: <yes|no> — <one line if yes>
- early-stop-eligible: <yes|no>
- Open execution risks: <≤3 or None>
- defender_claimed_write: <yes|no>
```

## ADR policy

Same as plan peer review: **needs-ADR: yes** only if sustained finding changes a lasting architecture/product contract (not routine fix-it tickets). Propose only; write on user confirm.

## Code / plan citation policy

Same ladder as `/peer-review-plan` (see that skill’s rubric if present). Summary:

1. Prefer in-repo spike `D#` / Acc `#` / ADR when a lock graduates.
2. Else cite compound ids: `{plan-stem}/C-M2` (plan review) or `{plan-stem}/execution/C-M2` (this skill).
3. **Forbidden in lasting code/tests:** bare `C-M2`, `C1`, `C-B1`, `Amended C-M1`.

Keep bare `C-*` inside review transcripts only. Plan-stem joins plans + `~/.cursor/plan-reviews/<stem>/`.

**Severity when reviewing a Build:**

| Issue | Severity |
|-------|----------|
| New product code/tests cite bare `C-M*` / `C-B*` | **Nit** (process) |
| Finding clearly drove a fix but comment/test has neither compound nor spike/ADR id | optional **Minor** |

## Anti-patterns

- Implementing fixes during the review
- Mutating plan/spike/ADR files
- Treating Known residue as failure when plan said park it
- Claiming Faithful when locked chip/copy verbs still wrong
- Reopening Accepted resolutions without new evidence
- Leaving bare `C-M*` as the only long-term citation in new code/tests
