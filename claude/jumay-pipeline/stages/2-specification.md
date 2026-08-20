# Stage 2 — Specification

Turn findings into a contract an executor can follow without guessing. This is
the stage that decides scope.

**The house format is mandatory.** `## Overview` + `## Acceptance Criteria` in
`fe-spec-tickets` style is what the ticket carries, and it constrains the AC
list — not the whole document. Engineering content lives below the ACs in
sections that are explicitly not ACs. See **Shape of spec.md**.

## Load

| | Skill | When |
|---|---|---|
| always | `fe-spec-tickets` | the mandated house style: `should` ACs, backticked labels, no boilerplate |
| always | `docs/quality-gate.md` **G19** | the single most important rule for writing a brief |
| if | `$jumay-parity` §Success Gate, §Figma-Accurate Parity Gates | design-parity ticket — its gates are the AC |

`fe-spec-tickets` lives in the `Kamino-Finance/almanack` catalog
(`skills/kamino/fe-spec-tickets`) and must be installed to load. It also governs
the upstream job — a feature request becoming Linear tickets — which happens
**before** stage 1. Here you are consuming its format, not running its workflow.

## Entry

`findings.md` with a populated **Open questions** list, plus the source ticket if
one exists.

## Shape of spec.md

```markdown
## **Overview**

[1–3 plain sentences: what the feature is, what it adapts or references.]
[Source links — Figma, ticket — as plain markdown links.]

## **Acceptance Criteria**

- [ ] should open the dropdown filter on `Filters` button click
- [ ] should persist selections in the url

---
## Non-goals
## Evidence required
## Rejected alternatives
## Constraints for the executor
```

Everything above the `---` is house style and may be pasted into the ticket
unchanged. Everything below it is the executor contract and never becomes an AC.

## Do

1. **Copy the ticket's ACs verbatim.** Never paraphrase them. If the ticket says
   ``should persist selections in the url`` and the spec says "URL state is
   preserved across navigation", a PR can satisfy one and fail the other — and
   review checks the spec while QA checks the ticket. Ticket ACs are a subset of
   spec ACs; add new ones beneath, never rewrite the existing ones.
2. **Write ACs in house style.** Flat checkbox list, no sub-headers or grouping,
   each item terse lowercase starting with `should`, test-description style. UI
   labels and values in backticks: `Filters`, `Reset`, `7 days`. Each item binary
   and verifiable — "should work well" is not an AC.
3. **User-observable behavior only, in the AC list.** A behavioral constraint is
   fine when it is user-visible (`should persist selections in the url`); a
   purely internal choice — where filtering runs, component structure — is not.
   **A technical constraint becomes an AC only when the requester states it**, so
   ask rather than inserting it yourself. Everything you would have inserted goes
   under **Constraints for the executor** instead, where it binds the executor
   without polluting the ticket.
4. **No boilerplate ACs.** `Add Unit tests`, `Add Tracking Events` and their kin
   are engineering conventions, not feature spec — the pipeline enforces them at
   stage 4. Include them only if explicitly requested.
5. **Quote only what you have read.** Every label in an AC must have been read
   off the design or the ticket, never inferred. If a label is not confidently
   readable, re-screenshot the node at a larger `maxDimension` or screenshot the
   sub-node in isolation. A guessed label is a wrong AC that reviews clean.
6. **Name the non-goals.** Scope creep is cheaper to prevent here than to review
   out at stage 4.
7. **G19 — never offer a choice between a safe and an unsafe option.** If the
   spec says "fall back OR throw", the executor picks one and you will
   rationalise it. Specify the safe one and explain why; put the alternative in
   a *rejected because* note. When a change hardens a shared function, enumerate
   every consumer before choosing the failure mode.
8. **Pre-declare the evidence** the PR will need (screenshots, overlays, scores)
   so stage 3 captures it while the context is live, not at stage 6 from memory.

## Grill the draft

Do not present the whole spec and ask "looks good?". Walk the user through it
**one question at a time, each with a recommended answer**, probing vague scope,
terminology that conflicts with the project glossary, and states visible in the
design but missing from the ACs. This is what forces the ACs to be checked
rather than skimmed, and it is what keeps the 1⇄2 loop bounded.

## The 1⇄2 loop

Bounded. Two round trips. If open questions survive a second pass they go to the
user as a decision, not to another investigation round.

## The go signal

Nothing leaves this stage — no ticket written, no executor dispatched — without
an explicit instruction to proceed ("create them", "go ahead", "ship it").

**Placement details, style edits, AC changes, content feedback, and even "looks
good" are not go.** When the draft is settled and every detail is known, confirm
in one line — "dispatching 2 executors against spec.md for FE-1234 — go?" — and
wait. One redundant confirmation beats an unwanted ticket or a wasted run.

## Progress

Append one line per step, so the run is visible without reading your pane:

```sh
echo "PROGRESS specification <what you are doing now>" >> "$PIPELINE_DIR/<ticket>/progress.log"
```

The dashboard renders the last line. A log that stops moving for five minutes
shows as quiet — which is the signal to check the agent, not the artifact.

## Exit gate

- `spec.md` carries `## **Overview**` and `## **Acceptance Criteria**` in house
  style, then **Non-goals**, **Evidence required**, **Rejected alternatives**,
  **Constraints for the executor** below the rule.
- Every AC starts with `should`, is lowercase, is binary, and backticks its UI
  labels. No sub-headers inside the list. No boilerplate ACs.
- The source ticket's ACs appear **verbatim**.
- Every quoted label was read, not inferred.
- **Open questions is empty**, or every entry names the user decision that
  closed it.
- No instruction offers the executor a safe/unsafe choice.
- The go signal was given.

## Out

`spec.md` → the contract. Carries through every remaining stage.
