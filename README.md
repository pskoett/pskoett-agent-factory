# pskoett-agent-factory

An agent factory template for GitHub repositories, built on [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/).

This repository started as the extracted pattern behind [`pskoett/measuring-ai-proficiency`](https://github.com/pskoett/measuring-ai-proficiency). The flow here now reflects the version that actually held up in testing.

## What Changed After Testing

The factory no longer relies on `/plan` plus sub-issues.

The source issue is now the unit of work from start to finish:

1. `spec-refiner` writes a plan PR whose filename is derived from the source issue number.
2. The plan PR uses a non-closing source issue reference such as `Refs #61`.
3. When that PR merges, `plan-merged-dispatcher` writes the implementation checklist back onto the source issue body.
4. The source issue receives `ready-for-implementation`.
5. `implementer-dispatcher` auto-assigns that same source issue.

The practical consequences are simpler and more reliable:

- No parent-issue lookup.
- No sub-issue fan-out.
- No plan-number race from scanning `docs/plans/`.
- No silent stalls when plan PRs accidentally close the source issue.
- No fake auto-routing for agents that do not have an assignable GitHub user.

Only `impl:copilot` auto-routes today. `impl:claude-opus`, `impl:claude-sonnet`, and `impl:codex` remain useful labels for manual hand-off, but the factory does not auto-assign them.

## Repository Layout

This repo is a template source, not a live installed factory:

- [`workflows/`](./workflows) contains the custom gh-aw Markdown workflow sources.
- [`workflow-support/`](./workflow-support) contains plain GitHub Actions workflows that the factory needs.
- [`skills/`](./skills) contains the vendored skill sources that `install.sh` copies into `.claude/skills/` in the target repo.
- [`docs/AGENT_FACTORY.md`](./docs/AGENT_FACTORY.md) is the operator guide.
- [`docs/chain.md`](./docs/chain.md) explains the design.
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
  v
human reviews and merges the plan PR
  |
  v
plan-merged-dispatcher
  |
  v
implementer-dispatcher
  |
  v
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
- `impl:copilot` is the only label that auto-routes today.
- If you edit a workflow source after installation, re-run `gh aw compile` in the target repo and commit the matching `.lock.yml`.
- The lock-sync guard exists because stale compiled workflow files were a real source of drift during testing.
