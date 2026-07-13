---
name: jumay-review-message
description: FE review Slack handoff format. Use when posting or drafting a pull request review request to your team's FE review channel, especially after jumay-oneshot or jumay-parity work, to resolve reviewer mentions and post the terse current channel format.
---

# Jumay Review Message

## Purpose

Post concise FE review requests without rediscovering the channel format.

## Destination

- Default channel: your team's FE review channel, configured locally (not
  stored in this repo).
- Resolve the channel ID before posting if it is not already known.
- Send directly when the user asks to post/leave a comment in Slack; draft only
  when the user explicitly asks for a draft.

## Mention Rules

- Resolve every requested reviewer to a Slack user ID before posting.
- Use Slack mention syntax, not bare names.
- Keep a small mapping of frequent reviewers to Slack user IDs here so they do
  not need re-resolution every time, for example:
  - Reviewer One: `<@REVIEWER_1_ID>`
  - Reviewer Two: `<@REVIEWER_2_ID>`
- Re-resolve if there is any ambiguity or if the user gives a different person.

## Default Message Shape

Use this structure unless the user or current channel context clearly requires a
different one:

```text
<reviewer mentions> pls take a look
<PR link in Slack explicit link syntax, e.g. <https://github.com/OWNER/REPO/pull/NNN|github.com/OWNER/REPO/pull/NNN>>
<PR title>
```

## Content Rules

- Keep it short; the channel convention is terse.
- Do not include Linear links, scope summaries, validation status, visual scores,
  or stacked PR notation unless the user explicitly asks for them.
- Put the reviewer request line first, then the PR link, then the PR title.
- Use Slack explicit link syntax for the PR line so Slack cannot merge the next
  title line into the link. The visible label should be only the PR URL without
  protocol, for example `github.com/OWNER/REPO/pull/NNN`.
- Do not mention reviewers who were not requested unless the user asks or the
  ticket/PR context clearly assigns them.
