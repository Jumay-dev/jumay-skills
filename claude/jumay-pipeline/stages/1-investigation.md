# ① Investigation

Find out what is true before anyone decides what to build. Read-only — this
stage never edits product code.

## Load

| | Skill | When |
|---|---|---|
| always | — | this stage is mostly reading |
| if | `$jumay-worktree` | the subject is an existing branch/PR you must check out |
| if | `figma:figma-design-to-code` | the ticket carries a Figma node URL |
| if | `docs/quality-gate.md` G3 | you are diffing a branch — stale-base deletions are not deletions |

Prefer `codedb_*` (symbol, callers, outline, context) over grep for structural
questions; grep only when the symbol name is unknown.

## Entry

A ticket, a Figma pointer, a bug report, or a plain description. Nothing else
required.

## Do

1. **Resolve the ticket first, exactly.** Read the issue by identifier including
   attachments, relations, and branch name. If exact lookup fails, search
   variants, remote branches, GitHub issues/PRs, Slack mentions. Never invent
   requirements — if the text stays inaccessible, say so and stop.
2. **Map the code that will change.** Files, the data-flow shape today, who
   calls what. The next stage decides scope from this map.
3. **Check prior art.** Has this been attempted? A stale branch, a reverted PR,
   or a CHANGELOG note changes the spec.
4. **Check team directives** for deprecations and sanctioned data sources before
   assuming any SDK surface is fair game (G15).
5. **Collect open questions** — every ambiguity you cannot resolve from code.
   This list is the handoff to ②, and it is what ends the ①⇄② loop.

## Progress

Append one line per step, so the run is visible without reading your pane:

```sh
echo "PROGRESS investigation <what you are doing now>" >> "$PIPELINE_DIR/<ticket>/progress.log"
```

The dashboard renders the last line. A log that stops moving for five minutes
shows as quiet — which is the signal to check the agent, not the artifact.

## Exit gate

- `findings.md` exists with: **File map**, **Current behavior**, **Prior art**,
  **Open questions**.
- Every claim about current behavior cites a file:line you actually read.
- Zero proposed solutions. Solutions are stage ②'s job; mixing them here is how
  a spec gets written against a codebase nobody checked.

## Out

`findings.md` → carries to ② whole; carries to ③ as the **File map** section only.
