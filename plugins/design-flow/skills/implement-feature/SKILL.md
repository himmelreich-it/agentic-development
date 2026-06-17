---
name: implement-feature
description: "End-to-end feature orchestration: create a dedicated worktree, run design-for-review and implementation there, then run `pr-review:review-pr` before handoff. Use when the user wants a feature implemented from idea to reviewed PR-ready changes with minimal back-and-forth."
---

# Implement Feature

Orchestrate a complete feature flow by composing existing skills. This skill does not replace those skills — it sequences them reliably.

## Required skills

Confirm all three skills are available before starting:

- `git-workflow:worktree`
- `design-flow:design-for-review`
- `pr-review:review-pr`

If any are missing, stop and report exactly which one is required.

## Workflow

1. **Create the worktree first** using `git-workflow:worktree`.
   - Use the user's feature request/context as input to derive the branch/worktree name.
   - Wait until worktree creation fully completes and you have the created path.

2. **Switch execution context to that worktree**.
   - All subsequent exploration, design, implementation, commits, and checks happen in the new worktree.
   - Do not continue development from the original repository path.

3. **Run `design-flow:design-for-review` in the worktree** using the original feature request as input.
   - Follow that skill through its normal design and planning handoff behavior.
   - Continue through the implementation phase it triggers until feature work is complete.

4. **Run `pr-review:review-pr` after implementation** in the same worktree.
   - Treat findings seriously; fix valid issues.
   - Re-run review as needed until results are clean or only clearly non-actionable findings remain.

## Completion criteria

Finish only when:
- feature design + implementation flow has completed in the created worktree, and
- PR review has been run on the resulting changes.

End with a concise summary: worktree path, branch name, implemented scope, and PR review outcome.
