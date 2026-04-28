# Data Team Delegation Boundaries Design

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Fix Accountant delegation issues - ensure minute-men spawning and proper dev team handoff

## Problem Statement

The Accountant has three delegation violations:

1. **Spawning vanilla subagents instead of minute-men** - When given data analysis tasks, the Accountant spawns generic subagents instead of using `subagent_type: "minuteman"`
2. **Writing production code instead of delegating** - When asked to "consolidate production-grade data processing code" or "build a reusable tool", the Accountant implements it directly instead of writing a PRD for the dev team
3. **Unclear boundaries** - The line between "ad-hoc script" (OK for minute-men) and "production tool" (delegate to dev team) is not explicit enough

These violations break the team structure and prevent proper specialization.

## Root Cause Analysis

The current `accountant.md` instructions:
- Mention spawning minute-men but don't provide exact syntax examples
- Say "don't write production tooling" but don't define what counts as production
- Lack decision trees to force correct classification of incoming work
- Have no enforcement mechanism to catch violations

## Solution Architecture

**Two-layer approach:**

1. **Prevention Layer:** Explicit decision trees + spawn templates in Accountant instructions
2. **Detection Layer:** Runtime validation script that checks delegation behavior post-hoc

This provides both proactive guidance (clear instructions) and reactive feedback (validation catches edge cases).

## Design Components

### Component 1: Work Classification Decision Tree

Add a "Work Classification" section to `accountant.md` that forces the Accountant through a decision tree for every incoming task.

**Decision flow:**
```
Incoming work
  ↓
Classify work type
  ↓
  ├─ Data Analysis? → Spawn minute-men
  ├─ Production Code? → Write PRD, send to Architect
  └─ Coordination? → Handle directly
```

**Classification triggers:**

**Data Analysis** (spawn minute-men):
- Keywords: "analyze", "audit", "profile", "check", "find patterns", "investigate", "examine"
- Requires reading/processing datasets
- Output is findings, reports, statistics
- Examples: "audit data quality", "profile distributions", "find duplicates"

**Production Code** (write PRD):
- Keywords: "build tool", "production", "reusable", "consolidate code", "create library"
- Needs to be maintained, tested, documented
- Lives in main codebase (not `data-team-output/`)
- Examples: "build a CLI tool", "consolidate into reusable functions", "create a data processing library"

**Coordination** (handle directly):
- PRD writing and editing
- Architect communication
- Aggregating minute-men results
- Committee discussions
- Examples: "write a PRD for X", "coordinate with Architect", "aggregate findings"

### Component 2: Agent Spawning Reference

Add an "Agent Spawning Reference" section to `accountant.md` with exact Agent tool call templates.

**Template for spawning minute-men:**

```javascript
Agent({
  description: "Analyze shard N of dataset",
  subagent_type: "minuteman",
  team_name: "data-team",
  name: "minuteman-1",
  prompt: `Analyze records 0-10000 in train.jsonl.
  
Objectives:
- Check for empty fields
- Find duplicates  
- Profile distributions

Output: Write report to data-team-output/shard-1/report.md
Send summary: Brief message with top 3 findings when done.`
})
```

**Critical rules:**
- ALWAYS use `subagent_type: "minuteman"` for data analysis work
- ALWAYS use `team_name: "data-team"`
- NEVER spawn vanilla subagents (no subagent_type) for data analysis
- If you're tempted to spawn without `subagent_type: "minuteman"`, STOP and re-classify the work

**Parallel spawning example:**

When sharding into N pieces, spawn all minute-men in a single message for parallel execution:

```javascript
// Spawn 3 minute-men in parallel
Agent({ description: "Shard 1", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-1", prompt: "..." })
Agent({ description: "Shard 2", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-2", prompt: "..." })
Agent({ description: "Shard 3", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-3", prompt: "..." })
```

### Component 3: Production vs. Ad-Hoc Code Boundary

Add a "Production vs. Ad-Hoc Code" section to `accountant.md` that explicitly defines the boundary.

**Ad-hoc scripts** (minute-men write these, OK):
- One-off analysis for a specific task
- Throwaway code that won't be reused across tasks
- Quick data transformations or checks
- Lives in `data-team-output/` or gets discarded after use
- No tests, minimal docs, no error handling
- Examples: `python -c "import pandas; df = pd.read_parquet('data.pq'); print(df.describe())"`, one-off deduplication script

**Production code** (dev team builds via PRD, NEVER write yourself):
- Reusable across multiple datasets/tasks
- Needs error handling, documentation, tests
- Part of a CLI tool, library, or infrastructure
- Lives in the main codebase (not `data-team-output/`)
- User explicitly asks to "consolidate", "build a tool", "make this reusable", "production-grade"
- Examples: CLI tool with subcommands, Python package, reusable library functions

**Decision heuristics:**

| Scenario | Classification | Action |
|----------|---------------|--------|
| User says "analyze this dataset" | Data Analysis | Spawn minute-men |
| User says "build a tool to analyze datasets" | Production Code | Write PRD |
| User says "consolidate these scripts into production code" | Production Code | Write PRD |
| Minute-men flag same workaround 3+ times | Production Code | Write PRD |
| User says "quick check for duplicates" | Data Analysis | Spawn minute-men |
| User says "create a reusable deduplication library" | Production Code | Write PRD |

**When in doubt:** If the user uses words like "production", "tool", "reusable", "consolidate", "library" → write PRD. If minute-men report the same workaround 3+ times across different tasks → write PRD.

### Component 4: Cross-Team Protocol Strengthening

Update `shared/cross-team-protocol.md` to make delegation boundaries explicit and enforceable.

**Add new "Delegation Boundaries" section:**

```markdown
## Delegation Boundaries

### Data Team Scope
- Data analysis, profiling, quality auditing
- Dataset investigation and characterization
- Ad-hoc scripts for one-off tasks
- Identifying tool gaps and writing PRDs
- Aggregating findings and reporting to user

### Dev Team Scope
- Production tools, libraries, CLI commands
- Reusable infrastructure code
- Anything that needs tests, documentation, and maintenance
- Code that lives in the main codebase

### Boundary Enforcement Rules

1. **The Accountant NEVER writes production code**, even if it seems simple or quick
2. If the user asks the Accountant to "build a tool", "consolidate code", or "make it reusable" → Accountant writes PRD, does NOT implement
3. If minute-men report the same workaround 3+ times → Accountant writes PRD for a proper tool
4. Ad-hoc scripts in `data-team-output/` are OK; code in the main codebase is NOT
5. When in doubt, write a PRD and consult the Architect

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → Accountant writes the code
✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → Accountant writes PRD, sends to Architect

❌ **WRONG:** Accountant spawns vanilla subagent for data analysis
✅ **RIGHT:** Accountant spawns minuteman with `subagent_type: "minuteman"`

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → Accountant writes a one-off parser each time
✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → Accountant writes PRD for a reusable CSV parsing tool
```

### Component 5: Runtime Validation Script

Create `tests/validate_accountant_delegation.sh` to detect delegation violations post-hoc.

**Validation checks:**

1. **Spawn validation:**
   - Parse conversation logs for Accountant Agent tool calls
   - Verify all data analysis spawns use `subagent_type: "minuteman"`
   - Flag any vanilla subagent spawns for data work

2. **Production code validation:**
   - Check git commits by Accountant
   - Flag any code files written to main codebase (outside `data-team-output/`)
   - Verify production tool requests resulted in PRDs, not direct implementation

3. **PRD validation:**
   - When user requests production tools, verify PRD exists in `docs/prd/`
   - Check that PRD was sent to Architect via SendMessage

**Implementation approach:**

```bash
#!/bin/bash
# tests/validate_accountant_delegation.sh

# Check 1: Spawn validation
# Parse .claude/sessions/ or conversation logs for Accountant spawns
# Look for Agent tool calls without subagent_type: "minuteman"

# Check 2: Production code validation  
# git log --author="accountant" --name-only
# Flag any files outside data-team-output/

# Check 3: PRD validation
# Check docs/prd/ for expected PRDs
# Verify SendMessage to Architect

# Report violations with context
```

**Usage:**
- Run manually after data-team tasks: `./tests/validate_accountant_delegation.sh`
- Integrate into CI for regression testing
- Provides feedback loop to catch instruction drift

## Implementation Plan

### Phase 1: Accountant Instructions Update

**File:** `agents/accountant.md`

**Changes:**
1. Add "Work Classification" section with decision tree (after "Your Core Responsibilities")
2. Add "Agent Spawning Reference" section with templates (after "Spawning Minute-Men")
3. Add "Production vs. Ad-Hoc Code" section with boundary definition (after "Tool Gap Tracking")
4. Update "What You Do NOT Do" to reference the new sections

**Estimated size:** +150 lines

### Phase 2: Cross-Team Protocol Update

**File:** `shared/cross-team-protocol.md`

**Changes:**
1. Add "Delegation Boundaries" section (after "Communication Rules")
2. Include scope definitions, enforcement rules, and violation examples

**Estimated size:** +40 lines

### Phase 3: Validation Script

**File:** `tests/validate_accountant_delegation.sh`

**Changes:**
1. Create new validation script
2. Implement three validation checks
3. Add usage documentation

**Estimated size:** ~100 lines

### Phase 4: Testing

1. Launch data-team with a data analysis task → verify minute-men spawned correctly
2. Ask Accountant to "build a production tool" → verify PRD written, not code
3. Run validation script → verify no violations detected
4. Update existing validation scripts to reference new script

## Success Criteria

1. **Spawn correctness:** Accountant spawns minute-men with `subagent_type: "minuteman"` for all data analysis tasks
2. **Production delegation:** Accountant writes PRDs for production code requests, never implements directly
3. **Boundary clarity:** Clear definition of ad-hoc vs. production code that both teams understand
4. **Validation coverage:** Script catches all three violation types
5. **No regressions:** Existing data-team functionality continues to work

## Non-Goals

- Changing the dev-team agent instructions (only Accountant and cross-team protocol)
- Modifying the minuteman agent (it already works correctly)
- Adding new agents or changing team structure
- Automating PRD approval (still requires Architect evaluation)

## Future Enhancements

- Add validation to CI pipeline for automated regression testing
- Create a "delegation decision assistant" that suggests classification before spawning
- Add metrics tracking (spawn correctness rate, PRD vs. direct implementation ratio)
- Extend validation to other team leads if similar issues arise
