# cursor-peer-review

Cursor agent skills for an **honest agent delivery loop**: adversarial multi-model **plan** peer review → human-gated Build → **execution** fidelity review → **agent** open PR → **agent** merge (chat-confirmed). No webhooks, no full-send from issue text, no “use the GitHub UI because agents shouldn’t merge.”

| Skill | Slash command | Role |
|-------|---------------|------|
| `peer-review-plan` | `/peer-review-plan` | Multi-model critique of a Cursor plan before implementation |
| `peer-review-execution` | `/peer-review-execution` | Critique the working-tree / commit diff against locked plan decisions |
| `peer-review-ship` | `/peer-review-ship` | Gated handrail: plan review → Apply → Build → execution review |
| `issue-to-plan` | `/issue-to-plan` | Draft a plan from a GitHub issue, then **stop** (issue text is untrusted) |
| `open-pr` | `/open-pr` | Validate → path-stage → commit → push → open PR, then **stop** |
| `merge-pr` | `/merge-pr` | Wait for checks + **chat confirm** → `gh pr merge --squash` |
| `delivery-ship` | `/delivery-ship` | Gated handrail: `/open-pr` then `/merge-pr` |

> Shared as-is, no warranty. Do whatever you want with it (MIT). Issues/PRs may be ignored.

**There is no full-send-from-issue-body skill.** Gates stay in **chat**. See [SECURITY.md](SECURITY.md).

Start with the [example walkthrough](examples/README.md) for review artifact shape.

## The one idea worth stealing

Run **diverse-model critics in parallel**, merge them in an **isolated synthesizer**, stress-test consensus with a **planner defender**, then require **explicit human gates** (Apply deltas, Build done, Fix, merge confirm) before anything lands on the default branch. Execution review checks the diff against the signed plan — not vibes.

Auto-Build / merge-from-issue-text is the failure mode this pack avoids. Agent merge **with a chat confirm after green checks** is intentional.

## Recommended pipeline (honest)

```text
/issue-to-plan 123            # optional; drafts plan; stops
/peer-review-ship this plan   # plan review → Apply → Build gate → execution review
# … Build when you ask the agent in chat …
/delivery-ship                # open PR, then merge-pr (still asks “merge?”)
# or: /open-pr   then later   /merge-pr
```

Every privileged step is a **chat confirmation**, not a webhook and not “because the issue said so.”

## Requirements

- [Cursor](https://cursor.com/) with Task / subagent support and multi-model access (peer-review-*)
- `gh` + `git` on PATH for issue/PR skills
- Bash-compatible environment (macOS, Linux, or WSL) for helper scripts
- Core three peer-review skills installed together — `/peer-review-ship` delegates to plan + execution

## Install

```bash
git clone https://github.com/mwgarner/cursor-peer-review.git
cd cursor-peer-review
chmod +x install.sh
./install.sh            # symlink all skills (default)
# ./install.sh --copy   # detached copies
# ./install.sh --core   # only plan + execution + ship
# ./install.sh --force  # replace a destination that is not already this clone
```

Skills use `disable-model-invocation: true` — invoke with the **slash commands** above (reload Cursor if they do not appear).

**Do not** symlink the repo root or the parent `skills/` directory alone.

### Manual install

<details>
<summary>Copy or symlink by hand</summary>

```bash
REPO=/path/to/cursor-peer-review
for name in peer-review-plan peer-review-execution peer-review-ship \
            issue-to-plan open-pr merge-pr delivery-ship; do
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

Review transcripts under `~/.cursor/plan-reviews/` are **runtime artifacts** — never commit them here.

## Quick start

```text
/peer-review-ship this plan
# Apply / Build when prompted …
/delivery-ship
# reply "merge" when checks look good
```

## Default model panel (peer-review-*)

These are **Cursor Task `model:` slugs**. They will rot — edit `SKILL.md` + `references/fallbacks.md` when Cursor renames them.

| Role | Default slug | Notes |
|------|--------------|-------|
| Critic A | `composer-2.5` | Isolated critique |
| Critic B | `cursor-grok-4.5-high` | Isolated critique |
| Critic C | `gpt-5.6-sol-high` | Override with `gpt=medium` / `gpt=terra` / `cheap` |
| Synthesizer | `composer-2.5` (preferred) | Falls back per `fallbacks.md` |
| Defender | `cursor-grok-4.5-high` | Plan: `planner=`; execution: `builder=` |

Quota tip: if GPT is exhausted, Critic C should jump family per `fallbacks.md` — do not burn same-family retries.

## Knobs

See each skill’s `SKILL.md`. Common peer-review flags:

| Knob | Default | Meaning |
|------|---------|---------|
| `loops=N` | `2` | Review loops (1–4) |
| `early-stop` | off | Stop after a clean loop (no blockers/majors) |
| `no-save` | off | Chat-only (skip writing `plan-reviews/`) |
| `gpt=high` | default | Critic C = Sol High |
| `gpt=medium` / `terra` / `cheap` | off | Weaker/cheaper Critic C |
| `from=plan` / `from=execution` | full ship | Ship handrail entry points |
| `base=<ref>` | auto | Execution / PR base |

### Empty diffs / initial commits

`collect-diff.sh`: prefer working tree when dirty; when clean, `base...HEAD`; if empty on a **root commit**, fall back to `empty-tree...HEAD`.

## Layout

```text
install.sh
SECURITY.md
examples/
skills/
  peer-review-plan|execution|ship/
  issue-to-plan/
  open-pr/
  merge-pr/
  delivery-ship/
```

## Limitations

- Peer-review needs Task/subagents + multi-model access; model slugs rot.
- No deploy recipes, no force-with-lease “machine branch sync,” no cloud IDs — keep those private.
- Does not protect you from pasting secrets into chat/issues — don’t.
- As-is / no support SLA.

## License

MIT — see [LICENSE](LICENSE).
