---
name: plan-for-review
description: "Use when you have an approved or resolved design and need a detailed implementation plan WITHOUT sitting at the terminal answering questions. Runs the normal writing-plans flow but writes any remaining implementation decisions into the plan as open questions with options and a recommendation, commits and pushes it, then hands off to resolve-review so the user can read and talk it through on their own time. Normally reached automatically from design-for-review once its design has zero open questions, but also trigger when the user asks to 'write the plan', 'turn this spec into a plan', or wants a hands-off / write-it-up-and-I'll-review planning flow."
---

# Plan For Review

This is a **delta skill**. It does not reimplement plan-writing — it runs the real one and changes only what "asynchronous review" requires. Base-skill improvements flow through automatically; only the deviations below are maintained here.

## Fail fast if the base skill is missing

Confirm `superpowers:writing-plans` is available. If it is NOT installed/available, STOP immediately. Do not improvise a plan-writing flow yourself. Report:

> "plan-for-review requires `superpowers:writing-plans`, which is not installed. Install the superpowers plugin, then retry."

## Input

Normally reached from `resolve-review` when a design hits zero open questions — the input is that resolved design (including its `## Resolved Decisions` log; treat those as settled, do not reopen). Otherwise use the spec/design the user points you at.

## Run the base, with deviations

Invoke the `superpowers:writing-plans` skill and follow it fully, EXCEPT these explicit overrides. State them as hard overrides, not soft preferences.

1. **OVERRIDE asking the user about unclear implementation choices.** The user is not at the terminal. Decide everything a skilled engineer would decide from the design. For a choice that genuinely depends on the user (library taste the design is silent on, migration vs rebuild, rollout order, anything with real product consequence), do NOT ask — write it into the plan as an open question in the machine contract defined by the `resolve-review` skill: an inline `> **❓ Qn — title** · status: OPEN` block with 2–3 options, trade-offs, and an explicit recommendation, AND a row in a bottom `## Open Questions` table. Stable IDs, status exactly `OPEN`/`RESOLVED`. The base's no-placeholder rule still holds: a decision you cannot make is a `Q`, never a TODO/"TBD".

2. **OVERRIDE the execution handoff** (the base ends by offering to execute the plan). Instead: after the base's own self-review and plan-reviewer pass complete (keep those — they are why the plan is buildable), commit and push. Per CLAUDE.md never commit to `main`: if on `main`/`master` create a branch first, else commit on the current branch; replace any blocked push gracefully. Then:

   - **If open questions remain:** end with ONE message (not a question) — where the plan is, that it's pushed, the open-question count, and to talk it through and paste the transcript back. Then invoke `resolve-review`.
   - **If zero open questions:** **STOP.** Do not auto-implement — the user drives that. Final message:

     > Plan complete and resolved — zero open questions — committed and pushed to `<path>`. To implement, run `superpowers:subagent-driven-development` against this plan (recommended) or `superpowers:executing-plans` for inline. I'll wait for your go.

Everything else from `superpowers:writing-plans` — scope check, file-structure mapping, bite-sized TDD task granularity, the no-placeholders rule, self-review, the plan-reviewer pass, the `REQUIRED SUB-SKILL: superpowers:subagent-driven-development` plan header, and the plan location convention — applies unchanged.
