---
on:
  schedule: weekly on sunday
  workflow_dispatch:
timeout-minutes: 30
engine:
  id: copilot
  model: gpt-5.4
permissions:
  actions: read
  issues: read
  pull-requests: read
tools:
  github:
    toolsets: [actions, issues, pull_requests]
  bash:
    - "gh"
    - "gh run"
    - "gh run list"
    - "gh run view"
    - "gh issue"
    - "gh issue list"
    - "gh pr"
    - "gh pr list"
    - "gh api"
    - "jq"
    - "date"
    - "printf"
    - "grep"
    - "wc"
    - "sort"
    - "uniq"
    - "head"
    - "tail"
    - "cat"
    - "echo"
safe-outputs:
  create-issue:
    max: 1
    title-prefix: "[health] "
    labels: [workflow-health, automation]
    close-older-issues: true
tracker-id: factory-health
concurrency:
  group: factory-health
  cancel-in-progress: false
---

# Factory Health Weekly Report

You are the factory's observability agent. Produce one stable weekly health report that answers five operational questions about the last 7 days of factory activity. Emit one `[health]` issue using `create-issue` with `close-older-issues: true`.

Do not add metrics beyond the five sections below. Do not speculate. Where data is insufficient, write `n/a` and say why.

## Reporting window

The reporting window is the 7 days ending at the time this workflow runs. Use ISO 8601 dates, `YYYY-MM-DD`, for all date references.

Compute the start of the window:

```bash
date -u -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ
date -u +%Y-%m-%d
```

## Section 1: Workflow run outcomes

List every factory workflow and its run counts for the reporting window. Factory workflows are:

```text
spec-refiner reviewer implementer-dispatcher plan-merged-dispatcher
ci-cleaner contribution-checker simplify-and-harden-ci learning-aggregator-ci
eval-creator-ci self-improvement-meta issue-triage pr-fix conflict-resolver
factory-health lock-file-sync
```

For each gh-aw workflow, run:

```bash
gh run list --workflow "<workflow>.lock.yml" --limit 50 \
  --json databaseId,displayTitle,conclusion,createdAt,event \
  --jq '[.[] | select(.createdAt >= "<window-start>")] |
        {success: (map(select(.conclusion == "success")) | length),
         failure: (map(select(.conclusion == "failure")) | length),
         skipped: (map(select(.conclusion == "skipped")) | length),
         cancelled: (map(select(.conclusion == "cancelled")) | length),
         total: length}'
```

For plain GitHub Actions workflows, use the workflow file name directly:

- `plan-merged-dispatcher.yml`
- `lock-file-sync.yml`

Build a table with columns: `Workflow | success | failure | skipped | cancelled | total | skip%`.

`skip%` = skipped / total * 100, rounded to one decimal place. Workflows with `skip% > 50` are flagged as **noop-heavy** in a note below the table.

Calculate and report the overall success rate across all workflows:
`overall success rate = total success / (total success + total failure) * 100`

Omit workflows that had zero total runs in the window.

## Section 2: Failure categorization

For each run with `conclusion == "failure"` in the reporting window, examine the run and classify the failure using this rubric:

- **Infra**: CDN timeouts, runner provisioning errors, Docker pull failures, GitHub API rate limits, or other infrastructure errors
- **Workflow bug**: a reproducible logic error in a `.md` workflow instruction or compiled `.lock.yml`
- **Agent error**: model output violated a constraint, such as malformed safe-output JSON, disallowed tool use, or hallucinated file paths
- **Unknown**: not enough evidence to classify

For each failure:

```bash
gh run view <run-id> --log-failed 2>/dev/null | head -100
```

Produce a table with columns: `Workflow | Run ID | Category | Evidence`.

If there are no failures, write "No failures in this reporting window."

## Section 3: Handoff latency, spec to plan

The spec-to-plan handoff measures how long it takes from `needs-spec` label application to a plan PR being opened. The `spec-refiner` workflow creates the plan PR when triggered by the `needs-spec` label.

### Primary method

Fetch recently opened plan PRs in the reporting window:

```bash
gh pr list --state all --label "plan-file" --limit 20 \
  --json number,title,body,createdAt,closedAt,mergedAt \
  --jq '[.[] | select(.createdAt >= "<window-start>")]'
```

For each plan PR found, identify the source issue from the body, which should use `Refs #NNN`, then check when the `needs-spec` label was applied to that issue:

```bash
gh api repos/{owner}/{repo}/issues/<issue-number>/timeline \
  --jq '[.[] | select(.event == "labeled" and .label.name == "needs-spec")] | last | .created_at'
```

Compute `latency = plan PR createdAt - needs-spec label applied_at` for each matched pair.

Report: number of pairs found, min, median, and max latency in hours.

### Fallback

If fewer than 2 pairs are found or label-event data is unavailable, write:

> Handoff latency: n/a — fewer than 2 spec-to-plan pairs with resolvable timestamps in the reporting window. Check `spec-refiner` run history manually.

## Section 4: Unresolved signals

Report these open signals. Use `gh issue list` and `gh pr list` with appropriate filters.

### Open workflow-health issues

```bash
gh issue list --label "workflow-health" --state open \
  --json number,title,createdAt \
  --jq 'sort_by(.createdAt)'
```

List each as: `#NNN title (opened YYYY-MM-DD)`.

### Open [aw] failed issues

```bash
gh issue list --state open --limit 50 \
  --json number,title,createdAt \
  --jq '[.[] | select(.title | startswith("[aw]"))] | sort_by(.createdAt)'
```

List each as: `#NNN title (opened YYYY-MM-DD)`.

### Stale plan PRs, older than 48 hours

```bash
gh pr list --state open --limit 50 \
  --json number,title,createdAt \
  --jq '[.[] | select(.title | startswith("[plan]"))] |
        [.[] | select(.createdAt <= "<48-hours-ago>")] |
        sort_by(.createdAt)'
```

List each as: `#NNN title (open since YYYY-MM-DD)`.

If all three subsections are empty, write: "No unresolved signals in this reporting window."

## Section 5: Human override rate

Count merged PRs in the reporting window that still carried the `needs-changes` label at merge time.

### Step 1: Merged PRs with needs-changes

```bash
gh pr list --state merged --limit 100 \
  --json number,title,mergedAt,labels \
  --jq '[.[] | select(.mergedAt >= "<window-start>") |
         select(.labels | map(.name) | contains(["needs-changes"]))] |
        {count: length, items: [.[] | {number, title, mergedAt}]}'
```

### Step 2: Total merged PRs in window

```bash
gh pr list --state merged --limit 100 \
  --json number,mergedAt \
  --jq '[.[] | select(.mergedAt >= "<window-start>")] | length'
```

Report: `N merged PRs carried needs-changes out of M total merged PRs (X%).`

If `N = 0`, write: "No PRs merged with unresolved needs-changes in this reporting window."

Note: The denominator includes all merged PRs in the repo, not just factory-reviewed ones. A high override rate for a small factory may be a false positive. Annotate if total is fewer than 5.

## Output format

Create one issue with this structure. Use stable headers and table shapes so week-to-week diffs are meaningful.

```markdown
## Factory Health Report

**Report date**: YYYY-MM-DD
**Reporting window**: YYYY-MM-DD to YYYY-MM-DD

---

### 1. Workflow Run Outcomes

**Overall success rate**: XX.X% (N success / M total)

| Workflow | success | failure | skipped | cancelled | total | skip% |
|----------|---------|---------|---------|-----------|-------|-------|
| ... | ... | ... | ... | ... | ... | ...% |

**Noop-heavy workflows** (skip% > 50): [list or "none"]

---

### 2. Failure Categorization

| Workflow | Run ID | Category | Evidence |
|----------|--------|----------|----------|
| ... | ... | infra / workflow-bug / agent-error / unknown | ... |

[or: No failures in this reporting window.]

---

### 3. Handoff Latency (spec-to-plan)

**Pairs found**: N
**Min / median / max**: Xh / Yh / Zh

[or fallback message]

---

### 4. Unresolved Signals

#### Open workflow-health issues
[list or "none"]

#### Open [aw] failed issues
[list or "none"]

#### Stale plan PRs (>48h open)
[list or "none"]

---

### 5. Human Override Rate

N merged PRs carried `needs-changes` out of M total merged PRs (X%).

[or: No PRs merged with unresolved needs-changes in this reporting window.]

---

*Generated by factory-health workflow. Source data: gh run list, gh issue list, gh pr list.*
```

## Noop conditions

Call `noop` if the GitHub API is unavailable and zero data can be retrieved for any section. Do not call noop if some sections have data and others are empty.

## Style

Follow the writing rules in `AGENTS.md`. Tables over prose. No speculation. Evidence over opinion. Short sentences.

## Session capture

This workflow's full session is automatically captured in the `agent` artifact for this run. The artifact includes the prompt, all tool calls, tool outputs, and token usage. The `learning-aggregator-ci` workflow downloads and analyzes these artifacts weekly to extract improvement patterns for the outer learning loop.
