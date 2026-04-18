# Scripts

Utility scripts for maintaining and testing installed repos that use this template.

## factory-smoke.sh

Dispatches each safely-dispatchable factory workflow via `gh workflow run`, waits for completion, and reports pass or fail per workflow.

```bash
scripts/factory-smoke.sh
scripts/factory-smoke.sh --wait-secs 900
```

Exit 0 if every dispatched workflow reaches `completed|success`. Exit 1 otherwise.

This template's generic smoke harness covers:

- `factory-health`
- `self-improvement-meta`
- `learning-aggregator-ci`

Event-driven workflows such as `spec-refiner`, `reviewer`, `pr-fix`, and `trigger-plan` are covered by the e2e harness instead.

## factory-e2e.sh

Files a canary issue and watches it through the installed factory chain.
The canary is a plumbing test only. It explicitly tells coding agents to call
`noop` instead of implementing anything, and the harness closes the issue on
exit unless `--keep` is set.

```bash
scripts/factory-e2e.sh
scripts/factory-e2e.sh --stage impl
scripts/factory-e2e.sh --stage full
scripts/factory-e2e.sh --keep
```

Default stop is `plan`, which is the last stage the harness can drive without waiting on a real Copilot coding run.

## check-workflow-lock-sync.sh

Checks that every gh-aw workflow source still matches its compiled `.lock.yml`.

```bash
bash scripts/check-workflow-lock-sync.sh
```

## smoke-test-install.sh

Template-source verification harness. Creates a temporary repo, installs this template into it, compiles the installed workflows, and verifies lock-file sync.

```bash
bash scripts/smoke-test-install.sh
```
