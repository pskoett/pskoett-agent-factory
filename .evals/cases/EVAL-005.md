---
eval-id: EVAL-005
source-learning: reviewer must reject bot-authored impl PRs that omit a closing keyword
target: workflows/reviewer.md
method: grep-check
expect: found
pattern: "impl PR must close its source issue"
created: 2026-04-18
last-run: 2026-04-18
last-result: pass
---

# EVAL-005: reviewer checks for closing keyword in bot-authored impl PR bodies

## Scenario

A bot-authored implementation PR merges without `Closes #NN`, `Fixes #NN`, or `Resolves #NN` in its body. GitHub does not auto-close the source issue. The fix ships, but the source issue stays open and requires manual cleanup.

## Regression path

The fix is an explicit check in the reviewer workflow. For bot-authored implementation PRs that are not labeled `plan-file`, reviewer must detect the absence of a closing keyword and add a Critical finding with the exact message: `impl PR must close its source issue. Add \`Closes #NN\` to the body.`

## Check

`workflows/reviewer.md` must contain the literal string `impl PR must close its source issue`. This confirms the close-the-loop guard is still in place.

## Pass condition

`grep -qF 'impl PR must close its source issue' workflows/reviewer.md` exits with code 0.

## Fail condition

The close-the-loop check has been removed or weakened. Bot-authored implementation PRs can once again merge without closing their source issue.
