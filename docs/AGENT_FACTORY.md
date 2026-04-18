# Agent Factory

This repository packages the agent factory pattern extracted from `measuring-ai-proficiency` and reshaped into a reusable template.

## Status

This template is still derived from an actively changing test factory. It is **not entirely stable yet**.

Use it as a strong starting point, not as a frozen contract. Workflow prompts, handoff rules, labels, and installer behavior may still change when the test project discovers a better flow.

## End-To-End Chain

```text
issue opened
  |
  v
issue-triage
  |
  v
human adds "needs-spec"
  |
  v
spec-refiner
  |
  +---> plan-worthy
  |       |
  |       v
  |     plan PR
  |       |
  |       v
  |     human reviews and merges the plan PR
  |       |
  |       v
  |     plan-merged-dispatcher
  |       |
  |       v
  |     implementer-dispatcher
  |
  +---> direct route
  |       |
  |       v
  |     Copilot assigned directly in the same run
  |
  +---> blocked or terminal
          |
          v
        blocked-on-human

PR opened
  |
  +---> reviewer
  +---> contribution-checker
  +---> simplify-and-harden-ci
  +---> eval-creator-ci
  |
  +---> conflict-resolver when labeled needs-rebase
  |
  v
pr-fix / ci-cleaner / self-improvement-meta
```

The source issue is still the unit of work end-to-end. There is no `/plan` fan-out and no sub-issue layer.

## Why The Flow Changed

The older flow used `/plan` plus sub-issues. In practice that introduced avoidable failure modes:

- source issues could be closed accidentally by plan PRs
- sequential plan numbering raced under parallel use
- parent-issue discovery was fragile
- auto-routing implied capabilities the platform did not actually provide

The current flow fixes those problems:

- plan filenames derive from the source issue number
- plan PRs reference the source issue with `Refs #N`, not `Fixes #N`
- merged plans write their checklist back onto the source issue body
- trivial issues can skip the plan PR when they are clearly bounded
- the source issue itself gets routed or blocked directly
- only `impl:copilot` is auto-routed
- reviewer marks PRs that are behind `main` with `needs-rebase`
- reviewer refuses to self-review PRs that modify its own instructions or adjacent guardrails
- the outer loop can inspect session transcripts through uploaded `agent` artifacts

## Repository Structure

This repo is the template source. The installed repo layout is different.

Template source here:

- [`../workflows`](../workflows) for custom gh-aw Markdown workflows
- [`../workflow-support`](../workflow-support) for plain GitHub Actions support workflows
- [`../skills`](../skills) for vendored skill sources
- [`../install.sh`](../install.sh) for installation into a target repo

Installed target repo:

- `.github/workflows/*.md` and matching `.lock.yml`
- `.github/workflows/plan-merged-dispatcher.yml`
- `.github/workflows/lock-file-sync.yml`
- `.claude/skills/*/SKILL.md`
- `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`

## Prerequisites

### Local tooling

- [GitHub CLI](https://cli.github.com/) installed and authenticated
- [gh-aw extension](https://github.com/github/gh-aw): `gh extension install github/gh-aw`
- Git 2.40+

### Repository settings

Apply these in the target repository:

| Setting | Value | Why |
|---------|-------|-----|
| Workflow permissions | Read and write permissions | Workflows need to open PRs, edit issues, move labels, and push fixes |
| Allow PR creation | Enabled | `ci-cleaner` and `self-improvement-meta` open PRs |
| Copilot cloud agent | Enabled | Required for `impl:copilot` routing |
| Copilot code review | Enabled | Useful for inline review on PRs |
| Partner Agents | Optional | Enables manual UI assignment of Claude or Codex, but not workflow auto-dispatch |
| Actions permissions | Allow all actions and reusable workflows | Needed for the full factory chain |

### Secrets

Set these in the target repository when you install the factory:

| Secret | Why |
|--------|-----|
| `COPILOT_GITHUB_TOKEN` | gh-aw runtime auth |
| `GH_AW_AGENT_TOKEN` | issue assignment for Copilot and label cascades from `plan-merged-dispatcher` |

`plan-merged-dispatcher` must use a PAT such as `GH_AW_AGENT_TOKEN`, not the default `GITHUB_TOKEN`, because label events emitted by `GITHUB_TOKEN` do not trigger downstream workflows.

## Installation

From the target repository:

```bash
git clone https://github.com/pskoett/pskoett-agent-factory.git /tmp/pskoett-agent-factory
/tmp/pskoett-agent-factory/install.sh
```

The installer copies all workflow sources, support workflows, skills, harness files, and helper scripts. It also creates the labels and runs `gh aw compile`.

## First Run

1. Open an issue in the target repo.
2. Add `needs-spec`.
3. `spec-refiner` classifies the issue into one of three paths.

### Path 1: Plan-worthy

This is still the default path for anything non-trivial.

1. `spec-refiner` opens a plan PR under `docs/plans/plan-NNN-<slug>.md`, where `NNN` is the source issue number.
2. The plan PR must reference the source issue with `Refs #NN`. It must not use closing keywords.
3. A human reviews the plan PR and may swap the implementer label before merge.
4. The plan PR merges.
5. `plan-merged-dispatcher` writes the implementation checklist back into the source issue body and adds `ready-for-implementation`.
6. `implementer-dispatcher` auto-assigns the source issue if it carries `impl:copilot`.

### Path 2: Direct route

This path exists for clearly bounded trivial work only.

Use it only when **all** of these are true:

- the change is small and obvious
- the acceptance criteria are fully specified in the issue
- no design decision is needed
- an implementer can start immediately without a plan

On this path, `spec-refiner`:

- skips the plan file
- removes `needs-spec`
- adds `impl:copilot`, `ready-for-implementation`, and `assigned-to-agent`
- assigns the Copilot cloud agent in the same run
- leaves a short issue comment explaining the fast-track decision

When uncertain, bias toward the plan-worthy path.

### Path 3: Blocked or terminal

This path covers:

- issues already labeled `human-review`
- issues that already have a linked plan
- spam or duplicates
- issues that need human input before any automation can proceed

On this path, `spec-refiner` removes `needs-spec`, adds `blocked-on-human`, and posts a comment explaining what a human must do next.

## Implementer Routing

The factory keeps the old labels, but not all of them can be auto-routed.

| Label | Auto-assigned | Meaning |
|-------|---------------|---------|
| `impl:copilot` | Yes | Auto-assign the source issue to the Copilot cloud agent |
| `impl:claude-opus` | No | Manual hand-off outside the factory |
| `impl:claude-sonnet` | No | Manual hand-off outside the factory |
| `impl:codex` | No | Manual hand-off outside the factory |

`spec-refiner` defaults to `impl:copilot` because that is the only route the factory can currently complete automatically. Claude and Codex may appear in the GitHub UI assignees picker, but the workflow-available REST path does not reliably assign them.

## Workflow Inventory

Custom gh-aw workflow sources in this repo:

| Workflow | File | Trigger |
|----------|------|---------|
| `spec-refiner` | [`../workflows/spec-refiner.md`](../workflows/spec-refiner.md) | Issue labeled `needs-spec` |
| `implementer-dispatcher` | [`../workflows/implementer-dispatcher.md`](../workflows/implementer-dispatcher.md) | Issue labeled `ready-for-implementation` |
| `reviewer` | [`../workflows/reviewer.md`](../workflows/reviewer.md) | PR opened or updated |
| `conflict-resolver` | [`../workflows/conflict-resolver.md`](../workflows/conflict-resolver.md) | PR labeled `needs-rebase` |
| `contribution-checker` | [`../workflows/contribution-checker.md`](../workflows/contribution-checker.md) | PR opened or updated |
| `ci-cleaner` | [`../workflows/ci-cleaner.md`](../workflows/ci-cleaner.md) | CI failure on `main` |
| `self-improvement-meta` | [`../workflows/self-improvement-meta.md`](../workflows/self-improvement-meta.md) | Nightly |
| `simplify-and-harden-ci` | [`../workflows/simplify-and-harden-ci.md`](../workflows/simplify-and-harden-ci.md) | PR opened or updated |
| `learning-aggregator-ci` | [`../workflows/learning-aggregator-ci.md`](../workflows/learning-aggregator-ci.md) | Weekly |
| `eval-creator-ci` | [`../workflows/eval-creator-ci.md`](../workflows/eval-creator-ci.md) | PR opened or updated |
| `issue-triage` | [`../workflows/issue-triage.md`](../workflows/issue-triage.md) | Issue opened or reopened |
| `pr-fix` | [`../workflows/pr-fix.md`](../workflows/pr-fix.md) | `/pr-fix` comment |

Plain GitHub Actions support workflows:

| Workflow | File | Trigger |
|----------|------|---------|
| `plan-merged-dispatcher` | [`../workflow-support/plan-merged-dispatcher.yml`](../workflow-support/plan-merged-dispatcher.yml) | Merged plan PR touching `docs/plans/plan-*.md` |
| `lock-file-sync` | [`../workflow-support/lock-file-sync.yml`](../workflow-support/lock-file-sync.yml) | PR touching workflow sources or lock files |

## Labels

These labels are created by `install.sh` because the workflows rely on them:

| Label | Purpose |
|-------|---------|
| `needs-spec`, `needs-plan`, `spec-refined` | spec refinement handoff |
| `blocked-on-human` | explicit stop that requires human input |
| `ready-for-implementation`, `assigned-to-agent` | implementation dispatch |
| `impl:claude-opus`, `impl:claude-sonnet`, `impl:copilot`, `impl:codex` | implementer routing |
| `ai-reviewed`, `needs-changes`, `fast-track`, `spec-drift` | review outcomes |
| `needs-rebase` | triggers conflict resolution |
| `human-review` | emergency circuit breaker |
| `plan-file`, `ci-fix`, `self-improvement`, `workflow-health` | factory provenance |
| `automation`, `low-risk`, `pr-fix` | routine automation labels |

## New Guardrails

### Reviewer Self-Tamper Guard

`reviewer` noops and applies `human-review` if a PR modifies:

- `.github/workflows/reviewer.md`
- `.github/workflows/self-improvement-meta.md`
- `.github/copilot-instructions.md`

That rule exists because those files can directly alter the reviewer's own behavior or adjacent safety rails.

### Behind-Main Detection

`reviewer` checks `mergeStateStatus` early. If the PR is `BEHIND`, it applies `needs-rebase` and continues the review. `conflict-resolver` then handles the clean merge path from `origin/main`.

### Transcript-Driven Learning Loop

Agent-backed workflows upload an `agent` artifact that contains the session transcript, tool outputs, and token usage. `learning-aggregator-ci` analyzes those artifacts weekly, then routes transcript-only patterns back into `self-improvement-meta` using `**TRANSCRIPT CANDIDATE**` markers.

### Project-Specific Optional Feature

`measuring-ai-proficiency` also has a Projects v2 status sync workflow. It is intentionally not auto-installed by this template because it depends on repo-specific project IDs and PAT scopes. Treat that as a project-level customization, not a factory default.

## Operator Notes

- If you change any installed `.github/workflows/*.md` file, re-run `gh aw compile` in the target repo and commit the matching `.lock.yml`.
- If you want to re-dispatch an already assigned issue, remove both `assigned-to-agent` and `ready-for-implementation`, then re-add `ready-for-implementation`.
- If you want Claude or Codex to implement the issue, swap the `impl:*` label after reviewing the plan PR and hand the issue off manually.
- Expect this guide to keep changing while the test factory stabilizes further.
