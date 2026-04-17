#!/usr/bin/env bash
# Validate that .github/workflows/*.md sources and .lock.yml files are in sync.

set -euo pipefail

WORKFLOWS_DIR=".github/workflows"

die() { echo "ERROR: $*" >&2; exit 1; }

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) \
  || die "'git rev-parse' failed. Run this script from inside the repository."
cd "$REPO_ROOT"

command -v gh >/dev/null 2>&1 || die "'gh' CLI is not installed."
gh aw --version >/dev/null 2>&1 || die "'gh aw' extension is not installed."

PAIR_COUNT=0
for md in "${WORKFLOWS_DIR}"/*.md; do
  [ -f "$md" ] || continue
  lock="${md%.md}.lock.yml"
  [ -f "$lock" ] && PAIR_COUNT=$((PAIR_COUNT + 1))
done

if [ "$PAIR_COUNT" -eq 0 ]; then
  echo "No .md/.lock.yml pairs found in ${WORKFLOWS_DIR}/. Nothing to check."
  exit 0
fi

echo "Checking ${PAIR_COUNT} workflow pair(s) in ${WORKFLOWS_DIR}/..."
echo ""

if gh aw compile --help | grep -q -- "--check-only"; then
  echo "Strategy: native 'gh aw compile --check-only'"
  echo ""
  CHECK_ONLY_OUT=$(gh aw compile --check-only 2>&1) || CHECK_ONLY_RC=$?
  CHECK_ONLY_RC=${CHECK_ONLY_RC:-0}
  echo "$CHECK_ONLY_OUT"
  if [ "$CHECK_ONLY_RC" -eq 0 ]; then
    echo ""
    echo "All workflow lock files are in sync."
    exit 0
  fi
  echo ""
  echo "One or more workflow lock files are out of sync."
  exit 1
fi

echo "Strategy: fallback (compile + git diff)"
echo ""

COMPILE_OUT=$(gh aw compile 2>&1) || {
  echo "$COMPILE_OUT"
  exit 1
}

STALE_FILES=()
while IFS= read -r f; do
  [ -n "$f" ] && STALE_FILES+=("$f")
done < <(git diff --name-only -- "${WORKFLOWS_DIR}"/*.lock.yml 2>/dev/null || true)

if [ "${#STALE_FILES[@]}" -eq 0 ]; then
  echo "All workflow lock files are in sync."
  exit 0
fi

echo "ERROR: ${#STALE_FILES[@]} workflow lock file(s) are out of sync:"
echo ""
for lock_file in "${STALE_FILES[@]}"; do
  workflow_name=$(basename "${lock_file%.lock.yml}")
  echo "  ${lock_file}"
  echo "    Repair: gh aw compile ${workflow_name}"
done
exit 1
