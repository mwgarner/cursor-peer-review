---
name: Example feature OSS snapshot
overview: Publish a no-support MIT snapshot of three Cursor peer-review skills as a public repo — as-is for fork/use.
todos:
  - id: invent-repo
    content: "Scaffold repo with MIT LICENSE, .gitignore; copy three skill trees into skills/"
    status: completed
  - id: scrub-inventory
    content: "Scrub all SKILL.md + references/* per Acc1; preserve compound-id teaching"
    status: completed
  - id: readme
    content: "README-only install docs (copy+symlink+env), Limitations, as-is stance"
    status: completed
  - id: publish
    content: "git init; gh repo create --public --push"
    status: completed
isProject: false
---

# Example feature — OSS snapshot (as-is)

## Goal

Publish three Cursor skills so others can copy or run them as-is. No support commitment.

## Locked decisions

| ID | Lock |
|----|------|
| **D1** | Public GitHub repo under your account |
| **D2** | Package = three skill folders + thin root docs (no fourth skill) |
| **D3** | MIT license; as-is README disclaimer |
| **D4** | Install: copy or symlink each `skills/<name>` → `~/.cursor/skills/<name>` (not repo root) |
| **D5** | Scrub product-identifying stems; keep compound-id teaching with neutral stems |
| **D6** | Never auto-Build; ship handrail keeps human Apply/Build/Fix gates |

### Acceptance locks (after plan peer review Apply)

| ID | Lock |
|----|------|
| **Acc1** | Scrub inventory: every `SKILL.md` + every `references/*`; deny-list stems must be absent post-scrub |
| **Acc2** | Plan + execution include `scripts/`; ship is `SKILL.md` + `references/` only |
| **Acc3** | Pre-push `rg` over Acc1 deny-list is clean |
| **Acc4** | README documents copy + symlink, env overrides, never-auto-Build, Limitations |

## Non-goals

- No CI, issue templates, or supported-model matrix
- No publishing private `~/.cursor/plan-reviews/` transcripts

## Work steps (summary)

1. Scaffold + copy skills  
2. Scrub Acc1 inventory  
3. Write README (Acc4)  
4. Acc3 `rg` gate  
5. Publish  

## Acceptance

1. Public cloneable repo exists  
2. Acc2 layout holds  
3. Acc3 clean  
4. Acc4 README complete  
