# ② Specification

Turn findings into a contract an executor can follow without guessing. This is
the stage that decides scope.

## Load

| | Skill | When |
|---|---|---|
| always | `docs/quality-gate.md` **G19** | the single most important rule for writing a brief |
| if | `$jumay-parity` §Success Gate, §Figma-Accurate Parity Gates | design-parity ticket — its gates are the AC |

## Entry

`findings.md` with a populated **Open questions** list.

## Do

1. **Close the open questions.** Each one is answered from code (go back to ①)
   or by the user. An unanswered question at exit is a decision the executor
   will make for you.
2. **Write acceptance criteria that are checkable**, not descriptive. "Handles
   the empty case" is not AC; "renders the pending state when `maxLtv` is null"
   is.
3. **Name the non-goals.** Scope creep is cheaper to prevent here than to review
   out at ④.
4. **G19 — never offer a choice between a safe and an unsafe option.** If the
   spec says "fall back OR throw", the executor picks one and you will
   rationalise it. Specify the safe one and explain why; put the alternative in
   a *rejected because* note. When a change hardens a shared function, enumerate
   every consumer before choosing the failure mode.
5. **Pre-declare the evidence** the PR will need (screenshots, overlays, scores)
   so ③ captures it while the context is live, not at ⑥ from memory.

## The ①⇄② loop

Bounded. Two round trips. If open questions survive a second pass they go to the
user as a decision, not to another investigation round.

## Exit gate

- `spec.md` has: **AC** (checkable), **Non-goals**, **Evidence required**,
  **Rejected alternatives**.
- **Open questions is empty**, or every entry names the user decision that
  closed it.
- No instruction in the spec offers the executor a safe/unsafe choice.

## Out

`spec.md` → the contract. Carries through every remaining stage.
