# Agents

This file defines the shared context for agents working on `pskoett-agent-factory`.

This repository is a **template source** for a GitHub agent factory. It is not the installed runtime layout. The canonical template files live here and are copied into a target repository by `install.sh`.

## Repository Purpose

This repo packages a tested agent-factory pattern built on [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/).

The tested flow is:

1. Triage the issue.
2. Refine a spec into a plan PR.
3. Merge the plan PR.
4. Activate the source issue directly.
5. Dispatch the source issue to an implementer.
6. Review the implementation PR.
7. Learn from failures and harden the system.

The source issue is the unit of work end-to-end. There is no `/plan` fan-out and no sub-issue layer.

## Source Layout

When editing this repository, use these paths:

- `workflows/*.md`: custom gh-aw workflow sources
- `workflow-support/*.yml`: plain GitHub Actions support workflows
- `skills/*/SKILL.md`: skill sources copied into `.claude/skills/` in installed repos
- `scripts/check-workflow-lock-sync.sh`: helper used by the lock-sync workflow
- `install.sh`: installs the factory into a target repository
- `README.md`, `docs/AGENT_FACTORY.md`, `docs/chain.md`: operator-facing documentation
- `CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md`: harness files updated by the learning loop

## Agent Roles

### Workflow Maintainer

**Purpose:** Maintain and improve the factory flow itself.

**Key behaviors:**
- Keep workflow behavior, installer behavior, and documentation aligned.
- Prefer simple, debuggable state transitions over clever choreography.
- Do not document automation the factory cannot actually complete.
- When adding workflow labels, update `install.sh`.

### Skill Maintainer

**Purpose:** Maintain the reusable skills that the workflows depend on.

**Key behaviors:**
- Keep skills self-contained and explicit.
- Prefer instructions that survive single-shot gh-aw runs.
- If a workflow references a skill, ensure the source exists under `skills/`.
- Update docs when a skill changes the flow semantics.

### Reviewer

**Purpose:** Review changes for correctness and internal consistency.

**Key behaviors:**
- Check that docs, workflows, support workflows, and installer match.
- Check that plan naming and handoff semantics remain consistent.
- Check that labels and copied files in `install.sh` cover the changed workflow set.
- Check that obsolete flow references do not remain in docs or prompts.

## Core Rules

1. **Do not reintroduce `/plan` or sub-issue routing.**
2. **Do not reintroduce sequential plan numbering.**
3. **Plan PRs must reference the source issue with `Refs #N`, not a closing keyword.**
4. **Only `impl:copilot` auto-routes today.** `impl:claude-opus`, `impl:claude-sonnet`, and `impl:codex` are manual hand-off labels because the workflow-available REST API path silently drops Partner Agent assignees.
5. **Keep the harness files aligned.** When a durable rule changes, update `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
6. **Keep the installer aligned with the file layout.** If you add or rename workflows, support files, scripts, or labels, update `install.sh`.
7. **Keep the docs aligned with the actual flow.** At minimum, update `README.md`, `docs/AGENT_FACTORY.md`, and `docs/chain.md` together when the flow changes.

## Skills

The canonical skill sources in this repository live under `skills/`. In an installed target repo, `install.sh` copies them into `.claude/skills/`.

Available skills in this source repo:

- `skills/plan-interview/`: structured requirements interview before planning
- `skills/self-improvement/`: learning capture and promotion rules
- `skills/intent-framed-agent/`: intent framing and drift checks
- `skills/context-surfing/`: context hygiene discipline
- `skills/simplify-and-harden/`: post-completion quality and security sweep
- `skills/verify-gate/`: verification discipline before completion
- `skills/eval-creator/`: regression checks derived from promoted learnings
- `skills/learning-aggregator/`: cross-session pattern analysis
- `skills/pre-flight-check/`: session-start scan of relevant learnings and eval status

When a workflow tells you to use a skill, read the installed path it will use in the target repo, usually `.claude/skills/<name>/SKILL.md`. When working on this source repo, edit the canonical file under `skills/<name>/SKILL.md`.

## Adapting Skills For gh-aw

gh-aw runs are single-shot and ephemeral. When a skill assumes interactivity or cross-turn memory, adapt it explicitly:

1. **Interview-style skills:** answer from issue and repo context when possible. Mark any unresolved point with `**NEEDS HUMAN INPUT**`.
2. **Hook-based skills:** apply their checks at natural boundaries such as after planning, after major tool calls, and before exit.
3. **Session-state skills:** run them as manual self-checks because gh-aw cannot preserve live session state.
4. **Script-bundled skills:** allowlist any required commands in the workflow frontmatter.

## Writing Style

These rules apply to agent-authored comments, issues, PR bodies, and commit messages in this repository:

- No em-dashes or double dashes.
- No throat-clearing openings.
- Short declarative sentences.
- State the answer first.
- Prefer concrete evidence over generalization.

## Plan Files

Plans live in `docs/plans/plan-NNN-<slug>.md`.

`NNN` is the **source issue number**, zero-padded to at least three digits:

- issue `#7` -> `plan-007-...`
- issue `#61` -> `plan-061-...`
- issue `#1042` -> `plan-1042-...`

Do not scan `docs/plans/` for the next sequential number.

## Learnings

Learnings live in `.learnings/LEARNINGS.md` and follow this structure:

```markdown
## [LRN-NNN] Short title

**Status**: pending | promoted_to_skill | regressed
**Priority**: low | medium | high
**Area**: backend | frontend | infra | ci | docs | process
**Pattern-Key**: <stable-dedupe-key>
**Discovered**: YYYY-MM-DD via <workflow-run-url>

### What went wrong
[One paragraph]

### Root cause
[One paragraph]

### Prevention rule
[One short, checkable rule written in the imperative]

### See also
- LRN-XXX
```

Never log secrets or raw confidential output. Prefer short summaries over pasted logs.

When a learning is promoted, write it to:

1. `AGENTS.md`
2. `CLAUDE.md`
3. `.github/copilot-instructions.md`

Add it to a workflow body too when the rule is workflow-specific.

Every agent-backed workflow run also uploads an `agent` artifact containing the session transcript, tool outputs, and token usage. `learning-aggregator-ci` consumes these artifacts weekly to surface transcript-derived patterns that are not yet captured in `.learnings/`.

## Routing Guidance

The factory retains multiple implementer labels, but platform reality matters more than theory.

### Auto-routable

**Copilot cloud agent**
- Only auto-routable implementer in this factory
- Selected via `impl:copilot`
- Dispatched by `implementer-dispatcher`
- Works because the available workflow assignment path supports Copilot

### Manual labels

**Claude Opus 4.6**
- Use when a human wants to hand off a complex task manually

**Claude Sonnet 4.6**
- Use when a human wants a lighter Claude hand-off manually

**Codex GPT-5.4**
- Use when a human wants a manual Codex hand-off or A/B comparison

`spec-refiner` recommends `copilot` by default because it is the only route the factory can complete automatically. Claude and Codex may appear in the GitHub UI assignees picker, but the workflow-accessible REST path does not reliably assign them.

## Workflow Inventory

| Workflow | Trigger | Notes |
|----------|---------|-------|
| `spec-refiner` | Issue labeled `needs-spec` | creates plan PR and applies `impl:copilot` |
| `plan-merged-dispatcher` | Merged plan PR | plain Actions workflow, activates source issue |
| `implementer-dispatcher` | Issue labeled `ready-for-implementation` | auto-assigns only `impl:copilot` |
| `reviewer` | PR opened or updated | plan-aware review with implementer calibration, self-tamper guard, and behind-main detection |
| `conflict-resolver` | PR labeled `needs-rebase` | merges `origin/main` into the PR branch when clean |
| `contribution-checker` | PR opened or updated | checks repo process alignment |
| `simplify-and-harden-ci` | PR opened or updated | scan-only quality and security pass |
| `eval-creator-ci` | PR opened or updated | advisory regression checks |
| `ci-cleaner` | CI failure on `main` | fixes failing mainline CI |
| `self-improvement-meta` | nightly | extracts learnings and promotes durable rules |
| `learning-aggregator-ci` | weekly | groups learnings, analyzes transcript artifacts, and ranks gaps |
| `issue-triage` | issue opened or reopened | issue intake and initial labeling |
| `pr-fix` | `/pr-fix` comment | on-demand PR repair |
| `lock-file-sync` | PR touches workflow sources or lock files | plain Actions guard for stale lock files |

## Human Circuit Breaker

Any workflow can be halted by adding the `human-review` label to the issue or PR it is operating on. When you see that label, call `noop` immediately and explain what would have happened otherwise.
