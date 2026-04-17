# Copilot Instructions

This repository is the source template for a GitHub agent factory.

## Flow Facts

- The source issue stays open through planning and implementation.
- `spec-refiner` creates a plan PR under `docs/plans/plan-NNN-<slug>.md`.
- `plan-merged-dispatcher` activates the source issue after the plan PR merges.
- `implementer-dispatcher` auto-routes only `impl:copilot`.
- Plan PRs use non-closing source issue references.
- Reviewer applies a self-tamper guard to PRs that touch its own instructions or adjacent guardrails.
- Agent-backed workflows upload `agent` transcript artifacts used by the learning loop.

## Repo Facts

- `workflows/` holds the gh-aw Markdown workflow sources.
- `workflow-support/` holds plain GitHub Actions workflows.
- `skills/` holds vendored skills for installation into target repos.
- `install.sh` is the supported installation path.

## Editing Guidance

- Keep docs and installer behavior aligned with workflow behavior.
- If you add a workflow that needs a label, update `install.sh`.
- If you add a plain Actions workflow or helper script, update both docs and installer copy logic.
- Do not claim auto-routing exists for Claude or Codex. It does not in this factory.
- Keep the docs honest about GitHub Partner Agents: manual UI assignment may work, workflow auto-dispatch does not.
