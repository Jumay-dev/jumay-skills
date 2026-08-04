---
name: jumay-worktree
description: Git worktree setup for new ticket work. Use before starting any new Linear or GitHub task, including jumay-oneshot and jumay-parity workflows, to fetch the latest base, create an isolated worktree, and branch from master or the explicit stacked-PR parent branch.
---

# Jumay Worktree

## Purpose

Create every new task in a fresh git worktree so existing local work is
preserved and the task starts from the correct base.

## Required Workflow

1. Resolve the task context before branching.
   - Identify the ticket identifier and slug.
   - Check for an existing active branch, PR, or local worktree for that ticket.
   - If active changes already exist, inspect and continue from them only when
     that is clearly the user's requested intent.

2. Choose the base branch.
   - Default base is `origin/master`.
   - For stacked PRs, use the explicit parent feature branch as the base instead
     of `origin/master`. When the parent is already tracked as a stack, put the
     new branch on top with `gh stack add` rather than branching by hand.
   - Do not infer a stacked base from naming alone; use ticket text, PR links, or
     user instructions.

3. Fetch the latest base BEFORE creating the worktree — never skip this.
   - `git fetch origin master` first, every time, even when you believe the
     local copy is current. Branching off a stale local `master` makes an
     already-squash-merged parent's commits reappear as conflicts and pulls
     unrelated commits into the diff.
   - Branch off `origin/master` (the just-fetched remote ref), not local
     `master`.
   - If you do use the local `master` branch, switch to it and fast-forward it
     from `origin/master` before branching — `git merge --ff-only
     origin/master`. If it will not fast-forward, stop and report; do not force.
   - If `master` cannot be checked out because another worktree owns it, create
     the new worktree directly from `origin/master` and state that in evidence.
   - For a stacked base, refresh the whole stack with `gh stack sync` instead of
     rebasing each branch by hand.

4. Create a new isolated worktree.
   - Use a new branch whose name includes the ticket identifier, for example
     `codex/TICKET-911-pin-shadcn-version`.
   - Use a sibling worktree path that makes the ticket obvious, for example
     `../REPO-TICKET-911-pin-shadcn-version`.
   - Do not reuse a dirty checkout or a previous ticket worktree for a new task.

5. Work only inside the task worktree.
   - Keep the original checkout untouched except for explicit skill/config edits
     requested by the user.
   - Run implementation, validation, commit, push, and PR commands from the task
     worktree.

6. Record setup evidence in the final report or PR body.
   - Worktree path.
   - Branch name.
   - Base ref or parent branch.
   - Fetch/fast-forward result or the reason a direct `origin/master` worktree
     was used.
