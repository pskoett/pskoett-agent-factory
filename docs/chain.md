# Factory Chain

This diagram reflects the tested agent-factory flow that now backs this template.

## Layered View

```text
+-------------------------------------------------------------+
|                     GitHub State Layer                      |
|  issues, labels, PRs, comments, plan files, workflow runs   |
+-----------------------------+-------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                  gh-aw And Actions Adapter Layer            |
|                                                             |
|  spec-refiner.md          reviewer.md                       |
|  implementer-dispatcher.md self-improvement-meta.md         |
|  simplify-and-harden-ci.md learning-aggregator-ci.md        |
|  eval-creator-ci.md        ci-cleaner.md                    |
|  conflict-resolver.md      contribution-checker.md          |
|  issue-triage.md           pr-fix.md                        |
|  plan-merged-dispatcher.yml lock-file-sync.yml              |
+-----------------------------+-------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                     Skill Source Layer                      |
|                                                             |
|  plan-interview/       intent-framed-agent/                 |
|  self-improvement/     simplify-and-harden/                 |
|  learning-aggregator/  eval-creator/                        |
|  context-surfing/      verify-gate/                         |
|  pre-flight-check/                                         |
+-------------------------------------------------------------+

+-------------------------------------------------------------+
|                    Observability Layer                      |
|  session transcripts, tool outputs, token usage artifacts   |
+-------------------------------------------------------------+
```

## Execution Flow

```text
issue opened
  |
  v
issue-triage
  |
  v
human adds needs-spec
  |
  v
spec-refiner
  |
  | writes docs/plans/plan-NNN-<slug>.md
  | where NNN is the source issue number
  | adds impl:copilot and needs-plan
  v
human reviews and merges the plan PR
  |
  v
plan-merged-dispatcher
  |
  | extracts the Implementation Checklist
  | writes it into the source issue body
  | removes needs-plan
  | adds ready-for-implementation
  v
implementer-dispatcher
  |
  | reads impl:* on the source issue
  | auto-assigns only impl:copilot
  v
coding agent opens PR
  |
  +--> reviewer
  +--> contribution-checker
  +--> simplify-and-harden-ci
  +--> eval-creator-ci
  |
  +--> reviewer adds needs-rebase when PR is behind main
  +--> reviewer self-tamper guard can force human-review
  |
  +--> conflict-resolver when labeled needs-rebase
  |
  v
merged PR

nightly and weekly side loops:
  self-improvement-meta
  learning-aggregator-ci
  ci-cleaner
```

## Routing Model

The factory still uses `impl:*` labels, but only one of them is truly automatable:

| Label | Behavior |
|-------|----------|
| `impl:copilot` | auto-assigned by `implementer-dispatcher` |
| `impl:claude-opus` | manual hand-off |
| `impl:claude-sonnet` | manual hand-off |
| `impl:codex` | manual hand-off |

That change matters. The old design implied that all implementer labels were equal. In practice they were not. `assign-to-agent` can target the Copilot cloud agent because it is a real GitHub account on the workflow-available assignment path. Claude and Codex remain manual UI assignments.

## Why There Is No `/plan`

The older `/plan` plus sub-issue layer looked elegant on paper and failed in the messy parts:

- parent lookups were brittle
- plan numbering raced
- PR closure semantics caused accidental source-issue closure
- sub-issue assignment added another state machine to debug

The source-issue-centric model is less clever and more reliable.

## Why The Plain Actions Workflows Exist

Two parts of the tested flow are better as plain GitHub Actions:

- `plan-merged-dispatcher.yml` reacts to merge events and edits issue bodies
- `lock-file-sync.yml` validates compiled `.lock.yml` files

These jobs are infrastructure glue, not reasoning-heavy agent work.

## Transcript Feedback

The current chain also has an explicit observability loop:

- agent-backed workflows emit `agent` artifacts
- `learning-aggregator-ci` analyzes them weekly
- transcript-only patterns are routed back into `self-improvement-meta`
- promoted rules land in the harness files and workflow prompts
