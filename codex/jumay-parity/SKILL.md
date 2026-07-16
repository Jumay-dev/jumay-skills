---
name: jumay-parity
description: Run UI design parity tickets end to end from a Linear/GitHub issue link. Use when a user asks to complete a component parity issue, match Storybook to Figma with >97 visual accuracy, align implementation text/structure with Figma, use Visual Ralph or Playwright evidence, create or update the one task PR, wait for Greptile/Devin/agent feedback, reply to fixed PR comments, preserve approvals, sign amended commits, or provide Storybook preview and Figma comparison links.
---

# Jumay Parity

## Overview

Execute a component parity ticket from a clean branch through verified
Storybook/Figma evidence and PR review. Default to exactly one PR per task:
Storybook/reference/evidence changes and component/style parity fixes belong in
the same reviewable branch. Do not split a parity task into stacked PRs just
because Linear asks for that shape; use stacked PRs only when the user explicitly
asks for a stack in the current conversation. The normal target is: issue link
in, one prepared component PR out, visual accuracy above the requested
threshold, and review-agent comments addressed.

## Success Gate

Do not call the work complete until all applicable gates are true:

- The implemented Storybook state is compared against the exact Figma node from
  the issue or reviewer correction.
- Implementation and Storybook examples use the exact visible Figma text,
  ordering, item structure, state labels, variant axes, and component hierarchy
  unless the ticket explicitly asks for product-specific copy.
- Visual Ralph verdict is `pass` and score is greater than the requested
  threshold. If the user gives no threshold, require `>97`.
- Do not report `>97` visual accuracy until a visible-delta ledger has been
  written under `.omx/artifacts/visual-ralph/<issue>/`. The ledger must compare
  every visible subpart in the Figma node and Storybook render: component frame,
  content/images, backgrounds, borders, radii, shadows, icons/glyphs, text,
  spacing, clipping/viewport room, enabled/disabled states, and orientation
  controls. If any visible subpart is not inspected, cap the score at `90/100`
  and keep iterating.
- If a known visible mismatch remains, do not call the gate passing unless the
  mismatch is explicitly out of scope for the task and is listed in both the
  ledger and PR body with the reason it will not be fixed in this PR.
  Known-but-hidden mismatches, optimistic scoring, or "looks close" estimates
  are not valid.
- Light and dark mode parity are both checked whenever the component supports
  theme switching or the Figma source includes both themes. If only one theme is
  available in Figma, verify Storybook does not regress the other theme and
  state that limitation in the PR.
- Playwright headless verifies the changed stories, states, visible content, and
  dark-mode rendering.
- At least one human/vision inspection pass has opened the Figma screenshot and
  the Storybook After screenshot side by side after the final code change. DOM
  geometry, dimensions, and automated verdicts are supporting evidence, not a
  substitute for inspecting the pixels.
- PR body links the Linear issue, exact Figma node(s), Storybook preview(s),
  score, and evidence paths.
- PR body follows the established parity format used by prior
  parity PRs: `Linear issue`, `## Summary`, one three-column `## Visual
  evidence` screenshot table, `Visual gate: N/100`, a compact list of
  intentional deviations from the design (with the decision/reason for
  each), and `## Validation`. The body must read like something a human
  reviewer wants to read: `## Summary` is plain-English prose (what the
  component is, what it does, notable decisions), and `## Validation` is
  4-6 short bullets naming what was validated (typecheck, lint, test suite
  with count, build, interaction flows, visual gate) — never command
  dumps. Machine-generated process proof (token/CSS-variable audit tables,
  focus-ring evidence subsections, capture diagnostics, command output)
  belongs in the ledger artifacts under `.omx/artifacts/`, NOT in the PR
  body. The
  screenshot table must have exactly `Figma`, `Before`, and `After` columns:
  exact Figma component screenshot, Storybook before screenshot, and Storybook
  after screenshot. Every `Before` cell must include an uploaded rendered image;
  explanatory text alone is not valid evidence. If a before story/state did not
  exist, capture and upload the base Storybook missing-state/absence screenshot.
- PR body includes an additional uploaded Figma-vs-After overlap or visual diff
  image after `Visual gate: N/100` and before `## Validation` whenever a Figma
  after comparison exists. This is a reviewer aid only; it does not replace the
  required `Figma | Before | After` evidence table and must not create a second
  evidence table. The overlap must compare the same visual region at the same
  pixel dimensions: either capture both sources with matching component bounds,
  or crop Storybook/Figma to the matching content region before compositing. Do
  not overlay a full shell against an inner Figma content node without cropping;
  that is misleading. Prefer a simple tinted overlay with Figma in magenta,
  Storybook after in cyan, and overlap in purple; mask white/transparent
  backgrounds when needed so the whole canvas does not become a false overlap.
  Use a heatmap/diff if that is clearer for the component. State the exact crop
  or alignment in one short sentence, for example `same 290x215 content crop`.
  If no same-region comparison can be produced, label the image as approximate
  and do not use it as evidence for increasing the visual score.
- For matrices, multi-row examples, or state collections, prefer
  per-component same-size overlays over one whole-matrix overlay. Each overlaid
  item should use the matching Storybook component crop size; scale the Figma
  component once into that item crop, and never stretch a full matrix/shell to
  force alignment. Whole-matrix overlays are acceptable only when the Figma and
  Storybook row/column positions and whitespace are intentionally identical.
- Generated overlaps are part of the visual parity loop, not a substitute for
  judgment. Inspect the overlap PNG before final scoring and classify every
  visible drift as either `real component mismatch` or `crop/alignment
  artifact`. Fix real mismatches in code/story; fix crop artifacts in the
  overlap evidence. Do not lower or raise the visual score based on an
  unverified overlay artifact.
- PR-only comparison screenshots are uploaded as GitHub PR description/body
  attachments and rendered inside the `## Visual evidence` table. Do not leave
  screenshot evidence as standalone PR comments; comments are only for replying
  to review threads or explicitly requested follow-up discussion.
  Links to Figma nodes, Storybook previews, local paths, or deployed iframes are
  not a substitute for rendered screenshot evidence in the visual table. Each
  table cell must contain uploaded markdown image syntax or an `<img>` tag whose
  URL starts with `https://github.com/user-attachments/assets/...`. The PR body
  must not contain `Upload blocked`, `Screenshot upload blocker`, or local-only
  screenshot prose as replacement evidence. If screenshot upload is genuinely
  blocked after all required fallbacks, stop before review handoff and report
  the blocker locally; do not mark the PR ready for review or share it in Slack
  unless the user explicitly overrides the evidence gate.
- PR screenshot evidence is component-scoped. Capture the exact Figma component
  node and the matching Storybook component/story element only; do not use whole
  Figma document/page screenshots or full-browser screenshots when a component
  element screenshot is possible. Include dark-mode component screenshots when
  Figma or the design system exposes dark-mode variants.
- A local evidence manifest exists under `.omx/artifacts/visual-ralph/<issue>/`
  before any PR is opened. It maps every visual evidence table row to:
  `figma_path`, `before_path`, `after_path`, `figma_url`, `before_url`,
  `after_url`, `story_preview_url`, and `notes`. Do not write the PR body from
  memory or prose; generate it from this manifest or manually verify it against
  this manifest.
- PR body self-audit has been run after the final body edit. The audit must
  confirm: exactly one `Figma | Before | After` table, each table row has
  uploaded `github.com/user-attachments/assets/...` images in all three columns,
  `Visual gate: N/100` is present, no screenshot evidence remains only in
  top-level comments, and no screenshot table cell is text-only. Use
  `scripts/validate-pr-body.js <pr-number> OWNER/REPO` from this
  skill directory for the audit.
- The live PR body self-audit passes before the PR is marked ready for review,
  before any FE code-review Slack handoff, and before the final response claims
  the PR is review-ready. Use `$jumay-review-message` for the FE code-review
  Slack handoff format.
- Greptile, Devin, or human review comments that were fixed have direct thread
  replies naming the latest fixing commit, then the GitHub review thread is
  resolved when the platform exposes a resolvable thread. Do this even if a
  newer agent summary comment is already clean; the original actionable thread
  still needs the reply/resolution trail.
- The unresolved review-thread count is machine-verified at the final head:
  query the GraphQL `reviewThreads` API and require zero threads with
  `isResolved: false`, or list each remaining unresolved thread in the final
  report with its non-actionable rationale. `isOutdated: true` does not mean
  resolved — unresolved-but-outdated threads still require the
  reply-and-resolve trail. Run this verification only after the final push's
  checks and review-agent runs have completed, because review bots can open
  new threads on the final head.
- Top-level comments, latest reviews, and thread-aware review comments for
  every opened parity PR have been re-read after fixes; every actionable
  Greptile, Devin, GitHub review, and human item is fixed or explicitly
  documented as non-actionable.
- The final pushed commit is signed when the repo/user requires signing.
- Existing PR approvals are preserved when possible by amending the final commit
  instead of adding avoidable follow-up commits after approval.
- Every new parity ticket starts through `$jumay-worktree` in its own
  new git worktree. Use refreshed `origin/master` by default, or the explicit
  parent feature branch only when the user explicitly requested a stacked PR
  workflow. Do not reuse a previous ticket worktree or dirty checkout for a new
  ticket.
- After opening the task PR, wait for GitHub checks and review agents such as
  Greptile and Devin to report. Fix or explicitly reply to every actionable
  comment before final handoff. If the user explicitly requested stacked PRs,
  do this for every PR in the stack.
- After every pushed commit, amended commit, force-push, rebase, merge, or PR
  body/doc update, wait for Greptile/Devin review checks to complete again on
  the live PR head SHA before continuing or reporting completion. Do not treat
  an older review-agent comment as current unless its "last reviewed commit" (or
  equivalent metadata) matches the live head SHA. If the latest agent feedback
  is stale, wait with a blocking watch or sleep at least 60 seconds between
  rechecks; do not re-read the full PR in a tight loop. If it stays stale,
  explicitly state that the review is still pending.

## Figma-Accurate Parity Gates

A high Visual Ralph score means "the rendered pixels look close," which is not
the same as "the component matches the design system." Image similarity cannot
resolve exact token values at matrix scale (8px vs 12px radius, 1px vs 0.5px
border, 16px vs 24px gaps), cannot see variant axes the story did not render,
and cannot exercise behavior. These gates close those blind spots. They are
additive: the visual/RMSE gate above still applies, and the work is complete
only when the pixel gate and every gate below agree.

- **Token-value audit (numeric, not pixel).** For every visible property, read
  the exact Figma variable — `spacing`, `radius`, `border-width`, `shadow`,
  `opacity`, fill/step, and type scale — from the node (via the Figma API/dev
  mode, not by eye) and diff it against the value the code actually resolves to.
  Assert the numbers match; do not accept a Tailwind token that is merely close
  (`rounded-xl` 8px when Figma is `rounded-2xl` 12px, `border-b` 1px when the
  node uses the 0.5px `border-width/border` token, a `-50` palette step when
  Figma layers the status color at 5% over white, a hardcoded `--shadow-md`
  when the node references a different shadow variable). Record each
  property → figma-value → code-value → match in the ledger. Any mismatch caps
  the score and keeps iterating, even when the screenshot passes.
- **Variant-matrix coverage.** Enumerate the Figma component's full variant
  axes and states (every `Variant`, `Size`, `State`, `Style` value in the node),
  not only the ones the ticket's preview happens to show. For each cell, verify
  it is both implemented and expressible through the component API. A component
  that cannot represent a documented Figma variant (e.g. a media slot hardcoded
  to one type, a number badge that cannot express its four axes) is a parity
  miss even if the rendered example looks right. List the matrix in the ledger
  with each cell marked covered or gap.
- **Behavior and API parity (pixels cannot see this).** Verify component API
  correctness, not just appearance: props/`style`/`ref`/`render` are merged and
  forwarded (use the codebase's established `useRender` + `mergeProps` pattern,
  never `cloneElement` that overwrites consumer props); interactive elements
  render the correct element and role (a link renders an `<a>` with `href` and
  is focusable, not a styled `<div>`); SSR/first paint is correct (watch for
  `delay=0`-style flags that hide content until an effect runs); slot overrides
  and disabled/loading states actually work; icons that must take a variable
  color are not frozen (e.g. an `<img>`-loaded SVG cannot inherit `currentColor`).
  Add story coverage for any new prop (such as `render`) so the behavior is
  demonstrated and testable.
- **Dark mode and full acceptance-criteria coverage are hard gates.** Capture
  and verify both light and dark whenever the component or Figma source exposes
  a theme; a value hardcoded to a light token (e.g. a literal light `--card`
  color that `twMerge` lets win over `bg-card`) is a failure, not a nit. Cover
  **every** Figma node listed in the ticket — if the issue names two targets,
  implement both; a story or MDX note that silently narrows scope to one node
  is a miss. Do not let partial coverage pass by scoring only the story that
  was built.
- **Evidence integrity.** Comparison images must be same-region and same-scale.
  Reject a side-by-side whose two panels are rendered at different pixel
  dimensions (it makes a mismatch invisible and overstates the score); crop or
  scale both sources to the identical region before compositing, and state the
  crop dimensions. The score is only trustworthy when it is measured against an
  aligned baseline.
- **Adversarial pre-submit review.** Before opening or marking the PR ready,
  run one independent Figma-node-level review pass whose sole job is to find
  deviations — spawn a subagent (or a fresh reasoning pass) that re-derives the
  expected token values, variant matrix, and behavior from the Figma node and
  the ticket, then tries to falsify the implementation the way a strict human
  reviewer would. Treat what it finds as pre-PR work, not post-review cleanup.
  This is the independent oracle the self-verifying capture loop otherwise
  lacks; use it to convert would-be review comments into self-corrections.

## Review-Response and Evidence Discipline

Most rework happens after review, not before. These rules govern how to respond
to reviewer comments and keep evidence trustworthy. Follow them for every
Greptile/Devin/human review round.

- **Verify the reviewer's premise before changing anything.** A comment can be
  wrong, and applying its suggestion blindly can regress a value that was
  already correct (e.g. reverting an exact `bg-card` that already equalled the
  Figma fill, or "fixing" a proportional value into a wrong one). Before editing
  what a reviewer flags, re-derive the correct value from the Figma node. If the
  code already matches, reply with the measured evidence and do not change it.
  Reviewers sometimes retract their own numbers — confirm against the node, not
  the prose.
- **Regenerate and re-upload evidence from the final HEAD.** Any overlay,
  screenshot, or comparison in the PR body must be captured from the current
  head commit. After every code change — including a later commit that touches
  the stories or component — regenerate the evidence and replace it in the body;
  a stale overlay from an earlier commit is an invalid evidence. Before handoff,
  confirm the evidence's capture commit equals HEAD. This is a hard gate: a
  present-but-stale overlay fails it just as a missing one does.
- **Measure residuals; never hand-wave "sub-pixel."** Before declaring a visible
  delta acceptable browser-vs-Figma rasterization, measure it in pixels. A
  residual above ~1-2px is a real gap to fix, not to excuse. State the measured
  number in the ledger and PR. "Looks close" and "probably rendering" are not
  valid dismissals.
- **Text and number width parity; keep raster-fitting out of the primitive.**
  Verify rendered text/number width against the Figma raster, not just the font
  tokens (family/size/weight); right-aligned cells expose width drift. Any
  compensation applied purely to make an overlay align (letter-spacing/tracking
  tuned to a raster) belongs in the parity STORY, never in the shipped
  component — the shipped component must match the Figma spec, not a screenshot.
- **Synthesize conflicting review feedback; do not flip-flop.** When two
  reviewers (or a reviewer and a bot) pull in opposite directions — e.g. one
  says a base primitive's hover is too broad, another says removing it breaks
  real consumers — implement the design that satisfies both concerns (here, an
  explicit interactive variant that owns the hover while the base stays inert)
  rather than reverting to whichever side commented last, which just re-triggers
  the other. Reply on both threads explaining how each concern is met.
- **Do not self-resolve a thread you reinterpreted; keep story-only state out of
  production.** If you only partially address or reinterpret a reviewer's ask,
  reply with your reasoning and leave the thread for the reviewer to resolve;
  self-resolve only when you complied literally or proved the premise wrong.
  Forced-state and tooling selectors that exist to drive Storybook (e.g.
  `data-[state=...]` overrides) must live in the stories/tooling, never in the
  shipped component's always-on class string, where they can permanently style
  any product element carrying that attribute.
- **After a merge, fix review feedback forward.** If the PR is already merged
  when review feedback arrives, do not force-push the merged branch; open a
  follow-up PR from a fresh branch with the fixes. Barrel/index export conflicts
  from parallel parity PRs resolve as a union — keep every side's exports.

## Efficiency Rules

Waiting is free; polling is not. Every repeated status read re-loads large
JSON and screenshot payloads into context. In measured runs, polling and
re-reading dominated token spend (11-19M input tokens per ticket at a ~0.3%
output ratio), so:

- Prefer one blocking command over repeated status reads: use
  `gh pr checks <pr> --watch` for CI. For review agents that expose no
  watchable check, sleep at least 60 seconds between rechecks and fetch only
  the fields needed (`gh pr view <pr> --json headRefOid,statusCheckRollup`),
  not the whole PR.
- Export each referenced Figma node to PNG once per ticket, store it in the
  evidence directory, and reuse that file for every later comparison and
  overlay. Re-fetch from Figma only when the node reference changes or a
  reviewer corrects the node.
- Capture component-scoped element screenshots from the first iteration; never
  capture full pages intending to crop later.
- On each visual iteration, re-capture and re-inspect only the stories/states
  that changed since the previous iteration, not the full evidence set.

## Workflow

1. Create a clean git worktree through `$jumay-worktree`.
   - Create a new worktree for every new ticket, even when another parity
     worktree already exists.
   - Fetch latest refs and refresh `master` from `origin/master` before
     branching unless the user explicitly asks to base this work on a feature
     branch.
   - Use the Linear issue branch name when present.
   - Use one branch and one PR for the whole task by default. Create child
     branches only when the user explicitly asks for stacked PRs.
   - Do not reuse a dirty checkout or revert unrelated user work.

2. Read the source of truth.
   - Fetch the Linear issue and comments.
   - Extract Figma file/node links, acceptance criteria, theme coverage
     (light/dark), and review expectations. Record any requested stacked PR
     order as ticket context only; do not follow it unless the user explicitly
     asks for stacked PRs in the current conversation.
   - If a reviewer/user corrects the Figma node, treat the newest correction as
     authoritative and update PR evidence accordingly.
   - Read repo-local parity docs such as `apps/frontend/docs/FIGMA_PARITY.md`
     and the component's existing stories/MDX/assets.

3. Use the required visual workflow.
   - Load `$visual-ralph` when visual parity is requested.
   - Use the Figma skill or CLI/MCP to capture metadata, design context,
     screenshots, and token data for every referenced node.
   - Prefer component-node screenshots (`contentsOnly`/node-specific capture)
     over page/overview screenshots. If a Figma link points to a page or broad
     overview, drill down to the exact component node before producing PR
     evidence.
   - Export each referenced Figma node once per ticket and reuse the stored
     PNG across all later iterations, overlays, and PR evidence; do not
     re-fetch the same node from Figma inside the fix-and-recheck loop.
   - Capture dark-mode Figma component nodes when present. If the Figma file has
     no explicit dark-mode node, document the absence and use the component's
     design tokens plus Storybook dark-mode screenshots as the dark-mode check.
   - Store evidence under `.omx/artifacts/visual-ralph/<issue>/`.
   - Name PR-table evidence files predictably, for example
     `<issue>-<pr-scope>-<theme>-figma.png`,
     `<issue>-<pr-scope>-<theme>-before.png`, and
     `<issue>-<pr-scope>-<theme>-after.png`, so each uploaded attachment can be
     traced back to the local evidence artifact.
   - Capture `Before` screenshots before editing whenever possible. If work has
     already started, create a temporary clean base worktree from the target base
     branch and capture the before state there. For the default single-PR
     workflow, `Before` screenshots come from the original base branch. If the
     user explicitly requested stacked PRs, the child PR's `Before` screenshots
     are normally the rendered output of its parent PR.
   - If a before story, variant, or state is missing, capture the base Storybook
     missing-story/missing-state screen or the nearest pre-change state and label
     that row explicitly. Do not replace the missing before screenshot with text.
   - Write `.omx/artifacts/visual-ralph/<issue>/evidence-manifest.json` before
     opening PRs. Minimum schema:

     ```json
     {
       "issue": "TICKET-000",
       "visual_gate": 98,
       "score_basis": "all visible subparts inspected; no known visible mismatch remains",
       "rows": [
         {
           "label": "Basic",
           "figma_node": "239:1300",
           "figma_path": ".../basic-figma.png",
           "before_path": ".../basic-before.png",
           "after_path": ".../basic-after.png",
           "figma_url": null,
           "before_url": null,
           "after_url": null,
           "story_preview_url": "https://...",
           "visible_delta_ledger_path": ".../basic-ledger.md"
         }
       ]
     }
     ```

   - Write a visible-delta ledger before assigning the visual score. Use one
     ledger row per visible subpart. Minimum columns:

     ```markdown
     | Area | Figma | Storybook after | Status | Evidence |
     | --- | --- | --- | --- | --- |
     | Arrow glyph | shaft arrow | shaft arrow | match | screenshot + DOM SVG path |
     | Slide content | rounded image only | rounded image only | match | screenshot + computed bg transparent |
     ```

   - Mandatory ledger areas for every component: outer dimensions, component
     background, content background, border, corner radius, shadow, typography,
     icon/glyph family, icon size, spacing/gaps, alignment, clipping/overflow,
     default state, disabled state, hover/focus/pressed state when Figma
     provides it, and any orientation/variant-specific layout.
   - Score caps:
     - `100`: exact visible match; all states inspected; no caveats.
     - `98-99`: tiny pixel-level rendering differences only; all states
       inspected; no structural or semantic visual mismatch.
     - `95-97`: close but at least one visible caveat remains; do not satisfy a
       `>97` gate.
     - `<=90`: any required visible area is uninspected, screenshots are stale,
       or a known mismatch is not fixed/deferred in the paired PR.

4. Preserve one-PR task scope.
   - Default: one task PR contains all required Storybook docs/stories, example
     text, states, matrices, Storybook/Figma reference assets, shared component
     code, tokens, spacing, typography, colors, borders, radii, shadows, and
     visual state fixes needed to pass the parity gate.
   - If Linear requests stacked Storybook-only and style-only PRs but the user
     has not explicitly requested a stack in the current conversation, override
     the ticket shape and use one PR.
   - Use stacked PRs only when the user explicitly asks for stacked PRs. In that
     case, preserve the requested split and keep each PR independently
     reviewable.

5. Implement against Figma.
   - Use exact Figma text, state names, variant axes, dimensions, and ordering.
   - Align visible implementation/story text and structure with Figma. For
     primitives and design-system examples, do not substitute product/browser
     demo copy such as app menu labels when Figma provides generic component
     copy.
   - Match the actual rendered content inside the component, not only the
     wrapper size. Check whether Figma shows an image, plain surface, card,
     placeholder, icon, or text; do not introduce Card backgrounds, demo
     surfaces, gray fills, or extra wrappers unless they are visible in Figma.
   - Match icon/glyph semantics, not just icon box size. A chevron, arrow with
     shaft, caret, plus, or custom path are different visible assets. Use the
     closest existing design-system icon; if none exists, document the gap and
     do not score above `97`.
   - Check first/last/advanced interaction states in Storybook. For carousels,
     tabs, steppers, pagers, accordions, and similar components, interact with
     the story so disabled/enabled controls are verified after state changes;
     do not validate only the initial disabled state.
   - Ensure Storybook capture wrappers leave room for off-content controls when
     the primitive positions controls outside the content box. A screenshot that
     clips an arrow or hides an off-canvas control is failing evidence, even if
     the component itself works.
   - Validate repeated rows, shortcut text, title labels, sub-trigger labels,
     checkbox/radio indicators, separators, disabled/hover/default states, and
     submenu structure against the Figma node before committing.
   - Keep Base UI primitives; do not introduce Radix unless the repo already
     uses it for that component.
   - Prefer story composition changes over primitive changes when the visual
     change is specific to a Storybook matrix or example.
   - Add stable `data-parity` hooks for Playwright element screenshots.

6. Verify with Playwright.
   - Start Storybook locally.
   - Capture iframe element screenshots, not full pages, at the relevant
     viewport/theme/state — starting from the first iteration, not only the
     final evidence pass.
   - Capture and inspect dark-mode Storybook screenshots for every changed
     component state that can render in dark mode. Use the project's existing
     theme toggle, decorator, `globals`, CSS class, or URL parameter rather than
     inventing a new theme mechanism.
   - Add a rendered text assertion for every changed story: required Figma text
     is present and old placeholder/demo text is absent.
   - Add a rendered visual-structure assertion for every non-text content area
     that affected the score. Examples: images have transparent backgrounds and
     expected radius; cards are absent when Figma has image-only content; arrow
     SVG paths/glyph exports match the Figma glyph family; controls are visible
     within the component-scoped screenshot; enabled controls become enabled
     after interaction when applicable.
   - Save the Playwright geometry/state JSON and then inspect the resulting PNGs
     with `view_image` or an equivalent image viewer before recording the final
     score. If the screenshot reveals a mismatch that metrics missed, fix it
     before uploading PR evidence.
   - Compare against fresh Figma PNGs and record a Visual Ralph verdict with
     `score`, `verdict`, `category_match`, `differences`, `suggestions`, and
     `reasoning`. The verdict must mention both light-mode and dark-mode
     outcomes, or explicitly state why one mode could not be compared against a
     Figma target.
   - Generate the Figma-vs-After overlap or visual diff before final scoring
     whenever a same-region comparison is possible. For matrices/state
     collections, build per-component same-size overlays first; use whole-region
     overlays only when shell geometry intentionally matches. Inspect the
     overlap and record whether each apparent drift is a real component
     mismatch or a crop/alignment artifact before changing code.
   - Use the user's requested score as the passing threshold; if absent, require
     `>97`.
   - If the score is at or below the threshold, inspect the screenshot and
     overlap evidence. If the drift is real, make the smallest scoped
     correction, rebuild Storybook, recapture screenshots, regenerate the
     overlap, and repeat. If the drift is a crop/alignment artifact, regenerate
     the overlap without changing code and reassess.

7. Run repo checks.
   - At minimum run formatting, lint/check, typecheck, and Storybook build when
     the frontend package supports them.
   - Report pre-existing warnings separately from failures.

8. Open the PR.
   - Push the worktree branch.
   - Preflight screenshot upload tooling before composing PR bodies:
     - Check for a primary uploader: `test -x ./vro-upload` or
       `command -v vro-upload`.
     - Check for the fallback uploader: `gh extension list | grep -q '^gh image'`.
       If it is missing, install it with `gh extension install drogers0/gh-image`
       and then run `gh image --version`.
     - Verify fallback authentication before upload:
       `gh image extract-token >/tmp/gh-image-token` and
       `GH_SESSION_TOKEN="$(cat /tmp/gh-image-token)" gh image check-token`.
       Delete `/tmp/gh-image-token` after the check. Do not print the
       extracted token.
   - Before writing or updating the PR body, upload every screenshot used by the
     `## Visual evidence` table:
     - First try `./vro-upload <png-path> OWNER/REPO` for each Figma,
       Before, and After image when the helper exists.
     - `./vro-upload` authenticates through GitHub browser cookies, not `gh` API
       tokens. It reads the newest Zen/Firefox `cookies.sqlite`, copies it to
       `/tmp`, and looks up `user_session`,
       `__Host-user_session_same_site`, and `dotcom_user` in the work/SSO
       container `^userContextId=2`, falling back to the default container.
       If the browser cookie DB is unavailable, set `VRO_GITHUB_COOKIE` to the
       full GitHub cookie string before retrying.
     - The helper must scrape `data-upload-repository-id` and the upload-policy
       CSRF token from an authenticated GitHub PR/issue page, POST
       `/upload/policies/assets`, POST the file to the returned S3
       `upload_url`, then PUT the returned `asset_upload_url` to finalize. Use
       the final `asset.href` URL in the PR body.
     - Capture the returned GitHub attachment URL for each upload.
     - Update `evidence-manifest.json` with the returned `figma_url`,
       `before_url`, and `after_url` values. Every PR-table row must have all
       three uploaded URL fields populated before editing the PR body.
     - If `vro-upload` is unavailable or fails, use an equivalent GitHub
       attachment upload flow before declaring upload blocked. Preferred
       fallback on this machine is:
       `gh image --repo OWNER/REPO <png-path>...`.
       It prints markdown images backed by
       `https://github.com/user-attachments/assets/...` URLs. If the helper
       cannot extract a browser session automatically, try
       `gh image extract-token`, `gh image check-token`, or set
       `GH_SESSION_TOKEN` before retrying. Do not create a repository branch or
       commit screenshots just to host review evidence unless the user
       explicitly approves that fallback.
     - A `gh image` upload that fails with `step 0 (get upload token): repo
       page returned 404` is almost never a tooling bug: `gh image
       extract-token` returns the *default* browser session, and that account
       may lack access to `OWNER/REPO`. Confirm with
       `gh image check-token` — if the printed username is not repo-authorized,
       the authorized account is signed in under a different browser profile.
       Do not declare upload blocked on this 404. Instead obtain a token from
       the authorized profile with `scripts/gh-image-token.sh`, which sweeps
       the local Chrome profiles and prints the first live github.com session
       `gh image check-token` accepts:
       `TOKEN=$(scripts/gh-image-token.sh) && GH_SESSION_TOKEN="$TOKEN" gh image --repo OWNER/REPO <png-path>...`.
       Only after the helper also fails to find any repo-authorized session is
       the upload genuinely blocked on a credential the user must supply.
     - Treat a missing primary uploader as a normal fallback case, not as a
       blocker. Do not declare screenshot upload blocked until `gh image`
       installation, token extraction/check, and upload have all failed.
     - Do not use Figma/Storybook/deploy URLs, local paths, or blocker prose
       inside screenshot table cells. If all upload methods fail, stop and ask
       for a credential/tooling fix or explicit override before PR handoff.
   - Use the established PR description shape:
     - `Linear issue: <direct Linear URL>`
     - `## Summary` with concise bullets and implementation constraints such as
       Base UI/no Radix.
     - `## Visual evidence`.
       - Exactly one markdown table with three columns: `Figma`, `Before`, and
         `After`. `Figma` is the localized exact component-node screenshot plus
         direct Figma node link. `Before` is the localized Storybook component
         screenshot from the pre-change/base preview. `After` is the localized
         Storybook component screenshot from the PR preview. Include light and
         dark rows in this table when both themes apply.
       - `Before` cells must render uploaded screenshots, not just text. When
         the before state is absence, capture the base Storybook missing-story,
         missing-state, or nearest pre-change visual state and label it clearly.
       - The table cells must render uploaded GitHub attachment images, with
         Figma and Storybook/deploy links placed adjacent to the image or in the
         surrounding text for navigation. Do not use link-only cells as visual
         evidence.
       - Screenshot evidence must live in the PR description/body before final
         handoff. Do not satisfy evidence requirements with separate top-level
         PR comments.
     - `Visual gate: <score>/100`.
     - `Additional overlap for review:` with an uploaded Figma-vs-After overlay
       or visual diff image. Keep it outside the `## Visual evidence` table so
       the required table remains exactly `Figma | Before | After`. Use GitHub
       attachment URLs, not local paths. The overlay should be same-crop and
       same-size; include the dimensions or crop basis in the caption. For
       matrices or state collections, prefer a per-component same-size overlay
       board and say that each item uses the matching Storybook component crop
       size. Do not use an overlap that visually looks double-scaled, clipped,
       or misleading; regenerate it or fall back to a labeled visual diff.
       Recommended caption:
       `same <WxH> <region> crop; magenta is Figma, cyan is Storybook after, and purple is overlap.`
     - `## Validation` with commands run and any existing warnings.
   - Include Linear issue, exact Figma node links, Storybook story/preview
     links, Visual Ralph score, light/dark screenshot or diff evidence, and
     commands run.
   - Run the PR body self-audit after `gh pr create` or `gh pr edit` and again
     after any later body edit:
     - Preferred command: `scripts/validate-pr-body.js <pr-number> OWNER/REPO`
       from this skill's directory.
     - Fetch the body with `gh pr view <pr> --json body,comments`.
     - Confirm the body contains `| Figma | Before | After |`.
     - Confirm every evidence row has `<img` or markdown image syntax in all
       three cells and every image URL starts with
       `https://github.com/user-attachments/assets/`.
     - Confirm no top-level screenshot-only comments remain. If screenshots were
       accidentally posted as comments, move them into the PR body and delete
       those comments before final handoff.
     - If the audit fails, fix the PR body and rerun the audit. Do not mark the
       PR ready for review, do not post/share to Slack, and do not claim
       review-readiness while the audit is failing.
   - Wait for GitHub checks with a blocking watch (`gh pr checks <pr> --watch`),
     then read Greptile/Devin comments once; address their feedback before
     final handoff.
   - After each pushed commit or PR-body/doc update, verify the review-agent
     result is fresh for the live head SHA:
     - Read `gh pr view <pr> --json headRefOid,statusCheckRollup,comments`.
     - Confirm the Greptile/Devin check is `COMPLETED` and successful.
     - Confirm the latest review-agent comment's reviewed commit SHA matches
       `headRefOid`. If it still references an older commit, sleep at least 60
       seconds and recheck only those JSON fields; do not claim the score or
       feedback is final.
     - If the fresh agent review reports actionable findings, fix them, push,
       and repeat this wait loop.

9. Close the review loop.
   - Run the final thread sweep only after the last push's CI and review-agent
     checks have completed on the live head; review bots open new threads
     late, and a sweep done before their final run misses them.
   - Machine-verify closure instead of judging thread state from summaries or
     `isOutdated` flags. Zero unresolved threads is the gate:

     ```sh
     gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){
       repository(owner:$o,name:$r){pullRequest(number:$n){
         reviewThreads(first:100){nodes{isResolved}}}}}' \
       -f o=OWNER -f r=REPO -F n=<pr> \
       --jq '[.data.repository.pullRequest.reviewThreads.nodes[]
              | select(.isResolved==false)] | length'
     ```

     Any nonzero count means unfinished work: fix and resolve each thread, or
     document why it is non-actionable in the final report.
   - Use thread-aware GitHub review reads for inline comments; flat PR comments
     are not enough.
   - If an app exposes only a summary review comment, open the linked review or
     use GitHub review thread APIs to fetch the concrete issue text before
     deciding it is non-actionable.
   - For every actionable Greptile, Devin, or human review comment fixed by the
     current work, reply directly on that review thread with the latest fixing
     commit SHA and concise evidence, then resolve the review thread when
     GitHub exposes it as resolvable.
   - If the agent left only a top-level PR comment and no resolvable review
     thread exists, leave a normal PR comment that links or names the original
     agent comment, names the latest fixing commit SHA, and states why no
     thread could be resolved.
   - Do not reply to bot deployment comments or non-actionable comments.
   - Re-read top-level comments, latest reviews, and review threads for the
     task PR after replying. If the user explicitly requested stacked PRs, do
     this for every PR in the stack. Do not finalize until each actionable
     Greptile, Devin, GitHub review, and human item is resolved, outdated by a
     newer commit, or explicitly documented as non-actionable with rationale.

10. Preserve approvals and signing.
   - After approvals, prefer `git commit --amend --no-edit` for final metadata,
     evidence-link, or signing fixes instead of creating a new commit.
   - Push amended commits with `--force-with-lease`.
   - If OpenPGP signing fails due to pinentry, refresh the GPG agent TTY and
     retry before falling back to SSH signing. Verify GitHub reports
     `verified: true` for the pushed head.

## Slack Handoff

When the user asks to share a completed parity task in the FE code review
channel, use the established concise parity handoff instead of rediscovering the
format from Slack history. Only re-check Slack history when the user explicitly
asks to check history or update the usual message.

Parity Slack handoffs are confirmation-gated by default: prepare the exact
Slack-ready message, show it to the user, and send only after the user confirms
that exact message. If the user asks for wording only, draft the text locally
and do not send it.

Default channel: your team's FE review channel (configure once, stored in your
local context, not in this repo).

Default reviewer mentions for parity PRs (replace with your team's Slack user
IDs):

```text
<@REVIEWER_1_ID> <@REVIEWER_2_ID>
```

Use this message shape:

```text
<reviewer mentions>
master <- <PR>
<Linear issue link>

Parity is at <score>/100 via Playwright headless + Figma screenshots, checks are green. Pls take a look
```

Default to the single-PR form `master <- <PR>`. For explicitly requested stacked
PRs only, preserve stack order from base to tip, for example
`master <- <PR 1> <- <PR 2>`, and say `all PRs are green`. Use Slack link syntax
(`<url|label>`) for PRs and Linear issues when sending through Slack tools. Add
one short `Note:` paragraph only when the user explicitly asks to include extra
context. Do not mention local tooling friction, screenshot upload failures,
draft status, signing issues, or local artifact paths in a sent Slack handoff
unless those remain real review blockers and the user explicitly approves
sharing them.

## Output

Final response must include:

- PR link. Default expectation is exactly one PR for the task; if there are
  multiple PRs, state the explicit user request that required stacking.
- Direct Storybook preview link(s) for the changed component/story, preferably
  deployed branch iframe URLs.
- Direct Figma node link(s) used for comparison.
- Visual score in `N/100` form and evidence path.
- Visible-delta ledger path, plus explicit statement that all required visible
  areas were inspected. If any score cap or deferred mismatch applies, state it
  instead of reporting a passing score.
- Dark-mode parity status and evidence path, or the documented reason dark mode
  could not be compared against Figma.
- Review-loop status: PRs checked, actionable comments fixed/replied, and any
  unresolved or non-actionable comments with rationale.
- Live PR-body screenshot audit result from
  `scripts/validate-pr-body.js <pr-number> OWNER/REPO`.
- Checks run and any remaining risk.
