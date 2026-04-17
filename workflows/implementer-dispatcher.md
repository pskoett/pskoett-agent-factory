---
on:
  issues:
    types: [labeled]
  workflow_dispatch:
if: github.event.label.name == 'ready-for-implementation' || github.event_name == 'workflow_dispatch'
timeout-minutes: 5
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  issues: read
tools:
  github:
    toolsets: [issues, repos]
safe-outputs:
  assign-to-agent:
    target-repo: ${{ github.repository }}
  add-comment:
    max: 1
  add-labels:
    allowed: [assigned-to-agent]
    max: 1
---

# Implementer Dispatcher

You auto-assign issues to the Copilot cloud agent based on the issue's implementer label. The `ready-for-implementation` label is applied directly to the source issue by `plan-merged-dispatcher` after the plan PR merges. There is no sub-issue layer.

## Routing model

Only `impl:copilot` auto-routes. The other `impl:*` labels exist as signals for humans who want to hand-assign via the GitHub UI, but the factory cannot dispatch them from a workflow.

Why: the GitHub REST API path available to workflows accepts Copilot as a valid assignee but silently drops Partner Agents such as Claude and Codex. The UI assignees picker uses a different backend path. Until GitHub exposes proper API-based assignment for Partner Agents, keep the other labels as manual hand-off signals.

## Process

### Step 1: Read the implementer label from this issue

- `impl:copilot`: continue to Step 2.
- `impl:claude-opus`, `impl:claude-sonnet`, `impl:codex`: call `noop` with a comment explaining that only `impl:copilot` auto-routes today and Partner Agents must be assigned manually in the GitHub UI.
- No implementer label: default to `impl:copilot` and note that in the comment.

### Step 2: Assign the issue

Use `assign-to-agent` to assign this issue to the Copilot cloud agent. Add the `assigned-to-agent` label. Post a brief comment: `Assigned to Copilot cloud agent based on label impl:copilot.`

## Noop conditions

Call `noop` if:

- The issue is labeled `human-review`
- The issue already has the `assigned-to-agent` label
- The issue uses a non-Copilot implementer label

## Style

Follow the writing rules in `AGENTS.md`. One-line comments. No filler.

## Session capture

This workflow's full session is automatically captured in the `agent` artifact for this run. The artifact includes the prompt, all tool calls, tool outputs, and token usage. `learning-aggregator-ci` analyzes these artifacts weekly for outer-loop improvement patterns.
