# Eval Index

Eval cases created from promoted learnings. Each case is a regression test that verifies a promoted rule still holds.

Managed by `eval-creator-ci`. Do not edit manually unless adding a hand-crafted eval.

## Cases

- `EVAL-004`: spec-refiner prompt still forbids closing keywords in plan PR bodies
- `EVAL-005`: reviewer checks that bot-authored implementation PRs close their source issue
- `EVAL-006`: reviewer rejects plan PR bodies that contain closing keywords

## Format

Each case lives in `.evals/cases/<eval-id>.md` with this frontmatter:

```yaml
---
eval-id: EVAL-NNN
source-learning: LRN-NNN
target: path/to/file
method: grep-check | command-check | file-check | rule-check
expect: found | not_found | exit_0 | contains
pattern: "the thing to check for"
created: YYYY-MM-DD
last-run: YYYY-MM-DD
last-result: pass | fail | skip
---
```
