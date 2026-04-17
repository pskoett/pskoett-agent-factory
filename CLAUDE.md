# Agent Factory Notes

This repository is the source template for the tested GitHub agent factory.

## Core Facts

- The source issue is the unit of work end-to-end.
- Plan files are named from the source issue number: `docs/plans/plan-NNN-<slug>.md`.
- Plan PRs must reference the source issue with `Refs #N`, not closing keywords.
- `plan-merged-dispatcher` writes the implementation checklist back onto the source issue body.
- Only `impl:copilot` auto-routes today.
- `impl:claude-opus`, `impl:claude-sonnet`, and `impl:codex` are manual hand-off labels.
- The workflow-available REST assignment path silently drops Partner Agents, so Claude and Codex remain manual hand-offs.
- Agent-backed workflows upload session transcripts as `agent` artifacts for the learning loop.

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
- Keep operator docs aligned with review self-tamper, `needs-rebase`, and transcript-driven learning behavior.
