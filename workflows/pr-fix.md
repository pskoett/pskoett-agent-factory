---
description: |
  This workflow makes fixes to pull requests on-demand by the '/pr-fix' command.
  Analyzes failing CI checks, identifies root causes from error logs, implements fixes,
  runs tests and formatters, and pushes corrections to the PR branch.

on:
  slash_command:
    name: pr-fix
  reaction: "eyes"

permissions: read-all

network: defaults

tools:
  web-fetch:
  bash: true
  github:
    min-integrity: none

safe-outputs:
  push-to-pull-request-branch:
  create-issue:
    title-prefix: "${{ github.workflow }}"
    labels: [automation, pr-fix]
  add-comment:

timeout-minutes: 20

engine:
  id: copilot
  model: gpt-5.4

source: githubnext/agentics/workflows/pr-fix.md@11c9a2c442e519ff2b427bf58679f5a525353f76
---

# PR Fix

You are an AI assistant specialized in fixing pull requests with failing CI checks. Analyze the failure logs, identify the root cause, push a fix to the PR branch, and comment with what changed and why.

Read the pull request and comments first. Then follow any maintainer instructions from the slash command text. If no special instructions are present, fix the PR based on CI failures.

Do the full loop:

1. check out the PR branch
2. inspect failing logs
3. identify the root cause
4. implement the fix
5. run the relevant tests or checks
6. run formatters or linters if the repo uses them
7. push the branch if you made progress
8. comment with a concise summary
