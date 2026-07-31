# Plan peer review (example, condensed)

**Plan:** `~/.cursor/plans/example_feature_aabbccdd.plan.md`  
**Loops:** 2 of 2  
**Critics:** composer-2.5 / cursor-grok-4.5-high / gpt-5.6-sol-high  
**Verdict: Reject** — Apply before Build

## Sustained findings

### Blockers

- **[example_feature_aabbccdd/C-B1]** Scrub step named only `examples.md`; product stems also live in `SKILL.md` and rubrics. Lock an explicit Acc1 inventory.
- **[example_feature_aabbccdd/C-B2]** Acceptance `rg` only checked obvious repo names; would false-green on private plan stems. Expand Acc3 patterns.
- **[example_feature_aabbccdd/C-B3]** Install docs said “INSTALL.md or README” — deferred. Lock README-only.

### Majors

- **[example_feature_aabbccdd/C-M2]** Acc claimed all three skills have `scripts/`; ship has none. Amend Acc2.
- **[example_feature_aabbccdd/C-M3]** Env overrides used by scripts were not Acc-gated in README.

## Recommended plan deltas

1. Acc1 scrub inventory (all `SKILL.md` + `references/*`)  
2. Acc3 expanded deny-list `rg`  
3. README-only install + env table (Acc4)  
4. Acc2 scripts-where-present  

## ADR

None

---

*Teaching fiction. Live reports are written under `~/.cursor/plan-reviews/<stem>/`.*
