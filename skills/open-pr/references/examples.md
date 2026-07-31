# Examples — open-pr

## Happy path (dirty tree)

```
/open-pr
```

Validate (e.g. `npm run check`), path-stage in-scope files, commit, push, `gh pr create`, print URL, **stop**.

## Already committed

Working tree clean; branch is ahead of `origin/main`:

```
/open-pr title: Document empty-tree diff fallback
```

Skip commit; push if needed; open PR (or return existing PR URL); **stop**.

## Custom validate

```
/open-pr validate='npm run check' base=main
```

## Nothing to do

Clean tree and not ahead of base → stop with “nothing to PR” (do not invent commits).

## Hard stops (by design)

- Never `gh pr merge`
- Never `git push --force` / `--force-with-lease`
- Never `git add .`
