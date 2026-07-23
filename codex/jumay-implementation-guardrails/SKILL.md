---
name: jumay-implementation-guardrails
description: Webapp implementation quality guardrails. Use by default before and during non-trivial webapp code changes, PR review fixes, Tokens API work, React Query hook changes, SDK data mapping, helper API design, and final self-review to avoid over-engineering, wrong query boundaries, broad optional types, duplicated SDK logic, and line-local review fixes.
---

# Jumay Implementation Guardrails

## When To Use

Use this for non-trivial webapp implementation work, including direct coding tasks, review-comment fixes, stacked PRs, and `jumay-oneshot` tickets. Load it before editing, then revisit it during self-review.

## Implementation Rules

1. Preserve the existing data-flow shape unless the task truly requires changing it.
   - If a hook was one query before, keep one query unless there is a real independent async resource.
   - Treat large structural rewrites as suspect when the ticket is an integration or migration.

2. Do not use React Query for synchronous derived data.
   - A query must own a network call, cacheable async SDK call, or independently refetchable resource.
   - Prefer plain derivation, existing mapper placement, or `select` for synchronous mapping.

3. Query keys describe fetch inputs, not fetched output.
   - Do not put API response payloads, `dataUpdatedAt`, timestamps, or display fields in query keys.
   - If a content-derived key seems necessary, re-check whether the query boundary is wrong.

4. Avoid custom merged query result objects.
   - Combining `status`, `isPending`, `isSuccess`, `error`, and `refetch` from multiple queries is a design smell.
   - Prefer returning the original query result directly.

5. Load canonical token metadata once at the highest useful boundary.
   - If all relevant mints are market reserve mints, load market reserve mints rather than reconstructing mints from API payloads.
   - Before adding a new token-mint collector, check whether a page/query-level mint list already covers the surface.

6. Keep helper API types narrow and honest.
   - Use `string[]` or `Array<string | undefined>` for generic token mint helpers when callers ultimately need strings.
   - Do not accept `Address | string | null | undefined` just to make callers easier.
   - Convert SDK `Address` values to strings at the caller boundary.

7. Keep token mint collection proportional to the call site.
   - For a single optional mint, prefer `mint ? [mint.toString()] : []` at the `useTokens` call site.
   - Use mint compaction/dedup helpers for aggregate lists from multiple sources, such as vault token plus shares, rewards, tables, or page-level metadata.
   - Do not move domain-specific mint normalization into generic hooks like `useTokens`; keep generic hook inputs narrow and normalize at the owning boundary.

8. Put optional handling at the caller that owns loading state.
   - Prefer `market ? getMarketReserveMints(market) : []`.
   - Do not make helper params optional when the helper logically requires the object.

9. Prefer existing SDK/object data over fallback chains.
   - If `deposit.mintAddress` is available, use it directly.
   - Do not resolve through a reserve and then fallback unless the reason is documented and tested.

10. Fix review comments at the design level, not only the line level.
   - For a comment like “why is this key huge?”, ask “why does this key exist?” before shortening it.
   - Inspect neighboring comments and the surrounding diff before patching.

11. Keep the diff tied to the ticket.
   - If a change looks unrelated to the feature, either remove it or document why it is required.
   - Prefer deletion and restoration of existing shape over adding compatibility layers.

12. Reuse a kit/design-system component's own size/variant PROPS; do not layer className geometry that fights them.
   - Prefer `<Switch size="sm">` over `<Switch className="w-7 ...translate-x-3">`. A className width/translate/radius override stacked on a variant/size class can silently win or lose a CSS-specificity fight, leaving inconsistent geometry (e.g. a switch thumb that overshoots its track only when ON).
   - If you genuinely must override geometry, verify the computed CSS in BOTH the resting and the active state — not just the state the Figma frame bakes.
   - When reusing a shared component, confirm it already matches its Figma spec in the states/props you use (incl. dark mode) before assuming reuse == correct.

13. Round computed numeric values to their domain precision before display or entry.
   - Any token amount fed into an input (Max, Half, or a price-derived amount) must be clamped to the token's decimals with the existing repo pattern: `value.toDecimalPlaces(token.decimals, Decimal.ROUND_DOWN)` (see lend DepositForm/WithdrawForm). Never pass a raw `Decimal.div()`/`.mul()` result straight to a value — it carries full float precision (e.g. Max showing `8790.2678571428571429`).
   - Cover the interactive handlers that produce these values (onMax/onHalf/derived amounts) with a play() story or unit assertion — the default static story never exercises them.

14. Make every public export earn its place.
   - Export a symbol only when another module or package imports it. Keep feature internals private and avoid speculative barrel exports.
   - Before committing, audit new exports and remove those without real consumers. Use the repository's unused-export tooling when available.

15. Require adapters and transforms to change something meaningful.
   - An adapter should validate, normalize, change representation, or bridge a documented incompatible type boundary.
   - Delete identity wrappers and broad casts that merely rename already-compatible SDK or application values. Use the typed value directly instead.

16. Keep domain normalization separate from generic unit conversion.
   - Apply reserve multipliers, exchange rates, scaling factors, and other domain policy at the owning feature boundary.
   - Then call the canonical SDK or shared unit-conversion utility. Do not hide both responsibilities in one generic-sounding helper.

17. Search existing dependencies and shared utilities before writing collection helpers.
   - Prefer an already-installed, canonical utility such as `es-toolkit` for deduplication, compaction, grouping, and similar generic operations.
   - Add a local helper only when it owns domain semantics beyond the generic collection operation.

## Self-Review Checklist

Before committing, answer these in your own head and fix any weak answer:

- Did I preserve the old hook/component contract where possible?
- Did I introduce a new async/cache boundary? If yes, what real resource owns it?
- Are query keys only stable fetch inputs?
- Did I avoid merging query statuses/refetch manually?
- Are helper inputs the narrowest type the callers actually need?
- Are single-mint `useTokens` calls written directly instead of routed through aggregate compaction helpers?
- Is optionality handled at the loading caller, not hidden in helpers?
- Did I reuse SDK/object fields instead of recomputing or fallback-searching?
- Did I reuse the component's size/variant props instead of fighting them with className geometry — and verify the ACTIVE state (toggle on, tab switched), not just the state the Figma frame bakes?
- Are computed numeric values (Max/Half/derived amounts) clamped to domain precision (token decimals, ROUND_DOWN) and covered by a handler-exercising test?
- Does every new export have a real external consumer?
- Does every new adapter perform validation, normalization, representation change, or a documented type bridge?
- Are domain scaling and generic unit conversion separate, with the canonical converter reused?
- Did I search shared code and installed dependencies before adding a generic collection helper?
- Did tests cover the behavior that could regress, not just the implementation detail?
