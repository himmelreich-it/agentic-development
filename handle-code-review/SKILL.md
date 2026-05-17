---
name: handle-code-review
description: "Process and critically evaluate code review comments on your PR. Use this skill when the user says 'handle PR comments', 'check review comments', 'address PR feedback', 'look at the review', 'handle review', or references PR/code review comments they've received. Also use when the user pastes a PR URL and asks about comments or feedback on it."
user_invocable: true
---

# Handle Code Review

Fetch all comments on a PR, critically evaluate each one, then help the user decide what to implement and how to respond.

## Core Principle

**Verify before implementing. Question before assuming. Technical correctness over social comfort.**

Code review comments are suggestions to evaluate, not orders to follow. Reviewers may lack context, misunderstand the codebase, or suggest changes that break existing functionality. Your job is to be the user's technical partner — figure out which comments are right, which are wrong, and which need clarification — so the user can make informed decisions.

This matters because LLMs have a strong tendency toward performative agreement ("Great point! Let me fix that right away!"). That impulse is actively harmful here. A wrong "fix" costs more than pushing back on a reviewer.

## Step 1: Fetch PR Comments

Determine the PR to process:
- If the user provides a PR URL or number, use that
- Otherwise, detect from the current branch: `gh pr view --json number,url,title`

Fetch all comment types. **Resolved comment threads must be excluded** — they have already been addressed and should not be evaluated or acted upon.

Use GraphQL to fetch review threads so you can filter by resolution status:

```bash
# Review threads with resolution status (paginate if needed)
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            isResolved
            isOutdated
            path
            line
            comments(first: 50) {
              nodes {
                id
                databaseId
                author { login }
                body
                createdAt
                path
                line
              }
            }
          }
        }
      }
    }
  }
' -f owner='{owner}' -f repo='{repo}' -F pr='{pr_number}'
```

From the GraphQL response:
- **Skip threads where `isResolved: true`** — these are already addressed
- Optionally flag `isOutdated: true` threads (code has changed under them) — still evaluate but note they may be stale

Also fetch general PR comments and reviews via REST (these don't have thread resolution):

```bash
# Issue comments (general PR comments)
gh api repos/{owner}/{repo}/issues/{pr_number}/comments

# Reviews (review summaries with approve/request-changes/comment status)
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews
```

Also fetch the PR diff for context:
```bash
gh pr diff {pr_number}
```

## Step 2: Categorize and Evaluate Each Comment

For every comment, determine:

1. **Who wrote it** — the user themselves, a teammate, or a bot/CI system
2. **What it's asking for** — a specific code change, a question, a style preference, an architectural concern
3. **Whether it's technically correct for THIS codebase** — not in the abstract, but given the actual code, conventions in `CLAUDE.md`, and the PR's intent

### Evaluation Criteria

For each comment, classify it:

- **Valid** — technically correct, improves the code, should be implemented
- **Valid but minor** — correct but low-impact (style nits, optional improvements)
- **Needs clarification** — the comment is ambiguous or could mean multiple things
- **Questionable** — may be incorrect, lacks codebase context, or conflicts with project conventions
- **Wrong** — demonstrably incorrect given the actual code

### How to Verify

Do not take comments at face value. For each non-trivial comment:

- Read the actual code being commented on (not just the diff snippet)
- Check if the suggested change would break existing tests or functionality
- Grep the codebase for usage patterns the reviewer may not be aware of
- Check `CLAUDE.md` and project conventions — does the suggestion conflict with established patterns?
- Consider whether the reviewer has full context of the PR's purpose

### YAGNI Check

When a reviewer suggests adding error handling, abstractions, or "proper implementation" for something, grep the codebase for actual usage. If the thing they're worried about can't actually happen given the current code, say so. Don't add defensive code for impossible scenarios just because a reviewer imagined them.

## Step 3: Present the Analysis

Present findings grouped by category, with the most important items first. For each comment:

- Quote the original comment
- State your evaluation (valid / questionable / wrong / needs clarification)
- Explain your reasoning with evidence from the codebase
- For questionable or wrong comments, show specifically why

Example format:

```
### Comment by @reviewer on `api/services/foo.py:42`
> "This should use a try/except for the database call"

**Evaluation: Valid**
The `get_listing()` call on line 42 hits the database without error handling.
The service layer convention (per CLAUDE.md) is to catch specific domain
exceptions here. Should wrap in `try/except ListingNotFoundError`.

---

### Comment by @reviewer on `api/adapters/bar.py:15`
> "You should add retry logic here"

**Evaluation: Questionable**
This adapter is called only from the batch service which already has its own
retry wrapper (`RetryPolicy` in `api/services/batch.py:28`). Adding retry
here would cause nested retries. The reviewer may not be aware of the
existing retry layer.
```

## Step 4: Offer Next Steps

After presenting the analysis, offer the user two paths:

### Implementation

Ask the user which comments they want to implement. Then offer:

1. **Plan Mode** — "I can create a plan and enter Plan Mode to work through these changes step by step"
2. **Feature Dev** — "I can use the `feature-dev` skill for a more structured implementation with architecture analysis"

Let the user pick. Don't start implementing without their go-ahead.

### Replies

Offer to draft reply comments for the PR. Be explicit about this:

"I can draft replies to each comment. I'll show you what I'd write before posting — you can edit the tone and wording since AI-generated replies tend to sound overly formal."

For replies, follow these rules:

- **Valid comments you're implementing:** Brief acknowledgment + what you changed. No gratitude theater.
  - Good: "Fixed — wrapped in `try/except ListingNotFoundError`."
  - Bad: "Great catch! You're absolutely right, thank you for pointing this out!"
- **Questionable/wrong comments:** Respectful technical pushback with evidence.
  - Good: "The retry logic already exists in the batch service layer (`RetryPolicy` in `batch.py:28`) — adding it here would cause nested retries."
  - Bad: "Thanks for the suggestion! I'll look into this."
- **Needs clarification:** Ask a specific question about what they mean.

Always show the drafted replies to the user before posting. The user knows the reviewer — they can adjust tone and phrasing.

To post replies, use the GitHub API to reply in the correct comment thread:
```bash
# Reply to a review comment (inline)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies -f body="..."

# Reply to an issue comment (general)
gh api repos/{owner}/{repo}/issues/{pr_number}/comments -f body="..."
```

## Handling the User's Own Comments

If the user left comments on their own PR (self-review notes, TODOs, questions for reviewers), surface these separately as "Your notes" — don't evaluate them the same way. They may be reminders the user wants to address or context they left for reviewers.

## Forbidden Behaviors

- **No performative agreement.** Never say "Great point!", "Excellent feedback!", "You're absolutely right!" — not in analysis, not in drafted replies, not anywhere.
- **No blind implementation.** Never implement a comment without verifying it's correct for this codebase first.
- **No batch implementation without testing.** If implementing multiple comments, handle one at a time and verify each.
- **No avoiding pushback.** If a comment is wrong, say so clearly with evidence. Being wrong politely is still being wrong.
- **No posting replies without user approval.** Always show drafts first.