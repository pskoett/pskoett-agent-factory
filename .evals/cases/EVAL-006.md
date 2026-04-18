---
eval-id: EVAL-006
source-learning: reviewer must reject plan PR bodies that contain closing keywords
target: workflows/reviewer.md
method: grep-check
expect: found
pattern: "Check for forbidden closing keyword on plan PRs"
created: 2026-04-18
last-run: 2026-04-18
last-result: pass
---

# EVAL-006: reviewer runtime check for closing keywords in plan PR bodies

## Scenario

Prompt-side prohibition alone is not enough. A plan PR body can still slip and contain `Closes #NN`, `Fixes #NN`, or `Resolves #NN`, which auto-closes the source issue on merge.

## Regression path

Reviewer Step 3b greps plan PR bodies for closing keywords and forces `needs-changes` when one is found. This eval verifies that the runtime guard is still in the workflow source.

## Check

`workflows/reviewer.md` must contain the literal string `Check for forbidden closing keyword on plan PRs`.

## Pass condition

`grep -qF 'Check for forbidden closing keyword on plan PRs' workflows/reviewer.md` exits with code 0.

## Fail condition

The reviewer-side guard has been removed. Plan PRs can once again merge with closing keywords and rely on downstream recovery instead of being blocked before merge.
