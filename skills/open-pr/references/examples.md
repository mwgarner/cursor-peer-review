# Examples — open-pr

## Happy path (dirty tree)

```
/open-pr
```

Validate → path-stage → commit → push → create PR → print URL → suggest `/merge-pr`.

## Already committed

```
/open-pr title: Document empty-tree diff fallback
```

Skip commit; push if needed; open or reuse PR; stop.

## Open + land (orchestrated)

```
/delivery-ship
```

Runs `/open-pr` then `/merge-pr` (merge still needs chat confirm).

## Hard stops

- Never merge inside `/open-pr`  
- Never `git push --force`  
- Never `git add .`  
