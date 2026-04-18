# Agent Factory

This repository packages an agent factory pattern extracted from a continuously tested reference implementation and reshaped into a reusable template.

## Status

This template is still evolving. It is **not entirely stable yet**.

Use it as a strong starting point, not as a frozen contract. Workflow prompts, handoff rules, labels, and installer behavior may still change as the flow matures.

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
- [`../.evals`](../.evals) for shipped regression checks and hand-crafted eval cases
- [`../install.sh`](../install.sh) for installation into a target repo

Installed target repo:

- `.github/workflows/*.md` and matching `.lock.yml`
- `.github/workflows/plan-merged-dispatcher.yml`
- `.github/workflows/lock-file-sync.yml`
- `.claude/skills/*/SKILL.md`
- `.evals/EVAL_INDEX.md` and optional `.evals/cases/*.md`
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
git clone <template-repo-url> /tmp/agent-factory-template
/tmp/agent-factory-template/install.sh
```

The installer copies all workflow sources, support workflows, skills, harness files, helper scripts, and any shipped `.evals/` content. It also creates the labels and runs `gh aw compile`.

Installed target repos also receive the operator-facing `.claude/skills/use-agent-factory/SKILL.md` skill from this template's `skills/use-agent-factory/` source.

## First Run

1. Open an issue in the target repo.
2. Add `needs-spec`.
3. `spec-refiner` classifies the issue into one of three paths.

### Path 1: Plan-worthy

This is still the default path for anything non-trivial.

1. `spec-refiner` opens a plan PR under `docs/plans/plan-NNN-<slug>.md`, where `NNN` is the source issue number.
2. The plan PR must reference the source issue with `Refs #NN`. It must not use closing keywords.
3. A human reviews the plan PR.
4. The plan PR merges.
5. `plan-merged-dispatcher` writes the implementation checklist back into the source issue body, adds `ready-for-implementation`, and stamps the merged plan file as `status: shipped` when lifecycle frontmatter is missing.
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

The factory routes to Copilot only.

| Label | Auto-assigned | Meaning |
|-------|---------------|---------|
| `impl:copilot` | Yes | Auto-assign the source issue to the Copilot cloud agent |

`spec-refiner` defaults to `impl:copilot` because that is the only route the factory can currently complete automatically. If a maintainer wants Claude or Codex, do that handoff outside the factory after the source issue is active.

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
| `factory-health` | [`../workflows/factory-health.md`](../workflows/factory-health.md) | Weekly observability report issue |
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
| `impl:copilot` | implementer routing |
| `ai-reviewed`, `needs-changes`, `fast-track`, `spec-drift` | review outcomes |
| `needs-rebase` | triggers conflict resolution |
| `eval-regression` | one or more eval cases failed on the PR; set by `eval-creator-ci` and cleared on the next green run |
| `human-review` | emergency circuit breaker |
| `plan-file`, `ci-fix`, `self-improvement`, `workflow-health` | factory provenance |
| `automation`, `low-risk`, `pr-fix` | routine automation labels |

### Optional Projects-board labels

These labels are **not** created by `install.sh` because the board layer is optional and repo-specific:

| Label | Purpose |
|-------|---------|
| `your-turn` | derived lane marker for items that need human action |
| `agent-working` | activity marker while a factory workflow is actively running |
| `model:<name>` | optional activity label showing the running workflow's `engine.model` |

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

`learning-aggregator-ci` now treats transcript download success and pattern extraction as separate signals. It should verify each `gh run download` with a directory listing, read `agent-stdio.log` from the extracted directory, and report both how many artifacts were actually read and how many new patterns were extracted.

### Weekly Factory Health Report

`factory-health` runs weekly and creates one `[health]` issue with five stable sections:

- workflow run outcomes
- failure categorization
- spec-to-plan handoff latency
- unresolved signals
- human override rate

Use it as an operator dashboard, not as a source of truth. Labels and PR state still drive the factory.

## Optional GitHub Projects Board

Some operators want a board-level view of the factory state. That works well, but it must stay a visualization layer only.

Labels remain authoritative. The board is derived and read-only. Do not drag cards to change state. Change labels and let the board follow.

This template does **not** install board-sync workflows by default because they depend on repo-specific project URLs, field IDs, option IDs, and PAT configuration. Add them only as a project-level customization after installation.

### Suggested lanes

Use the built-in `Status` field with four lanes:

| Status | Meaning |
|--------|---------|
| `Waiting for spec` | new issue or work not yet picked up by the factory |
| `Factory building` | plan or implementation automation is in progress |
| `Your turn` | a human needs to review, unblock, merge, or re-dispatch |
| `Done` | issue or PR is closed |

### Suggested label-to-lane mapping

Evaluate top-down. The first matching rule wins:

| Priority | Condition | Lane |
|----------|-----------|------|
| 1 | item is closed | `Done` |
| 2 | has any of `needs-changes`, `needs-rebase`, `human-review`, `blocked-on-human`, `ai-reviewed`, `plan-file`, `eval-regression` | `Your turn` |
| 3 | is an open draft PR with no stronger signal | `Factory building` |
| 4 | is an open PR with no stronger signal | `Your turn` |
| 5 | has any of `ready-for-implementation`, `assigned-to-agent`, `needs-plan` | `Factory building` |
| 6 | everything else | `Waiting for spec` |

If you implement this board layer, the `your-turn` label can mirror the `Your turn` lane so issue and PR lists can be filtered the same way as the board.

### Optional activity labels

If you add a companion activity tracker workflow, it can apply:

- `agent-working` while at least one factory workflow run is in progress on the item
- `model:<name>` for the running workflow's configured model, such as `model:gpt-5.4`

These labels are useful for visibility, but they are not part of the control plane. The factory should continue to function without them.

### Generic setup model

If you want this board layer in a target repo:

1. Create a GitHub Projects v2 board for the repo owner.
2. Rename the built-in `Status` field options to match the four lanes above.
3. Capture the project URL, the `Status` field ID, and the option IDs for the four lanes.
4. Create a `PROJECTS_PAT` Actions secret with the required Projects scopes. `GITHUB_TOKEN` is not enough for Projects v2 writes.
5. Enable the project's built-in auto-add behavior so new issues and PRs appear on the board automatically.
6. Create the supporting labels `your-turn` and `agent-working`. Let `model:<name>` be created on demand if your implementation supports that.
7. Add plain GitHub Actions workflows for board sync and activity tracking, populated with the repo-specific IDs from step 3.
8. Run an initial reconcile to backfill existing board items.

### Guard rails

- Keep the board one-way. Labels should drive the board, not the reverse.
- Treat project IDs, field IDs, option IDs, and PAT setup as per-repo configuration. Do not hardcode reference values into a shared template.
- If you add a reconcile sweep, have it iterate every board item already on the project rather than only the most recent repo issues or PRs. Old items otherwise keep stale lane values forever.
- Accept that activity tracking may miss very short runs if it relies on polling. That is fine for a visualization layer.
- Keep these workflows out of the default installer unless you are ready to parameterize their repo-specific configuration.

See [`FACTORY_STATE_MACHINE.md`](FACTORY_STATE_MACHINE.md) for the operator-facing quick reference version of this model.

## Operator Notes

- If you change any installed `.github/workflows/*.md` file, re-run `gh aw compile` in the target repo and commit the matching `.lock.yml`.
- If you want to re-dispatch an already assigned issue, remove `assigned-to-agent` if it is present, then re-add `ready-for-implementation`.
- Expect this guide to keep changing while the flow stabilizes further.
