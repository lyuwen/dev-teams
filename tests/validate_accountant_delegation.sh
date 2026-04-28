#!/bin/bash
# Validation script for Accountant delegation boundaries
# Checks that the Accountant follows delegation rules

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Accountant Delegation Validation ==="
echo ""

VIOLATIONS=0

# Check 1: Static structure - verify sections exist in accountant.md
echo "Check 1: Verifying accountant.md structure..."

if ! grep -q "^## Work Classification" "$PROJECT_ROOT/agents/accountant.md"; then
    echo "  ❌ FAIL: Missing 'Work Classification' section in agents/accountant.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Work Classification section exists"
fi

if ! grep -q "^## Agent Spawning Reference" "$PROJECT_ROOT/agents/accountant.md"; then
    echo "  ❌ FAIL: Missing 'Agent Spawning Reference' section in agents/accountant.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Agent Spawning Reference section exists"
fi

if ! grep -q "^## Production vs. Ad-Hoc Code" "$PROJECT_ROOT/agents/accountant.md"; then
    echo "  ❌ FAIL: Missing 'Production vs. Ad-Hoc Code' section in agents/accountant.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Production vs. Ad-Hoc Code section exists"
fi

if ! grep -q "subagent_type: \"minuteman\"" "$PROJECT_ROOT/agents/accountant.md"; then
    echo "  ❌ FAIL: Missing minuteman spawn template in agents/accountant.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Minuteman spawn template exists"
fi

echo ""

# Check 2: Cross-team protocol structure
echo "Check 2: Verifying cross-team-protocol.md structure..."

if ! grep -q "^## Delegation Boundaries" "$PROJECT_ROOT/shared/cross-team-protocol.md"; then
    echo "  ❌ FAIL: Missing 'Delegation Boundaries' section in shared/cross-team-protocol.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Delegation Boundaries section exists"
fi

if ! grep -q "Data Team Scope" "$PROJECT_ROOT/shared/cross-team-protocol.md"; then
    echo "  ❌ FAIL: Missing 'Data Team Scope' in cross-team-protocol.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Data Team Scope defined"
fi

if ! grep -q "Dev Team Scope" "$PROJECT_ROOT/shared/cross-team-protocol.md"; then
    echo "  ❌ FAIL: Missing 'Dev Team Scope' in cross-team-protocol.md"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo "  ✓ Dev Team Scope defined"
fi

echo ""

# Check 3: Git history analysis - look for production code violations
echo "Check 3: Analyzing git history for production code violations..."

# Check if git repo exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "  ⚠ SKIP: Not a git repository"
else
    # Look for commits by accountant that touch files outside data-team-output/
    ACCOUNTANT_COMMITS=$(git -C "$PROJECT_ROOT" log --all --author="accountant" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v "^$" || true)

    if [ -n "$ACCOUNTANT_COMMITS" ]; then
        PRODUCTION_FILES=$(echo "$ACCOUNTANT_COMMITS" | grep -v "^data-team-output/" || true)

        if [ -n "$PRODUCTION_FILES" ]; then
            echo "  ❌ FAIL: Accountant committed production code files:"
            echo "$PRODUCTION_FILES" | sed 's/^/    /'
            VIOLATIONS=$((VIOLATIONS + 1))
        else
            echo "  ✓ No production code violations in git history"
        fi
    else
        echo "  ✓ No accountant commits found (expected for new setup)"
    fi
fi

echo ""

# Check 4: Session log parsing - verify spawn correctness
echo "Check 4: Checking session logs for spawn correctness..."

SESSION_DIR="$PROJECT_ROOT/.claude/sessions"

if [ ! -d "$SESSION_DIR" ]; then
    echo "  ⚠ SKIP: No session logs found at $SESSION_DIR"
else
    # Find recent session logs (last 10)
    RECENT_LOGS=$(find "$SESSION_DIR" -name "*.jsonl" -type f 2>/dev/null | sort -r | head -n 10)

    if [ -z "$RECENT_LOGS" ]; then
        echo "  ⚠ SKIP: No .jsonl session logs found"
    else
        SPAWN_VIOLATIONS=0

        for LOG in $RECENT_LOGS; do
            # Look for Agent tool calls in accountant sessions
            # Check if any spawns are missing subagent_type: "minuteman" for data analysis

            # Extract Agent tool calls from accountant
            AGENT_CALLS=$(grep -o '"name":"Agent"' "$LOG" 2>/dev/null | wc -l || echo "0")

            if [ "$AGENT_CALLS" -gt 0 ]; then
                # Check for vanilla spawns (Agent calls without subagent_type: minuteman)
                # This is a simplified check - full implementation would parse JSON properly
                VANILLA_SPAWNS=$(grep '"name":"Agent"' "$LOG" | grep -v 'subagent_type.*minuteman' | wc -l || echo "0")

                if [ "$VANILLA_SPAWNS" -gt 0 ]; then
                    echo "  ⚠ WARNING: Found $VANILLA_SPAWNS potential vanilla spawns in $(basename "$LOG")"
                    SPAWN_VIOLATIONS=$((SPAWN_VIOLATIONS + 1))
                fi
            fi
        done

        if [ "$SPAWN_VIOLATIONS" -eq 0 ]; then
            echo "  ✓ No spawn violations detected in recent sessions"
        else
            echo "  ⚠ Found potential spawn violations in $SPAWN_VIOLATIONS session(s)"
            echo "    (Manual review recommended - this is a heuristic check)"
        fi
    fi
fi

echo ""
echo "=== Validation Summary ==="
echo ""

if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✅ All checks passed! Delegation boundaries are properly configured."
    exit 0
else
    echo "❌ Found $VIOLATIONS violation(s). Review the output above for details."
    exit 1
fi
