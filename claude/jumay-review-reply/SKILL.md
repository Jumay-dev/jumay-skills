---
name: jumay-review-reply
description: Write replies to PR review threads that a human can scan — a verdict line, the sha, and what changed, inside a hard length budget. Use when responding to review comments from a human or a bot (Greptile, Devin, Codex), when an agent's replies are too long to read, or when asked to "address the comments", "reply to review", or "respond to the review threads". Covers the reply text only; jumay-quality-gate Phase 7 enumerates the threads and jumay-parity owns response policy.
---

# Jumay Review Reply

A reviewer with 40 open threads reads **40 first lines**. Write for that.

Measured on real threads before this skill existed: median reply 541–1138
characters, max 1479, 11–15 lines each. One PR carried 49 threads at that
length — roughly 500 lines of prose standing between the reviewer and the
answer to *did you fix it*.

**Scope:** the reply text. Enumerating threads and reconciling counts is
`/jumay-quality-gate` Phase 7. Whether to comply, push back, or self-resolve is
`$jumay-parity` §Review-Response. This skill is only the shape.

## The form

```
<verdict> — <what changed, one line>.
<residual / deviation / decision needed — only if one exists>
```

The verdict is one of six, and it is the first thing on the line:

| Verdict | Use when | Budget |
|---|---|---|
| `Fixed in <sha>` | done as asked | 2 lines |
| `Fixed in <sha>, differently` | done, not the way they proposed | 3 lines |
| `Not fixing` | you disagree | 6 lines — the one place length is earned |
| `Deferred → <ticket>` | agreed, not in this PR | 2 lines |
| `Answered` | it was a question, no code change | 3 lines |
| `Your call` | you need a decision to proceed | 3 lines |

**Hard budget: 3 lines or ~400 characters**, except `Not fixing`. Over budget
means you are explaining rather than reporting — cut, or move it to the PR body.

## Cut these

Every item below came out of a real reply on an open PR:

1. **Gratitude and rapport.** "thank you", "you're right", "Not stupid at all",
   "thanks for the correction", "this was the most important finding".
2. **Reflecting their own diagnosis back at them.** "Your diagnosis was exactly
   right: `isWithdrawOnly` meant two different things…" — they wrote that.
3. **Investigation replay.** How you found it, what you checked first, which
   premise you verified. The reviewer wants the outcome.
4. **Self-justification.** Why you originally did it the wrong way, how many
   times the area has been restructured, how often the branch conflicts.
5. **Test enumeration in prose.** "Three tests cover it: reuse of an emptied
   slot, an elevation-grouped slot being skipped, and…" → `Tests cover both
   branches.` or nothing. CI proves tests ran; G17 proves they are real.
6. **Code blocks that re-show the diff.** The reviewer is looking at the diff.
7. **Adjacent topics.** A new concern buried in the last paragraph of a reply
   about something else is a concern nobody will action. Own thread, or the body.
8. **Meta-commentary on your earlier replies.** "I under-credited that when I
   was answering the xstate version."

## Keep these — always

- **The sha.** Every `Fixed` names the commit. No sha, no claim.
- **Residuals.** A `Fixed` reply that hides a known remainder is worse than no
  reply: it retires a thread the reviewer would still want. Say what is left.
- **Deviations.** If you did not do what they asked, the first line says so.
- **The decision you need**, stated as a question, not buried in analysis.

## Before / after

Real reply, 1296 characters:

> Fixed in `a716350f`. This was the most important finding on the stack — thank
> you. Your diagnosis was exactly right: `isWithdrawOnly` meant two different
> things. The state field means "this wallet is restricted to exits" (hardcoded
> `true` for `risk-flagged`, which is what `deriveAccessGate` reads, so
> Repay/Withdraw CTAs stayed enabled), while `isWithdrawOnlyEnabled()` meant
> "the `?WITHDRAW_ONLY` URL param is present" … *(+9 more lines, a code block,
> and a test enumeration)*

Same content, 380 characters:

> Fixed in `a716350f`. `isWithdrawOnly` was two things — the state field
> ("restricted to exits") and `isWithdrawOnlyEnabled()` ("`?WITHDRAW_ONLY` is
> set") — so the guard threw on exits too. It now blocks only
> `exposure !== REDUCE`; compromised wallets stay blocked for every exposure.
> Also deletes `shared/lib/withdrawOnly.ts`, its last consumer — closes the SSR
> concern on #544.

Nothing a reviewer needs was lost. What went is the part that was written for
the author's benefit, not theirs.

## Disagreeing

`Not fixing` earns six lines because it has to carry an argument. It still opens
with the verdict, never with the build-up:

> Not fixing here. Both existing zustand stores are global; panel state is
> per-loan-instance, so this needs a store factory plus loan-keying — a redesign,
> not a swap. Ticket: FE-1141. Aligning the type names to
> `transaction-sending-machine.ts` in this PR instead (`kind` → `status`).
> Say the word if you want the migration blocking and I will do it here.

If you cannot make the case in six lines, the thread needs a conversation, not a
longer comment.

## Batch discipline

- One thread, one reply. Never answer three threads in one comment.
- Replies land **after** the fix is pushed, naming the pushed sha — not before.
- Do not self-resolve a thread you reinterpreted or only partly addressed
  (`$jumay-parity` §Review-Response). Resolution is the reviewer's.
- Reply on every stack PR's threads, not just the top one.

## Checklist

- [ ] Every reply opens with one of the six verdicts.
- [ ] Every `Fixed` names a sha that is on origin.
- [ ] Nothing over 3 lines except `Not fixing`.
- [ ] No gratitude, no replayed diagnosis, no investigation narrative.
- [ ] Known residuals stated, not omitted.
- [ ] Adjacent concerns moved to their own thread.
