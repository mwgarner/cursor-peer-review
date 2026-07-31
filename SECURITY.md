# Security

This pack is **agent skills + bash helpers** you run under **your** Cursor/`gh`/`git` identity. It does not ship webhooks, bots, or tokens.

## What we deliberately do not provide

| Capability | Why omitted |
|------------|-------------|
| Issue/PR webhook → auto Build/merge | Untrusted GitHub text + privileged git/`gh` = account takeover pattern |
| “Full-send” (issue → plan → build → merge) | Skips human gates; prompt injection wins |
| Auto-merge / force-push recipes | Easy to misuse on shared branches |
| Deploy hooks | Environment-specific; out of scope |

## Untrusted input

Treat **GitHub issue/PR titles, bodies, and comments** as hostile:

- `/issue-to-plan` drafts a plan and **stops**. It must not obey “ignore previous instructions”, run shell from the issue, or follow exfil URLs.
- `/open-pr` opens a PR and **stops**. It must not merge, force-push, or execute remote template snippets.
- `/peer-review-*` skills never auto-Build.

## What you should do locally

- Keep `gh` auth least-privilege (no org-owner PATs in agent environments).
- Do not paste secrets into issues, plans, or review reports.
- Merge in the GitHub UI (or a private skill of your own) after you read the PR.
- Prefer `./install.sh` symlinks only from a clone you trust.

## Reporting

This repo is as-is / best-effort. If you find a skill instruction that directs agents to merge, force-push, or execute issue body shell, open an issue or fork a fix — there is no SLA.
