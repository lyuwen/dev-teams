#!/usr/bin/env bash
# Validation checks for dev-team launcher memory wiring and team isolation.
#
# Usage: bash tests/validate_dev_team_memory.sh
# Exit 0 = all pass, Exit 1 = one or more failures

set -euo pipefail

PASS=0
FAIL=0
TOTAL=0

pass() {
  TOTAL=$((TOTAL + 1))
  PASS=$((PASS + 1))
  printf "  \033[32mPASS\033[0m  %s\n" "$1"
}

fail() {
  TOTAL=$((TOTAL + 1))
  FAIL=$((FAIL + 1))
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  if [[ -n "${2:-}" ]]; then
    printf "        → %s\n" "$2"
  fi
}

section() {
  echo ""
  printf "\033[1m=== %s ===\033[0m\n" "$1"
}

SKILL_FILE="skills/dev-team/SKILL.md"
HELP_FILE="skills/dev-team-help/SKILL.md"
README_FILE="README.md"
ARCHITECT_FILE="agents/architect.md"

section "1. Dev-team launcher uses project-scoped teams"

if grep -q 'project-scoped team name' "$SKILL_FILE"; then
  pass "launcher describes project-scoped team naming"
else
  fail "launcher describes project-scoped team naming" "Expected 'project-scoped team name' in $SKILL_FILE"
fi

if grep -q 'derived `team_name`' "$SKILL_FILE"; then
  pass "launcher reuses derived team_name in spawns"
else
  fail "launcher reuses derived team_name in spawns" "Expected 'derived `team_name`' in $SKILL_FILE"
fi

if grep -q 'team_name: "dev-team"' "$SKILL_FILE"; then
  fail "launcher no longer hardcodes team_name: \"dev-team\"" "Found stale hardcoded team_name in $SKILL_FILE"
else
  pass "launcher no longer hardcodes team_name: \"dev-team\""
fi

if grep -q 'Use TeamCreate with team name `dev-team`' "$SKILL_FILE"; then
  fail "launcher no longer hardcodes TeamCreate team name" "Found stale TeamCreate instruction in $SKILL_FILE"
else
  pass "launcher no longer hardcodes TeamCreate team name"
fi

section "2. Dev-team launcher reinforces memory behavior"

if grep -q '.claude/team-memory/MEMORY.md' "$SKILL_FILE"; then
  pass "launcher mentions team memory file"
else
  fail "launcher mentions team memory file" "Expected .claude/team-memory/MEMORY.md in $SKILL_FILE"
fi

if grep -q 'proactively update/index team memory' "$SKILL_FILE"; then
  pass "launcher tells Architect to proactively index memory"
else
  fail "launcher tells Architect to proactively index memory" "Expected proactive memory indexing instruction in $SKILL_FILE"
fi

if grep -q 'create or update a focused memory topic file' "$SKILL_FILE"; then
  pass "launcher tells non-leads to create topic files and notify Architect"
else
  fail "launcher tells non-leads to create topic files and notify Architect" "Expected non-lead memory instruction in $SKILL_FILE"
fi

section "3. Architect respawn stays on current team"

if grep -q 'team_name: "dev-team"' "$ARCHITECT_FILE"; then
  fail "architect respawn no longer hardcodes dev-team" "Found stale hardcoded respawn team in $ARCHITECT_FILE"
else
  pass "architect respawn no longer hardcodes dev-team"
fi

if grep -q 'same `name`, `subagent_type`, and `team_name`' "$ARCHITECT_FILE"; then
  pass "architect respawn uses generic current team_name"
else
  fail "architect respawn uses generic current team_name" "Expected generic team_name wording in $ARCHITECT_FILE"
fi

section "4. Docs describe isolated shared memory behavior"

if grep -q 'project-scoped runtime team' "$README_FILE"; then
  pass "README documents project-scoped runtime teams"
else
  fail "README documents project-scoped runtime teams" "Expected project-scoped runtime team wording in $README_FILE"
fi

if grep -q 'project-scoped runtime team' "$HELP_FILE"; then
  pass "dev-team-help documents project-scoped runtime teams"
else
  fail "dev-team-help documents project-scoped runtime teams" "Expected project-scoped runtime team wording in $HELP_FILE"
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo ""
  printf "\033[32mAll %d checks passed.\033[0m\n" "$TOTAL"
  exit 0
else
  echo ""
  printf "\033[31m%d of %d checks failed.\033[0m\n" "$FAIL" "$TOTAL"
  exit 1
fi
