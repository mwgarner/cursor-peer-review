# Examples — delivery-ship

## After peer-review-ship + Build

```
/delivery-ship
```

Runs `/open-pr`, prints PR URL, then `/merge-pr` (asks you to reply `merge` when ready).

## With title / validate

```
/delivery-ship title: Harden collect-diff empty-tree validate='npm run check'
```

## Cancel at merge gate

Open succeeds; at merge confirm you say `cancel` → PR stays open; no merge.
