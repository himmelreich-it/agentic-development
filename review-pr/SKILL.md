name: review-pr
description: Run a comprehensive PR review focused on files changed in this branch, using specialized parallel agents. Invokes pr-review-toolkit:review-pr with project-specific scoping.
user_invocable: true
---

# PR Review

Run a comprehensive review of the current PR using the `pr-review-toolkit:review-pr` skill as the execution engine.

## Scoping Rules

1. **Only review files actually changed in this PR.** Use this priority order to determine the file list:
   - **Preferred:** `gh pr diff --name-only` — this is GitHub's view of the PR and the source of truth. It correctly handles rebases and merge commits.
   - **Fallback (no PR exists yet):** `git diff --name-only $(git merge-base main HEAD)..HEAD` — use the merge-base to avoid including unrelated commits from main.
   - **Never use** `git diff --name-only main...HEAD` — the three-dot diff can include files from main that were merged into the branch, inflating the changeset.
2. **Exclude from size judgement:** `uv.lock` and `*.md` files. These do not count when deciding whether the PR is small, medium, or large, and should not be flagged for review unless they contain an actual defect.
3. **Focus review agents on source and test files only** — Python source (`api/`, `migrations/`, `tests/`), config files (`pyproject.toml`, `Makefile`, `Dockerfile`, `docker-compose.yml`, `alembic.ini`, `.env.example`). Ignore generated or lock files.
4. **For diffs**, also prefer `gh pr diff` over `git diff` for the same reasons. Only the actual PR diff should be reviewed.

## Behaviour Guidelines

- **Be thorough but realistic.** This review may have been run multiple times already. If the code is clean, say so — do not invent issues to justify the review.
- **Only report genuine issues.** Every finding must include a concrete reason it matters (bug, security, performance, maintainability). "Could be improved" without a specific downside is not a finding.
- **Respect project conventions.** Judge code against the standards in `CLAUDE.md`, not generic best practices that conflict with this project's choices.
- **No busywork suggestions.** Do not suggest adding docstrings, comments, type annotations, or error handling to code that wasn't changed in this PR, and do not suggest these for code that already follows project conventions.
- **Acknowledge good work.** If the code is well-structured, tested, and follows conventions, say that clearly. A clean review is a valid outcome.

## Execution

Invoke the `pr-review-toolkit:review-pr` skill with all applicable review aspects, passing the scoping context above. The skill handles agent orchestration, parallelism, and result aggregation.
