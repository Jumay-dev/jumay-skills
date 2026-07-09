---
name: jumay-oneshot
description: End-to-end webapp ticket workflow. Use when asked to solve a Linear/GitHub ticket for the webapp from issue lookup through isolated worktree, scoped code change, verification, PR creation, Linear update, and Slack review ping.
---

# Jumay Oneshot

## Workflow

Use this for one-ticket webapp fixes where the expected outcome is a shipped PR, not just analysis.

1. Resolve the ticket first.
   - Read the Linear issue by exact identifier, including attachments, relations, customer needs, and branch name.
   - If exact lookup fails, search Linear by likely variants, remote branches, GitHub issues/PRs, and public Slack mentions.
   - Do not invent ticket requirements. If ticket text remains inaccessible, continue only with non-product setup work and report the blocker clearly.

2. Create an isolated worktree.
   - Load and follow `$jumay-worktree` before branching.
   - Start from refreshed `origin/master` unless the ticket is explicitly a stacked PR, in which case use the explicit parent feature branch as the base.
   - Use a branch name that includes the ticket identifier, for example `codex/TICKET-1234-short-slug`.
   - Keep the original checkout untouched except for intentional skill/config changes explicitly requested by the user.

3. Implement narrowly.
   - Follow the repo `AGENTS.md`/`CLAUDE.md` conventions.
   - Load and follow `$jumay-implementation-guardrails` before editing non-trivial code, and revisit it during self-review.
   - Prefer existing UI kit, Tailwind tokens, SDK helpers, route/query key constants, and feature-sliced imports.
   - For copy/text tickets, search all user-facing strings, update the smallest owning component or locale/source, and add or adjust focused tests only when behavior or rendering contract can regress.

4. Verify before publishing.
   - Run the smallest targeted test or static check that proves the change.
   - For non-trivial webapp changes, run `pnpm typecheck`; add `pnpm check` or targeted tests when relevant.
   - Read failures and fix them before claiming the PR is ready. If a check cannot run, state the exact reason.

5. Publish the PR.
   - Inspect `git status` and `git diff`; stage only intended files.
   - Commit with a conventional commit scope from the repo config.
   - Push the branch and open a draft PR unless the user explicitly requested ready-for-review.
   - PR body should include the ticket link, what changed, why, and validation evidence.

6. Finish integrations.
   - Add a Linear comment with PR link and validation, and move status only if the requested transition is clear and low risk.
   - Once local validation and visible PR checks are green, load and follow `$jumay-review-message` for the requested Slack review message.
   - Resolve Slack user IDs before mentioning people; use `<@U...>` syntax. If a requested mention cannot be resolved, say so and avoid pretending it will notify.

## Stop Conditions

Stop only when the PR exists, requested checks are green or a precise blocker is documented, Linear has the PR context when accessible, and any requested Slack message has been sent. Ask the user only for inaccessible ticket context, destructive actions, production credentials, or materially ambiguous product requirements.
