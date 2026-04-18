#!/usr/bin/env bash
# Install the agent factory into the current repository.
#
# This script:
#   1. Copies gh-aw workflow sources to .github/workflows/
#   2. Copies plain Actions support workflows to .github/workflows/
#   3. Copies helper scripts used by support workflows
#   4. Vendors skills to .claude/skills/
#   5. Copies shared harness files when missing
#   6. Seeds .learnings/ and docs/plans/
#   7. Creates all labels required by the factory
#   8. Runs gh aw compile

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}!!${NC} %s\n" "$*"; }
error() { printf "${RED}xx${NC} %s\n" "$*" >&2; }

command -v gh >/dev/null 2>&1 || { error "gh CLI not found. Install from https://cli.github.com"; exit 1; }
GH_EXTENSIONS="$(gh extension list 2>/dev/null || true)"
[[ "$GH_EXTENSIONS" == *"gh-aw"* ]] || { error "gh-aw extension not installed. Run: gh extension install github/gh-aw"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { error "Not in a git repository"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
info "Installing agent factory from ${SCRIPT_DIR}"
echo ""

info "Copying workflow files to .github/workflows/..."
mkdir -p .github/workflows
for wf in "$SCRIPT_DIR"/workflows/*.md; do
  [ -f "$wf" ] || continue
  name=$(basename "$wf")
  if [ -f ".github/workflows/$name" ]; then
    warn "$name already exists, skipping"
  else
    cp "$wf" ".github/workflows/$name"
    printf "  + %s\n" "$name"
  fi
done
for wf in "$SCRIPT_DIR"/workflow-support/*.{yml,yaml}; do
  [ -f "$wf" ] || continue
  name=$(basename "$wf")
  if [ -f ".github/workflows/$name" ]; then
    warn "$name already exists, skipping"
  else
    cp "$wf" ".github/workflows/$name"
    printf "  + %s\n" "$name"
  fi
done
echo ""

info "Copying helper scripts..."
mkdir -p scripts
for script in "$SCRIPT_DIR"/scripts/check-workflow-lock-sync.sh; do
  [ -f "$script" ] || continue
  name=$(basename "$script")
  if [ -f "scripts/$name" ]; then
    warn "$name already exists in scripts/, skipping"
  else
    cp "$script" "scripts/$name"
    chmod +x "scripts/$name" || true
    printf "  + %s\n" "$name"
  fi
done
echo ""

info "Vendoring skills to .claude/skills/..."
mkdir -p .claude/skills
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target=".claude/skills/$skill_name"
  if [ -d "$target" ]; then
    warn "$skill_name already exists, skipping"
  else
    mkdir -p "$target"
    cp -r "$skill_dir"* "$target/"
    printf "  + %s\n" "$skill_name"
  fi
done
echo ""

if [ ! -f "AGENTS.md" ]; then
  info "Copying AGENTS.md..."
  cp "$SCRIPT_DIR/AGENTS.md" AGENTS.md
else
  warn "AGENTS.md already exists. Merge the factory sections manually if needed."
fi

if [ ! -f "CLAUDE.md" ]; then
  info "Copying CLAUDE.md..."
  cp "$SCRIPT_DIR/CLAUDE.md" CLAUDE.md
else
  warn "CLAUDE.md already exists, skipping"
fi

mkdir -p .github
if [ ! -f ".github/copilot-instructions.md" ]; then
  info "Copying .github/copilot-instructions.md..."
  cp "$SCRIPT_DIR/.github/copilot-instructions.md" .github/copilot-instructions.md
else
  warn ".github/copilot-instructions.md already exists, skipping"
fi
echo ""

if [ ! -f ".learnings/LEARNINGS.md" ]; then
  info "Seeding .learnings/..."
  mkdir -p .learnings
  cp "$SCRIPT_DIR/.learnings/LEARNINGS.md" .learnings/LEARNINGS.md
else
  info ".learnings/ already exists"
fi

if [ ! -d "docs/plans" ]; then
  info "Creating docs/plans/..."
  mkdir -p docs/plans
  cp "$SCRIPT_DIR/docs/plans-README.md" docs/plans/README.md
else
  info "docs/plans/ already exists"
fi
echo ""

info "Creating factory labels..."
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  warn "Could not detect repo. Skipping label creation."
else
  create_label() {
    gh label create "$1" --repo "$REPO" --description "$2" --color "$3" 2>/dev/null \
      && printf "  + %s\n" "$1" \
      || printf "  = %s (exists)\n" "$1"
  }

  create_label "needs-spec" "Issue needs a structured plan file" "0E8A16"
  create_label "needs-plan" "Plan PR opened and waiting to be merged" "1D76DB"
  create_label "blocked-on-human" "Agent needs human input" "D93F0B"
  create_label "spec-refined" "Plan file created" "0E8A16"
  create_label "ready-for-implementation" "Source issue ready for coding agent" "5319E7"
  create_label "assigned-to-agent" "Issue dispatched to coding agent" "BFD4F2"
  create_label "impl:claude-opus" "Manual hand-off to Claude Opus" "7057FF"
  create_label "impl:claude-sonnet" "Manual hand-off to Claude Sonnet" "A371F7"
  create_label "impl:copilot" "Auto-route to Copilot cloud agent" "3FB950"
  create_label "impl:codex" "Manual hand-off to Codex" "F9826C"
  create_label "ai-reviewed" "PR passed automated review" "0E8A16"
  create_label "needs-changes" "PR has blockers or missed criteria" "D93F0B"
  create_label "fast-track" "PR is small, clean, and ready to merge" "0E8A16"
  create_label "spec-drift" "PR does things the plan did not ask for" "E4E669"
  create_label "human-review" "Emergency stop for automation" "B60205"
  create_label "needs-rebase" "PR needs origin/main merged into it" "E4E669"
  create_label "eval-regression" "One or more eval cases failed on this PR" "E4E669"
  create_label "self-improvement" "Created by the learning loop" "C5DEF5"
  create_label "ci-fix" "Created by ci-cleaner" "FBCA04"
  create_label "plan-file" "PR contains a plan file" "D4C5F9"
  create_label "workflow-health" "Tracks workflow or data-layer issues" "FEF2C0"
  create_label "automation" "Created by automation" "BFDADC"
  create_label "low-risk" "Routine low-risk automation output" "C2E0C6"
  create_label "pr-fix" "Created by /pr-fix" "F9D0C4"
fi
echo ""

info "Compiling workflows..."
gh aw compile
echo ""

info "Done."
echo ""
echo "Next steps:"
echo "  1. Review .github/workflows/*.md and adjust any project-specific wording"
echo "  2. Confirm required Actions secrets exist in the target repo, especially COPILOT_GITHUB_TOKEN and GH_AW_AGENT_TOKEN"
echo "  3. Confirm Workflow permissions are set to read and write"
echo "  4. Commit and push the installed files"
echo "  5. Open an issue and add the 'needs-spec' label to test the chain"
