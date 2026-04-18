# Factory State Machine

Quick operator reference for the current factory flow.

This page documents the label state machine and the optional GitHub Projects board model. Labels are the control plane. The board, if you add it, is only a visualization layer.

For the layered architecture and design rationale, see [`chain.md`](chain.md). For setup and operating guidance, see [`AGENT_FACTORY.md`](AGENT_FACTORY.md).

## Core label states

These are the main labels that drive the factory:

| Label | Meaning | Set by |
|-------|---------|--------|
| `needs-spec` | issue is ready for spec refinement | human |
| `needs-plan` | plan PR is open and waiting on human review | `spec-refiner` |
| `blocked-on-human` | automation is stopped until a human acts | `spec-refiner`, `conflict-resolver`, other workflows |
| `ready-for-implementation` | source issue is ready for a coding agent | `plan-merged-dispatcher` on the plan-worthy path, `spec-refiner` on the direct route |
| `assigned-to-agent` | source issue has been dispatched to Copilot | `implementer-dispatcher` or `spec-refiner` on the direct route |
| `impl:copilot` | auto-routable implementer label | `spec-refiner` or human |
| `needs-rebase` | PR branch is behind `main` | `reviewer` or human |
| `ai-reviewed` | review passed with no blockers | `reviewer` |
| `needs-changes` | review found blockers or missed criteria | `reviewer` |
| `fast-track` | small PR with zero meaningful findings | `reviewer` |
| `spec-drift` | PR does work the plan did not ask for | `reviewer` |
| `human-review` | circuit breaker that forces workflows to noop | human or `reviewer` self-tamper guard |
| `eval-regression` | one or more eval cases failed on this PR | `eval-creator-ci` |

## Optional Projects-board labels

If you add the optional board-sync layer, these derived labels are useful:

| Label | Meaning | Set by |
|-------|---------|--------|
| `your-turn` | item is in the human-action lane | optional board-sync workflow |
| `agent-working` | at least one factory workflow is actively running | optional activity tracker |
| `model:<name>` | model label for the active run, such as `model:gpt-5.4` | optional activity tracker |

## Optional board lanes

If you add a Projects v2 board, this four-lane model matches the tested flow well:

| Priority | Condition | Lane |
|----------|-----------|------|
| 1 | item is closed | `Done` |
| 2 | has any of `needs-changes`, `needs-rebase`, `human-review`, `blocked-on-human`, `ai-reviewed`, `plan-file`, `eval-regression` | `Your turn` |
| 3 | is an open draft PR with no stronger signal | `Factory building` |
| 4 | is an open PR with no stronger signal | `Your turn` |
| 5 | has any of `ready-for-implementation`, `assigned-to-agent`, `needs-plan` | `Factory building` |
| 6 | everything else | `Waiting for spec` |

This is intentionally label-derived. Do not use the board as the source of truth.

## Workflow trigger table

| Workflow | Trigger | Primary effect |
|----------|---------|----------------|
| `issue-triage` | issue opened or reopened | initial labels and analysis comment |
| `spec-refiner` | issue labeled `needs-spec` | opens a plan PR, direct-routes trivial work, or blocks for human input |
| `plan-merged-dispatcher` | merged plan PR | writes the checklist back to the source issue and adds `ready-for-implementation` |
| `implementer-dispatcher` | issue labeled `ready-for-implementation` | assigns Copilot when `impl:copilot` is present |
| `reviewer` | PR opened or updated | plan-aware review, behind-main detection, verdict labels |
| `conflict-resolver` | PR labeled `needs-rebase` | merges `origin/main` when clean or blocks for human help |
| `contribution-checker` | PR opened or updated | checks process and contribution alignment |
| `simplify-and-harden-ci` | PR opened or updated | scan-only simplicity and security review |
| `eval-creator-ci` | PR opened or updated | regression verification against promoted learnings; adds `eval-regression` on failures and clears it on the next green run |
| `pr-fix` | `/pr-fix` comment | pushes repair commits to the PR branch |
| `ci-cleaner` | CI failure on `main` | opens a fix PR for mainline breakage |
| `factory-health` | weekly | creates one `[health]` issue with workflow outcomes, failure types, handoff latency, unresolved signals, and override rate |
| `self-improvement-meta` | nightly | promotes durable learnings into harness files and workflows |
| `learning-aggregator-ci` | weekly | analyzes learnings and transcript artifacts for patterns |
| `lock-file-sync` | PR touches workflow sources or lock files | fails on stale compiled workflow locks |

Optional project-level additions:

| Workflow | Trigger | Primary effect |
|----------|---------|----------------|
| board sync | issue or PR label/state changes, plus reconcile schedule | mirrors labels onto a Projects v2 `Status` field, routes draft PRs to `Factory building`, can apply `your-turn`, and should reconcile every board item instead of only recent repo items |
| activity tracker | periodic schedule | applies or removes `agent-working` and `model:<name>` |

## Happy path

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
  |     +--> plan PR under docs/plans/plan-NNN-<slug>.md
  |     +--> human reviews and merges
  |     +--> plan-merged-dispatcher writes checklist onto source issue
  |     +--> ready-for-implementation
  |     +--> implementer-dispatcher assigns Copilot
  |
  +--> direct route
  |     |
  |     +--> no plan PR
  |     +--> spec-refiner assigns Copilot directly
  |
  +--> blocked or terminal
        |
        +--> blocked-on-human

PR opened
  |
  +--> reviewer
  +--> contribution-checker
  +--> simplify-and-harden-ci
  +--> eval-creator-ci
  |
  +--> conflict-resolver when labeled needs-rebase
  |
  v
human merges implementation PR
```

## Quick answers

| Question | Answer |
|----------|--------|
| What starts planning? | Add `needs-spec` to the source issue. |
| What starts implementation? | `ready-for-implementation` on the source issue. |
| What is auto-routable? | Only `impl:copilot`. |
| How do I stop the chain? | Add `human-review` to the issue or PR. |
| How do I re-dispatch a source issue? | Remove `assigned-to-agent` if present, then re-add `ready-for-implementation`. |
| Is the Projects board required? | No. It is an optional visualization layer, not a factory requirement. |
