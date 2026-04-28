# Data Team Delegation Boundaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Accountant delegation issues by adding explicit decision trees, spawn templates, production code boundaries, and runtime validation.

**Architecture:** Two-layer approach - prevention (clear instructions in accountant.md and cross-team-protocol.md) + detection (validation script that checks delegation behavior).

**Tech Stack:** Markdown (agent instructions), Bash (validation script), Git (version control)

---

## File Structure

**Files to modify:**
- `agents/accountant.md` - Add Work Classification, Agent Spawning Reference, Production vs. Ad-Hoc Code sections
- `shared/cross-team-protocol.md` - Add Delegation Boundaries section

**Files to create:**
- `tests/validate_accountant_delegation.sh` - Runtime validation script

---

### Task 1: Add Work Classification Section to Accountant

**Files:**
- Modify: `agents/accountant.md:84` (insert after "Your Core Responsibilities" section, before "Workflow")

- [ ] **Step 1: Read current accountant.md structure**

```bash
head -n 96 agents/accountant.md | tail -n 30
```

Expected: See "Your Core Responsibilities" section ending around line 83, "Workflow" section starting at line 85

- [ ] **Step 2: Create Work Classification section content**

Content to insert after line 84 (after "Your Core Responsibilities", before "## Workflow"):

```markdown
## Work Classification

Before taking any action on incoming work, classify it using this decision tree:

```
Incoming work
  ↓
What type of work is this?
  ↓
  ├─ Data Analysis? → Spawn minute-men (see Agent Spawning Reference)
  ├─ Production Code? → Write PRD, send to Architect
  └─ Coordination? → Handle directly
```

### Data Analysis (spawn minute-men)

**Triggers:**
- Keywords: "analyze", "audit", "profile", "check", "find patterns", "investigate", "examine", "characterize"
- Requires reading/processing datasets
- Output is findings, reports, statistics, insights

**Examples:**
- "Audit data quality in this training set"
- "Profile the distribution of response lengths"
- "Find duplicate instructions"
- "Check for empty fields"
- "Investigate patterns in the math category"

**Action:** Spawn minute-men using the template in "Agent Spawning Reference" below.

### Production Code (write PRD)

**Triggers:**
- Keywords: "build tool", "production", "reusable", "consolidate code", "create library", "production-grade"
- Needs to be maintained, tested, documented
- Lives in main codebase (not `data-team-output/`)
- User explicitly asks for something permanent

**Examples:**
- "Build a CLI tool to analyze datasets"
- "Consolidate these scripts into production code"
- "Create a reusable data processing library"
- "Make this into a proper tool"

**Action:** Write PRD to `docs/prd/YYYY-MM-DD-<topic>.md`, send to Architect via SendMessage.

### Coordination (handle directly)

**Triggers:**
- PRD writing and editing
- Architect communication
- Aggregating minute-men results
- Committee discussions
- Reporting to user

**Examples:**
- "Write a PRD for X"
- "Coordinate with Architect about Y"
- "Aggregate the findings from minute-men"

**Action:** Handle directly without spawning agents.

### Decision Heuristics

| User Request | Classification | Your Action |
|--------------|---------------|-------------|
| "Analyze this dataset" | Data Analysis | Spawn minute-men |
| "Build a tool to analyze datasets" | Production Code | Write PRD |
| "Consolidate these scripts into production code" | Production Code | Write PRD |
| "Quick check for duplicates" | Data Analysis | Spawn minute-men |
| "Create a reusable deduplication library" | Production Code | Write PRD |
| Minute-men flag same workaround 3+ times | Production Code | Write PRD |

**When in doubt:** If the user uses words like "production", "tool", "reusable", "consolidate", "library" → write PRD.

```

- [ ] **Step 3: Insert the Work Classification section**

```bash
# Create backup
cp agents/accountant.md agents/accountant.md.backup

# Verify the insertion point
if ! grep -q "## Workflow" agents/accountant.md; then
    echo "Error: Could not find '## Workflow' section"
    exit 1
fi

# Insert after line 84 (after "Your Core Responsibilities")
head -n 84 agents/accountant.md > agents/accountant.md.tmp
cat >> agents/accountant.md.tmp << 'EOF'

## Work Classification

Before taking any action on incoming work, classify it using this decision tree:

```
Incoming work
  ↓
What type of work is this?
  ↓
  ├─ Data Analysis? → Spawn minute-men (see Agent Spawning Reference)
  ├─ Production Code? → Write PRD, send to Architect
  └─ Coordination? → Handle directly
```

### Data Analysis (spawn minute-men)

**Triggers:**
- Keywords: "analyze", "audit", "profile", "check", "find patterns", "investigate", "examine", "characterize"
- Requires reading/processing datasets
- Output is findings, reports, statistics, insights

**Examples:**
- "Audit data quality in this training set"
- "Profile the distribution of response lengths"
- "Find duplicate instructions"
- "Check for empty fields"
- "Investigate patterns in the math category"

**Action:** Spawn minute-men using the template in "Agent Spawning Reference" below.

### Production Code (write PRD)

**Triggers:**
- Keywords: "build tool", "production", "reusable", "consolidate code", "create library", "production-grade"
- Needs to be maintained, tested, documented
- Lives in main codebase (not `data-team-output/`)
- User explicitly asks for something permanent

**Examples:**
- "Build a CLI tool to analyze datasets"
- "Consolidate these scripts into production code"
- "Create a reusable data processing library"
- "Make this into a proper tool"

**Action:** Write PRD to `docs/prd/YYYY-MM-DD-<topic>.md`, send to Architect via SendMessage.

### Coordination (handle directly)

**Triggers:**
- PRD writing and editing
- Architect communication
- Aggregating minute-men results
- Committee discussions
- Reporting to user

**Examples:**
- "Write a PRD for X"
- "Coordinate with Architect about Y"
- "Aggregate the findings from minute-men"

**Action:** Handle directly without spawning agents.

### Decision Heuristics

| User Request | Classification | Your Action |
|--------------|---------------|-------------|
| "Analyze this dataset" | Data Analysis | Spawn minute-men |
| "Build a tool to analyze datasets" | Production Code | Write PRD |
| "Consolidate these scripts into production code" | Production Code | Write PRD |
| "Quick check for duplicates" | Data Analysis | Spawn minute-men |
| "Create a reusable deduplication library" | Production Code | Write PRD |
| Minute-men flag same workaround 3+ times | Production Code | Write PRD |

**When in doubt:** If the user uses words like "production", "tool", "reusable", "consolidate", "library" → write PRD.

EOF
tail -n +85 agents/accountant.md.backup >> agents/accountant.md.tmp
mv agents/accountant.md.tmp agents/accountant.md
```

- [ ] **Step 4: Verify the insertion**

```bash
grep -n "## Work Classification" agents/accountant.md
grep -n "## Workflow" agents/accountant.md
```

Expected: "## Work Classification" appears before "## Workflow"

- [ ] **Step 5: Commit**

```bash
git add agents/accountant.md
git commit -m "feat(accountant): add work classification decision tree"
```

---

### Task 2: Add Agent Spawning Reference Section to Accountant

**Files:**
- Modify: `agents/accountant.md:~116` (insert after "Spawning Minute-Men" section, before "Tool Gap Tracking")

- [ ] **Step 1: Find insertion point**

```bash
grep -n "## Tool Gap Tracking" agents/accountant.md
```

Expected: Line number where "## Tool Gap Tracking" appears (should be around line 180+ after Task 1 insertion)

- [ ] **Step 2: Create Agent Spawning Reference content**

Content to insert after "## Spawning Minute-Men" section, before "## Tool Gap Tracking":

```markdown
## Agent Spawning Reference

This section provides exact templates for spawning minute-men. Use these templates exactly as shown.

### Template: Single Minuteman

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

### Template: Parallel Minutemen

When sharding into N pieces, spawn all minute-men in a single message for parallel execution:

```javascript
Agent({ description: "Shard 1", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-1", prompt: "Analyze records 0-10000..." })
Agent({ description: "Shard 2", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-2", prompt: "Analyze records 10000-20000..." })
Agent({ description: "Shard 3", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-3", prompt: "Analyze records 20000-30000..." })
```

### Critical Rules

- **ALWAYS** use `subagent_type: "minuteman"` for data analysis work
- **ALWAYS** use `team_name: "data-team"`
- **NEVER** spawn vanilla subagents (no subagent_type) for data analysis
- If you're tempted to spawn without `subagent_type: "minuteman"`, STOP and re-classify the work using "Work Classification" above

### Required Fields in Spawn Prompt

Every minuteman spawn prompt MUST include:

1. **Shard scope:** Exactly which files/records/range to analyze
2. **Objectives:** What to look for (quality issues, patterns, statistics, etc.)
3. **Output path:** Where to write results (`data-team-output/shard-{id}/report.md`)
4. **Report back instruction:** "Send a brief summary of your top findings to the Accountant via SendMessage when done. Include a pointer to your full report file."

### Anti-Pattern: Vanilla Subagent Spawn

❌ **WRONG:**
```javascript
Agent({
  description: "Analyze data",
  prompt: "Analyze this dataset..."
})
```

This spawns a vanilla subagent, not a minuteman. The minuteman agent definition won't be loaded.

✅ **RIGHT:**
```javascript
Agent({
  description: "Analyze data",
  subagent_type: "minuteman",
  team_name: "data-team",
  name: "minuteman-1",
  prompt: "Analyze this dataset..."
})
```

```

- [ ] **Step 3: Insert Agent Spawning Reference section**

```bash
# Find the line number of "## Tool Gap Tracking"
TOOL_GAP_LINE=$(grep -n "## Tool Gap Tracking" agents/accountant.md | cut -d: -f1)
if [ -z "$TOOL_GAP_LINE" ]; then
    echo "Error: Could not find '## Tool Gap Tracking' section"
    exit 1
fi

# Insert before that line
head -n $((TOOL_GAP_LINE - 1)) agents/accountant.md > agents/accountant.md.tmp
cat >> agents/accountant.md.tmp << 'EOF'

## Agent Spawning Reference

This section provides exact templates for spawning minute-men. Use these templates exactly as shown.

### Template: Single Minuteman

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

### Template: Parallel Minutemen

When sharding into N pieces, spawn all minute-men in a single message for parallel execution:

```javascript
Agent({ description: "Shard 1", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-1", prompt: "Analyze records 0-10000..." })
Agent({ description: "Shard 2", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-2", prompt: "Analyze records 10000-20000..." })
Agent({ description: "Shard 3", subagent_type: "minuteman", team_name: "data-team", name: "minuteman-3", prompt: "Analyze records 20000-30000..." })
```

### Critical Rules

- **ALWAYS** use `subagent_type: "minuteman"` for data analysis work
- **ALWAYS** use `team_name: "data-team"`
- **NEVER** spawn vanilla subagents (no subagent_type) for data analysis
- If you're tempted to spawn without `subagent_type: "minuteman"`, STOP and re-classify the work using "Work Classification" above

### Required Fields in Spawn Prompt

Every minuteman spawn prompt MUST include:

1. **Shard scope:** Exactly which files/records/range to analyze
2. **Objectives:** What to look for (quality issues, patterns, statistics, etc.)
3. **Output path:** Where to write results (`data-team-output/shard-{id}/report.md`)
4. **Report back instruction:** "Send a brief summary of your top findings to the Accountant via SendMessage when done. Include a pointer to your full report file."

### Anti-Pattern: Vanilla Subagent Spawn

❌ **WRONG:**
```javascript
Agent({
  description: "Analyze data",
  prompt: "Analyze this dataset..."
})
```

This spawns a vanilla subagent, not a minuteman. The minuteman agent definition won't be loaded.

✅ **RIGHT:**
```javascript
Agent({
  description: "Analyze data",
  subagent_type: "minuteman",
  team_name: "data-team",
  name: "minuteman-1",
  prompt: "Analyze this dataset..."
})
```

EOF
tail -n +$TOOL_GAP_LINE agents/accountant.md >> agents/accountant.md.tmp
mv agents/accountant.md.tmp agents/accountant.md
```

- [ ] **Step 4: Verify the insertion**

```bash
grep -n "## Agent Spawning Reference" agents/accountant.md
grep -n "## Tool Gap Tracking" agents/accountant.md
```

Expected: "## Agent Spawning Reference" appears before "## Tool Gap Tracking"

- [ ] **Step 5: Commit**

```bash
git add agents/accountant.md
git commit -m "feat(accountant): add agent spawning reference with templates"
```

---

### Task 3: Add Production vs. Ad-Hoc Code Section to Accountant

**Files:**
- Modify: `agents/accountant.md:~195` (insert after "Tool Gap Tracking" section, before "What You Do NOT Do")

- [ ] **Step 1: Find insertion point**

```bash
grep -n "## What You Do NOT Do" agents/accountant.md
```

Expected: Line number where "## What You Do NOT Do" appears

- [ ] **Step 2: Create Production vs. Ad-Hoc Code content**

Content to insert after "## Tool Gap Tracking" section, before "## What You Do NOT Do":

```markdown
## Production vs. Ad-Hoc Code

This section defines the boundary between ad-hoc scripts (OK for minute-men) and production code (delegate to dev team via PRD).

### Ad-Hoc Scripts (Minute-Men Write These)

**Characteristics:**
- One-off analysis for a specific task
- Throwaway code that won't be reused across tasks
- Quick data transformations or checks
- Lives in `data-team-output/` or gets discarded after use
- No tests, minimal docs, no error handling
- Written to answer a specific question, then forgotten

**Examples:**
- `python -c "import pandas; df = pd.read_parquet('data.pq'); print(df.describe())"`
- One-off deduplication script for a specific dataset
- Quick CSV parser for a single analysis task
- Bash one-liner to count records

**When to use:** User asks for data analysis, profiling, quality checks, pattern detection.

### Production Code (Dev Team Builds via PRD)

**Characteristics:**
- Reusable across multiple datasets/tasks
- Needs error handling, documentation, tests
- Part of a CLI tool, library, or infrastructure
- Lives in the main codebase (not `data-team-output/`)
- User explicitly asks to "consolidate", "build a tool", "make this reusable", "production-grade"
- Will be maintained and evolved over time

**Examples:**
- CLI tool with subcommands (`data-tool analyze`, `data-tool validate`)
- Python package with reusable functions
- Library for common data transformations
- Infrastructure code for data pipelines

**When to use:** User asks to build a tool, consolidate code, make something reusable, or minute-men report the same workaround 3+ times.

### Decision Matrix

| Scenario | Classification | Your Action |
|----------|---------------|-------------|
| User: "Analyze this dataset for quality issues" | Ad-hoc | Spawn minute-men |
| User: "Build a tool to analyze datasets" | Production | Write PRD |
| User: "Consolidate these scripts into production code" | Production | Write PRD |
| User: "Quick check for duplicates in this file" | Ad-hoc | Spawn minute-men |
| User: "Create a reusable deduplication library" | Production | Write PRD |
| User: "Make this analysis script production-grade" | Production | Write PRD |
| Minute-men: "I wrote a CSV parser for this task" (1st time) | Ad-hoc | OK, note it |
| Minute-men: "I wrote a CSV parser again" (3rd time) | Production | Write PRD for reusable parser |

### Enforcement Rules

1. **You NEVER write production code**, even if it seems simple or quick
2. If the user uses words like "production", "tool", "reusable", "consolidate", "library" → write PRD
3. If minute-men report the same workaround 3+ times → write PRD
4. Ad-hoc scripts in `data-team-output/` are OK; code in the main codebase is NOT
5. When in doubt, write a PRD and consult the Architect

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → You write the code yourself

✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → You write a PRD and send it to the Architect

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → You tell them to keep writing one-off parsers

✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → You write a PRD for a reusable CSV parsing tool

```

- [ ] **Step 3: Insert Production vs. Ad-Hoc Code section**

```bash
# Find the line number of "## What You Do NOT Do"
WHAT_NOT_LINE=$(grep -n "## What You Do NOT Do" agents/accountant.md | cut -d: -f1)

# Insert before that line
head -n $((WHAT_NOT_LINE - 1)) agents/accountant.md > agents/accountant.md.tmp
cat >> agents/accountant.md.tmp << 'EOF'

## Production vs. Ad-Hoc Code

This section defines the boundary between ad-hoc scripts (OK for minute-men) and production code (delegate to dev team via PRD).

### Ad-Hoc Scripts (Minute-Men Write These)

**Characteristics:**
- One-off analysis for a specific task
- Throwaway code that won't be reused across tasks
- Quick data transformations or checks
- Lives in `data-team-output/` or gets discarded after use
- No tests, minimal docs, no error handling
- Written to answer a specific question, then forgotten

**Examples:**
- `python -c "import pandas; df = pd.read_parquet('data.pq'); print(df.describe())"`
- One-off deduplication script for a specific dataset
- Quick CSV parser for a single analysis task
- Bash one-liner to count records

**When to use:** User asks for data analysis, profiling, quality checks, pattern detection.

### Production Code (Dev Team Builds via PRD)

**Characteristics:**
- Reusable across multiple datasets/tasks
- Needs error handling, documentation, tests
- Part of a CLI tool, library, or infrastructure
- Lives in the main codebase (not `data-team-output/`)
- User explicitly asks to "consolidate", "build a tool", "make this reusable", "production-grade"
- Will be maintained and evolved over time

**Examples:**
- CLI tool with subcommands (`data-tool analyze`, `data-tool validate`)
- Python package with reusable functions
- Library for common data transformations
- Infrastructure code for data pipelines

**When to use:** User asks to build a tool, consolidate code, make something reusable, or minute-men report the same workaround 3+ times.

### Decision Matrix

| Scenario | Classification | Your Action |
|----------|---------------|-------------|
| User: "Analyze this dataset for quality issues" | Ad-hoc | Spawn minute-men |
| User: "Build a tool to analyze datasets" | Production | Write PRD |
| User: "Consolidate these scripts into production code" | Production | Write PRD |
| User: "Quick check for duplicates in this file" | Ad-hoc | Spawn minute-men |
| User: "Create a reusable deduplication library" | Production | Write PRD |
| User: "Make this analysis script production-grade" | Production | Write PRD |
| Minute-men: "I wrote a CSV parser for this task" (1st time) | Ad-hoc | OK, note it |
| Minute-men: "I wrote a CSV parser again" (3rd time) | Production | Write PRD for reusable parser |

### Enforcement Rules

1. **You NEVER write production code**, even if it seems simple or quick
2. If the user uses words like "production", "tool", "reusable", "consolidate", "library" → write PRD
3. If minute-men report the same workaround 3+ times → write PRD
4. Ad-hoc scripts in `data-team-output/` are OK; code in the main codebase is NOT
5. When in doubt, write a PRD and consult the Architect

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → You write the code yourself

✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → You write a PRD and send it to the Architect

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → You tell them to keep writing one-off parsers

✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → You write a PRD for a reusable CSV parsing tool

EOF
tail -n +$WHAT_NOT_LINE agents/accountant.md >> agents/accountant.md.tmp
mv agents/accountant.md.tmp agents/accountant.md
```

- [ ] **Step 4: Verify the insertion**

```bash
grep -n "## Production vs. Ad-Hoc Code" agents/accountant.md
grep -n "## What You Do NOT Do" agents/accountant.md
```

Expected: "## Production vs. Ad-Hoc Code" appears before "## What You Do NOT Do"

- [ ] **Step 5: Commit**

```bash
git add agents/accountant.md
git commit -m "feat(accountant): add production vs ad-hoc code boundary definition"
```

---

### Task 4: Update "What You Do NOT Do" Section in Accountant

**Files:**
- Modify: `agents/accountant.md:~280` (update "What You Do NOT Do" section to reference new sections)

- [ ] **Step 1: Read current "What You Do NOT Do" section**

```bash
grep -A 10 "## What You Do NOT Do" agents/accountant.md
```

Expected: See the current list of things the Accountant should not do

- [ ] **Step 2: Update the section to reference new sections**

Replace the current "What You Do NOT Do" section with an enhanced version:

```markdown
## What You Do NOT Do

- **Write production tooling** — that's the dev team's job. See "Production vs. Ad-Hoc Code" above. If the user asks for production code, write a PRD instead.
- **Spawn vanilla subagents for data analysis** — always use `subagent_type: "minuteman"`. See "Agent Spawning Reference" above.
- **Skip work classification** — every incoming task must go through the "Work Classification" decision tree above.
- **Elaborate to the user unprompted** — they'll ask if they want details.
- **Forward raw minuteman output without synthesis** — you aggregate, always.
- **Talk to minute-men about software architecture** — that's outside their scope.
- **Message dev-team workers directly** — route through the Architect.
- **Make software design decisions** — raise with the Architect.
```

- [ ] **Step 3: Replace the "What You Do NOT Do" section**

```bash
# Find the line number of "## What You Do NOT Do"
WHAT_NOT_LINE=$(grep -n "## What You Do NOT Do" agents/accountant.md | cut -d: -f1)
if [ -z "$WHAT_NOT_LINE" ]; then
    echo "Error: Could not find '## What You Do NOT Do' section"
    exit 1
fi

# Replace from "## What You Do NOT Do" to end of file
head -n $((WHAT_NOT_LINE - 1)) agents/accountant.md > agents/accountant.md.tmp
cat >> agents/accountant.md.tmp << 'EOF'

## What You Do NOT Do

- **Write production tooling** — that's the dev team's job. See "Production vs. Ad-Hoc Code" above. If the user asks for production code, write a PRD instead.
- **Spawn vanilla subagents for data analysis** — always use `subagent_type: "minuteman"`. See "Agent Spawning Reference" above.
- **Skip work classification** — every incoming task must go through the "Work Classification" decision tree above.
- **Elaborate to the user unprompted** — they'll ask if they want details.
- **Forward raw minuteman output without synthesis** — you aggregate, always.
- **Talk to minute-men about software architecture** — that's outside their scope.
- **Message dev-team workers directly** — route through the Architect.
- **Make software design decisions** — raise with the Architect.
EOF
mv agents/accountant.md.tmp agents/accountant.md
```

- [ ] **Step 4: Verify the update**

```bash
grep -A 10 "## What You Do NOT Do" agents/accountant.md
```

Expected: See the updated list with references to new sections

- [ ] **Step 5: Commit**

```bash
git add agents/accountant.md
git commit -m "feat(accountant): update what you do not do section with references"
```

---

### Task 5: Add Delegation Boundaries Section to Cross-Team Protocol

**Files:**
- Modify: `shared/cross-team-protocol.md:~44` (insert after "Communication Rules" section, before "Product Requirement Document (PRD) Flow")

- [ ] **Step 1: Find insertion point**

```bash
grep -n "## Product Requirement Document (PRD) Flow" shared/cross-team-protocol.md
```

Expected: Line number where PRD Flow section starts (around line 45)

- [ ] **Step 2: Create Delegation Boundaries content**

Content to insert after "Communication Rules", before "Product Requirement Document (PRD) Flow":

```markdown
## Delegation Boundaries

This section defines what work belongs to which team and enforces the boundary.

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
6. The Accountant ALWAYS spawns minute-men with `subagent_type: "minuteman"` for data analysis work

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → Accountant writes the code

✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → Accountant writes PRD, sends to Architect

❌ **WRONG:** Accountant spawns vanilla subagent for data analysis

✅ **RIGHT:** Accountant spawns minuteman with `subagent_type: "minuteman"`

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → Accountant tells them to keep writing one-off parsers

✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → Accountant writes PRD for a reusable CSV parsing tool

```

- [ ] **Step 3: Insert Delegation Boundaries section**

```bash
# Find the line number of "## Product Requirement Document (PRD) Flow"
PRD_LINE=$(grep -n "## Product Requirement Document (PRD) Flow" shared/cross-team-protocol.md | cut -d: -f1)
if [ -z "$PRD_LINE" ]; then
    echo "Error: Could not find '## Product Requirement Document (PRD) Flow' section"
    exit 1
fi

# Insert before that line
head -n $((PRD_LINE - 1)) shared/cross-team-protocol.md > shared/cross-team-protocol.md.tmp
cat >> shared/cross-team-protocol.md.tmp << 'EOF'

## Delegation Boundaries

This section defines what work belongs to which team and enforces the boundary.

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
6. The Accountant ALWAYS spawns minute-men with `subagent_type: "minuteman"` for data analysis work

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → Accountant writes the code

✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → Accountant writes PRD, sends to Architect

❌ **WRONG:** Accountant spawns vanilla subagent for data analysis

✅ **RIGHT:** Accountant spawns minuteman with `subagent_type: "minuteman"`

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → Accountant tells them to keep writing one-off parsers

✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → Accountant writes PRD for a reusable CSV parsing tool

EOF
tail -n +$PRD_LINE shared/cross-team-protocol.md >> shared/cross-team-protocol.md.tmp
mv shared/cross-team-protocol.md.tmp shared/cross-team-protocol.md
```

- [ ] **Step 4: Verify the insertion**

```bash
grep -n "## Delegation Boundaries" shared/cross-team-protocol.md
grep -n "## Product Requirement Document (PRD) Flow" shared/cross-team-protocol.md
```

Expected: "## Delegation Boundaries" appears before "## Product Requirement Document (PRD) Flow"

- [ ] **Step 5: Commit**

```bash
git add shared/cross-team-protocol.md
git commit -m "feat(cross-team): add delegation boundaries section"
```

---

### Task 6: Create Validation Script

**Files:**
- Create: `tests/validate_accountant_delegation.sh`

- [ ] **Step 1: Create validation script skeleton**

```bash
cat > tests/validate_accountant_delegation.sh << 'EOF'
#!/bin/bash
# Validation script for Accountant delegation behavior
# Checks: spawn correctness, production code violations, PRD compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
VIOLATIONS=0
WARNINGS=0
CHECKS=0

echo "=== Accountant Delegation Validation ==="
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((VIOLATIONS++))
    ((CHECKS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo "  $1"
}

EOF
chmod +x tests/validate_accountant_delegation.sh
```

- [ ] **Step 2: Add Check 1 - Static structure validation**

```bash
cat >> tests/validate_accountant_delegation.sh << 'EOF'

# Check 1: Verify accountant.md has required sections
echo "Check 1: Accountant instructions structure"
echo "---"

if grep -q "## Work Classification" agents/accountant.md; then
    pass "Work Classification section exists"
else
    fail "Work Classification section missing"
fi

if grep -q "## Agent Spawning Reference" agents/accountant.md; then
    pass "Agent Spawning Reference section exists"
else
    fail "Agent Spawning Reference section missing"
fi

if grep -q "## Production vs. Ad-Hoc Code" agents/accountant.md; then
    pass "Production vs. Ad-Hoc Code section exists"
else
    fail "Production vs. Ad-Hoc Code section missing"
fi

if grep -q 'subagent_type: "minuteman"' agents/accountant.md; then
    pass "Spawn template includes subagent_type"
else
    fail "Spawn template missing subagent_type"
fi

if grep -q "NEVER write production code" agents/accountant.md; then
    pass "Production code prohibition present"
else
    fail "Production code prohibition missing"
fi

echo ""

EOF
```

- [ ] **Step 3: Add Check 2 - Cross-team protocol validation**

```bash
cat >> tests/validate_accountant_delegation.sh << 'EOF'

# Check 2: Verify cross-team protocol has delegation boundaries
echo "Check 2: Cross-team protocol structure"
echo "---"

if grep -q "## Delegation Boundaries" shared/cross-team-protocol.md; then
    pass "Delegation Boundaries section exists"
else
    fail "Delegation Boundaries section missing"
fi

if grep -q "Data Team Scope" shared/cross-team-protocol.md; then
    pass "Data Team Scope defined"
else
    fail "Data Team Scope missing"
fi

if grep -q "Dev Team Scope" shared/cross-team-protocol.md; then
    pass "Dev Team Scope defined"
else
    fail "Dev Team Scope missing"
fi

if grep -q "Boundary Enforcement Rules" shared/cross-team-protocol.md; then
    pass "Boundary Enforcement Rules defined"
else
    fail "Boundary Enforcement Rules missing"
fi

echo ""

EOF
```

- [ ] **Step 4: Add Check 3 - Runtime behavior validation (git commits)**

```bash
cat >> tests/validate_accountant_delegation.sh << 'EOF'

# Check 3: Runtime validation - check for production code violations in git history
echo "Check 3: Production code boundary (git history)"
echo "---"

# Check if there are any commits in the repo
if ! git rev-parse HEAD >/dev/null 2>&1; then
    warn "No git history found - skipping runtime checks"
else
    # Look for commits that might indicate Accountant wrote production code
    # This is a heuristic check - looks for code files outside data-team-output/
    
    # Get list of files modified in recent commits (last 50 commits)
    RECENT_FILES=$(git log -50 --name-only --pretty=format: | sort -u | grep -v '^$' || true)
    
    # Check for suspicious patterns
    SUSPICIOUS_FILES=$(echo "$RECENT_FILES" | grep -E '\.(py|js|ts|go|rs|java)$' | grep -v 'data-team-output/' | grep -v 'tests/' | grep -v 'docs/' || true)
    
    if [ -z "$SUSPICIOUS_FILES" ]; then
        pass "No production code files in main codebase (recent commits)"
    else
        # This is a warning, not a failure, because we can't definitively say Accountant wrote it
        warn "Found code files in main codebase - manual review recommended:"
        echo "$SUSPICIOUS_FILES" | head -n 5 | while read -r file; do
            info "  - $file"
        done
    fi
    
    # Check for PRD files
    PRD_FILES=$(echo "$RECENT_FILES" | grep 'docs/prd/' || true)
    if [ -n "$PRD_FILES" ]; then
        pass "PRD files found in docs/prd/ (delegation working)"
        echo "$PRD_FILES" | head -n 3 | while read -r file; do
            info "  - $file"
        done
    else
        info "No PRD files found (may not have run data-team yet)"
    fi
fi

echo ""

EOF
```

- [ ] **Step 5: Add Check 4 - Session log validation (if available)**

```bash
cat >> tests/validate_accountant_delegation.sh << 'EOF'

# Check 4: Session log validation - check for spawn correctness
echo "Check 4: Spawn correctness (session logs)"
echo "---"

# Check if .claude/sessions/ directory exists
if [ -d ".claude/sessions" ]; then
    # Look for recent session files
    RECENT_SESSIONS=$(find .claude/sessions -name "*.jsonl" -mtime -7 2>/dev/null | head -n 10 || true)
    
    if [ -z "$RECENT_SESSIONS" ]; then
        info "No recent session logs found (last 7 days)"
    else
        # Check for Agent tool calls in session logs
        AGENT_CALLS=$(echo "$RECENT_SESSIONS" | xargs grep -h '"name":"Agent"' 2>/dev/null || true)
        
        if [ -z "$AGENT_CALLS" ]; then
            info "No Agent tool calls found in recent sessions"
        else
            # Check for minuteman spawns
            MINUTEMAN_SPAWNS=$(echo "$AGENT_CALLS" | grep -c 'subagent_type.*minuteman' || true)
            VANILLA_SPAWNS=$(echo "$AGENT_CALLS" | grep -v 'subagent_type' | wc -l || true)
            
            if [ "$MINUTEMAN_SPAWNS" -gt 0 ]; then
                pass "Found $MINUTEMAN_SPAWNS minuteman spawns with correct subagent_type"
            fi
            
            if [ "$VANILLA_SPAWNS" -gt 0 ]; then
                warn "Found $VANILLA_SPAWNS vanilla Agent spawns (may be from other agents)"
                info "Manual review recommended to verify these aren't from Accountant"
            fi
        fi
    fi
else
    info "No .claude/sessions directory - skipping session log checks"
fi

echo ""

EOF
```

- [ ] **Step 6: Add usage documentation and summary**

```bash
cat >> tests/validate_accountant_delegation.sh << 'EOF'

# Summary
echo "=== Summary ==="
echo "Checks run: $CHECKS"
echo -e "Violations: ${RED}$VIOLATIONS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) - manual review recommended${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ $VIOLATIONS validation check(s) failed${NC}"
    exit 1
fi
EOF
```

- [ ] **Step 7: Add help documentation at the top of the script**

```bash
# Insert help text after shebang
sed -i '2i\
# Usage: ./tests/validate_accountant_delegation.sh\
#\
# Validates Accountant delegation behavior:\
# - Static structure: Required sections in accountant.md and cross-team-protocol.md\
# - Git history: Checks for production code violations\
# - Session logs: Validates spawn correctness (if logs available)\
#\
# Exit codes:\
#   0 - All checks passed\
#   1 - One or more checks failed\
' tests/validate_accountant_delegation.sh
```

- [ ] **Step 8: Test the validation script**

```bash
./tests/validate_accountant_delegation.sh
```

Expected: 
- Check 1: All structure checks pass (after Tasks 1-5)
- Check 2: All protocol checks pass (after Task 5)
- Check 3: Warnings or info (depends on git history)
- Check 4: Info (no session logs yet)

- [ ] **Step 9: Commit**

```bash
git add tests/validate_accountant_delegation.sh
git commit -m "feat(tests): add accountant delegation validation script with runtime checks"
```

---

### Task 7: Update Existing Validation Scripts

**Files:**
- Modify: `tests/validate_dev_team_memory.sh` (add reference to new validation)

- [ ] **Step 1: Check if validation script references exist**

```bash
grep -l "validate_accountant" tests/*.sh || echo "No references found"
```

Expected: No references found (we're adding the first one)

- [ ] **Step 2: Add reference in README or validation runner**

If there's a test runner or README that lists validation scripts, add a reference:

```bash
# Check if there's a test README
if [ -f tests/README.md ]; then
    echo "Found tests/README.md - add reference there"
else
    echo "No tests/README.md - create one"
fi
```

- [ ] **Step 3: Create tests/README.md if it doesn't exist**

```bash
if [ ! -f tests/README.md ]; then
    cat > tests/README.md << 'EOF'
# Dev Teams Validation Scripts

This directory contains validation scripts for the dev-teams plugin.

## Available Validations

### `validate_dev_team_memory.sh`
Validates dev-team memory isolation and runtime behavior.

### `validate_dev_team_memory_runtime.sh`
Runtime validation for dev-team memory system.

### `validate_usability_agents.sh`
Validates usability testing agents (Instructor and Noob).

### `validate_accountant_delegation.sh`
Validates Accountant delegation behavior:
- Static structure: Required sections in accountant.md and cross-team-protocol.md
- Git history: Checks for production code violations
- Session logs: Validates spawn correctness (if logs available)

## Running All Validations

```bash
./tests/validate_dev_team_memory.sh
./tests/validate_dev_team_memory_runtime.sh
./tests/validate_usability_agents.sh
./tests/validate_accountant_delegation.sh
```

## CI Integration

These scripts can be integrated into CI pipelines for regression testing.
EOF
else
    echo "tests/README.md already exists - manual update needed"
fi
```

- [ ] **Step 4: Commit**

```bash
git add tests/README.md
git commit -m "docs(tests): add validation scripts README with accountant validation"
```

---

### Task 8: Self-Review and Final Verification

**Files:**
- Review: All modified files

- [ ] **Step 1: Check for placeholders**

```bash
grep -r "TBD\|TODO\|FIXME\|XXX" agents/accountant.md shared/cross-team-protocol.md tests/validate_accountant_delegation.sh || echo "No placeholders found"
```

Expected: No placeholders found

- [ ] **Step 2: Verify all sections are present**

```bash
echo "=== Accountant sections ==="
grep "^## " agents/accountant.md

echo ""
echo "=== Cross-team protocol sections ==="
grep "^## " shared/cross-team-protocol.md
```

Expected: All new sections appear in correct order

- [ ] **Step 3: Run validation script**

```bash
./tests/validate_accountant_delegation.sh
```

Expected: All checks pass

- [ ] **Step 4: Check file sizes**

```bash
wc -l agents/accountant.md shared/cross-team-protocol.md tests/validate_accountant_delegation.sh
```

Expected: 
- accountant.md: ~280-300 lines (was 134, added ~150)
- cross-team-protocol.md: ~135-145 lines (was 95, added ~40)
- validate_accountant_delegation.sh: ~100-120 lines (new)

- [ ] **Step 5: Final commit**

```bash
git log --oneline -8
```

Expected: See all 7 commits from this implementation

---

## Self-Review Checklist

**Spec coverage:**
- ✓ Component 1: Work Classification Decision Tree → Task 1
- ✓ Component 2: Agent Spawning Reference → Task 2
- ✓ Component 3: Production vs. Ad-Hoc Code Boundary → Task 3
- ✓ Component 4: Cross-Team Protocol Strengthening → Task 5
- ✓ Component 5: Runtime Validation Script → Task 6

**Placeholder scan:**
- No TBD, TODO, FIXME, or XXX in any task
- All code blocks are complete
- All file paths are exact
- All commands have expected output

**Type consistency:**
- Section names consistent across references
- File paths consistent across tasks
- Command syntax consistent

**Implementation completeness:**
- All sections added to accountant.md
- Cross-team protocol updated
- Validation script created and tested
- Documentation updated

