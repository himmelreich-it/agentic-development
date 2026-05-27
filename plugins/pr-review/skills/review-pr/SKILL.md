---
name: review-pr
description: Run a comprehensive PR review focused on files changed in this branch, then aggressively filter out false positives with an independent skeptic pass and explain the survivors in plain, investigable language. Use whenever the user wants to review a PR, review the diff, check a branch before merge, or asks "what's wrong with this code" on changed files. Prefer this over invoking pr-review-toolkit:review-pr directly — that engine over-reports; this skill adds the scoping, the skeptic filter, and the human-readable write-up the user actually wants.
user_invocable: true
---

# PR Review

This is a **delta skill**. It does not reimplement code review — it runs the real engine (`pr-review-toolkit:review-pr`), then adds three things that engine lacks: project scoping, a skeptic pass that kills false positives, and a write-up aimed at someone who did **not** write the code and needs to investigate each finding. Engine improvements flow through automatically; only the deviations below are maintained here.

## Why this skill exists

The base engine is good at *finding* things but bad at *judging* them — it reports plausible-looking issues that aren't real problems, and it phrases survivors in terse, expert-to-expert shorthand. The user reviews code Claude wrote, so a finding like `"unbounded gather() — backpressure risk"` is useless without seeing the actual line and a concrete reason it bites. This skill closes both gaps: it disproves what it can, then explains what's left so the user can verify it independently.

## Fail fast if the engine is missing

Confirm `pr-review-toolkit:review-pr` is available. If it is NOT installed/available, STOP immediately. Do not improvise a review pipeline. Report:

> "review-pr requires `pr-review-toolkit:review-pr`, which is not installed. Install the pr-review-toolkit plugin, then retry."

## Phase 1 — Scope the changeset

Determine the file list with this priority. Scoping wrong is the most common way a review wastes everyone's time on code that didn't change.

- **Preferred:** `gh pr diff --name-only` — GitHub's own view of the PR, correct across rebases and merge commits.
- **Fallback (no PR yet):** `git diff --name-only $(git merge-base main HEAD)..HEAD` — the merge-base avoids dragging in unrelated commits from main.
- **Never** `git diff --name-only main...HEAD` — the three-dot form can include files merged from main, inflating the changeset.

Then:
- **Exclude from size judgement and from review** `uv.lock` and `*.md` — they don't decide whether the PR is small/large and aren't flagged unless they contain a real defect.
- **Review only source, test, and config** — `api/`, `migrations/`, `tests/`, and `pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.yml`, `alembic.ini`, `.env.example`. Ignore generated and lock files.
- Use `gh pr diff` (not `git diff`) for the diff content too, for the same rebase/merge reasons.

## Phase 2 — Run the engine

Invoke `pr-review-toolkit:review-pr` with all applicable review aspects, passing the scope above. Tell it the project standards live in `CLAUDE.md` and to judge against those, not generic best practices. The engine handles agent orchestration, parallelism, and aggregation.

Collect its raw findings into a list. Keep each finding's `file:line`, severity, and the agent's stated reason — you need all three for the skeptic pass. **Do not show these raw findings to the user yet.** They are candidates, not conclusions.

If the engine returns nothing, say so plainly and stop — a clean review is a valid, good outcome. Do not invent findings to justify the run.

## Phase 3 — Skeptic pass (kill false positives)

The agent that raises a finding is biased to defend it. So hand each finding to a **fresh** subagent whose only job is to *disprove* it. Independence is the whole point — do not revalidate findings inline in this thread.

Spawn skeptic subagents in parallel — one per finding for full independence, or batch findings that touch the same file into one agent (cheaper, still independent of the finder). Each gets this brief:

```
You are a skeptic. A PR review flagged the issue below. Your job is to
DISPROVE it by reading the actual code — assume it is a false positive
until the code forces you to conclude otherwise.

Finding: <reason>
Location: <file:line>
Project standards: see CLAUDE.md

Read the surrounding code and any callers/callees needed. Then return:
- verdict: STANDS | FALLS | UNCERTAIN
- one-paragraph reason grounded in specific lines
- if STANDS: the concrete downside (bug / security / perf / maintainability)
  and the smallest input or condition that triggers it
```

Resolve verdicts:
- **FALLS** → drop it. Record a one-line note (finding + why it was dismissed) for the transparency list in Phase 5.
- **UNCERTAIN** → keep it, but label it clearly so the user knows it needs their judgement.
- **STANDS** → carry it into the write-up.

A review where most findings FALL is a success, not a failure — it means the filter worked.

## Phase 4 — Write up survivors for someone who didn't write the code

Terse expert shorthand fails the user here. Explain concretely: lead with a small real example, then the rule. Show jargon rather than letting the term carry the explanation — the first time a pattern name appears, sketch what it looks like.

For each surviving finding, use this structure:

```
### [n] <plain-language title> — `file:line`  ·  <severity> · <STANDS|UNCERTAIN>

**What the code does** — a ≤10-line snippet copied from the actual diff for
behaviour, OR a small ASCII sketch for structure/flow. Real code from the PR,
not a toy analogue.

**Why it's a problem** — the concrete downside in one or two sentences. Name
the failure: what breaks, under what input/condition. If a pattern name helps
(e.g. "N+1 query" — one query, then one more per row returned), show the shape
the first time, then use the name.

**See it yourself** — the exact spot to look, or a command / input that
triggers it, so the user can confirm independently rather than trust the agent.

**Suggested direction** — where the fix lives and the shape of it. A direction,
not necessarily finished code, unless the fix is a one-liner.
```

Order findings by severity: critical first, then important, then suggestions.

Keep examples to the point — a 10-line snippet that shows the bug beats 40 lines of surrounding context. If a structural issue is clearer as a diagram than as code, draw the ASCII sketch instead.

## Phase 5 — Output to chat

Print, in this order:

1. **One-line scope** — what was reviewed (file count, PR/branch), so the user knows the boundary.
2. **Survivors** — the Phase 4 write-ups, grouped by severity. If there are none, say the code is clean and why that's credible (e.g. "engine raised N, all N failed the skeptic pass for the reasons below").
3. **Dismissed by skeptic** — a short collapsed list: each dropped finding as one line with the disproving reason. This earns trust: the user sees the filter ran and why, instead of wondering what was hidden.
4. **Strengths** — if the code is well-structured, tested, and convention-following, say so plainly.

Output to chat only — do not write a file or commit anything unless the user asks.
