#!/usr/bin/env bash
# Create a temporary git repository, install the template into it, and verify
# that the installed layout compiles and stays lock-file clean.

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEEP_SMOKE_REPO="${KEEP_SMOKE_REPO:-0}"
SMOKE_REPO="${SMOKE_REPO:-$(mktemp -d "${TMPDIR:-/tmp}/agent-factory-smoke.XXXXXX")}"

info() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [ "$KEEP_SMOKE_REPO" = "1" ]; then
    info "Keeping smoke-test repo at $SMOKE_REPO"
  else
    rm -rf "$SMOKE_REPO"
  fi
}
trap cleanup EXIT

assert_file() {
  local path="$1"
  [ -f "$path" ] || die "Expected file not found: $path"
}

assert_dir() {
  local path="$1"
  [ -d "$path" ] || die "Expected directory not found: $path"
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v gh >/dev/null 2>&1 || die "gh CLI is required"

info "Creating smoke-test repo at $SMOKE_REPO"
git init "$SMOKE_REPO" >/dev/null

(
  cd "$SMOKE_REPO"
  git branch -m main
  printf '# Dummy Repo\n' > README.md
)

info "Installing template into smoke-test repo"
(
  cd "$SMOKE_REPO"
  "$TEMPLATE_ROOT/install.sh"
)

info "Checking installed layout"
(
  cd "$SMOKE_REPO"

  assert_dir ".github/workflows"
  assert_dir ".claude/skills"
  assert_dir "scripts"
  assert_dir ".learnings"
  assert_dir ".evals"
  assert_dir ".evals/cases"
  assert_dir "docs/plans"

  assert_file "AGENTS.md"
  assert_file "CLAUDE.md"
  assert_file ".github/copilot-instructions.md"
  assert_file ".learnings/LEARNINGS.md"
  assert_file ".evals/EVAL_INDEX.md"
  assert_file "docs/plans/README.md"
  assert_file "scripts/check-workflow-lock-sync.sh"
  assert_file "scripts/factory-smoke.sh"
  assert_file "scripts/factory-e2e.sh"

  for src in "$TEMPLATE_ROOT"/.evals/cases/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    assert_file ".evals/cases/$name"
  done

  for src in "$TEMPLATE_ROOT"/workflows/*.md; do
    name="$(basename "$src")"
    workflow_id="${name%.md}"
    assert_file ".github/workflows/$name"
    assert_file ".github/workflows/${workflow_id}.lock.yml"
  done

  for src in "$TEMPLATE_ROOT"/workflow-support/*.yml "$TEMPLATE_ROOT"/workflow-support/*.yaml; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    assert_file ".github/workflows/$name"
  done

  for skill_dir in "$TEMPLATE_ROOT"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    assert_dir ".claude/skills/$skill_name"
    assert_file ".claude/skills/$skill_name/SKILL.md"
  done

  bash scripts/check-workflow-lock-sync.sh
  git diff --check
)

info "Smoke test passed"
