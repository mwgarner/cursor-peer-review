# cursor-peer-review

Cursor agent skills for **adversarial multi-model peer review** of plans before Build, then fidelity review of the diff after Build — with hard human gates so agents never auto-Build.

Three skills:

| Skill | Slash command | Role |
|-------|---------------|------|
| `peer-review-plan` | `/peer-review-plan` | Multi-model critique of a Cursor plan before implementation |
| `peer-review-execution` | `/peer-review-execution` | Critique the working-tree / commit diff against locked plan decisions |
| `peer-review-ship` | `/peer-review-ship` | Gated handrail: plan review → Apply → Build → execution review |

> Shared as-is, no warranty. Do whatever you want with it (MIT). Issues/PRs may be ignored.

## The one idea worth stealing

Run **diverse-model critics in parallel**, merge them in an **isolated synthesizer**, stress-test consensus with a **planner defender**, then require **explicit human gates** (Apply deltas, Build done, Fix) before anything ships. Execution review checks the diff against the signed plan — not vibes.

Auto-Build is the failure mode this pack is designed to prevent.

## Requirements

- [Cursor](https://cursor.com/) with Task / subagent support and access to multiple models
- A bash-compatible environment (macOS, Linux, or WSL) for the helper scripts
- All **three** skills installed — `/peer-review-ship` delegates to the plan and execution siblings

## Install

Clone (or copy) this repo, then install each skill folder into `~/.cursor/skills/<name>`.

**Do not** symlink the repo root or the parent `skills/` directory alone — Cursor discovers one skill per folder name.

### Copy

```bash
REPO=~/Code/cursor-peer-review   # or path to your clone

cp -R "$REPO/skills/peer-review-plan" ~/.cursor/skills/peer-review-plan
cp -R "$REPO/skills/peer-review-execution" ~/.cursor/skills/peer-review-execution
cp -R "$REPO/skills/peer-review-ship" ~/.cursor/skills/peer-review-ship
```

### Symlink

```bash
REPO=~/Code/cursor-peer-review

ln -sfn "$REPO/skills/peer-review-plan" ~/.cursor/skills/peer-review-plan
ln -sfn "$REPO/skills/peer-review-execution" ~/.cursor/skills/peer-review-execution
ln -sfn "$REPO/skills/peer-review-ship" ~/.cursor/skills/peer-review-ship
```

### Environment overrides (optional)

Scripts default to the usual Cursor locations. Override if needed:

| Variable | Default | Used by |
|----------|---------|---------|
| `CURSOR_PLANS_DIR` | `~/.cursor/plans` | `resolve-plan.sh` |
| `CURSOR_PLAN_REVIEWS_DIR` | `~/.cursor/plan-reviews` | `report-path.sh` |
| `CURSOR_WORKSPACE` | `$PWD` | `resolve-plan.sh` |

Review transcripts are written under `~/.cursor/plan-reviews/` at runtime and are **never** part of this repo.

## Quick start

```text
/peer-review-plan this plan
# … Apply deltas if asked …
# … Build when ready …
/peer-review-execution this plan
```

Or the gated pipeline:

```text
/peer-review-ship this plan
```

Ship stops for Apply / Build-done / Fix. It never starts product implementation unless you explicitly ask at the Build gate.

## Knobs

See each skill’s `SKILL.md` for full flags. Common ones:

| Knob | Default | Meaning |
|------|---------|---------|
| `loops=N` | `2` | Review loops (1–4) |
| `early-stop` | off | Stop after a clean loop |
| `no-save` | off | Chat-only (skip writing `plan-reviews/`) |
| `cheap` / `gpt=` | — | Weaker/cheaper Critic C (and related) |
| `from=plan` / `from=execution` | full ship | Ship handrail entry points |

## Layout

```text
skills/
  peer-review-plan/       # SKILL.md, references/, scripts/
  peer-review-execution/  # SKILL.md, references/, scripts/
  peer-review-ship/       # SKILL.md, references/  (no scripts/ — orchestrator only)
```

## Limitations

- Requires Cursor Task/subagents and multi-model access; a single-model setup will not match the intended panel.
- Default model slugs in `SKILL.md` are Cursor Task ids and **will rot** — edit the skill files when Cursor renames them.
- This is a **snapshot** of a personal workflow. There is no auto-sync from anyone’s live `~/.cursor/skills`.
- Helper scripts assume bash; Windows users should use WSL or equivalent.
- No support commitment — fork freely.

## License

MIT — see [LICENSE](LICENSE).
