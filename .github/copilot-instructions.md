# Copilot Instructions

This repository is the source template for a GitHub agent factory.

It is still test-derived and not entirely stable yet.

## Flow Facts

- The source issue stays open through planning and implementation.
- `spec-refiner` classifies issues into a plan-worthy path, a direct route, or a blocked path.
- Direct route is only for clearly bounded trivial work. When uncertain, use the plan-worthy path.
- `spec-refiner` creates a plan PR under `docs/plans/plan-NNN-<slug>.md` for plan-worthy issues.
- `plan-merged-dispatcher` activates the source issue after the plan PR merges.
- `implementer-dispatcher` auto-routes only `impl:copilot`.
- If a maintainer wants Claude or Codex, that handoff happens outside the automated factory.
- Plan PRs use non-closing source issue references.
- Reviewer applies a self-tamper guard to PRs that touch its own instructions or adjacent guardrails.
- `factory-health` opens a weekly observability issue for workflow outcomes and stuck-state signals.
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
- Do not claim factory auto-routing exists for Claude or Codex. It does not in this template.
- If the template ships hand-crafted evals under `.evals/`, make sure the installer and smoke test copy them too.
