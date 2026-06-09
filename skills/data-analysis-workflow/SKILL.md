---
name: data-analysis-workflow
description: |
  Launch a parallel data analysis workflow. Use when the user wants to analyze datasets using a dynamic workflow orchestration pattern instead of persistent agents. Appropriate for: data quality audits, dataset profiling, pattern detection, consistency checks, statistical analysis. Trigger phrases: "run data analysis workflow", "analyze with workflow", "workflow-based data analysis", or when the user explicitly asks for workflow orchestration over agents.
---

# Data Analysis Workflow Launcher

Launch a dynamic workflow for parallel data analysis.

## When to Use This vs data-team Skill

**Use this workflow when:**
- User explicitly requests workflow-based approach
- Task is a one-shot analysis with clear scope
- You want deterministic phases with automatic aggregation
- User prefers structured orchestration over autonomous agents

**Use the data-team skill (agents) when:**
- User requests "the data team" or "spawn agents"
- Task requires ongoing coordination and adaptation
- Accountant needs to make dynamic decisions during execution
- Task may spawn follow-up work (PRDs, tool gap analysis)

Both approaches work for data analysis. The workflow is more structured; agents are more flexible.

## Arguments

The skill expects arguments in this format (JSON or natural language):

```json
{
  "task": "Audit train.jsonl for quality issues",
  "dataPath": "./data/train.jsonl",
  "shardingStrategy": "auto",
  "maxWorkers": 10
}
```

Or natural language:
```
Analyze the training dataset for quality issues and inconsistencies
```

## Launch Sequence

### Step 1: Parse arguments

Extract or infer:
- `task`: The data analysis task (required)
- `dataPath`: Path to data (optional, workflow will discover)
- `shardingStrategy`: "auto", "by-file", "by-range", "by-category", "by-sample" (default: "auto")
- `maxWorkers`: Cap on parallel workers (default: 10)

If the user provided natural language, construct the args object.

### Step 2: Verify git repository

The workflow writes output to `data-team-output/`. Run:

```bash
git rev-parse --git-dir
```

If there's no git repo, tell the user and offer to initialize one.

### Step 3: Create output directory

```bash
mkdir -p data-team-output
```

### Step 4: Launch the workflow

The workflow script is located at `skills/data-analysis-workflow/workflows/data-analysis.js` relative to the plugin root.

Use the Workflow tool with `scriptPath` pointing to the workflow file:

```javascript
{
  scriptPath: "skills/data-analysis-workflow/workflows/data-analysis.js",
  args: {
    task: "<task description>",
    dataPath: "<path or undefined>",
    shardingStrategy: "<strategy or 'auto'>",
    maxWorkers: <number or 10>
  }
}
```

The workflow script is distributed with the plugin, so it will be available wherever the plugin is installed.

### Step 5: Report to user

Tell them:
- The data analysis workflow is running
- Phase 1: decompose (coordinator decides sharding)
- Phase 2: analyze (parallel workers analyze shards)
- Phase 3: aggregate (coordinator synthesizes findings)
- Output will be in `data-team-output/REPORT.md`
- They can watch progress with `/workflows` or wait for completion

## Example Invocations

### Quality audit
```
User: "Audit train.jsonl for quality issues"
Assistant: [launches workflow with task="Audit train.jsonl for quality issues"]
```

### Dataset profiling
```
User: "Profile the token distributions and category balance in my instruction dataset"
Assistant: [launches workflow with task="Profile token distributions and category balance"]
```

### Consistency check
```
User: "Check for duplicates, empty fields, and format inconsistencies across all parquet files in data/"
Assistant: [launches workflow with task="Check for duplicates, empty fields, and format inconsistencies", dataPath="data/"]
```

## Workflow Phases

The workflow has three phases:

### Phase 1: Decompose
Coordinator agent:
- Discovers/verifies data location
- Analyzes data structure
- Decides optimal sharding strategy
- Generates shard assignments
- Outputs `decomposition.json`

### Phase 2: Analyze (parallel)
Worker agents (one per shard):
- Read assigned data slice
- Run analysis scripts
- Find patterns, issues, statistics
- Write `report.md`, `findings.jsonl`, `summary.json` to `data-team-output/shard-{id}/`

### Phase 3: Aggregate
Coordinator agent:
- Reads all shard outputs
- Identifies cross-shard patterns
- Deduplicates issues
- Prioritizes findings
- Writes `data-team-output/REPORT.md` (executive summary)

## Output Files

After completion:

```
data-team-output/
  REPORT.md                      # Executive summary (read this first)
  aggregated-findings.jsonl      # All findings with cross-shard context
  tool-gaps.md                   # Missing tools (if any)
  shard-001/
    report.md                    # Shard 1 detailed report
    findings.jsonl               # Shard 1 findings
    summary.json                 # Shard 1 top-level stats
  shard-002/
    ...
```

## Differences from Agent-Based data-team

| Aspect | Workflow | Agents |
|--------|----------|--------|
| Structure | Fixed 3-phase pipeline | Dynamic coordination |
| Spawning | All workers spawn at phase 2 | Accountant spawns on-demand |
| Adaptation | No mid-flight changes | Accountant can adjust strategy |
| State | Phase-based, deterministic | Task-based, flexible |
| Output | Structured files in phases | Reports + PRDs + memory updates |
| Cross-team | No committee participation | Accountant joins committee |
| Memory | No team memory updates | Writes to `.claude/team-memory/` |
| Tool gaps | Listed in report | PRDs sent to Architect |
| Lifecycle | Completes and terminates | Agents persist for follow-up |

Use workflows for bounded, one-shot analysis. Use agents for ongoing coordination.
