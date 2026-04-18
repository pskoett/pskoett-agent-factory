---
name: use-agent-factory
description: |
  How to drive the installed agent factory from a live coding-agent session. Covers when to use the factory versus direct edits, how to start the chain, where the human gates are, how to pick an implementer, how to interpret labels, and how to recover from the common stuck states.

  Use this skill when the user asks you to ship a feature, fix, or refactor through the factory; when they reference an issue or PR already moving through the chain; or when a workflow appears stuck and you need to explain the next operator action.

  Do NOT use this skill for scratch edits that will not go through the factory, read-only research, or tasks the user explicitly wants to bypass the factory.
---

# Use The Agent Factory

## Purpose

This skill is the operator handbook for an installed target repo that uses this template. The factory is issue-first and label-driven. The source issue is the unit of work from start to finish. There is no sub-issue layer.

Use this skill to answer:

- how to start new work through the factory
- which labels mean what
- when to wait for a human gate
- when direct route applies
- how to recover from stuck workflow states

## When to invoke

Activate this skill when any of these are true:

- the user wants to ship a non-trivial change through the factory
- the user references a source issue, plan PR, or implementation PR already in the chain
- the user asks what a factory label means
- the user asks why the chain is stuck or what should happen next
- the user asks you to prepare work so the factory can pick it up correctly

Skip this skill when the work is intentionally bypassing the factory, is purely exploratory, or does not produce a PR to `main`.

## Factory flow

The chain is:

`issue -> needs-spec -> spec-refiner -> plan-worthy OR direct route OR blocked -> plan-merged-dispatcher -> implementer-dispatcher -> PR review -> merge -> learn`

### Path 1: Plan-worthy

Use this for most non-trivial work.

1. Human opens or updates the source issue.
2. Human adds `needs-spec`.
3. `spec-refiner` opens `docs/plans/plan-NNN-<slug>.md` in a plan PR.
4. Human reviews and merges that plan PR.
5. `plan-merged-dispatcher` writes the checklist back onto the source issue and adds `ready-for-implementation`.
6. `implementer-dispatcher` assigns Copilot if the issue has `impl:copilot`.
7. The coding agent opens an implementation PR.

### Path 2: Direct route

Use this only for clearly bounded trivial work.

`spec-refiner` skips the plan PR, assigns Copilot in the same run, and adds:

- `impl:copilot`
- `ready-for-implementation`
- `assigned-to-agent`

### Path 3: Blocked or terminal

If the issue is unclear, duplicated, paused, or needs human input, `spec-refiner` removes `needs-spec`, adds `blocked-on-human`, and leaves a comment explaining the next human action.

## Required setup

Before the factory can work end to end, the target repo needs:

- Actions workflow permissions set to read and write
- GitHub Actions allowed to create pull requests
- Copilot coding agent enabled
- Copilot code review enabled if you want inline review help
- Actions permissions set broadly enough for the factory
- `COPILOT_GITHUB_TOKEN`
- `GH_AW_AGENT_TOKEN`
- the factory label set created by `install.sh`

If the optional Projects board layer is enabled, add the repo-specific `PROJECTS_PAT` secret and its supporting workflows too.

## Routing rules

Only one implementer label auto-routes:

| Label | Meaning |
|-------|---------|
| `impl:copilot` | the only auto-routable implementer |

If a human wants Claude or Codex, do that handoff outside the automated path after the source issue is active.

## Operator moves by label

| Label | What it means | Operator move |
|-------|---------------|---------------|
| `needs-spec` | issue is waiting for spec refinement | wait for `spec-refiner` |
| `needs-plan` | plan PR is open | review and merge the plan PR |
| `ready-for-implementation` | source issue is ready for assignment | wait for `implementer-dispatcher` |
| `assigned-to-agent` | source issue has been dispatched | wait for the implementation PR |
| `ai-reviewed` | reviewer found no blockers | ready for human merge review |
| `fast-track` | reviewer found the PR small and clean | ready for merge |
| `needs-changes` | reviewer found blockers | use `/pr-fix` or push a manual fix |
| `spec-drift` | PR went beyond the plan | decide whether to narrow the PR or expand the plan |
| `needs-rebase` | PR branch is behind `main` | let `conflict-resolver` run |
| `eval-regression` | promoted-learnings regression failed on the PR | inspect the eval result and decide whether to fix before merge |
| `blocked-on-human` | automation is paused | read the latest comment and act on it |
| `human-review` | hard stop | keep automation paused until a human removes the label |

## Common stuck states

### No plan PR appeared after `needs-spec`

Check whether the issue was direct-routed instead. If it now has `assigned-to-agent`, `ready-for-implementation`, and a comment explaining the fast track, that is expected.

If neither a plan PR nor a direct-route comment exists, inspect the failed workflow run and the issue comments for missing setup or `NEEDS HUMAN INPUT`.

### Reviewer did not post a verdict

If the PR is ready for review and still got no verdict, retrigger by toggling draft state or by pushing a new commit.

### PR is behind `main`

Use `needs-rebase`. `conflict-resolver` will attempt a clean merge from `origin/main`. If it cannot, resolve the conflict manually and push.

### `/pr-fix` could not edit the needed file

The source repo version of `/pr-fix` needs an allowlist that covers the real edit surface. If it hits an allowlist failure on root-level docs or harness files, update the workflow source and recompile.

### Lock-file sync failed

A workflow source changed without regenerating its `.lock.yml`.

Run:

```bash
gh aw compile <workflow-name>
```

or:

```bash
gh aw compile
```

Then commit the regenerated lock file alongside the workflow source.

## Plan file lifecycle

Merged plans may be stamped with YAML frontmatter like:

```yaml
---
plan-id: plan-097
status: shipped
shipped-in: "#97"
---
```

Treat non-`active` plans as historical artifacts:

- `active`: current design or open planning artifact
- `shipped`: implemented historical plan
- `superseded`: replaced by a newer plan
- `abandoned`: intentionally not completed

Do not use a `shipped`, `superseded`, or `abandoned` plan as the current source of truth without checking the live code.

## When to bypass the factory

Bypass can make sense for:

- emergency fixes while the factory itself is broken
- edits to the factory that would cause automation loops
- tiny changes the user explicitly wants handled directly

When bypassing, say so clearly and do not pretend the normal chain is running.

## One-line summary

Write a crisp source issue, add `needs-spec`, let the workflows move the issue through planning or direct route, react to labels instead of improvising state changes, and treat plan files plus the source issue as the durable record of the work.
