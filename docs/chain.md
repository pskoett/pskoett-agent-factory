# Factory Chain

This diagram reflects the current tested agent-factory flow behind this template.

It is still evolving. Treat it as the latest known working model, not a permanent contract.

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
|  factory-health.md                                           |
|  conflict-resolver.md      contribution-checker.md          |
|  issue-triage.md           pr-fix.md                        |
|  plan-merged-dispatcher.yml trigger-plan.yml                |
|  lock-file-sync.yml                                         |
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
|  pre-flight-check/     use-agent-factory/                   |
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
  +--> plan-worthy
  |     |
  |     | writes docs/plans/plan-NNN-<slug>.md
  |     | where NNN is the source issue number
  |     | adds impl:copilot and needs-plan
  |     v
  |   human reviews and merges the plan PR
  |     |
  |     v
  |   plan-merged-dispatcher
  |     |
  |     | extracts the Implementation Checklist
  |     | writes it into the source issue body
  |     | removes needs-plan
  |     | adds ready-for-implementation
  |     v
  |   implementer-dispatcher
  |     |
  |     | reads impl:* on the source issue
  |     | auto-assigns only impl:copilot
  |     v
  |   coding agent opens PR
  |
  +--> direct route
  |     |
  |     | skips the plan PR
  |     | adds impl:copilot
  |     | adds ready-for-implementation and assigned-to-agent
  |     | assigns Copilot in the same run
  |     v
  |   coding agent opens PR
  |
  +--> blocked or terminal
        |
        | removes needs-spec
        | adds blocked-on-human
        | posts a human handoff comment
        v
      human action required

PR opened
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
  factory-health
  ci-cleaner
```

## Routing Model

The factory uses one routing label inside the automated path:

| Label | Behavior |
|-------|----------|
| `impl:copilot` | auto-assigned by `implementer-dispatcher` or directly by `spec-refiner` on the direct route |

That change matters. The old design implied that all implementer labels were equal. In practice they were not. `assign-to-agent` can target the Copilot cloud agent because it is a real GitHub account on the workflow-available assignment path. If a maintainer wants Claude or Codex, that handoff happens outside the automated factory.

## Why There Is No `/plan`

The older `/plan` plus sub-issue layer looked elegant on paper and failed in the messy parts:

- parent lookups were brittle
- plan numbering raced
- PR closure semantics caused accidental source-issue closure
- sub-issue assignment added another state machine to debug

The source-issue-centric model is less clever and more reliable.

## Why Direct Route Exists

Not every issue deserves a plan PR.

For clearly bounded trivial work, the extra plan handoff adds delay without adding much signal. The direct route exists to keep the simple path simple while preserving the plan-first path for ambiguous or risky work.

The rule is conservative on purpose: when uncertain, choose the plan-worthy path.

There is also an intentional skip-spec operator shortcut. Labeling an issue `needs-plan` directly can activate it through `trigger-plan.yml`, which restores the same `ready-for-implementation` handoff the normal path would produce.

## Why The Plain Actions Workflows Exist

Two parts of the tested flow are better as plain GitHub Actions:

- `plan-merged-dispatcher.yml` reacts to merge events and edits issue bodies
- `trigger-plan.yml` handles direct `needs-plan` activation and merged-plan recovery
- `factory-smoke.yml` gives operators a manual environment-level smoke run
- `lock-file-sync.yml` validates compiled `.lock.yml` files

These jobs are infrastructure glue, not reasoning-heavy agent work.

## Optional Projects View

Some installations also add a GitHub Projects v2 board as a read-only visualization layer on top of the label state machine.

That board is optional and is **not** installed by this template by default. The factory still runs entirely from labels, PRs, comments, and plan files. If you add the board later, keep labels authoritative and let the board derive from them.

See [`AGENT_FACTORY.md`](AGENT_FACTORY.md) for the generic setup model and [`FACTORY_STATE_MACHINE.md`](FACTORY_STATE_MACHINE.md) for the label-to-lane reference.

## Operator Skill

Installed target repos can also vendor a `use-agent-factory` skill into `.claude/skills/`. That skill is the operator-facing handbook for starting work through the factory, interpreting labels, and recovering from stuck states without reverse-engineering the workflows every time.

## Transcript Feedback

The current chain also has an explicit observability loop:

- agent-backed workflows emit `agent` artifacts
- `learning-aggregator-ci` analyzes them weekly
- `factory-health` opens one weekly `[health]` issue for operator visibility
- transcript-only patterns are routed back into `self-improvement-meta`
- promoted rules land in the harness files and workflow prompts

## Stability Note

This template is still evolving. The diagrams and handoff rules here are accurate to the latest sync, but more changes are likely before the factory can be called stable.
