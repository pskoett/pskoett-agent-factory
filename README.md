# Agent Factory Template

An agent factory template for GitHub repositories, built on [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/).

## Status

This repository is still very much an **experimental template**.

It is **not entirely stable yet**. The flow, prompts, labels, and installer behavior are still being adjusted. Treat this repo as an evolving baseline, not a finished production product.

## Current Factory Shape

The source issue is the unit of work from start to finish.

`spec-refiner` now has three paths:

1. **Plan-worthy**: open a plan PR, wait for merge, then dispatch the source issue.
2. **Direct route**: for clearly bounded trivial work, assign Copilot directly without a plan PR.
3. **Blocked or terminal**: hand the issue back to a human with `blocked-on-human`.

Core properties of the current flow:

- Plan files use the source issue number in the filename.
- The implementation checklist is written back onto the source issue after a plan PR merges.
- Trivial issues can go straight to Copilot without a plan PR.
- Non-trivial issues go through a plan PR and human merge gate.
- Only `impl:copilot` can be auto-routed.

Only `impl:copilot` auto-routes today. `impl:claude-opus`, `impl:claude-sonnet`, and `impl:codex` remain useful labels for manual hand-off, but the factory does not auto-assign them.

Recent stabilizations included here:

- `reviewer` auto-labels PRs that are behind `main` with `needs-rebase`
- `reviewer` refuses to self-review PRs that modify its own instructions or adjacent guardrails
- `conflict-resolver` can safely merge workflow-file changes from `main`
- agent-backed workflows emit session transcript artifacts for the outer learning loop
- `learning-aggregator-ci` consumes those transcript artifacts and routes transcript-only patterns back into `self-improvement-meta`

## Repository Layout

This repo is a template source, not a live installed factory:

- [`.github/workflows/`](./.github/workflows) contains source-repo checks for the template itself.
- [`workflows/`](./workflows) contains the custom gh-aw Markdown workflow sources.
- [`workflow-support/`](./workflow-support) contains plain GitHub Actions workflows that the factory needs.
- [`skills/`](./skills) contains the vendored skill sources that `install.sh` copies into `.claude/skills/` in the target repo.
- [`docs/AGENT_FACTORY.md`](./docs/AGENT_FACTORY.md) is the operator guide.
- [`docs/chain.md`](./docs/chain.md) explains the chain and handoffs.
- [`docs/FACTORY_STATE_MACHINE.md`](./docs/FACTORY_STATE_MACHINE.md) is the quick operator reference, including the optional Projects board model.
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
git clone <template-repo-url> /tmp/agent-factory-template
/tmp/agent-factory-template/install.sh
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

## Permanent Verification

This template repo now includes a permanent install smoke test:

- [`scripts/smoke-test-install.sh`](./scripts/smoke-test-install.sh) creates a temporary git repo, installs the template into it, compiles the installed workflows, and verifies lock-file sync.
- [`.github/workflows/template-smoke-test.yml`](./.github/workflows/template-smoke-test.yml) runs that smoke test on pushes to `main` and on pull requests.

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

This template still does **not** auto-install any Projects board sync workflow because those workflows are usually tied to repo-specific Projects v2 IDs, field IDs, and PAT configuration. If you want the same board-style operator view, treat it as an optional project-level customization after installation. The generic setup model is documented in [`docs/AGENT_FACTORY.md`](./docs/AGENT_FACTORY.md) and [`docs/FACTORY_STATE_MACHINE.md`](./docs/FACTORY_STATE_MACHINE.md).

## Skills

The factory depends on these skill sources:

- External skill repository: [pskoett/pskoett-ai-skills](https://github.com/pskoett/pskoett-ai-skills)
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
- Expect this template to change again as the flow continues to evolve.
