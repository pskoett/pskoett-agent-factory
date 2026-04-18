#!/usr/bin/env bash
#
# factory-smoke.sh
# Dispatch each safely-dispatchable factory workflow and report pass/fail per
# workflow. This is a smoke harness for installed repos that use this template.
#
# Usage:
#   scripts/factory-smoke.sh [--wait-secs N]
#
# Exit 0 if every dispatched workflow reaches completed|success.
# Exit 1 otherwise.

set -euo pipefail

REPO="${GH_AW_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
WAIT_SECS=480

while [ $# -gt 0 ]; do
  case "$1" in
    --wait-secs) WAIT_SECS="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

WORKFLOWS=(
  "factory-health.lock.yml"
  "self-improvement-meta.lock.yml"
  "learning-aggregator-ci.lock.yml"
)

printf '%-10s %-44s %-12s %s\n' "RESULT" "WORKFLOW" "RUN-ID" "DURATION"
printf '%-10s %-44s %-12s %s\n' "------" "--------" "------" "--------"

exit_code=0

for wf in "${WORKFLOWS[@]}"; do
  start_ts=$(date +%s)

  if ! gh workflow run "$wf" --repo "$REPO" >/dev/null 2>&1; then
    printf '%-10s %-44s %-12s %s\n' "SKIP" "$wf" "-" "dispatch failed"
    continue
  fi

  sleep 5

  run_id=$(gh run list \
    --workflow="$wf" \
    --repo "$REPO" \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId' 2>/dev/null || echo "")

  if [ -z "$run_id" ]; then
    printf '%-10s %-44s %-12s %s\n' "SKIP" "$wf" "-" "no run id"
    continue
  fi

  waited=0
  status=""
  concl=""
  while [ "$waited" -lt "$WAIT_SECS" ]; do
    payload=$(gh run view "$run_id" --repo "$REPO" --json status,conclusion 2>/dev/null || echo '{}')
    status=$(echo "$payload" | jq -r '.status // ""')
    concl=$(echo "$payload" | jq -r '.conclusion // ""')

    if [ "$status" = "completed" ]; then
      break
    fi

    sleep 15
    waited=$((waited + 15))
  done

  elapsed=$(( $(date +%s) - start_ts ))

  if [ "$status" != "completed" ]; then
    printf '%-10s %-44s %-12s %s\n' "TIMEOUT" "$wf" "$run_id" "${elapsed}s (still $status)"
    exit_code=1
  elif [ "$concl" = "success" ]; then
    printf '%-10s %-44s %-12s %s\n' "PASS" "$wf" "$run_id" "${elapsed}s"
  else
    printf '%-10s %-44s %-12s %s\n' "FAIL" "$wf" "$run_id" "${elapsed}s ($concl)"
    exit_code=1
  fi
done

echo ""
if [ "$exit_code" -eq 0 ]; then
  echo "All workflows passed smoke test."
else
  echo "One or more workflows failed. Run 'gh run view <run-id> --log-failed' for details."
fi

exit "$exit_code"
