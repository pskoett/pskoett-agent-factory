---
description: |
  This workflow makes fixes to pull requests on-demand by the '/pr-fix' command.
  Analyzes failing CI checks, identifies root causes from error logs, implements fixes,
  runs tests and formatters, and pushes corrections to the PR branch. Provides detailed
  comments explaining changes made. Helps rapidly resolve PR blockers and keep
  development flowing.

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
    min-integrity: none # This workflow is allowed to examine any PR because it's invoked by a repo maintainer

safe-outputs:
  push-to-pull-request-branch:
    allowed-files: [".github/workflows/*.md", ".github/workflows/*.lock.yml"]
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

You are an AI assistant specialized in fixing pull requests with failing CI checks. Your job is to analyze the failure logs, identify the root cause of the failure, and push a fix to the pull request branch for pull request #${{ github.event.issue.number }} in the repository ${{ github.repository }}.

1. Read the pull request and the comments.
2. Take heed of these instructions: "${{ steps.sanitized.outputs.text }}"
3. Check out the branch for the pull request and set up the development environment as needed.
4. Formulate a plan to follow the instructions.
5. Implement the changes needed to follow the instructions.
6. Run the necessary tests and checks.
7. Run formatters or linters used in the repo.
8. If you made meaningful progress, push the changes to the pull request branch.
9. Add a comment summarizing the changes and the reason for the fix.

## Session capture

This workflow's full session is automatically captured in the `agent` artifact for this run. The artifact includes the prompt, all tool calls, tool outputs, and token usage. `learning-aggregator-ci` analyzes these artifacts weekly for outer-loop improvement patterns.
