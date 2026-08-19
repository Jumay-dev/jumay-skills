# ⑥ PR

Open or update the PR, with evidence intact, and route it for review.

## Load

| | Skill | When |
|---|---|---|
| always | `/jumay-pr-writeup` | title + body house style |
| if | `/jumay-quality-gate` | before undrafting, before merging, or when an agent claims done |
| if | `/jumay-review-message` | Slack handoff to the FE review channel |
| if | `docs/quality-gate.md` G2 | you are editing a body that already has evidence |

## Entry

`spec.md` + the commits + evidence paths captured at ③.

## Do

1. **Title**: `type(scope): short description (FE-1234)` — scope is the product
   area, not the file or layer. Derive the convention from recent merged PRs;
   never guess it.
2. **Body**: exactly `Closes` / `## Problem` / `## What this does` /
   `## Screenshots` / `## QA steps`. Nothing else. The body describes **the
   change** — it does not defend the work, narrate the process, or restate what
   CI already proves.
3. **Evidence (G2)**: screenshots are *uploaded*, not linked. Never remove
   evidence without regenerating it at the current head in the same task —
   "stale screenshot cleanup" is only valid as remove-AND-regenerate, and the
   removal is reported explicitly, not buried in a clause.
4. **Preserve bot-appended blocks** when editing an existing body.
5. **Answer and resolve every review thread.** A thread that looks "outdated" is
   still an open thread. Reconcile the claimed count against the API.
6. **Gate before undrafting** — `/jumay-quality-gate` proves the claims with its
   own commands. CI state comes from `gh pr checks` **on the exact head**.

## Exit gate

- Body validates: five sections, evidence present, capture-commit equals the
  pushed head.
- Every review thread replied to and resolved, counts reconciled via the API.
- `gh pr checks` green on the current head — not on an earlier one.

## Out

A reviewed PR. The flow ends here; merging is `/land-and-deploy`.
