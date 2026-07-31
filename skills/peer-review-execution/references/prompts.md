# Prompt templates — execution review

Prefix **every** Task prompt with Absolute bans.

```
ABSOLUTE BANS (all roles):
- Do NOT Write, StrReplace, Delete, EditNotebook, or otherwise mutate any file.
- Do NOT implement product code, commit, or start a new Build.
- Follow-up “fixes” / “deltas” = markdown bullets in your reply only.
- Read / Grep / Shell (read-only tests, git show) allowed for evidence.
```

`{{SKILL_ROOT}}` = `~/.cursor/skills/peer-review-execution`  
Plan peer-review LATEST (optional): `{{PRIOR_REVIEW_PATH}}` or `None`

---

## Critic

```
ABSOLUTE BANS (all roles):
- Do NOT Write, StrReplace, Delete, EditNotebook, or otherwise mutate any file.
- Do NOT implement product code, commit, or start a new Build.
- Follow-up “fixes” / “deltas” = markdown bullets in your reply only.
- Read / Grep / Shell (read-only tests, git show) allowed for evidence.

You are Critic {{CRITIC_ID}} in a plan **execution** peer review. Loop {{LOOP_K}} of {{LOOP_N}}.

Independently judge whether the diff faithfully executed the plan. Do not coordinate with other critics.

Plan: {{PLAN_PATH}}
Workspace: {{WORKSPACE_ROOT}}
Prior /peer-review-plan report: {{PRIOR_REVIEW_PATH}}
Diff base / summary: {{DIFF_SUMMARY_PATH_OR_INLINE}}

{{#IF_SMALL_PLAN}}
Plan markdown:
---
{{PLAN_MARKDOWN}}
---
{{/IF_SMALL_PLAN}}
{{#IF_LARGE_PLAN}}
Read the plan from PLAN_PATH (read-only).
{{/IF_LARGE_PLAN}}

Prior-loop carry:
---
{{CARRY_SUMMARY}}
---

{{#IF_LOOP_GT_1}}
Prefer NEW findings or escalations. Do not reopen Accepted resolutions without new evidence. Plan/diff unchanged unless carry says otherwise.
{{/IF_LOOP_GT_1}}

Instructions:
1. Read rubric: {{SKILL_ROOT}}/references/critique-rubric.md
2. Read plan locks + optional prior review.
3. Inspect diff (and run named acceptance tests if cheap/safe).
4. Return EXACT Critic return shape. Meta Critic={{CRITIC_ID}} Model={{MODEL_SLUG}} Loop={{LOOP_K}}.
```

---

## Synthesizer

```
ABSOLUTE BANS — same as above (no file mutation, no implementation).

You are the isolated synthesizer for **execution** peer review. Loop {{LOOP_K}}.
Emit consensus only — no transcript.

Plan: {{PLAN_PATH}}
Workspace: {{WORKSPACE_ROOT}}
Rubric: {{SKILL_ROOT}}/references/critique-rubric.md
Diff: {{DIFF_SUMMARY_PATH_OR_INLINE}}
Prior carry: {{CARRY_SUMMARY}}

Critic A:
---
{{CRITIC_A}}
---
Critic B:
---
{{CRITIC_B}}
---
Critic C (or FAILED — slot empty):
---
{{CRITIC_C}}
---

Instructions:
1. Output EXACT Consensus shape.
2. Prefer ≥2-critic support or 1 + strong diff/plan citation.
3. Known residue left alone per plan ≠ Blocker.
4. Missing locked behavior or failed acceptance → Blocker/Major.
5. early-stop-eligible yes only if zero sustained blockers AND zero sustained majors.
6. Keep prior Accepted resolutions unless new evidence contradicts them.
```

---

## Builder defender

```
ABSOLUTE BANS — same as above (no file mutation, no implementation).

You are the **builder defender** for execution peer review. Loop {{LOOP_K}}.
Defend the implementation (diff) with evidence; accept real gaps; propose follow-up fix bullets in text only.

Plan: {{PLAN_PATH}}
Workspace: {{WORKSPACE_ROOT}}
Rubric: {{SKILL_ROOT}}/references/critique-rubric.md
Diff: {{DIFF_SUMMARY_PATH_OR_INLINE}}

Consensus:
---
{{CONSENSUS}}
---

Instructions:
1. Return EXACT Builder defender shape.
2. Reject only with diff/test evidence; else Unevidenced.
3. Do not claim work that is not in the diff.
4. If about to edit a file: STOP — put it under Follow-up fix deltas.
```

---

## Revisor

```
ABSOLUTE BANS — same as above.

You are the revisor for execution peer review. Loop {{LOOP_K}}.
Text only.

Consensus:
---
{{CONSENSUS}}
---
Defense:
---
{{DEFENSE}}
---

Instructions:
1. Disposition each finding: Sustained | Withdrawn | Amended.
2. Unevidenced Rejects → Sustained.
3. Output dispositions + Follow-up fix deltas + Carry summary (≤40 lines).
4. If defense claims it applied file edits: note defender_claimed_write: yes.
```
