---
name: data-team
description: |
  Launch a data team with an Accountant (team lead) who dynamically spawns minute-men workers for parallel data analysis. Use this when the user wants to analyze datasets, audit data quality, investigate data characteristics, synthesize training data, or any data-intensive task that benefits from parallel workers. Trigger when the user says things like "launch the data team", "analyze this dataset", "audit data quality", "spin up the data team", "have the data team look at...", or describes a data task that needs coordination. The argument is the data task to pass to the Accountant.
---

# Data Team Launcher

Launch the data team and hand off the user's data task to the Accountant.

The user's data task is the argument passed to this skill. If no argument was provided, ask what data work they need before proceeding.

## Agent-Based vs Workflow-Based

This skill supports **both** approaches:

| Approach | When to Use | How to Launch |
|----------|-------------|---------------|
| **Agents** | Flexible coordination, ongoing work, cross-team integration, tool gap analysis, dynamic decisions | Default — launches Accountant as persistent agent |
| **Workflow** | One-shot analysis, deterministic phases, structured orchestration, explicit user request | Pass `mode: "workflow"` in args or user says "workflow" |

Key differences:
- **Agents:** Accountant makes dynamic decisions, spawns workers on-demand, participates in committee, writes PRDs to dev-team
- **Workflow:** Fixed 4-phase pipeline (plan → execute → aggregate → report), all workers spawn at once, no cross-team coordination

The skill will ask which mode to use if unclear. Continue reading for both approaches.

## Team Composition

| Agent | Role | Spawning |
|-------|------|----------|
| **Accountant** (team lead) | Receives data tasks, decides sharding strategy, spawns minute-men, aggregates results, reports to user | Spawned at launch |
| **Minuteman** (worker) | Analyzes an assigned data shard, writes reports, flags tool gaps | Spawned on-demand by the Accountant |

Unlike the dev-team which spawns 7 peer agents upfront, the data team only spawns the Accountant at launch. Minute-men are ephemeral — the Accountant spawns them per-task based on the work required.

## Determining Mode

Before launching, determine which mode to use:

1. **User explicitly requests workflow:** "use workflow", "run as workflow", "workflow mode"
2. **Args include `mode: "workflow"`**
3. **Task is one-shot with clear scope** and no follow-up coordination expected
4. **Otherwise:** default to agents

If unclear, ask: "Would you like agents (flexible, ongoing coordination) or workflow (deterministic, one-shot)?"

## Launch Sequence: Agents Mode

### Step 1: Verify git

The team uses shared memory in `.claude/team-memory/`, so the project needs a git repository. Run `git rev-parse --git-dir` to check. If there's no git repo, tell the user and offer to initialize one.

### Step 2: Create the team

Use TeamCreate with team name `data-team`. This creates the shared task list for the data team.

### Step 3: Initialize team memory

Check if `.claude/team-memory/MEMORY.md` exists. If not, create the directory and seed file:

```bash
mkdir -p .claude/team-memory
```

Then create `.claude/team-memory/MEMORY.md` with:

```markdown
# Shared Team Memory

All agents: read this file at the start of every task. User preferences here ALWAYS override defaults, conventions, and your own judgment.

Read individual memory files for details. Update this index and create new memory files when you learn new preferences.

<!-- Keep this index under 200 lines. Prune stale entries. -->
```

If it already exists (e.g., dev-team already created it), leave it as-is.

### Step 4: Create the output directory

```bash
mkdir -p data-team-output
```

This is where minute-men write their shard reports.

### Step 5: Create the initial data task

Use TaskCreate to capture the user's data task on the shared task list.

### Step 6: Spawn the Accountant

Spawn the Accountant as a teammate using the Agent tool with `team_name: "data-team"` and `name: "accountant"`. Use the `accountant` subagent_type.

Include in the prompt:
- The user's full data task (verbatim)
- That minute-men workers are available — spawn them as needed using `subagent_type: "minuteman"` with `team_name: "data-team"`
- That the user expects brief, focused reports — lead with the most important finding, don't elaborate unless asked
- The team name (`data-team`) so the Accountant can read the team config
- That output files go to `data-team-output/shard-{id}/`
- That the Accountant should read `.claude/team-memory/MEMORY.md` for user preferences and context
- If the dev-team is also running, the Accountant can message the Architect for cross-team coordination (see `shared/cross-team-protocol.md`)

### Step 7: Report to user

Tell the user:
- The data team is up — the Accountant is analyzing their task
- The Accountant will spawn minute-men as needed for parallel analysis
- They'll get a brief, focused report when analysis is complete
- They can message the Accountant directly if needed

## Key Differences from Dev Team

| Aspect | Dev Team | Data Team |
|--------|----------|-----------|
| Launch | 7 peer agents spawned upfront (Noob is a subagent of Instructor) | Only Accountant spawned; minute-men on-demand |
| Workers | Fixed roles (Implementer, Tester, etc.) | Generic minute-men, sharded by data |
| Pipeline | Sequential phases (build -> review -> usability) | Parallel shards -> aggregation |
| Output | Code on branches | Reports and findings files |
| Lifecycle | Agents persist through full pipeline | Minute-men are ephemeral per-task |

## Launch Sequence: Workflow Mode

### Step 1: Verify git repository

The workflow writes output to `data-team-output/`. Run:

```bash
git rev-parse --git-dir
```

If there's no git repo, tell the user and offer to initialize one.

### Step 2: Create output directory

```bash
mkdir -p data-team-output
```

### Step 3: Parse arguments

Extract or infer:
- `task`: The data analysis task (required)
- `dataPath`: Path to data (optional, Accountant will discover)
- `shardingStrategy`: "auto", "by-file", "by-range", "by-category", "by-sample" (default: "auto")
- `maxWorkers`: Cap on parallel workers (default: 10)

If the user provided natural language, construct the args object.

### Step 4: Launch the workflow

Use the Workflow tool with the workflow script at `skills/data-team/workflows/data-team.js` (relative to plugin root):

```javascript
{
  scriptPath: "${CLAUDE_PLUGIN_ROOT}/dev-teams/skills/data-team/workflows/data-team.js",
  args: {
    task: "<task description>",
    dataPath: "<path or undefined>",
    shardingStrategy: "<strategy or 'auto'>",
    maxWorkers: <number or 10>
  }
}
```

The workflow script is distributed with the plugin, so `${CLAUDE_PLUGIN_ROOT}` will resolve correctly wherever the plugin is installed.

### Step 5: Report to user

Tell them:
- The data-team workflow is running
- **Phase 1 (plan):** Accountant analyzes task and plans sharding
- **Phase 2 (execute):** Minutemen analyze shards in parallel
- **Phase 3 (aggregate):** Accountant synthesizes findings
- **Phase 4 (report):** Accountant writes final report
- Output will be in `data-team-output/REPORT.md`
- They can watch progress with `/workflows` or wait for completion

### Workflow Phases

**Phase 1: Plan**
- Accountant analyzes the task
- Discovers/verifies data location
- Decides sharding strategy
- Generates shard assignments
- Outputs `decomposition.json`

**Phase 2: Execute (parallel)**
- Minutemen (one per shard) analyze assigned data
- Write analysis scripts as needed
- Find patterns, issues, statistics
- Write `report.md`, `findings.jsonl`, `summary.json` to `data-team-output/shard-{id}/`

**Phase 3: Aggregate**
- Accountant reads all shard outputs
- Identifies cross-shard patterns
- Deduplicates issues
- Prioritizes findings
- Writes `aggregated-findings.jsonl` and `tool-gaps.md`

**Phase 4: Report**
- Accountant writes `REPORT.md` with executive summary
- Brief, focused, most-important-finding-first
- Points user to detailed shard reports if needed

### Output Files

After completion:

```
data-team-output/
  REPORT.md                      # Executive summary (read this first)
  aggregated-findings.jsonl      # All findings with cross-shard context
  tool-gaps.md                   # Missing tools (if any)
  decomposition.json             # Sharding plan from phase 1
  aggregation-summary.json       # Aggregation stats from phase 3
  shard-001/
    report.md                    # Shard 1 detailed report
    findings.jsonl               # Shard 1 findings
    summary.json                 # Shard 1 top-level stats
  shard-002/
    ...
```

## Choosing Between Agents and Workflow

| Scenario | Recommended Mode | Reason |
|----------|------------------|--------|
| User asks "analyze this dataset" | Agents | Default for open-ended tasks |
| User asks "run data analysis workflow" | Workflow | Explicit request |
| One-shot quality audit | Either | Workflow is simpler if no follow-up |
| Ongoing data pipeline work | Agents | Needs coordination and adaptation |
| Task may spawn dev-team PRDs | Agents | Accountant participates in committee |
| User wants deterministic phases | Workflow | Fixed pipeline structure |
| Multiple related data tasks | Agents | Accountant persists across tasks |

When in doubt, use agents — they're more flexible and can handle follow-up work.
