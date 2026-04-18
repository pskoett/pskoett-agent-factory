#!/usr/bin/env bash
# Validate that each .github/workflows/*.md source file is in sync with its
# compiled .lock.yml counterpart.

set -euo pipefail

WORKFLOWS_DIR=".github/workflows"

die() { echo "ERROR: $*" >&2; exit 1; }

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) \
  || die "'git rev-parse' failed. Run this script from inside the repository."
cd "$REPO_ROOT"

if ! command -v gh &>/dev/null; then
  die "'gh' CLI is not installed. See https://cli.github.com/ then run: gh extension install github/gh-aw"
fi

if ! gh aw --version &>/dev/null; then
  die "'gh aw' extension is not installed. Run: gh extension install github/gh-aw"
fi

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

COMPILE_HELP="$(gh aw compile --help 2>&1 || true)"

if [[ "$COMPILE_HELP" == *"--check-only"* ]]; then
  echo "Strategy: native 'gh aw compile --check-only' (read-only, no side effects)"
  echo ""
  CHECK_ONLY_OUT=$(gh aw compile --check-only 2>&1) || CHECK_ONLY_RC=$?
  CHECK_ONLY_RC=${CHECK_ONLY_RC:-0}
  echo "$CHECK_ONLY_OUT"
  if [ "$CHECK_ONLY_RC" -eq 0 ]; then
    echo ""
    echo "All workflow lock files are in sync."
    exit 0
  else
    echo ""
    echo "One or more workflow lock files are out of sync. Run the repair commands above."
    exit 1
  fi
else
  echo "Note: 'gh aw compile --check-only' is not available."
  echo "  Switching to compile-and-diff fallback."
  echo ""
fi

echo "Strategy: fallback (compile + git diff)"
echo "  Running 'gh aw compile' and checking for changes to .lock.yml files."
echo "  In CI the checkout is ephemeral. Locally, restore modified files with:"
echo "    git restore .github/workflows/*.lock.yml"
echo ""

if ! COMPILE_OUT=$(gh aw compile 2>&1); then
  echo "ERROR: 'gh aw compile' failed:"
  echo "$COMPILE_OUT" | sed 's/^/  /'
  exit 1
fi

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
  md_file="${lock_file%.lock.yml}.md"
  workflow_name=$(basename "${lock_file%.lock.yml}")
  echo "  Stale pair:"
  echo "    Source : ${md_file}"
  echo "    Lock   : ${lock_file}"
  echo "    Repair : gh aw compile ${workflow_name}"
  echo ""
done

echo "To repair all stale files at once:"
echo "  gh aw compile"
echo "  git add .github/workflows/*.lock.yml"
echo "  git commit -m 'chore: recompile workflow lock files'"
exit 1
