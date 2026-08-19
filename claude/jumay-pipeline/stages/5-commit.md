# ⑤ Commit

Get the work into signed, correctly-based commits. **Never runs in a container**
— the signing key is on the host, and G1 forbids working around that.

## Load

| | Skill | When |
|---|---|---|
| always | `docs/quality-gate.md` **G1** | signing invariant |
| always | `docs/quality-gate.md` **G8** | fetch before you base — always, first |
| if | `gh stack` | the branch is part of a stack |

## Entry

The diff + `selfreview.md` with a passing verdict.

## Do

1. **Never touch git signing config.** No local `user.signingkey`, no signature
   format switch, no unsigned commit when the signer is unavailable. On signing
   failure: STOP, leave the work uncommitted, report `BLOCKED-SIGNING`.
2. **Commit atomically** — one logical change per commit, message in the repo's
   existing convention (derive it from `git log`, never guess it).
3. **Verify your own signatures** before pushing:
   ```sh
   git log --format='%G? %h %s' origin/<base>..HEAD
   ```
   Every new commit shows `G`. An `N` or `E` means the signer was bypassed.
4. **Restack with `gh stack`**, not hand-rolled rebase chains. `gh stack sync`
   cascade-rebases onto updated parents and restores every branch on conflict
   rather than leaving the stack half-rebased. Fall back to
   `git rebase --onto` only for what the stack model cannot express.
5. **Never sync upward** while a lower branch has unverified signatures (G1) or
   stripped evidence (G2).

## Exit gate

- `git log --format='%G?'` shows `G` on every new commit.
- Commits exist **on origin**, not just locally — verify with your own command,
  not the agent's word (G7).
- Branch is based on a freshly fetched base; no resurrected squash-merged commits
  in the diff.

## Out

Signed commits on origin.
