---
name: jumay-ci-preflight
description: Derive the repo's full CI gate list from its workflow config and run every gate that can run locally BEFORE pushing, reporting explicitly which gates could not be checked. Use before opening a PR, before pushing to an open PR, or when asked to "preflight", "check CI locally", or "will CI pass". Also triages an already-red gate for provenance — yours or inherited from the base.
---

# Jumay CI Preflight

Typecheck + lint + tests is a **subset** of CI, not the set. This skill finds the
rest before CI does.

Implements quality-gate **G16 (CI gate parity)** and **G18 (failure provenance)**.

## Phase 1 — Enumerate the gates

Never assume the gate list. Read it:

```bash
ls .github/workflows/
# then read each file — one workflow often holds many jobs
```

Extract, per job: its **name** (as it appears in `gh pr checks`) and its **run
commands**. Most repos run the same command locally that CI runs — the value here
is discovering jobs you did not know existed, not inventing commands.

Cross-check against a real run, which shows the true job list including
third-party checks that live outside the workflow file:

```bash
gh pr checks <n>                    # on an open PR
gh api repos/<owner>/<repo>/commits/<sha>/check-runs \
  --jq '.check_runs[] | "\(.name): \(.conclusion)"'
```

## Phase 2 — Classify each gate

Sort every gate into one of three buckets and keep the list:

| Bucket | Meaning | Action |
| --- | --- | --- |
| **Runnable** | A local command reproduces it (lint, typecheck, tests, knip, steiger, format, custom ast-grep rules) | Run it |
| **Not runnable** | Needs CI infrastructure (Workers/Cloudflare builds, deploy previews, coverage upload) | Report as unchecked |
| **External** | Review bots, third-party analysis (Devin, Greptile) | Report as unchecked |

Never silently drop a gate. A gate you cannot run is an **unknown**, and saying
"CI will pass" while three gates were never checked is the failure this skill
exists to prevent.

## Phase 3 — Run the runnable ones

Run each from the right working directory (monorepos: the workflow's
`working-directory` or `-C` flag tells you). Capture exact output.

Two traps, both real:

- **Package scripts that already pass a separator.** `pnpm test -- <path>` can
  expand into the full suite when the script supplies its own `--`. If a filtered
  run balloons, invoke the runner directly (`pnpm exec vitest run <paths>`).
- **Repo-wide formatters over a dirty tree.** `format --check` may fail on
  pre-existing unrelated files. Check your changed files explicitly
  (`pnpm exec oxfmt --check <files>`) and report the repo-wide state separately
  rather than treating it as your failure.

## Phase 4 — Report

State per gate: pass, fail, or **not checked locally** with the reason. Example
shape:

```
Runnable  ✓ TypeScript    ✓ Lint    ✓ Tests (108 files/960)    ✓ Knip    ✓ Steiger
Unchecked   Workers build (needs CI)    Devin/Greptile (external)
```

Then say plainly what that does and does not license: "every gate I can run
locally is green; three could not be" — not "CI will pass".

## Phase 5 — Provenance triage for a red gate (G18)

When a gate is already failing, establish ownership BEFORE fixing:

```bash
# 1. Do the flagged files even exist on your branch?
git ls-tree --name-only HEAD <flagged-path>

# 2. Did the base gain them after your merge-base?
git fetch origin <base>
git log --oneline $(git merge-base HEAD origin/<base>)..origin/<base> -- <flagged-path>

# 3. Does the gate fail on the base independently?
gh pr checks <pr-that-introduced-it> | grep -i <gate>
```

- **Yours** → fix it.
- **Inherited** → report it, name the PR that introduced it, and do NOT fix it
  inside your PR. Deleting or ignoring another team's files in an unrelated PR is
  scope creep with a blast radius. Offer the options (ping the author, a separate
  one-line PR, or merge red if there is precedent) and let the human choose.

Re-check after any base sync: a rebase onto a fixed base can clear an inherited
failure with no code change from you.

## When to run

- Before opening a PR — always.
- Before every push to an open PR — the cheap version: the gates your diff could
  plausibly affect, plus any that failed last time.
- After a rebase onto a new base — the full set, since the base changed under you.

## Checklist

- [ ] Gate list read from workflow config, not assumed
- [ ] Cross-checked against a real `check-runs` list for external gates
- [ ] Every gate classified runnable / not runnable / external
- [ ] Runnable gates actually run, exact output captured
- [ ] Unchecked gates named explicitly in the report
- [ ] Any red gate triaged for provenance before being fixed
