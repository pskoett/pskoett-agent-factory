#!/usr/bin/env bash
# Install the pskoett agent factory into the current repository.
#
# This script:
#   1. Copies workflow files to .github/workflows/
#   2. Vendors skills to .claude/skills/
#   3. Copies AGENTS.md if not present
#   4. Seeds .learnings/ directory
#   5. Creates all factory labels
#   6. Compiles all workflows
#
# Prerequisites: gh CLI, gh-aw extension, COPILOT_GITHUB_TOKEN secret.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}!!${NC} %s\n" "$*"; }
error() { printf "${RED}xx${NC} %s\n" "$*" >&2; }

# Check prerequisites
command -v gh >/dev/null 2>&1 || { error "gh CLI not found. Install from https://cli.github.com"; exit 1; }
gh extension list 2>/dev/null | grep -q "gh-aw" || { error "gh-aw extension not installed. Run: gh extension install github/gh-aw"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { error "Not in a git repository"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
info "Installing agent factory from ${SCRIPT_DIR}"
echo ""

# Step 1: Copy workflows
info "Copying workflow files to .github/workflows/..."
mkdir -p .github/workflows
for wf in "$SCRIPT_DIR"/workflows/*.md; do
  name=$(basename "$wf")
  if [ -f ".github/workflows/$name" ]; then
    warn "$name already exists, skipping (use --force to overwrite)"
  else
    cp "$wf" ".github/workflows/$name"
    printf "  + %s\n" "$name"
  fi
done
echo ""

# Step 2: Vendor skills
info "Vendoring skills to .claude/skills/..."
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
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

# Step 3: Copy AGENTS.md if not present
if [ ! -f "AGENTS.md" ]; then
  info "Copying AGENTS.md..."
  cp "$SCRIPT_DIR/AGENTS.md" AGENTS.md
else
  warn "AGENTS.md already exists. Consider merging the factory sections from ${SCRIPT_DIR}/AGENTS.md"
fi
echo ""

# Step 4: Seed .learnings/
if [ ! -f ".learnings/LEARNINGS.md" ]; then
  info "Seeding .learnings/ directory..."
  mkdir -p .learnings
  cp "$SCRIPT_DIR/.learnings/LEARNINGS.md" .learnings/LEARNINGS.md
else
  info ".learnings/ already exists"
fi
echo ""

# Step 5: Create docs/plans/
if [ ! -d "docs/plans" ]; then
  info "Creating docs/plans/ directory..."
  mkdir -p docs/plans
  cp "$SCRIPT_DIR/docs/plans-README.md" docs/plans/README.md
else
  info "docs/plans/ already exists"
fi
echo ""

# Step 6: Create labels
info "Creating factory labels..."
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  warn "Could not detect repo. Skipping label creation. Create labels manually."
else
  create_label() {
    gh label create "$1" --repo "$REPO" --description "$2" --color "$3" 2>/dev/null \
      && printf "  + %s\n" "$1" \
      || printf "  = %s (exists)\n" "$1"
  }
  create_label "needs-spec" "Issue needs a structured plan file" "0E8A16"
  create_label "needs-plan" "Spec ready, waiting for /plan" "1D76DB"
  create_label "blocked-on-human" "Agent needs human input" "D93F0B"
  create_label "spec-refined" "Spec refinement complete" "0E8A16"
  create_label "ready-for-implementation" "Sub-issue ready for coding agent" "5319E7"
  create_label "impl:claude-opus" "Route to Claude Opus 4.6" "7057FF"
  create_label "impl:claude-sonnet" "Route to Claude Sonnet 4.6" "A371F7"
  create_label "impl:copilot" "Route to Copilot cloud agent" "3FB950"
  create_label "impl:codex" "Route to Codex GPT-5.4" "F9826C"
  create_label "assigned-to-agent" "Sub-issue dispatched to agent" "BFD4F2"
  create_label "ai-reviewed" "PR passed automated review" "0E8A16"
  create_label "needs-changes" "PR has critical findings" "D93F0B"
  create_label "fast-track" "Zero findings, ready to merge" "0E8A16"
  create_label "spec-drift" "PR does things plan did not ask for" "E4E669"
  create_label "human-review" "Emergency stop: all agents noop" "B60205"
  create_label "self-improvement" "PR from nightly learning loop" "C5DEF5"
  create_label "ci-fix" "PR from CI cleaner" "FBCA04"
  create_label "plan-file" "PR contains a plan file" "D4C5F9"
  create_label "workflow-health" "Workflow infrastructure issue" "FEF2C0"
fi
echo ""

# Step 7: Compile
info "Compiling workflows..."
gh aw compile
echo ""

info "Done."
echo ""
echo "Next steps:"
echo "  1. Review .github/workflows/*.md and adjust for your project"
echo "  2. Ensure COPILOT_GITHUB_TOKEN secret exists in repo settings"
echo "  3. Enable: Settings > Actions > General > Allow GitHub Actions to create and approve pull requests"
echo "  4. Commit and push:"
echo "       git add .github/ .claude/skills/ AGENTS.md .learnings/ docs/plans/"
echo "       git commit -m 'Install agent factory chain'"
echo "       git push"
echo "  5. Open an issue and add the 'needs-spec' label to test the chain"
