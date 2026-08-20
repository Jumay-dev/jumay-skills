---
name: jumay-commit
description: Pre-commit gate and commit discipline — derive the repo's own check commands and git hooks, run only the gap the hooks do not cover, on the STAGED content rather than the working tree, then commit atomically and signed with the message convention read from git log. Use before every commit, when a commit needs typecheck/lint verified first, or when asked to "commit this", "check before committing", or "will this commit compile". Not a CI sweep — that is jumay-ci-preflight before pushing.
---

# Jumay Commit

Cheap gate, run often. Its job is that **every commit compiles and lints on its
own**, not that the branch passes CI — the full sweep is `/jumay-ci-preflight`
at stage 4, once, before push. Running the CI set on each of five atomic commits
wastes minutes per commit and is why per-commit checks get abandoned.

Implements quality-gate **G1 (signing)** and **G8 (fetch before you base)**.

## Phase 1 — Derive the checks and the hooks

Never assume the commands. Read them, both halves:

```bash
# What the repo can run
cat package.json | jq '.scripts'         # root; then each workspace package
ls Makefile justfile Taskfile.yml 2>/dev/null

# What already runs on its own
git config core.hooksPath
ls .husky/ 2>/dev/null; cat .husky/pre-commit .husky/pre-push 2>/dev/null
cat lefthook.yml .pre-commit-config.yaml 2>/dev/null
```

Build the gap table — **you only run the right-hand column**:

| | Covered by a hook | Your gap |
|---|---|---|
| kmono | `pre-commit`: oxfmt + oxlint on staged `apps/frontend/src/**` · `pre-push`: typecheck, knip, `lint:rules` | anything outside those globs — `libs/ui`, configs, workflows — and typecheck **per commit** rather than once per push |

Two things that table exposes, both real in kmono:

- **The hook's globs are not your diff.** `pre-commit` matches
  `apps/frontend/src/**` and three specific files. A commit touching only
  `libs/ui` or `.github/workflows` passes through completely unchecked.
- **Nothing typechecks until push.** You can build five atomic commits and learn
  at push that #2 does not compile. If the commits are meant to be individually
  revertable or bisectable, typecheck each one; if they will be squashed, once
  before push is enough. Decide deliberately — do not discover it.

## Phase 2 — Check the index, not the working tree

Every check runs against files **on disk**. If the working tree differs from what
you staged, you validated something you are not committing.

```bash
git diff --quiet && echo "tree == index — checks are valid for this commit" \
                 || echo "UNSTAGED CHANGES — checks do not describe the commit"
```

If it reports unstaged changes: stage them, or state plainly in your report that
the check covered the tree and not the commit. **Do not `git stash` to work
around this in an agent loop** — a failed check between stash and pop strands the
user's work in a stash they did not create.

## Phase 3 — Run the gap

- **Format and lint: scope to staged files.** `git diff --cached --name-only
  --diff-filter=ACMR` gives the list; most linters take paths.
- **Typecheck: cannot be scoped.** It is project-wide by nature. This is the
  expensive one, so Phase 1's decision about per-commit vs per-push is the whole
  cost question.
- **Verify by exit code**, never by reading output. A linter that prints warnings
  and exits 0 passed; a tool that prints nothing and exits 1 did not.

## Phase 4 — Never bypass, never double-run

- **`--no-verify` is forbidden.** If a hook fails, the hook is right until proven
  otherwise. A blocked commit is information.
- **A hook may rewrite your commit.** kmono's `pre-commit` runs `oxfmt` and then
  `git add` on the staged paths — the content committed is not the content you
  staged. After a hook-formatted commit, read the diff you actually made.
- **A red gate may not be yours (G18).** Before fixing: does the flagged file
  exist on your branch, and does the same gate fail on the base independently? An
  inherited failure is reported, not fixed inside an unrelated commit.
- Do not re-run what the hook just ran. That is the gap table's purpose.

## Phase 5 — The commit itself

1. **Fetch before you base — always, first (G8).** `git fetch origin master`,
   then base off the freshly fetched `origin/master`, never a stale local
   `master`, which resurrects a squash-merged parent's commits as conflicts.
2. **Derive the message convention from `git log`, never guess it:**
   ```bash
   git log --format='%s' -30
   ```
   Match the observed shape — type, scope vocabulary, whether a ticket key is
   appended and how.
3. **One logical change per commit.** If the message needs "and", it is two
   commits.
4. **Never touch signing config (G1).** No local `user.signingkey`, no signature
   format switch, no unsigned commit when the signer is unavailable. On signing
   failure: STOP, leave the work uncommitted, report `BLOCKED-SIGNING`. Do not
   retry with a workaround.

## Phase 6 — Verify with your own commands (G7)

```bash
git log --format='%G? %h %s' origin/<base>..HEAD   # every new commit shows G
git diff --cached --quiet                          # nothing left staged
git status --short                                 # nothing unexpectedly untracked
```

After pushing, confirm the commits are **on origin** — locally present is not
pushed:

```bash
git merge-base --is-ancestor <sha> origin/<branch> && echo "on origin"
```

## Checklist

- [ ] Hook coverage read, gap table built, only the gap run.
- [ ] `git diff --quiet` clean — or the report says the check covered the tree.
- [ ] Every check judged by exit code.
- [ ] No `--no-verify`. No signing-config changes.
- [ ] Message convention derived from `git log`, one logical change.
- [ ] `%G?` shows `G` on every new commit; shas confirmed on origin.
