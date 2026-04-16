# pskoett-agent-factory

An end-to-end agent factory for GitHub repositories, powered by [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/). Issue goes in, reviewed PR comes out. The human merges the plan and merges the final PR. Everything in between is automated.

## What This Is

A choreography-based agent factory where specialist workflows chain together through GitHub events (labels, PRs, comments). No orchestrator, no DAG, no pipeline engine. Each agent does one job, hands off via a label swap, and the next agent picks it up.

The factory was built and battle-tested on [pskoett/measuring-ai-proficiency](https://github.com/pskoett/measuring-ai-proficiency). This repo documents the pattern so you can replicate it in your own projects.

## The Chain

```
issue opened
  |
  v
issue-triage (auto-labels by type, detects spam)
  |
  v
human adds "needs-spec" label
  |
  v
spec-refiner (plan file + implementer label on issue)
  |
  v
human reviews plan PR, optionally swaps implementer label  <-- ONE decision
  |
  v
/plan (breaks plan into sub-issues)
  |
  v
implementer-dispatcher (auto-assigns sub-issues from parent label)
  |
  v
PR opened
  |
  +---> reviewer (plan-aware code review with implementer calibration)
  +---> contribution-checker (CONTRIBUTING.md compliance)
  |
  v
needs-changes? ---> /pr-fix (auto-fix CI failures)
  |
  v
CI failure on main? ---> ci-cleaner (lint, test, compile fix loop)
  |
  v
nightly ---> self-improvement-meta (extract learnings, commit guardrails)
```

State lives in GitHub, not in memory. Each agent starts cold. Every handoff is mediated by a file, a label, or a PR. You can inspect the state at any point by looking at the repo.

## The Human's Job

Three decisions across the entire lifecycle:

1. **Merge the plan** (approve the spec-refiner's plan file PR)
2. **Merge the final PR** (after the reviewer's first pass, you do the final one)
3. **Merge learnings** (if the nightly loop finds something worth keeping, approve it)

Everything else is automated. The `impl:*` label on the parent issue is the only routing decision, and spec-refiner sets that for you. You only swap it if you disagree.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) installed and authenticated
- [gh-aw extension](https://github.com/github/gh-aw): `gh extension install github/gh-aw`
- A `COPILOT_GITHUB_TOKEN` secret in the repo
- Copilot cloud agent enabled (Settings > Copilot > Cloud agent)
- "Allow GitHub Actions to create and approve pull requests" enabled (Settings > Actions > General)
- Optional: `DX_MCP_TOKEN` secret for DX Data Cloud integration in the reviewer

## Installation

### Step 1: Install gh-aw

```bash
gh extension install github/gh-aw
```

### Step 2: Add the support workflows from githubnext/agentics

```bash
gh aw add githubnext/agentics/issue-triage
gh aw add githubnext/agentics/plan
gh aw add githubnext/agentics/pr-fix
```

### Step 3: Create the custom workflows

Create these files in `.github/workflows/` of your target repo. Each is a thin adapter shell that references skills for its logic.

**spec-refiner.md**: [see Workflows section below](#spec-refiner)

**reviewer.md**: [see Workflows section below](#reviewer)

**self-improvement-meta.md**: [see Workflows section below](#self-improvement-meta)

**implementer-dispatcher.md**: [see Workflows section below](#implementer-dispatcher)

**ci-cleaner.md**: [see Workflows section below](#ci-cleaner)

**contribution-checker.md**: [see Workflows section below](#contribution-checker)

### Step 4: Compile

```bash
gh aw compile
git add .github/workflows/
git commit -m "Install agent factory chain"
git push
```

### Step 5: Create labels

The factory uses these labels for handoffs. Create them in your repo:

| Label | Color | Purpose |
|-------|-------|---------|
| `needs-spec` | `#0E8A16` | Issue needs a plan file |
| `needs-plan` | `#1D76DB` | Spec ready, waiting for /plan |
| `blocked-on-human` | `#D93F0B` | Agent needs human input |
| `spec-refined` | `#0E8A16` | Spec refinement complete |
| `ready-for-implementation` | `#5319E7` | Sub-issue ready for coding agent |
| `impl:claude-opus` | `#7057FF` | Route to Claude Opus 4.6 |
| `impl:claude-sonnet` | `#A371F7` | Route to Claude Sonnet 4.6 |
| `impl:copilot` | `#3FB950` | Route to Copilot cloud agent |
| `impl:codex` | `#F9826C` | Route to Codex GPT-5.4 |
| `assigned-to-agent` | `#BFD4F2` | Dispatch completed |
| `ai-reviewed` | `#0E8A16` | PR passed automated review |
| `needs-changes` | `#D93F0B` | PR has critical findings |
| `fast-track` | `#0E8A16` | Zero findings, ready to merge |
| `spec-drift` | `#E4E669` | PR does things the plan did not ask for |
| `human-review` | `#B60205` | Emergency stop |
| `self-improvement` | `#C5DEF5` | PR from nightly learning loop |
| `ci-fix` | `#FBCA04` | PR from CI cleaner |
| `plan-file` | `#D4C5F9` | PR contains a plan file |

## Quick Start: Your First Run

1. Open an issue describing a feature or bug fix
2. `issue-triage` auto-labels it
3. Add the `needs-spec` label
4. `spec-refiner` creates a plan PR with an implementer recommendation and adds an `impl:*` label
5. Review the plan PR. Swap the `impl:*` label if you disagree. Merge.
6. Comment `/plan` on the issue (or wait for `needs-plan` to trigger it)
7. `/plan` creates sub-issues. `implementer-dispatcher` auto-assigns them.
8. Agents open PRs. `reviewer` + `contribution-checker` + `simplify-and-harden-ci` + `eval-creator-ci` review them.
9. Merge the PRs. Done.
10. Weekly: `learning-aggregator-ci` analyzes accumulated learnings, ranks promotion candidates.

## Workflows

### spec-refiner

Triggers on `issues.labeled` when the label is `needs-spec`. Reads the plan-interview skill, simulates a requirements interview from issue context, writes a plan file to `docs/plans/`, recommends an implementer, and adds the `impl:*` label.

```yaml
---
on:
  issues:
    types: [labeled]
  workflow_dispatch:
if: github.event.label.name == 'needs-spec' || github.event_name == 'workflow_dispatch'
timeout-minutes: 10
engine:
  id: copilot
  model: gpt-5.4
permissions:
  issues: read
  contents: read
tools:
  github:
    toolsets: [issues, repos, search]
  cache-memory:
safe-outputs:
  update-issue:
    max: 1
  add-comment:
    max: 1
  create-pull-request:
    max: 1
    title-prefix: "[plan] "
    labels: [plan-file, automation]
  add-labels:
    allowed: [needs-plan, blocked-on-human, spec-refined, "impl:claude-opus", "impl:claude-sonnet", "impl:copilot", "impl:codex"]
    max: 3
  remove-labels:
    allowed: [needs-spec]
    max: 1
---
```

The workflow body tells the agent to read the plan-interview skill, simulate the interview, assess complexity, recommend an implementer, write the plan file, and hand off via labels.

### reviewer

Triggers on `pull_request` events. Reviews the PR against its plan file with implementer-aware calibration: Claude PRs checked for scope drift, Copilot PRs checked for test gaps, Codex PRs checked for control flow correctness.

```yaml
---
on:
  pull_request:
    types: [opened, ready_for_review, synchronize]
  workflow_dispatch:
timeout-minutes: 8
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  pull-requests: read
  issues: read
tools:
  github:
    toolsets: [pull_requests, issues, repos, search]
  cache-memory:
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
  add-labels:
    allowed: [ai-reviewed, needs-changes, spec-drift, fast-track]
    max: 2
---
```

### implementer-dispatcher

Triggers when a sub-issue is labeled `ready-for-implementation`. Reads the parent issue's `impl:*` label and auto-assigns the sub-issue to the chosen agent.

```yaml
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
```

### self-improvement-meta

Runs nightly. Reads the last 24h of workflow run logs, extracts failure patterns, and opens a PR with prevention rules committed to AGENTS.md, CLAUDE.md, and .github/copilot-instructions.md.

```yaml
---
on:
  schedule: daily around 2am
  workflow_dispatch:
timeout-minutes: 15
engine:
  id: copilot
  model: gpt-5.4
permissions:
  actions: read
  contents: read
  issues: read
  pull-requests: read
tools:
  github:
    toolsets: [actions, repos, issues, pull_requests]
  cache-memory:
  bash:
    - "gh aw logs"
    - "gh aw audit"
    - "gh aw status"
    - "gh run list"
    - "gh run view"
    - "grep"
    - "wc"
    - "sort"
    - "uniq"
    - "head"
    - "tail"
    - "cat"
safe-outputs:
  create-pull-request:
    max: 1
    title-prefix: "[learnings] "
    labels: [self-improvement, automation, low-risk]
  create-issue:
    title-prefix: "[meta] "
    labels: [self-improvement, workflow-health]
    max: 2
    close-older-issues: true
---
```

### ci-cleaner

Triggers on CI failures on main. Runs lint, test, and compile in sequence. Creates a PR with fixes. Includes a mandatory exit protocol (always produces a PR or noop) and a file-count guard (refuses PRs with 50+ changed files).

```yaml
---
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]
  workflow_dispatch:
timeout-minutes: 10
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  actions: read
tools:
  github:
    toolsets: [repos, actions]
  bash: true
  edit:
  cache-memory:
network: defaults
safe-outputs:
  create-pull-request:
    max: 1
    title-prefix: "[ci-fix] "
    labels: [ci-fix, automation, low-risk]
---
```

### contribution-checker

Triggers on PR events. Evaluates the PR against CONTRIBUTING.md with a structured checklist: on-topic, focused, has tests, has description, skills synced.

```yaml
---
on:
  pull_request:
    types: [opened, synchronize, ready_for_review]
  workflow_dispatch:
timeout-minutes: 5
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  pull-requests: read
tools:
  github:
    toolsets: [pull_requests, repos]
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
---
```

### simplify-and-harden-ci

Triggers on PR events. Headless quality and security scan on changed files. Runs simplify, harden, and document passes without modifying code. Posts structured findings.

```yaml
---
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
timeout-minutes: 8
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  actions: read
  pull-requests: read
tools:
  github:
    toolsets: [pull_requests, actions]
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
---
```

### learning-aggregator-ci

Runs weekly. Reads all accumulated `.learnings/` entries, groups by pattern key, computes cross-session recurrence, and ranks promotion candidates. Posts gap report as an issue.

```yaml
---
on:
  schedule: weekly on monday
  workflow_dispatch:
timeout-minutes: 10
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  actions: read
  issues: read
  pull-requests: read
tools:
  github:
    toolsets: [pull_requests, actions, issues]
  cache-memory: true
safe-outputs:
  create-issue:
    max: 1
    title-prefix: "[learnings] "
    labels: [self-improvement, automation]
    close-older-issues: true
tracker-id: learning-aggregator
---
```

### eval-creator-ci

Triggers on PR events. Runs regression tests from `.evals/cases/` to verify promoted rules still hold. Gate policy: advisory (reports results, does not block merge).

```yaml
---
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
timeout-minutes: 8
engine:
  id: copilot
  model: gpt-5.4
permissions:
  contents: read
  actions: read
  pull-requests: read
tools:
  github:
    toolsets: [pull_requests, actions]
  cache-memory: true
  bash:
    - "grep"
    - "rg"
    - "cat"
    - "head"
    - "wc"
    - "test"
    - "ls"
    - "find"
    - "pytest"
    - "ruff"
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
tracker-id: eval-creator
---
```

## Skills

The factory workflows are thin adapter shells. The actual agent logic lives in skills from [pskoett/pskoett-ai-skills](https://github.com/pskoett/pskoett-ai-skills):

| Skill | Used by | Purpose |
|-------|---------|---------|
| `plan-interview` | spec-refiner | Structured requirements interview before planning |
| `self-improvement` | self-improvement-meta | Learning capture, categorization, and promotion |
| `intent-framed-agent` | reviewer | Scope drift detection against plan intent |
| `simplify-and-harden` | simplify-and-harden-ci | Quality and security sweep (three passes) |
| `verify-gate` | (available) | Machine verification gate (tests, lint) before quality review |
| `eval-creator` | eval-creator-ci | Create and run regression test cases from promoted learnings |
| `learning-aggregator` | learning-aggregator-ci | Cross-session pattern detection and promotion ranking |
| `pre-flight-check` | (available) | Session-start visibility of prior learnings and eval status |
| `context-surfing` | (available) | Context window health monitoring |

Skills live in `.claude/skills/` and work identically in Claude Code, Codex CLI, and gh-aw. Update a skill once, every consumer gets the fix.

To vendor skills into your repo:

```bash
git clone --depth 1 https://github.com/pskoett/pskoett-ai-skills /tmp/skills
cp -r /tmp/skills/skills/* .claude/skills/
rm -rf /tmp/skills
```

## Implementer Routing

The spec-refiner recommends an implementer based on plan complexity. The human confirms by keeping or swapping the `impl:*` label. The implementer-dispatcher auto-assigns sub-issues based on that label.

| Label | Agent | When to use |
|-------|-------|-------------|
| `impl:claude-opus` | Claude Opus 4.6 | Multi-file refactors, high blast radius, 6+ checklist items |
| `impl:claude-sonnet` | Claude Sonnet 4.6 | Single-component features, medium complexity |
| `impl:copilot` | Copilot | Trivial fixes, dependency bumps, config changes |
| `impl:codex` | Codex GPT-5.4 | A/B comparison, different reasoning style |

The reviewer then calibrates its review based on which agent produced the code:
- Claude PRs: weight toward scope adherence (tends to over-implement)
- Copilot PRs: weight toward test coverage (tends to under-test)
- Codex PRs: weight toward correctness on unusual control flow
- Human PRs: standard rigor

## Controlling the Chain

| Action | How |
|--------|-----|
| **Pause any step** | Add the `human-review` label. All agents call noop. |
| **Skip spec-refinement** | Label the issue `needs-plan` directly |
| **Skip automated review** | Label the PR `human-review` |
| **Fix a failing PR** | Comment `/pr-fix` on the PR |
| **Break a plan into tasks** | Comment `/plan` on the issue |
| **Trigger manually** | Every workflow has `workflow_dispatch` |
| **Fast-forward** | For trivial fixes, just open a PR directly |

## Architecture

```
+-------------------------------------------------------------+
|                     GitHub Actions Runtime                   |
|  (triggers, permissions, sandboxing, safe outputs, MCP)      |
+-----------------------------+-------------------------------+
                              |
+-----------------------------+-------------------------------+
|                    gh-aw Adapter Layer                       |
|  (frontmatter, handoff logic, label semantics)              |
|                                                              |
|   spec-refiner    reviewer    self-improvement-meta          |
|   implementer-dispatcher    ci-cleaner    contribution-checker
+-----------------------------+-------------------------------+
                              | reads skills from
                              v
+-------------------------------------------------------------+
|                    Agent Skills Library                      |
|  (pskoett/pskoett-ai-skills, vendored into .claude/skills/) |
|                                                              |
|   plan-interview    dx-data-navigator    self-improvement    |
|   intent-framed-agent              context-surfing           |
+-------------------------------------------------------------+
```

The adapter layer is thin on purpose. It owns GitHub-specific concerns: when to trigger, what permissions to request, which safe outputs to configure, how to move labels around. It does not own the agent's internal process. That lives in the skills.

The same skill runs in Claude Code on your laptop, in Codex CLI in a terminal, and in gh-aw in GitHub Actions. One canonical definition, three runtime surfaces.

## Engine Configuration

All custom workflows use `engine: copilot` with `model: gpt-5.4` by default. This uses the existing `COPILOT_GITHUB_TOKEN` secret with no additional API keys needed.

To switch to a different engine, change the frontmatter:

```yaml
# Copilot with GPT-5.4 (default, no extra secrets)
engine:
  id: copilot
  model: gpt-5.4

# Claude (experimental, needs bundled subscription or ANTHROPIC_API_KEY)
engine:
  id: claude
  model: claude-opus-4-6

# Codex (experimental, needs CODEX_API_KEY or OPENAI_API_KEY)
engine: codex
```

Then recompile: `gh aw compile`

## Debugging

```bash
# Check workflow status
gh aw status

# View logs for a specific workflow
gh aw logs spec-refiner

# Audit a failed run
gh aw audit <run-id>

# Recompile after editing a workflow
gh aw compile <workflow-name>

# Recompile all workflows
gh aw compile

# Remove orphaned lock files
gh aw compile --purge

# Upgrade gh-aw extension
gh extension upgrade gh-aw
```

## Design Principles

1. **Choreography, not orchestration.** No DAG, no pipeline engine. Agents hand off through GitHub events. Loose coupling all the way down.
2. **Skills are the new software.** The factory workflows are adapter shells. The real logic lives in version-controlled, testable, cross-runtime skills.
3. **The human decides, the machine executes.** Three human decisions: approve the plan, merge the PR, accept learnings. Everything else is automated.
4. **The factory improves itself.** The nightly self-improvement loop turns failures into prevention rules committed to the repo. The factory gets smarter every day.
5. **State lives in GitHub.** Issues are the database. Labels are the routing table. PRs are the delivery mechanism. Files are the source of truth.

## Reference Implementation

See [pskoett/measuring-ai-proficiency](https://github.com/pskoett/measuring-ai-proficiency) for a working implementation with all 11 workflows, 8 skills, and full documentation.

## Related

- [GitHub Agentic Workflows (gh-aw)](https://github.github.com/gh-aw/)
- [githubnext/agentics sample pack](https://github.com/githubnext/agentics)
- [pskoett/pskoett-ai-skills](https://github.com/pskoett/pskoett-ai-skills)
- [Agent Skills Standard](https://agentskills.io/)

## License

MIT
