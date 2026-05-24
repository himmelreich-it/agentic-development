---
name: design-for-review
description: "Use when turning an idea, feature, or change into a design WITHOUT sitting at the terminal answering questions one at a time. Runs the normal brainstorming design flow but writes every open question into the document with options and a recommendation, commits and pushes it, and either hands off to resolve-review (when questions remain) or starts plan-for-review immediately (when zero questions remain). Trigger when the user wants to 'design X', 'brainstorm a feature', 'spec this out', or explicitly wants an asynchronous / hands-off / write-it-up-and-I'll-review design flow. Prefer this over synchronous brainstorming whenever the user signals they will not be watching the terminal."
---

# Design For Review

This is a **delta skill**. It does not reimplement brainstorming — it runs the real one and changes only what "asynchronous review" requires. Base-skill improvements flow through automatically; only the deviations below are maintained here.

## Fail fast if the base skill is missing

Confirm `superpowers:brainstorming` is available. If it is NOT installed/available, STOP immediately. Do not improvise a brainstorming flow yourself. Report:

> "design-for-review requires `superpowers:brainstorming`, which is not installed. Install the superpowers plugin, then retry."

## Run the base, with deviations

Invoke the `superpowers:brainstorming` skill and follow it fully, EXCEPT these explicit overrides. State them to yourself as hard overrides, not soft preferences — the base skill has strong directives (e.g. "ask one question at a time") that these deliberately replace.

1. **OVERRIDE the "ask clarifying questions one at a time" loop.** The user is not at the terminal. Do NOT ask interactive questions. Decide everything a competent engineer would decide alone. For every genuine fork you cannot decide (depends on user intent, taste, constraints, external facts), do not ask — instead write it into the design document as an open question, in the machine contract defined by the `resolve-review` skill: an inline `> **❓ Qn — title** · status: OPEN` block with 2–3 options, trade-offs, and an explicit recommendation, AND a row in a bottom `## Open Questions` table. Stable IDs, status exactly `OPEN`/`RESOLVED`. Do not manufacture filler questions — an over-long list is a failure.

2. **OVERRIDE the Visual Companion (browser).** Do not offer or start the browser companion — it assumes a present user. When a question is genuinely visual (layout, flow, diagram, side-by-side UI), embed the mockup IN the document next to its `Q` marker: a ` ```mermaid ` block for flows/architecture or an ASCII/box mockup for layouts, showing the competing options, then your recommendation.

3. **OVERRIDE the synchronous user-review gate and the writing-plans handoff.** The base ends by asking the user to review the spec, then invoking writing-plans. Instead: after the base's own spec self-review and reviewer-subagent pass complete (keep those — they are why the spec is good), commit and push the design. Per CLAUDE.md never commit to `main`: if on `main`/`master` create `design/<topic>` first, else commit on the current branch; replace any blocked push gracefully. Then:

   - **If open questions remain:** end with ONE message (not a question):

     > Design written to `<path>` and pushed. N open questions (Q1–Qn) are inline where each decision lives and collected in the bottom table. Read it, talk it through however you like (solo or with a group), then paste the transcript back here — `resolve-review` will classify your answers, agreements, and questions, update the doc, and recommit.

     Then invoke `resolve-review`.
   - **If zero open questions:** end with ONE message (not a question):

     > Design complete and resolved — zero open questions — committed and pushed to `<path>`. Starting `plan-for-review` now with this design as input.

     Then invoke `plan-for-review` immediately with this design as input. Do not ask the user for permission to continue.

Everything else from `superpowers:brainstorming` — project exploration, scope decomposition, approach exploration, the spec self-review, the reviewer-subagent pass, the spec document location convention — applies unchanged.
