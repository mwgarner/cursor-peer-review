# Fallbacks — execution review

Same critic panel and quota rules as `/peer-review-plan` (see `~/.cursor/skills/peer-review-plan/references/fallbacks.md` if present). Summary:

| Slot | Primary | Fallback 1 | Fallback 2 |
|------|---------|------------|------------|
| A | `composer-2.5` | `composer-2.5-fast` | `claude-sonnet-5-thinking-high` |
| B | `cursor-grok-4.5-high` | retry once | `claude-sonnet-5-thinking-high` |
| C | `gpt-5.6-sol-high` | `gpt-5.6-terra-medium` once | **other family:** `claude-sonnet-5-thinking-high` |

**Provider quota:** treat as family failure; do not chain GPT variants; jump to Fallback 2.

| Role | Primary | Fallback |
|------|---------|----------|
| Synthesizer / revisor | `composer-2.5` | `claude-sonnet-5-thinking-high` → `cursor-grok-4.5-high` |
| Builder defender | `builder=` or `cursor-grok-4.5-high` | `composer-2.5` |

## Reduced panel

| Usable critiques | Action |
|------------------|--------|
| 3 | Full synthesizer |
| 2 | Continue; mark FAILED slot |
| 0–1 | Abort loop; partial report |

## Diff collection failures

1. Not a git repo → AskQuestion for patch path or abort.
2. Empty diff → AskQuestion (base / uncommitted / already committed elsewhere).
3. `collect-diff.sh` missing → manual `git status` + `git diff` + `git diff --cached`.

## Subagent mutates files

Record Process miss; do not treat as approved fix.
