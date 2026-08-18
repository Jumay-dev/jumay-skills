---
name: jumay-ci-preflight
description: Run the repo's real CI gates locally before committing and before pushing, derived from the workflow config rather than assumed, and prove the base is current first — a green run against a stale base is not evidence. Use before any commit, before opening or pushing to a PR, after any rebase, or when asked to "preflight", "check CI locally", "run the checks", or "will CI pass". Also triages an already-red gate for provenance — yours or inherited from the base.
---

# Jumay CI Preflight

Typecheck + lint + tests is a **subset** of CI, not the set. This skill finds the
rest before CI does.

Implements quality-gate **G16 (CI gate parity)**, **G18 (failure provenance)** and
**G20 (stale-base green runs)**.

Two moments, two lanes:

| Lane | When | What runs |
| --- | --- | --- |
| **Commit lane** | before every commit | the fast gates your diff can break: typecheck, lint, custom rules, the affected tests |
| **Push lane** | before push / PR / after rebase | Phase 0 base check, then every runnable gate |

The commit lane is the cheap one and it is not optional — an executor that commits
without it hands the orchestrator work that has to be redone. The push lane is the
full sweep below.

## Phase 0 — Prove the base is current (push lane)

**Do this first. A green run against a stale base is not evidence** — CI tests your
branch *merged with the base*, so a base that moved under you can turn a green local
run red with no change of yours.

```bash
git fetch origin <base>
git rev-list --count HEAD..origin/<base>     # 0 = current
```

If you are behind, rebase locally **before** running any gate — never via GitHub's
"Update branch", which re-signs nothing and leaves every commit Unverified.

After any rebase, **re-run the gates even if git reported no conflicts.** The
dangerous case is the one git merges silently:

- the base adds a **required field** to a shared type, and your new fixture predates
  it — clean merge, broken `tsc`;
- the base changes a **shared function's signature or semantics**, and your caller
  still compiles but now means something different;
- the base moves a symbol between modules while you edited its old home.

Typecheck is the cheapest detector for the first two and catches what git cannot.
"Rebased cleanly" is a statement about text, not about meaning.

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

- **Before every commit** — commit lane. Typecheck, lint, custom rules and the
  affected tests. Cheap, and it keeps broken work out of the history.
- **Before opening a PR** — push lane, full set, starting at Phase 0.
- **Before every push to an open PR** — Phase 0, then the gates your diff could
  plausibly affect plus any that failed last time.
- **After every rebase** — full set. Especially typecheck. See Phase 0.
- **Whenever CI goes red on a branch that was green locally** — suspect the base
  first (Phase 0), then run provenance triage (Phase 5).

## Checklist

- [ ] Gate list read from workflow config, not assumed
- [ ] Cross-checked against a real `check-runs` list for external gates
- [ ] Every gate classified runnable / not runnable / external
- [ ] Runnable gates actually run, exact output captured
- [ ] Unchecked gates named explicitly in the report
- [ ] Any red gate triaged for provenance before being fixed
- [ ] Base confirmed current (`HEAD..origin/<base>` is 0) before trusting a green run
- [ ] After any rebase, typecheck re-run even though git reported no conflicts
- [ ] Commit lane run before each commit, not just once before the push
