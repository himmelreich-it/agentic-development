---
name: resolve-review
description: "Use to reconcile a design-for-review or plan-for-review document against the user's feedback. The user reads the committed doc, talks it through (alone or in a group), and pastes the transcript (or a path to a transcript file) back. This skill classifies every piece of that feedback as an answer to an open question, an agreement to a proposal, or a question about a question/proposal, updates the document accordingly, recommits and pushes, and reports what is still open. Trigger when the user pastes a transcript, discussion notes, or review comments after a design-for-review/plan-for-review handoff, or says 'here's the feedback', 'reconcile this', 'I talked it through', 'resolve the open questions'. Loop this until zero open questions remain."
---

# Resolve Review

Reconcile a review document against the user's feedback, one round per transcript, until nothing is open. This skill is net-new — it composes with `design-for-review` and `plan-for-review` (which produce the documents) and owns the open-questions contract they both write to.

**Announce at start:** "Using resolve-review to classify your feedback and update the document."

## The Open-Questions Contract (canonical)

`design-for-review` and `plan-for-review` write this; `resolve-review` reads and updates it. It is a data contract between skills — keep the format exact, it is not styling.

**Inline marker**, placed in the section where the decision lives:

```markdown
> **❓ Qn — <short title>** · status: OPEN
> <1–3 sentences of context: what's being decided and why it needs the user>
> - **A (recommended):** <option> — <trade-off>
> - **B:** <option> — <trade-off>
> _Recommendation: A — <one-line reason>._
```

**Bottom summary**, every question in stable ID order:

```markdown
## Open Questions

| ID | Question | Options | Recommendation | Status |
|----|----------|---------|----------------|--------|
| Q1 | <short title> | A / B | A | OPEN |
```

Plus an append-only `## Resolved Decisions` log. Rules: IDs are stable and never reused; `status` is exactly `OPEN` or `RESOLVED` in both the inline marker and the table; a document is **fully resolved** when the table has zero `OPEN` rows — that single fact drives the terminal transition, so keep it accurate.

## Inputs

1. The document — the most recently committed `Status: DRAFT` design or plan with open questions, or the path the user gives.
2. The feedback — pasted transcript text, or a file path the user points at (read it).

If the target document is genuinely ambiguous, ask that one question only. Everything else you infer from the transcript — do not regress into the one-question-at-a-time flow the user is explicitly avoiding.

## The Classification Rule (the core of this skill)

The transcript is a messy talk-through (solo or group, out of order, with tangents). Every substantive statement is one of three things. Treating them the same is the failure this skill exists to prevent — especially marking a question "resolved" when the user was actually *asking you about it*.

**1. An answer to an open question.** The user picked an option, gave a different answer, or stated a constraint that settles a `Q`.
→ Bake the decision into the document body where it lives. Flip the inline marker and the table row to `status: RESOLVED`. Append to `## Resolved Decisions`: `Qn: <decision> — <one-line rationale from the transcript>`. Remove the now-stale options text, keep the chosen outcome as plain prose. If the answer adds a constraint beyond picking an option ("A, but also X"), fold X into the affected sections too, not just the decision line. If the `Q` had an embedded visual, keep only the chosen option's visual and delete the rejected alternatives.

**2. An agreement to a proposal.** The user accepted something you proposed — "yes", "go with your rec", "the first one's fine", or an explicit blanket delegation ("just use your recommendations for the rest").
→ Lock that proposal into the body. If it maps to a `Q`, resolve it as case 1 with rationale "accepted recommendation". A blanket "use your recommendations for everything else" resolves *all* remaining `Q`s to their recommended option — do it, and say so.

**3. A question about a question or proposal (meta-question).** The user is asking *you* something — "why Postgres?", "what does option B cost us?", "is C even possible?", "what do you mean by units here?".
→ Do **NOT** update the body and do **NOT** mark anything resolved. Answer the question: put the answer in your reply, and add a `> _Clarification: …_` line under that `Q`'s inline marker so the context survives into the next round. The question stays `OPEN`. Resolving a question the user was merely probing destroys the decision they were trying to make.

When a statement is ambiguous between answer and meta-question, treat it as a meta-question and answer it — leaving something open and explaining is safe; silently deciding is not. Note the ambiguity in your report so the user can confirm next round.

**Also handle:**
- **Changed mind / new constraint:** update the body; if it invalidates a `RESOLVED` decision, reopen that `Q` (keep its ID) or open a new `Q` with the next unused ID; note it.
- **New question the user raises:** add it as a new `Q` with the next unused ID, options, and your recommendation, same contract.
- **Explicit "out of scope, don't add":** record it as out-of-scope; add nothing.
- **Scope expansion:** if feedback pushes past one plan's worth of work, say so and recommend decomposition rather than silently absorbing it.

## Process

1. Read the document and the transcript fully before changing anything.
2. Walk every open `Q` and every proposal. For each, find the relevant feedback and classify it (answer / agreement / meta-question / none-yet).
3. Apply the updates. Keep the contract exact: inline markers and the bottom table stay in sync; `status` exactly `OPEN`/`RESOLVED`; IDs stable.
4. Self-check: does every transcript decision map to a doc change? Did any meta-question get treated as an answer? Is the table consistent with the inline markers?
5. **Recommit and push.** Per CLAUDE.md never commit to `main`; stay on the document's existing branch (it was branched at authoring time if needed).

```bash
git add <doc path>
git commit -m "docs: resolve review round for <topic> (<k> resolved, <m> open)"
git push
```

Multiple commits across rounds are expected — that is the design, not a problem.

## Report & Loop

End with a compact status (one message, not a question):

> Round applied and pushed. Resolved this round: Q2, Q5 (accepted recommendations), Q3 (you chose B).
> Answered without changing the doc (still OPEN): Q4 — you asked why X; my answer: <one line>.
> Still open: Q1, Q4, Q6. New: Q7 (added from your point about rate limits).
> Read the updated doc and the meta-question answers, talk through what's left, paste the next transcript when ready.

Then **stay in resolve-review** for the next transcript.

## Terminal Transitions (only on zero open questions)

When the bottom `## Open Questions` table has zero `OPEN` rows after a round:

- Set the document `Status:` to `RESOLVED`, commit and push.
- **If the document is a design:** announce it is fully resolved, then invoke `plan-for-review` with this design as input. The plan phase runs the same write → review → resolve loop.
- **If the document is a plan:** **STOP.** Do not start implementation — the user drives that. Final message:

  > All open questions resolved. Plan finalized, committed and pushed to `<path>`. To implement, run `superpowers:subagent-driven-development` against this plan (recommended) or `superpowers:executing-plans` for inline. I'll wait for your go.

Never report fully resolved unless the table truly has no `OPEN` rows — the trustworthiness of the whole loop rests on that.
