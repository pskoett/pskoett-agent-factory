# pskoett-agent-factory

An agent factory template for GitHub repositories, built on [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/).

## Status

This repository is still very much a **test project template** extracted from [`pskoett/measuring-ai-proficiency`](https://github.com/pskoett/measuring-ai-proficiency).

It is **not entirely stable yet**. The flow, prompts, labels, and installer behavior are still being adjusted as the test factory keeps changing. Treat this repo as an evolving baseline, not a finished production product.

## Current Factory Shape

The source issue is the unit of work from start to finish. The factory no longer relies on `/plan` plus sub-issues.

`spec-refiner` now has three paths:

1. **Plan-worthy**: open a plan PR, wait for merge, then dispatch the source issue.
2. **Direct route**: for clearly bounded trivial work, assign Copilot directly without a plan PR.
3. **Blocked or terminal**: hand the issue back to a human with `blocked-on-human`.

The practical consequences are simpler and more reliable:

- No parent-issue lookup.
- No sub-issue fan-out.
- No plan-number race from scanning `docs/plans/`.
- No silent stalls when plan PRs accidentally close the source issue.
- No fake auto-routing for agents that do not have an assignable GitHub user.

Only `impl:copilot` auto-routes today. `impl:claude-opus`, `impl:claude-sonnet`, and `impl:codex` remain useful labels for manual hand-off, but the factory does not auto-assign them.

Recent stabilizations pulled from the test project:

- `reviewer` auto-labels PRs that are behind `main` with `needs-rebase`
- `reviewer` refuses to self-review PRs that modify its own instructions or adjacent guardrails
- `conflict-resolver` can safely merge workflow-file changes from `main`
- agent-backed workflows emit session transcript artifacts for the outer learning loop
- `learning-aggregator-ci` consumes those transcript artifacts and routes transcript-only patterns back into `self-improvement-meta`

## Repository Layout

This repo is a template source, not a live installed factory:

- [`workflows/`](./workflows) contains the custom gh-aw Markdown workflow sources.
- [`workflow-support/`](./workflow-support) contains plain GitHub Actions workflows that the factory needs.
- [`skills/`](./skills) contains the vendored skill sources that `install.sh` copies into `.claude/skills/` in the target repo.
- [`docs/AGENT_FACTORY.md`](./docs/AGENT_FACTORY.md) is the operator guide.
- [`docs/chain.md`](./docs/chain.md) explains the chain and handoffs.
- [`install.sh`](./install.sh) installs the factory into another repository.

## Factory Chain

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
  |     human reviews and merges
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
  |     Copilot assigned in the same run
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
  +---> conflict-resolver (when PR is labeled needs-rebase)
  |
  v
pr-fix / ci-cleaner / self-improvement-meta
```

## Installing Into A Target Repo

From the target repository:

```bash
git clone https://github.com/pskoett/pskoett-agent-factory.git /tmp/pskoett-agent-factory
/tmp/pskoett-agent-factory/install.sh
```

The installer:

- copies `workflows/*.md` into `.github/workflows/`
- copies `workflow-support/*.yml` into `.github/workflows/`
- copies the lock-sync helper script into `scripts/`
- vendors skills into `.claude/skills/`
- copies `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` when missing
- seeds `.learnings/` and `docs/plans/`
- creates the labels used by the factory
- runs `gh aw compile`

The full setup checklist, required secrets, and label reference live in [`docs/AGENT_FACTORY.md`](./docs/AGENT_FACTORY.md).

## Included Workflows

Custom gh-aw sources in this repo:

- [`workflows/spec-refiner.md`](./workflows/spec-refiner.md)
- [`workflows/implementer-dispatcher.md`](./workflows/implementer-dispatcher.md)
- [`workflows/reviewer.md`](./workflows/reviewer.md)
- [`workflows/conflict-resolver.md`](./workflows/conflict-resolver.md)
- [`workflows/contribution-checker.md`](./workflows/contribution-checker.md)
- [`workflows/ci-cleaner.md`](./workflows/ci-cleaner.md)
- [`workflows/self-improvement-meta.md`](./workflows/self-improvement-meta.md)
- [`workflows/simplify-and-harden-ci.md`](./workflows/simplify-and-harden-ci.md)
- [`workflows/learning-aggregator-ci.md`](./workflows/learning-aggregator-ci.md)
- [`workflows/eval-creator-ci.md`](./workflows/eval-creator-ci.md)
- [`workflows/issue-triage.md`](./workflows/issue-triage.md)
- [`workflows/pr-fix.md`](./workflows/pr-fix.md)

Plain GitHub Actions support workflows:

- [`workflow-support/plan-merged-dispatcher.yml`](./workflow-support/plan-merged-dispatcher.yml)
- [`workflow-support/lock-file-sync.yml`](./workflow-support/lock-file-sync.yml)

The current template still does **not** auto-install the Projects board sync workflow from `measuring-ai-proficiency` because that workflow is tied to repo-specific Projects v2 IDs and PAT configuration. Port it only as a project-specific customization after installation.

## Skills

The factory depends on these skill sources:

- [`skills/plan-interview`](./skills/plan-interview/SKILL.md)
- [`skills/self-improvement`](./skills/self-improvement/SKILL.md)
- [`skills/intent-framed-agent`](./skills/intent-framed-agent/SKILL.md)
- [`skills/simplify-and-harden`](./skills/simplify-and-harden/SKILL.md)
- [`skills/learning-aggregator`](./skills/learning-aggregator/SKILL.md)
- [`skills/eval-creator`](./skills/eval-creator/SKILL.md)
- [`skills/context-surfing`](./skills/context-surfing/SKILL.md)
- [`skills/verify-gate`](./skills/verify-gate/SKILL.md)
- [`skills/pre-flight-check`](./skills/pre-flight-check/SKILL.md)

## Notes

- Plan filenames use the source issue number, not a sequential scan.
- Plan PRs must not close the source issue.
- Direct route is only for clearly bounded trivial work. When uncertain, bias toward a plan PR.
- `impl:copilot` is the only label that auto-routes today.
- If you edit a workflow source after installation, re-run `gh aw compile` in the target repo and commit the matching `.lock.yml`.
- The lock-sync guard exists because stale compiled workflow files were a real source of drift during testing.
- Expect this template to change again as the test project keeps evolving.
