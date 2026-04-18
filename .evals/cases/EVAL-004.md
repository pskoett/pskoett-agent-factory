---
eval-id: EVAL-004
source-learning: spec-refiner wrote `Fixes #NN` in a plan PR body
target: workflows/spec-refiner.md
method: grep-check
expect: found
pattern: "Before finalizing the body, grep your own draft"
created: 2026-04-18
last-run: 2026-04-18
last-result: pass
---

# EVAL-004: spec-refiner forbids closing keywords in plan PR bodies

## Scenario

A plan PR body must not contain `Closes #NN`, `Fixes #NN`, or `Resolves #NN`. If it does, GitHub auto-closes the source issue on merge and breaks the normal handoff path.

## Regression path

The fix is the explicit prohibition in `spec-refiner.md`, including the self-grep instruction before the PR body is finalized. This eval verifies that prompt-side guard is still present.

## Check

`workflows/spec-refiner.md` must contain the literal string `Before finalizing the body, grep your own draft`.

## Pass condition

`grep -qF 'Before finalizing the body, grep your own draft' workflows/spec-refiner.md` exits with code 0.

## Fail condition

The self-grep instruction has been removed or weakened. Plan PRs can once again emit closing keywords and auto-close their source issues on merge.

