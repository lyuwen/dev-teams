#!/usr/bin/env bash
# Validation tests for the 3 usability testing agents (documenter, noob, instructor)
# and their integration into the existing dev-team plugin files.
#
# Usage: bash tests/validate_usability_agents.sh
# Exit 0 = all pass, Exit 1 = one or more failures

set -euo pipefail

# -- Counters ------------------------------------------------------------------
PASS=0
FAIL=0
TOTAL=0

# -- Helpers -------------------------------------------------------------------
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

# Extract YAML frontmatter (between first and second ---) from a file.
# Outputs the frontmatter lines (excluding delimiters).
frontmatter() {
  awk 'BEGIN{n=0} /^---/{n++; next} n==1{print} n>=2{exit}' "$1"
}

# Extract system prompt body (everything after the second ---).
body() {
  awk 'BEGIN{n=0} /^---/{n++; next} n>=2{print}' "$1"
}

# -- Paths (relative to repo root) --------------------------------------------
AGENTS_DIR="agents"
SKILL_FILE="skills/dev-team/SKILL.md"
PLUGIN_FILE=".claude-plugin/plugin.json"

DOCUMENTER="$AGENTS_DIR/documenter.md"
NOOB="$AGENTS_DIR/noob.md"
INSTRUCTOR="$AGENTS_DIR/instructor.md"
IMPLEMENTER="$AGENTS_DIR/implementer.md"
TESTER_FILE="$AGENTS_DIR/tester.md"
REVIEWER="$AGENTS_DIR/reviewer.md"

# Known-good blob hashes of files that must NOT be modified.
IMPLEMENTER_HASH="19ae131b2af8e04ab4d76d75e7bcf42aacd0648c"
TESTER_HASH="76636fd0529a4f2ecdce8722f2dcdb72c298720b"
REVIEWER_HASH="43498a8691f9c6c7c3a5b325f7c051e4a2ba5c39"

###############################################################################
# 1. FILE EXISTENCE
###############################################################################
section "1. File Existence"

for f in "$DOCUMENTER" "$NOOB" "$INSTRUCTOR"; do
  name="$(basename "$f")"
  if [[ -f "$f" ]]; then
    pass "$name exists"
  else
    fail "$name exists" "File not found: $f"
  fi
done

###############################################################################
# 2. YAML FRONTMATTER STRUCTURE
###############################################################################
section "2. YAML Frontmatter Structure"

# Checks applied to each agent: (file, expected_name, expected_color)
declare -a AGENTS=(
  "$DOCUMENTER|documenter|blue"
  "$NOOB|noob|yellow"
  "$INSTRUCTOR|instructor|cyan"
)

for entry in "${AGENTS[@]}"; do
  IFS='|' read -r file ename ecolor <<< "$entry"
  label="$(basename "$file")"

  if [[ ! -f "$file" ]]; then
    fail "$label frontmatter — file missing, skipping" ""
    continue
  fi

  # Starts with ---
  if head -1 "$file" | grep -q '^---$'; then
    pass "$label starts with --- delimiter"
  else
    fail "$label starts with --- delimiter" "First line: $(head -1 "$file")"
  fi

  fm=$(frontmatter "$file")

  # name field
  if echo "$fm" | grep -qE "^name:\s*${ename}\s*$"; then
    pass "$label name: $ename"
  else
    fail "$label name: $ename" "Got: $(echo "$fm" | grep '^name:' || echo '(missing)')"
  fi

  # description non-empty
  if echo "$fm" | grep -qE "^description:\s*\|?\s*$" || echo "$fm" | grep -qE "^description:\s+\S"; then
    # Check that the description block has actual content (not just the key)
    desc_content=$(echo "$fm" | awk '/^description:/{found=1; sub(/^description:\s*\|?\s*/, ""); if(length($0)>0) print; next} found && /^\s/{print; next} found{exit}')
    if echo "$fm" | grep -qP "^description:\s*\S" || [[ -n "$desc_content" ]]; then
      pass "$label has non-empty description"
    else
      fail "$label has non-empty description" "description field appears empty"
    fi
  else
    fail "$label has non-empty description" "No description field found"
  fi

  # model: inherit
  if echo "$fm" | grep -qE "^model:\s*inherit\s*$"; then
    pass "$label model: inherit"
  else
    fail "$label model: inherit" "Got: $(echo "$fm" | grep '^model:' || echo '(missing)')"
  fi

  # color field
  if echo "$fm" | grep -qE "^color:\s*${ecolor}\s*$"; then
    pass "$label color: $ecolor"
  else
    fail "$label color: $ecolor" "Got: $(echo "$fm" | grep '^color:' || echo '(missing)')"
  fi

  # Second --- delimiter (closes frontmatter)
  second_delim=$(awk 'BEGIN{n=0} /^---/{n++; if(n==2){print "found"; exit}}' "$file")
  if [[ "$second_delim" == "found" ]]; then
    pass "$label has closing --- delimiter"
  else
    fail "$label has closing --- delimiter" "Could not find second --- in file"
  fi
done

# Tool restrictions
section "2b. Tool Restrictions"

if [[ -f "$DOCUMENTER" ]]; then
  fm_doc=$(frontmatter "$DOCUMENTER")
  if echo "$fm_doc" | grep -qE "^tools:"; then
    fail "documenter.md has NO tools: field (All tools)" "Found a tools: field — documenter should have All tools (omit the field)"
  else
    pass "documenter.md has NO tools: field (All tools)"
  fi
fi

if [[ -f "$NOOB" ]]; then
  fm_noob=$(frontmatter "$NOOB")
  if echo "$fm_noob" | grep -qE '^tools:\s*\["Bash"\]\s*$'; then
    pass "noob.md tools: [\"Bash\"] exactly"
  else
    fail "noob.md tools: [\"Bash\"] exactly" "Got: $(echo "$fm_noob" | grep '^tools:' || echo '(missing)')"
  fi
fi

if [[ -f "$INSTRUCTOR" ]]; then
  fm_inst=$(frontmatter "$INSTRUCTOR")
  tools_line=$(echo "$fm_inst" | grep '^tools:' || true)
  if [[ -z "$tools_line" ]]; then
    fail "instructor.md has tools: field" "No tools: field found"
  else
    missing=""
    for tool in Read Grep Glob Bash; do
      if ! echo "$tools_line" | grep -q "\"$tool\""; then
        missing="$missing $tool"
      fi
    done
    if [[ -z "$missing" ]]; then
      pass "instructor.md tools: contains Read, Grep, Glob, Bash"
    else
      fail "instructor.md tools: contains Read, Grep, Glob, Bash" "Missing:$missing — Got: $tools_line"
    fi
  fi
fi

###############################################################################
# 3. CONTENT COMPLETENESS
###############################################################################
section "3. Content Completeness — Generic Checks"

for entry in "${AGENTS[@]}"; do
  IFS='|' read -r file ename ecolor <<< "$entry"
  label="$(basename "$file")"

  if [[ ! -f "$file" ]]; then
    fail "$label content checks — file missing, skipping" ""
    continue
  fi

  fm=$(frontmatter "$file")
  bd=$(body "$file")

  # At least 2 <example> blocks in description (frontmatter)
  example_count=$(echo "$fm" | grep -c '<example>' || true)
  if [[ "$example_count" -ge 2 ]]; then
    pass "$label has >= 2 <example> blocks in description ($example_count found)"
  else
    fail "$label has >= 2 <example> blocks in description" "Found $example_count"
  fi

  # <commentary> tags inside examples
  if echo "$fm" | grep -q '<commentary>'; then
    pass "$label has <commentary> tags in examples"
  else
    fail "$label has <commentary> tags in examples" "No <commentary> tags found in frontmatter"
  fi

  # ## headings in body
  heading_count=$(echo "$bd" | grep -cE '^##\s' || true)
  if [[ "$heading_count" -ge 2 ]]; then
    pass "$label system prompt has ## headings ($heading_count found)"
  else
    fail "$label system prompt has ## headings" "Found $heading_count"
  fi

  # Core Responsibilities section
  if echo "$bd" | grep -qiE '^\#\#.*Responsibilities'; then
    pass "$label has Core Responsibilities section"
  else
    fail "$label has Core Responsibilities section" "No heading matching 'Responsibilities' found"
  fi

  # What You Do NOT Do section
  if echo "$bd" | grep -qiE '^\#\#.*Do NOT Do|^\#\#.*Do Not Do'; then
    pass "$label has 'What You Do NOT Do' section"
  else
    fail "$label has 'What You Do NOT Do' section" "No matching heading found"
  fi
done

section "3b. Content Completeness — Agent-Specific (documenter)"

if [[ -f "$DOCUMENTER" ]]; then
  content=$(cat "$DOCUMENTER")

  if echo "$content" | grep -qi 'documentation'; then
    pass "documenter.md mentions 'documentation'"
  else
    fail "documenter.md mentions 'documentation'" ""
  fi

  if echo "$content" | grep -qi 'source code access'; then
    pass "documenter.md mentions 'source code access'"
  else
    fail "documenter.md mentions 'source code access'" ""
  fi
fi

section "3c. Content Completeness — Agent-Specific (noob)"

if [[ -f "$NOOB" ]]; then
  content=$(cat "$NOOB")

  if echo "$content" | grep -qiE 'MUST NOT read.*(source|code)|MUST NOT.*(read|access).*source'; then
    pass "noob.md has 'MUST NOT read source code' restriction"
  else
    fail "noob.md has 'MUST NOT read source code' restriction" ""
  fi

  if echo "$content" | grep -qi 'Bash'; then
    pass "noob.md mentions Bash as tool"
  else
    fail "noob.md mentions Bash as tool" ""
  fi

  if echo "$content" | grep -qiE 'temporary|isolated|temp.dir'; then
    pass "noob.md mentions temporary/isolated directory"
  else
    fail "noob.md mentions temporary/isolated directory" ""
  fi

  if echo "$content" | grep -qi 'Instructor'; then
    pass "noob.md mentions Instructor"
  else
    fail "noob.md mentions Instructor" ""
  fi
fi

section "3d. Content Completeness — Agent-Specific (instructor)"

if [[ -f "$INSTRUCTOR" ]]; then
  content=$(cat "$INSTRUCTOR")

  if echo "$content" | grep -qi 'Noob'; then
    pass "instructor.md references Noob"
  else
    fail "instructor.md references Noob" ""
  fi

  if echo "$content" | grep -qiE 'UX|usability'; then
    pass "instructor.md mentions UX/usability"
  else
    fail "instructor.md mentions UX/usability" ""
  fi

  if echo "$content" | grep -qiE '^\#\#.*report|^\#\#.*findings|^\#\#.*format'; then
    pass "instructor.md has report format section"
  else
    fail "instructor.md has report format section" "No heading matching report/findings/format found"
  fi

  if echo "$content" | grep -qi 'SendMessage'; then
    pass "instructor.md mentions SendMessage"
  else
    fail "instructor.md mentions SendMessage" ""
  fi
fi

###############################################################################
# 4. INTEGRATION CONSISTENCY
###############################################################################
section "4. Integration Consistency — SKILL.md"

if [[ -f "$SKILL_FILE" ]]; then
  skill=$(cat "$SKILL_FILE")

  for agent in Documenter Instructor Noob; do
    if echo "$skill" | grep -q "$agent"; then
      pass "SKILL.md mentions $agent"
    else
      fail "SKILL.md mentions $agent" ""
    fi
  done

  if echo "$skill" | grep -qi '8-agent'; then
    pass "SKILL.md references 8-agent team"
  else
    fail "SKILL.md references 8-agent team" "May still say 4-agent or 5-agent"
  fi

  if echo "$skill" | grep -qiE 'usability.*(test|phase)|usability'; then
    pass "SKILL.md workflow mentions usability testing"
  else
    fail "SKILL.md workflow mentions usability testing" ""
  fi
else
  fail "SKILL.md exists" "File not found: $SKILL_FILE"
fi

section "4b. Integration Consistency — architect.md"

if [[ -f "$AGENTS_DIR/architect.md" ]]; then
  arch=$(cat "$AGENTS_DIR/architect.md")

  for agent in Documenter Instructor Noob; do
    if echo "$arch" | grep -q "$agent"; then
      pass "architect.md mentions $agent"
    else
      fail "architect.md mentions $agent" ""
    fi
  done

  if echo "$arch" | grep -qiE 'usability.*(test|phase|workflow)|usability'; then
    pass "architect.md has usability testing workflow"
  else
    fail "architect.md has usability testing workflow" ""
  fi
else
  fail "architect.md exists" "File not found"
fi

section "4c. Integration Consistency — plugin.json"

if [[ -f "$PLUGIN_FILE" ]]; then
  pjson=$(cat "$PLUGIN_FILE")

  if echo "$pjson" | grep -qi 'dev-team'; then
    pass "plugin.json references dev-team"
  else
    fail "plugin.json references dev-team" "$(grep -i 'team' "$PLUGIN_FILE" || echo '(no match)')"
  fi

  if echo "$pjson" | grep -qi 'data-team\|minute-men\|Accountant'; then
    pass "plugin.json references data-team"
  else
    fail "plugin.json references data-team" ""
  fi
else
  fail "plugin.json exists" "File not found: $PLUGIN_FILE"
fi

###############################################################################
# 5. EXISTING FILES NOT MODIFIED
###############################################################################
section "5. Existing Files Not Modified"

check_unchanged() {
  local file="$1"
  local expected_hash="$2"
  local label="$(basename "$file")"

  if [[ ! -f "$file" ]]; then
    fail "$label unchanged (file missing!)" ""
    return
  fi

  actual_hash=$(git hash-object "$file")
  if [[ "$actual_hash" == "$expected_hash" ]]; then
    pass "$label unchanged (hash matches)"
  else
    fail "$label unchanged" "Expected hash $expected_hash, got $actual_hash — file was modified"
  fi
}

check_unchanged "$IMPLEMENTER" "$IMPLEMENTER_HASH"
check_unchanged "$TESTER_FILE" "$TESTER_HASH"
check_unchanged "$REVIEWER"   "$REVIEWER_HASH"

###############################################################################
# SUMMARY
###############################################################################
echo ""
echo "========================================"
printf "  Total: %d  |  \033[32mPassed: %d\033[0m  |  \033[31mFailed: %d\033[0m\n" "$TOTAL" "$PASS" "$FAIL"
echo "========================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
