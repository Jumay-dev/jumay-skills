# ⑦ Review response

Review came back. Triage it, route the code changes, reply so a human can read
the replies. This is the only stage that can send you backwards.

## Load

| | Skill | When |
|---|---|---|
| always | `/jumay-review-reply` | the shape of every reply |
| always | `/jumay-quality-gate` §Phase 7 | enumerate threads, reconcile claimed vs fetched counts |
| if | `$jumay-parity` §Review-Response | whether to comply, push back, or self-resolve |
| if | `docs/quality-gate.md` G3 | a comment flags deletions or "removed infrastructure" |
| if | `docs/quality-gate.md` G2 | the response touches PR evidence |

## Entry

An open PR with review threads. `spec.md` still applies — a comment asking for
something the spec listed as a **non-goal** is a scope question, not a task.

## Do

1. **Enumerate first, fix nothing.** Fetch every thread on every PR in the stack
   via GraphQL — `--paginate`, never truncated. Reconcile the count a review body
   claims against the threads you hold. A green bot check is not an empty review.
2. **Verify each premise before changing anything.** A comment can be wrong;
   applying it blindly regresses code that was already correct. If the code is
   right, the reply is the evidence, not a change.
3. **Triage each thread into one of the six verdicts** (`/jumay-review-reply`).
   The triage *is* the plan for this round.
4. **Route the code work back to ③** — anything verdicted `Fixed` re-enters
   implementation, then ④ and ⑤ as normal. Fixes regress at the same rate as
   features (G4); a fix round is not exempt from selfreview.
5. **Reply only after the fix is on origin**, naming the pushed sha. A reply
   naming a sha that is not pushed is a false claim.
6. **Do not resolve threads.** An agent resolving threads against its own work
   hides history from the reviewer. Resolution is the reviewer's.

## Loop control

Each round: enumerate → triage → route → fix → reply. Do not start a second
round while the first has unanswered threads — that is how a count drifts from 8
to 3 without anyone noticing.

## Progress

Append one line per step, so the run is visible without reading your pane:

```sh
echo "PROGRESS review-response <what you are doing now>" >> "$PIPELINE_DIR/<ticket>/progress.log"
```

The dashboard renders the last line. A log that stops moving for five minutes
shows as quiet — which is the signal to check the agent, not the artifact.

## Exit gate

- Every thread across every stack PR carries a verdict.
- Every `Fixed` reply names a sha that is on origin (`merge-base --is-ancestor`).
- No reply over 3 lines except `Not fixing`.
- Anything still open is named explicitly, not silently carried.

## Out

Replied threads + `review-round-<n>.md` (the ledger: thread, finding, verdict,
sha). Loops to ③ for code, or ends the flow when the round is clean.
