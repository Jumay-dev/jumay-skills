---
name: jumay-figma-implement
description: Implement any feature the user points to in Figma, end to end, via a deterministic five-phase agent pipeline — investigate → interview → execute → verify → close. Use when the user gives a Figma node URL (optionally with a Linear/GitHub ticket) and wants the component/feature built, visually verified against Figma, and delivered as one reviewed PR. Builds on herdr-agents for pane orchestration; the verifier skill is pluggable (default $jumay-parity).
---

# Jumay Figma Implement

Turn a Figma pointer into a merged-ready PR through a fixed pipeline of
spawned agents, with the orchestrator (you) independently verifying every
stage and gating on explicit user decisions. The pipeline is deterministic:
phases run in order, each has an entry contract and an exit gate, and no
phase's self-reported success is trusted without orchestrator verification.

## Inputs

- **required**: one or more Figma node URLs (file key + node-id), or a ticket
  that embeds them.
- **optional**: ticket URL (Linear/GitHub) for AC and branch naming; a
  verifier skill name (default `$jumay-parity`); a target repo/dir if not cwd.

## Preconditions (Phase 0)

1. `herdr status` running and `HERDR_ENV=1` — follow the herdr-agents skill
   for all pane mechanics. Never tmux.
2. Repo identified; note git submodules (they must never be staged by any
   agent — name them explicitly in every dispatch).
3. Figma MCP reachable (a `get_screenshot` on the given node succeeds).

## Phase 1 — INVESTIGATE (Fable pane)

Spawn a `claude` pane (`claude --model fable --dangerously-skip-permissions`),
label it `<ticket>-spec`. Write the brief to a scratchpad file and dispatch
"Read <file> and execute it" (long prompts pasted into TUIs are fragile).

The brief must demand a spec file containing:

- **Per-state Figma node IDs** — the pointed node is often an umbrella
  section; the verifier needs the exact frame per state/level/variant.
  Record dimensions per state (they can genuinely differ).
- **In-context usage walk** — for every frame where the design EMBEDS the
  component inside a page, screenshot it and record the container semantics:
  anchored popover vs centered modal (scrim? centering math?) vs inline
  section, plus elevation/contrast against the page on both themes. The
  standalone component frames alone cannot answer "what is this thing hosted
  in?" — skipping this walk causes packaging rework (content-only → popover
  → modal is one session's real churn).
- **Provenance for visual claims** — any statement about typography, weight,
  color, or spacing must cite `get_design_context`/variable output for the
  node, never an eyeballed screenshot. Orchestrator- or spec-authored visual
  guesses propagate: the executor implements them and the verifier
  rationalizes them.
- **Verbatim visible text** for every state, including apostrophe style,
  case quirks, and duplicated placeholder rows — flag content that looks
  like a design artifact instead of silently keeping or fixing it.
- **Conventions mined from the last 3-5 similar PRs** (component location,
  story/MDX patterns, export style, commit message format, asset dirs).
- **Design-token mapping** (Figma variable → repo utility), noting variables
  with per-theme redirects (a variable named like `accent dark:input/50`
  means light uses the accent token, dark uses input at 50% — a single
  utility class will be wrong in one theme).
- **Component-instance metadata**: for every Figma layer that is an instance
  of a design-system component (buttons, inputs), record the component name
  and variant/size — the executor must reuse the kit equivalent, never
  hand-roll.
- **Icon inventory**: exact Figma icon layer names AND style (filled vs
  outlined) per icon; map each to a concrete package export, marking
  unverified guesses `(verify)`.
- **Pre-downloaded assets** to scratchpad (Figma asset URLs expire).
- **Repo/branch/validation commands** (verify workspace filter/package
  names against the actual manifest `name` fields — e.g. `pnpm --filter`
  targets), files-to-create list, explicit
  out-of-scope list, and a **Known uncertainties** section.

Exit gate: orchestrator READS the spec (not the agent's summary of it) and
confirms every section above exists.

## Phase 2 — INTERVIEW (orchestrator ↔ user)

Mandatory. Before any code, ask the user about behavior via AskUserQuestion
(batch up to 4 per call, multiple calls fine). Derive questions from the
spec's Known uncertainties plus this standing bank — every item below caused
rework when skipped:

1. **Interactivity scope** — which elements are clickable/navigable? Should
   visually-repeated items get mock data so ALL of them work, or only the
   ones with designed content?
2. **Inputs** — is each input-looking element a REAL editable input or
   presentational? What happens on submit/Enter?
3. **Keyboard & a11y** — Tab order, Enter/Space activation, Backspace/Escape
   navigation expectations, focus management between views.
4. **Hover/press affordances** — Figma-literal values can be imperceptible
   (e.g. two near-identical translucent fills); does the user want literal
   parity or a perceptible interaction? Any reveal animations (easing,
   duration)?
5. **Content corrections** — for each flagged design artifact (duplicate
   rows, lowercase quirks, placeholder copy): keep verbatim or correct?
6. **States baked into frames** — Figma often bakes hover/focus/cursor into
   the exported frame. Confirm those are capture-only states, never
   user-visible defaults.
7. **Reuse policy** — kit components/variants over custom markup; which
   icon package family (filled/outlined) when Figma is ambiguous.
8. **Scope** — component-workbench-only (Storybook or equivalent) vs wired
   into app routes; theming expectations
   when Figma is single-theme; responsive expectations.
9. **Container semantics** — if any in-context frame shows the component
   floating over a page, ask what packaging ships NOW: content pane only,
   anchored popover, or modal with overlay — and walk the user through the
   in-context screenshots (scrim, centering, elevation) before they answer.
   Also ask how the floating form must separate visually on both themes when
   the design gives it no shadow/border.
10. **Interaction-test stories** — play() stories auto-replay their whole
   interaction sequence every time the story renders, which reads as
   "component opens/closes by itself" during manual QA. Default to splitting:
   clean visual story + separate `…Interactions` story carrying play().

Recommendation bias: when marking an option "(Recommended)", do not default
to the Figma-literal reading. For consent/safety-pattern controls (confirm
checkboxes, destructive actions), recommend the protective behavior (e.g.
gate the action until consent) and offer design-literal as the override —
design frames usually show only the happy state, and users reverse
literal-first recommendations after build, at rework cost.

Append the answers to the spec as a `## Behavior decisions` section, each
line marked USER-DECISION (they override Figma literals; the verifier must
record any resulting Figma deviation in ledger + PR as an intentional,
user-requested exclusion).

Exit gate: user has answered; spec updated.

## Phase 3 — EXECUTE (Codex pane)

Spawn `codex --yolo` pane, label `<ticket>-exec`, dispatch: spec path +
"implement exactly, run all validation commands until clean, commit on the
branch, do NOT create a PR" + the submodule ban + "for focus management,
dismissal, and positioning, use the primitive library's own APIs before
hand-rolling any machinery". The verifier owns the PR so evidence and parity
fixes live in one reviewable place.

If work happens in a fresh git worktree and the repo has submodules,
INITIALIZE the submodules in the worktree before any dependency change
(`git submodule update --init`) even though they must never be staged: with
empty submodule dirs, a workspace package manager silently PRUNES their
importers from the lockfile — a 30k-line rewrite that breaks every other
checkout — and the trap stays invisible until the first real dep addition.

Exit gate (orchestrator, independently): branch exists with the commit;
`git show --stat` matches the files-to-create list; validation commands the
agent claims passed actually pass (spot-run at least typecheck); no
submodule or artifact dirs staged. Verify command outcomes by EXIT CODE,
never by grepping their output: colored output puts ANSI codes between words
("error TS" never matches), and "no output through my grep" reads as green
while the command failed — both produced false-green gates in real runs.

## Phase 4 — VERIFY (Codex pane, verifier skill)

Spawn `codex --yolo` pane, label `<ticket>-verify`, dispatch the verifier
skill (default `$jumay-parity`) with: ticket URL, branch + commit, the spec
path, the story↔node mapping table, the capture-only state notes, and the
USER-DECISION deviations list. State explicitly: "implementation exists —
verify and fix, do not reimplement."

Then run the review sweep until done: all automated review-agent threads
(Greptile, Devin, or whatever bots the repo uses) across all heads
fixed-or-justified and resolved, fresh review on the final head,
unresolved thread count 0.

HUMAN reviewer threads follow different etiquette: fix, then REPLY on each
thread with what changed + the fixing commit sha — never resolve a human's
threads for them. For human-review rounds the sweep gate becomes: 0
unresolved BOT threads, a reply posted on every human thread, checks green
on the final head; the human resolves and re-approves on their own time.

Exit gate — orchestrator verifies with own eyes/commands, never from the
agent's summary:

- Open the overlap/evidence images yourself (Read tool). Blank ≈500-byte
  PNGs, uniform vertical offsets, doubled glyphs, different text wrapping
  are pipeline bugs (see Failure playbook), not "rasterization".
- `capture_commit` in the evidence manifest == final pushed head. Evidence
  captured before the last code change is invalid — demand regeneration.
- `gh pr view`: checks all SUCCESS, body has the evidence table with
  uploaded images, gate score present, zero unresolved threads.
- Grep the code for each specific claim (icon exports, keyboard handlers,
  scoped style selectors) rather than trusting the report.
- Typography/weight/color claims in ledgers must be re-derived from
  `get_design_context` on the Figma node — never accepted from the spec or
  the implementation (a wrong spec note otherwise becomes self-confirming).
- Any class or style doing geometry (radius, gaps, z-index, corner collapse)
  must be verified as COMPUTED CSS in the capture browser — malformed utility
  variants are silent no-ops that pass typecheck, lint, and tests while
  rendering nothing.
- Exact outer dimensions prove nothing about internals: wrong inner gaps can
  cancel out by the last block (compensated drift). Spot-check per-block
  y-positions (Figma metadata geometry vs DOM getBoundingClientRect) on at
  least one state.
- Grep the diff for hard-coded style literals — hex/rgba colors, arbitrary
  values (`bg-[#…]`, `rounded-[Npx]`, shadow/duration literals) — every one
  must either map to a design token / CSS variable or carry a one-line
  no-token-exists justification. Component-specific geometry from the
  design (fixed widths/heights) may stay literal. RE-RUN this grep on every
  fix round's new diff, not just the first gate — later rounds introduce new
  surfaces (overlays, wrappers) and a literal added in round N sails past a
  gate that only ran in round 1 (a hardcoded scrim color that was invisible
  in dark mode shipped exactly this way).
- Public-API contract pass — read the new component's exported props as a
  consumer would: every lifecycle callback fires on EVERY path that triggers
  it (an `onClose` that fires from the close button but not Escape/backdrop
  is a trap); no type casts that erase required callback parameters (they
  surface as consumer-side runtime crashes the stories never hit);
  children/trigger/slot semantics match ecosystem expectations.
- Hand-rolled interaction machinery is a smell: if the diff implements focus
  management, dismissal, or positioning around a primitive library
  (Base UI/Radix/etc.), check the library's own API first — it almost always
  has the hook (e.g. modality-aware `initialFocus`), and the hand-rolled
  version is where stale refs and a11y bugs live.
- Dialogs/popovers must have a programmatic accessible name: assert
  `getByRole("dialog", { name: <title> })` in a test. Visible headings that
  aren't registered through the primitive's Title/Description components
  leave the dialog unnamed for screen readers, and no visual gate ever
  catches it.
- Reviewer suggestions are changes like any other: verify them with the same
  rigor before applying. A "this class is redundant" nit can be wrong — a
  wrapper's base class may make the override load-bearing — and applying it
  blindly regresses pixels that only the next recapture catches. When an
  override survives a redundancy claim, document why inline.
- Drive the deployed/local component workbench with a headless browser
  (the browse skill) for user-reported behaviors (hover, keyboard, scroll).

## Phase 4.5 — FRESH-EYES REVIEW (optional, recommended before close)

Accumulated context blinds every long-running participant — orchestrator,
executor, verifier, even the human reviewer engaging thread-by-thread. Spawn
one NEW agent with ZERO prior context (fresh pane, read-only contract, report
file as deliverable) to review the final branch diff with two mandated
lenses: (1) a11y roles/names, and (2) "what will the NEXT consumer of this
API hit first." In one real run this phase found a HIGH (unnamed dialog) and
an API-adequacy blocker that four verification rounds and three human review
rounds all missed. Gate its completion on the report file existing, not on
the pane going idle.

## Phase 5 — CLOSE

Report to the user: final head SHA + signature status, PR link, gate score,
what deviated from Figma and why (USER-DECISIONs), remaining human steps
(merge, ticket status). Offer to close panes — never close them unprompted.

## Dispatch & monitoring mechanics (hard-won)

- `pane split` prints JSON — parse `.result.pane.pane_id` with a JSON parser;
  do NOT grep for a fixed id pattern (formats vary by version, e.g.
  `w<workspace>-N`, and a wrong grep silently returns empty). Label
  immediately; pane IDs RENUMBER when any pane closes — always relocate
  agents by label via `pane list` before sending anything.
- After `pane run <agent-cli>`, VERIFY the agent is actually alive before
  dispatching: agent CLIs can auto-update and exit on launch ("restart me"),
  dropping the pane back to a shell — text sent then goes to the shell
  prompt. Wait for agent-status idle AND confirm the agent is detected.
- Sending to codex TUI: `send-text` then Enter; a paste often needs a
  SECOND Enter when idle. If the agent is `working`, use Tab to queue
  instead — check `herdr agent list` status first, every time.
- VERIFY every dispatch landed: after sending, confirm status flips to
  `working` (or the token counter moves). Dispatches sent during TUI startup
  or right after a turn are silently dropped — re-send if the pane stays
  idle with unchanged counters.
- Idle ≠ done: agents die mid-turn on API errors (ECONNRESET) and sit idle
  with no output. Every brief must define an exact completion marker
  ("X COMPLETE <artifact>"); on idle, check for the marker first — if absent,
  read the pane tail for API errors and resume with "continue" (the session
  context survives; re-state any retargets in the resume message).
- Marker ≠ work: a compacted agent can print the completion marker WITHOUT
  doing the task (observed: "COMPLETE 99/100" over hour-old artifacts).
  Pair every marker with orchestrator-verifiable proof-of-work, and know the
  hierarchy: markers and mtimes are hints (agents can and did "normalize"
  mtimes to satisfy a check); CONTENT is the only unfakeable evidence —
  re-open the artifact and compare against the previous accepted round.
  Gate background monitors on the deliverable existing, not on pane idleness.
- EVERY multi-step order goes to a scratchpad file, not just Phase-1 briefs —
  the pane gets one line: "Read <file> and execute it." Files survive
  compaction; pasted instructions don't (a mid-task compaction dropped a
  pasted recapture order and produced the fake-marker incident above).
- Never chain publish steps (thread replies, PR comments, body edits) behind
  a gating command in one shell line. `git commit … | tail` reports the
  PIPE's exit code — a failed commit sailed through `&&` and posted a
  wrong-sha reply, twice. Use `set -o pipefail`, verify the commit/push
  landed as its own step, and never interpolate `git rev-parse HEAD` into a
  message before the commit is confirmed.
- A listening port is not your server: dev servers die and other agents'
  servers take over the port silently (an FE-xxx worktree's Storybook
  answered on the "user QA" port and poisoned two headless checks). Before
  any capture or QA against a local port, verify identity — the listening
  PID's cwd (lsof) or content (`index.json` contains your story IDs).
- If the user is manually QA-ing on a local dev server, name its port in
  EVERY dispatch with "do not kill port <N>" and give the verifier its own
  capture port — agents cleaning up "their" servers otherwise kill the
  user's session.
- One live feedback item = one dispatch; root-cause it yourself first
  (browser/QA/grep) and send the diagnosis + fix contract, not the raw
  complaint.
- **Batch edits, verify once.** The agent will NOT self-interrupt: its
  queued messages are only consumed when the current turn ends, so edits
  queued behind a checks-wait starve until the wait finishes. POLICING THIS
  IS THE ORCHESTRATOR'S JOB — whenever you queue an edit and the agent's
  current turn is a CI/review wait (read the pane to check), INTERRUPT the wait
  (`herdr pane send-keys <id> Esc` — the key name is `Esc`, not `Escape`)
  and fold the new work into a consolidated batch. Waiting out checks on a
  head you are about to replace is pure waste: group all pending edits,
  then do ONE close — one recapture, one signed commit + push, one
  checks-wait, one review sweep — after the LAST change. Prefer APPENDING a
  new commit over amend + force-push: plain pushes never invalidate a
  reviewer's or bot's in-flight review state, keep the fix history auditable
  against the review threads, and can't clobber the remote branch; squash at
  merge if the repo wants one commit. Amend only when the repo's convention
  explicitly demands a single-commit branch. Re-issue the
  standing constraints (commit hold if active, submodule ban, evidence
  rules) with the consolidated order, since the interrupted turn's context
  may be stale. Long-running agents COMPACT and forget standing orders —
  do not rely on a rule stated once; append the no-wait-while-edits-pending
  rule to every edit dispatch, and expect to re-interrupt regardless.
- **User-QA gate before push (when requested).** If the user wants to test
  before committing: instruct the agent to implement + validate but leave
  the working tree uncommitted with the local workbench hot-reloading, wait
  for the user's explicit go, and only then commit + push. New feedback during
  the QA window folds into the same held batch.
- Waiting: `herdr wait agent-status --status idle` fires on between-turn
  blips. Use a debounce loop — require idle to hold across two 180s checks —
  run in background, and handle the pane-gone case.
- GPG/smartcard signing: if an agent reports pinentry cancelled /
  unverified signatures, trigger `echo test | gpg --clearsign -u <key>` from
  the orchestrator to pop pinentry for the user, then tell the agent to
  re-commit (signed). Cache TTL is short — expect re-prompts on long runs,
  warm the cache immediately before every commit step, and VERIFY the warm
  itself succeeded (check its exit code and tell the user a prompt is
  waiting) — a silently-failed warm followed by a piped commit is how the
  wrong-sha-reply incident chained.

## Failure playbook (evidence)

- **Blank overlays** (tiny solid PNGs): white-background masking erased
  white-on-white content — regenerate without masking; inspect before
  scoring.
- **Doubled text / wrap differences / glyph offsets in overlays**: capture
  ran before webfonts loaded — await `document.fonts.ready`, record font
  diagnostics per capture, then re-judge; real spacing bugs may hide
  underneath.
- **Compensated drift**: outer dimensions match exactly, but overlays show
  uniform double-strike on inner text/edges. Cause: one wrong gap "fixed" by
  other wrong gaps/paddings that cancel by the footer (e.g. header gap 4px
  short + panel padding 4px over). "Antialiasing" is only an acceptable
  verdict for single-strike glyph deltas — any doubled line must be measured
  (Figma metadata y vs DOM y) and the whole gap chain re-derived from Figma,
  not re-balanced with new literals.
- **Mid-animation capture**: drift is worst at the component's outer edges
  (full-width rows doubled at both extremes, corners, borders) and near-zero
  at the center — the screenshot fired during an enter animation (scale/zoom
  transitions on dialogs/popovers). Await animation completion on the target
  subtree (`getAnimations({subtree:true})` all finished) AND
  `document.fonts.ready` before every capture — or gate a reduced-motion
  override on `navigator.webdriver` so only capture browsers skip animations.
- **Portal-hosted parity targets**: when packaging moves the component into a
  dialog/popover, the target renders in a PORTAL outside the story wrapper —
  capture the component element itself (its `data-slot`), not the wrapper.
  With `defaultOpen`, the primitive focuses the first tabbable element
  programmatically on load, which counts as `:focus-visible` — a focus ring
  appears in captures that real pointer users never see. Blur the active
  element before the screenshot; capture-only, never a code change.
- **Forced states leaking to users**: parity stories that force hover/focus
  must scope injected CSS to a per-story instance attribute AND gate on
  `navigator.webdriver` so only capture browsers see them.
- **Score with unexplained visible drift**: push back; every visible delta
  is either a real mismatch (fix code) or a capture artifact (fix pipeline)
  — "looks close" and "antialiasing" without inspection are not verdicts.
