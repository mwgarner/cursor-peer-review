# cursor-peer-review

Cursor agent skills for **adversarial multi-model peer review** of plans before Build, then fidelity review of the diff after Build — with hard human gates so agents never auto-Build.

| Skill | Slash command | Role |
|-------|---------------|------|
| `peer-review-plan` | `/peer-review-plan` | Multi-model critique of a Cursor plan before implementation |
| `peer-review-execution` | `/peer-review-execution` | Critique the working-tree / commit diff against locked plan decisions |
| `peer-review-ship` | `/peer-review-ship` | Gated handrail: plan review → Apply → Build → execution review |
| `issue-to-plan` | `/issue-to-plan` | Draft a plan from a GitHub issue, then **stop** (untrusted input) |
| `open-pr` | `/open-pr` | Validate → path-stage → commit → push → open PR, then **stop** (never merges) |

> Shared as-is, no warranty. Do whatever you want with it (MIT). Issues/PRs may be ignored.

**There is no full-send skill** (issue → build → merge). See [SECURITY.md](SECURITY.md).

Start with the [example walkthrough](examples/README.md) if you want to see review artifact shape before installing.

## The one idea worth stealing

Run **diverse-model critics in parallel**, merge them in an **isolated synthesizer**, stress-test consensus with a **planner defender**, then require **explicit human gates** (Apply deltas, Build done, Fix) before anything ships. Execution review checks the diff against the signed plan — not vibes.

Auto-Build (and auto-merge from issue text) is the failure mode this pack is designed to prevent.

## Recommended human pipeline

```text
/issue-to-plan 123          # optional; drafts plan; stops
/peer-review-ship this plan # or plan + execution separately
# … you Build when ready …
/open-pr                    # opens PR; you merge in GitHub UI
```

Every arrow that matters stays a **chat confirmation**, not a webhook.

## Requirements

- [Cursor](https://cursor.com/) with Task / subagent support and access to multiple models (for peer-review-*)
- `gh` + `git` on PATH for `/issue-to-plan` and `/open-pr`
- A bash-compatible environment (macOS, Linux, or WSL) for helper scripts
- Core three peer-review skills installed together — `/peer-review-ship` delegates to plan + execution

## Install

```bash
git clone https://github.com/mwgarner/cursor-peer-review.git
cd cursor-peer-review
chmod +x install.sh
./install.sh            # symlink all skills (default)
# ./install.sh --copy   # detached copies
# ./install.sh --core   # only plan + execution + ship
```

**Do not** symlink the repo root or the parent `skills/` directory alone — Cursor discovers one skill per folder name.

### Manual install

<details>
<summary>Copy or symlink by hand</summary>

```bash
REPO=/path/to/cursor-peer-review
for name in peer-review-plan peer-review-execution peer-review-ship issue-to-plan open-pr; do
  ln -sfn "$REPO/skills/$name" ~/.cursor/skills/$name
done
```

</details>

### Environment overrides (optional)

| Variable | Default | Used by |
|----------|---------|---------|
| `CURSOR_PLANS_DIR` | `~/.cursor/plans` | `resolve-plan.sh` in plan + execution |
| `CURSOR_PLAN_REVIEWS_DIR` | `~/.cursor/plan-reviews` | `report-path.sh` in plan + execution |
| `CURSOR_WORKSPACE` | `$PWD` | `resolve-plan.sh` in plan + execution |
| `CURSOR_SKILLS_DIR` | `~/.cursor/skills` | `install.sh` destination |

Execution also ships `collect-diff.sh` (workspace path argument; no extra env vars).

Review transcripts are written under `~/.cursor/plan-reviews/` at runtime and are **never** part of this repo.

## Quick start

```text
/peer-review-plan this plan
# … Apply deltas if asked …
# … Build when ready …
/peer-review-execution this plan
/open-pr
```

Or:

```text
/peer-review-ship this plan
```

Ship stops for Apply / Build-done / Fix. It never starts product implementation unless you explicitly ask at the Build gate.

## Default model panel (peer-review-*)

These are **Cursor Task `model:` slugs**. They will rot — edit `SKILL.md` + `references/fallbacks.md` when Cursor renames them.

| Role | Default slug | Notes |
|------|--------------|-------|
| Critic A | `composer-2.5` | Isolated critique |
| Critic B | `cursor-grok-4.5-high` | Isolated critique |
| Critic C | `gpt-5.6-sol-high` | Override with `gpt=medium` / `gpt=terra` / `cheap` |
| Synthesizer | `composer-2.5` (preferred) | Falls back per `fallbacks.md` |
| Defender | `cursor-grok-4.5-high` | Plan: `planner=`; execution: `builder=` |

Quota tip: if GPT is exhausted, Critic C should jump to another family (see `references/fallbacks.md`) — do not burn turns on same-family retries.

## Knobs

See each skill’s `SKILL.md`. Common peer-review flags:

| Knob | Default | Meaning |
|------|---------|---------|
| `loops=N` | `2` | Review loops (1–4) |
| `early-stop` | off | Stop after a clean loop (no blockers/majors) |
| `no-save` | off | Chat-only (skip writing `plan-reviews/`) |
| `gpt=high` | default | Critic C = Sol High (quality default) |
| `gpt=medium` / `terra` / `cheap` | off | Weaker/cheaper Critic C (+ related) |
| `from=plan` / `from=execution` | full ship | Ship handrail entry points |
| `base=<ref>` | auto | Execution diff base when the tree is clean |

### Empty diffs / initial commits

`/peer-review-execution` uses `collect-diff.sh`. Prefer the **working tree** when dirty. When clean:

- Diff is `base...HEAD` (default `main` / `master`).
- If that range is empty **and** `HEAD` is a **root commit** (no parent), the script falls back to `empty-tree...HEAD` so the initial commit is reviewable.
- If the range is empty on a long-lived branch tip, there is genuinely nothing to review — commit or leave uncommitted work, or pass an explicit `base=`.

## Layout

```text
install.sh
SECURITY.md
examples/                 # anonymized walkthrough artifacts
skills/
  peer-review-plan/
  peer-review-execution/  # includes collect-diff.sh
  peer-review-ship/       # no scripts/ — orchestrator only
  issue-to-plan/
  open-pr/
```

`resolve-plan.sh` and `report-path.sh` exist under both plan and execution on purpose: execution’s `report-path.sh` writes under `<stem>/execution/`. Keep them in sync mentally when you edit one.

## Limitations

- Peer-review skills need Cursor Task/subagents and multi-model access.
- Model slugs **will rot** — edit the skill files.
- Snapshot workflow: no auto-sync unless you symlink via `./install.sh` from a clone you maintain.
- Helper scripts assume bash (use WSL on Windows).
- `/open-pr` does not merge; `/issue-to-plan` does not Build — by design.
- No support commitment — fork freely.

## License

MIT — see [LICENSE](LICENSE).
