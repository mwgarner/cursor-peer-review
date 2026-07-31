# Fallbacks & failure handling

## Critic model panel (Task-allowlisted defaults)

Primary panel matches models usable via Task `model:` today. CursorBench Sol Medium is preferred for cost when/if that slug is accepted; until then default Critic C to Sol High.

| Slot | Primary | Fallback 1 | Fallback 2 |
|------|---------|------------|------------|
| A | `composer-2.5` | `composer-2.5-fast` | `claude-sonnet-5-thinking-high` |
| B | `cursor-grok-4.5-high` | retry once same slug | `claude-sonnet-5-thinking-high` |
| C | `gpt-5.6-sol-high` | `gpt-5.6-terra-medium` (once) | **different family:** `claude-sonnet-5-thinking-high` (or `composer-2.5-fast` if Sonnet also quota’d) |

**User overrides for Critic C:**
- `gpt=high` (default) → `gpt-5.6-sol-high`
- `gpt=medium` → try `gpt-5.6-sol-medium`, else Sol High
- `gpt=terra` or `cheap` → `gpt-5.6-terra-medium` (weaker; note in report)

**Provider quota / “API usage limit reached”:**
- Treat as **family-level** failure, not single-slug.
- Do **not** burn turns retrying other GPT variants after Sol High + Terra both hit quota.
- Jump immediately to Fallback 2 (Anthropic/Composer).
- Note in final report: `Critic C: GPT quota → <fallback slug>`.

**Constraints:**
- After fallbacks, keep **different families** when possible (Composer / Grok / GPT / Anthropic).
- Never run two critics on the identical slug.
- Never silently upgrade a slot to Opus/Fable/Max unless the user passed `max-depth`.
- If Critic B used Grok, note CursorBench contamination asterisk in final report Meta.

## Synthesizer / revisor / defender

| Role | Primary | Fallback |
|------|---------|----------|
| Synthesizer | Prefer `composer-2.5` (avoids GPT quota) or parent-class if known | `claude-sonnet-5-thinking-high` → `cursor-grok-4.5-high` |
| Revisor | Same as synthesizer (`resume` preferred) | Same fallback |
| Defender | `planner=` override, else `cursor-grok-4.5-high` | `composer-2.5` (not GPT if GPT quota’d) |

Defender sharing Critic B’s slug is OK (fresh context). Prefer synthesizer ≠ any critic slug when alternatives exist.

## Task launch failures

1. **Slug rejected / model unavailable:** apply table fallback once; relaunch that slot only.
2. **Provider quota / usage limit:** skip same-family fallbacks; jump to different-family Fallback 2.
3. **Empty / missing mandatory headings:** one retry with prefix `Your previous reply was malformed. Return the rubric shape exactly.`
4. **Tool/crash error:** one retry; then mark slot `FAILED`.
5. **Timeout / hang / user cancel on one critic:** mark FAILED; continue if ≥2 critics usable.
6. **Subagent mutates plan/code despite bans:** orchestrator records Process miss; do not treat as approved apply; leave files as-is unless user asks to revert or keep.

## Reduced panel policy

| Usable critiques | Action |
|------------------|--------|
| 3 | Full synthesizer |
| 2 | Synthesizer with third slot `FAILED — slot empty`; note reduced panel in consensus Meta + final report |
| 0–1 | **Abort loop.** Partial report; ask user to retry or change models |

## Synthesizer / defender failures

1. One retry with malformed-repair prefix.
2. Synthesizer still fails → **abort loop** (do not invent a creative merge). Emergency exception: if ≥2 critics share identical blocker titles, list those bullets only as emergency consensus and ask user whether to continue.
3. Defender fails → revisor treats defense as empty; all consensus findings **Sustained**; carry notes `defender: failed`.

## Plan path resolution failures

1. Not found → `scripts/resolve-plan.sh` or list 8 recent `~/.cursor/plans/*.plan.md` + AskQuestion.
2. Ambiguous bare name → AskQuestion.
3. Unreadable / empty → stop; ask for another path.
4. Script missing/non-executable → resolve manually; do not fail the skill.

## Mid-flight interrupts

| User says | Action |
|-----------|--------|
| cancel / stop | Partial report for completed loops |
| change loops to K | Apply to **remaining** loops only |
| apply deltas now | Finish or pause review; edit plan only if user confirms — still no code |
| also review ADR X | Next loop may Read it; do not expand into full ADR review unless asked |

## Cost / depth overrides (opt-in)

| Flag | Effect |
|------|--------|
| `gpt=high` | Critic C → `gpt-5.6-sol-high` (default) |
| `gpt=medium` | Prefer Sol Medium if Task accepts it |
| `gpt=terra` / `cheap` | Critic C → `gpt-5.6-terra-medium`; if `cheap`, defender → `composer-2.5`; note reduced rigor |
| `max-depth` | Defender may use `claude-opus-5-thinking-max`; critics unchanged unless also upgraded |
| `early-stop` | Stop when carry says early-stop-eligible |
| `no-save` | Skip `~/.cursor/plan-reviews/` write (chat-only) |

## Idempotency / artifacts

- **Default:** save under `~/.cursor/plan-reviews/<plan-stem>/` via `scripts/report-path.sh`:
  - `YYYY-MM-DDTHHMMSSZ.md` — immutable archive
  - `LATEST.md` — overwritten with the newest review for that stem
- Re-runs add a new timestamped file and refresh `LATEST.md` (never clobber archives).
- `no-save` → chat only.
- Do not write peer reviews into `~/.cursor/plans/`.
