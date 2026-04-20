#!/usr/bin/env bash
# Live integration test for dev-team shared memory using the real architect agent.
#
# Usage: bash tests/validate_dev_team_memory_runtime.sh
#
# This test launches a real non-interactive Claude session in a temporary git repo,
# uses the real architect agent definition, and verifies that team memory files are
# created and indexed in the repo-local .claude/team-memory directory.

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

REPO_ROOT="$(git rev-parse --show-toplevel)"
TMPDIR="$(mktemp -d /tmp/dev-team-memory-runtime.XXXXXX)"
MEMORY_DIR="$TMPDIR/.claude/team-memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
OUTPUT_FILE="$TMPDIR/architect-output.txt"
TOPIC_REL_PATH=""
TOPIC_FILE=""
INDEXED_REL_PATH=""

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

section "1. Set up isolated runtime repo"

if git -C "$TMPDIR" init >/dev/null 2>&1; then
  pass "temporary git repo initialized"
else
  fail "temporary git repo initialized"
fi

mkdir -p "$MEMORY_DIR" "$TMPDIR/shared"
cp "$REPO_ROOT/shared/team-memory-protocol.md" "$TMPDIR/shared/team-memory-protocol.md"
cp "$REPO_ROOT/shared/operational-resilience.md" "$TMPDIR/shared/operational-resilience.md"
cat > "$MEMORY_INDEX" <<'EOF'
# Dev Team Shared Memory

All agents: read this file at the start of every task. User preferences here ALWAYS override defaults, conventions, and your own judgment.

Read individual memory files for details. Update this index and create new memory files when you learn new preferences.

<!-- Keep this index under 200 lines. Prune stale entries. -->
EOF

if [[ -f "$MEMORY_INDEX" ]]; then
  pass "seed MEMORY.md created"
else
  fail "seed MEMORY.md created"
fi

section "2. Run live architect agent"

PROMPT=$(cat <<'EOF'
Read shared/team-memory-protocol.md and .claude/team-memory/MEMORY.md.
Create a team memory topic file for this reusable user preference: use one-line imperative commit messages.
Then update MEMORY.md to index it.
Respond with only the changed file paths.
EOF
)

if env -C "$TMPDIR" claude -p --bare --plugin-dir "$REPO_ROOT" --agent architect --allowedTools "Read,Write,Edit,Bash" -- "$PROMPT" > "$OUTPUT_FILE" < /dev/null; then
  pass "live architect run completed"
else
  fail "live architect run completed" "claude -p architect invocation failed"
fi

TOPIC_REL_PATH=$(grep -E '^\.claude/team-memory/[^/]+\.md$' "$OUTPUT_FILE" | grep -v '/MEMORY.md$' | head -n 1 || true)
if [[ -n "$TOPIC_REL_PATH" ]]; then
  TOPIC_FILE="$TMPDIR/$TOPIC_REL_PATH"
fi

INDEXED_REL_PATH=$(python3 - <<'PY' "$MEMORY_INDEX"
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
patterns = [
    r'\[[^\]]+\]\((?:\./)?([^)]+\.md)\)',
    r'`((?:\./)?[^`]+\.md)`',
]
for pattern in patterns:
    match = re.search(pattern, text)
    if match:
        print(match.group(1))
        break
else:
    print('')
PY
)

section "3. Verify memory files were written"

if [[ -n "$TOPIC_REL_PATH" ]]; then
  pass "architect output included a repo-local topic file path"
else
  fail "architect output included a repo-local topic file path" "No topic file path found in $OUTPUT_FILE"
fi

if [[ -n "$TOPIC_FILE" && -f "$TOPIC_FILE" ]]; then
  pass "topic file created in repo-local team memory"
else
  fail "topic file created in repo-local team memory" "Missing runtime topic file under $MEMORY_DIR"
fi

if [[ -n "$INDEXED_REL_PATH" ]]; then
  pass "MEMORY.md indexed a topic file"
else
  fail "MEMORY.md indexed a topic file" "Expected a markdown link in $MEMORY_INDEX"
fi

if [[ -n "$TOPIC_REL_PATH" && -n "$INDEXED_REL_PATH" ]]; then
  NORMALIZED_INDEXED_REL_PATH="${INDEXED_REL_PATH#./}"
  if [[ "$TOPIC_REL_PATH" == ".claude/team-memory/$NORMALIZED_INDEXED_REL_PATH" ]]; then
    pass "MEMORY.md indexed the file written by the architect"
  else
    fail "MEMORY.md indexed the file written by the architect" "Output path '$TOPIC_REL_PATH' did not match indexed path '$INDEXED_REL_PATH'"
  fi
else
  fail "MEMORY.md indexed the file written by the architect" "Missing output path or indexed path"
fi

if grep -qi 'imperative commit messages' "$MEMORY_INDEX"; then
  pass "MEMORY.md recorded the preference summary"
else
  fail "MEMORY.md recorded the preference summary" "Expected preference summary in $MEMORY_INDEX"
fi

if [[ -n "$TOPIC_FILE" ]] && grep -q '^name:' "$TOPIC_FILE"; then
  pass "topic file captured memory name"
else
  fail "topic file captured memory name" "Missing name field in runtime topic file"
fi

if [[ -n "$TOPIC_FILE" ]] && grep -q '^type: preference$' "$TOPIC_FILE"; then
  pass "topic file captured preference type"
else
  fail "topic file captured preference type" "Unexpected type field in runtime topic file"
fi

if [[ -n "$TOPIC_FILE" ]] && grep -qi 'one-line imperative commit messages' "$TOPIC_FILE"; then
  pass "topic file captured the reusable preference"
else
  fail "topic file captured the reusable preference" "Preference body missing from runtime topic file"
fi

section "4. Verify agent output references the written files"

if [[ -n "$TOPIC_REL_PATH" ]] && grep -Fq "$TOPIC_REL_PATH" "$OUTPUT_FILE"; then
  pass "architect output referenced topic file"
else
  fail "architect output referenced topic file" "Expected topic path in architect output"
fi

if grep -q '\.claude/team-memory/MEMORY.md' "$OUTPUT_FILE"; then
  pass "architect output referenced MEMORY.md"
else
  fail "architect output referenced MEMORY.md" "Expected MEMORY.md path in architect output"
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
