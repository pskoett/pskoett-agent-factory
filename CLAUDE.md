# Agent Factory Notes

This repository is the source template for the tested GitHub agent factory.

It is still test-derived and not entirely stable yet.

## Core Facts

- The source issue is the unit of work end-to-end.
- `spec-refiner` has three paths: plan-worthy, direct route, or blocked.
- Direct route is only for clearly bounded trivial work. When uncertain, use the plan-worthy path.
- Plan files are named from the source issue number: `docs/plans/plan-NNN-<slug>.md`.
- Plan PRs must reference the source issue with `Refs #N`, not closing keywords.
- `plan-merged-dispatcher` writes the implementation checklist back onto the source issue body.
- `trigger-plan` can activate a source issue when `needs-plan` is applied manually.
- Only `impl:copilot` auto-routes today.
- If a maintainer wants Claude or Codex, that handoff happens outside the automated factory.
- Agent-backed workflows upload session transcripts as `agent` artifacts for the learning loop.
- `factory-health` opens a weekly observability issue for workflow outcomes and stuck-state signals.

## Repo Layout

- `workflows/`: custom gh-aw workflow sources
- `workflow-support/`: plain GitHub Actions support workflows
- `skills/`: skill sources copied into `.claude/skills/` by `install.sh`
- `scripts/check-workflow-lock-sync.sh`: helper used by the lock-sync workflow

## Editing Rules

- Keep the docs, installer, and workflow source files in sync.
- If you change the flow, update `README.md`, `docs/AGENT_FACTORY.md`, `docs/chain.md`, and `AGENTS.md` together.
- Do not reintroduce `/plan` or sub-issue routing.
- Do not reintroduce sequential plan numbering.
- If you add or change workflow files, make sure `install.sh` copies them.
- If the template ships hand-crafted evals under `.evals/`, make sure `install.sh` and the smoke test seed them into installed repos.
- Keep operator docs aligned with review self-tamper, `needs-rebase`, and transcript-driven learning behavior.
- If `learning-aggregator-ci` downloads workflow artifacts, keep `network: defaults` in place.
