---
name: data-team
description: |
  Launch a data team with an Accountant (team lead) who dynamically spawns minute-men workers for parallel data analysis. Use this when the user wants to analyze datasets, audit data quality, investigate data characteristics, synthesize training data, or any data-intensive task that benefits from parallel workers. Trigger when the user says things like "launch the data team", "analyze this dataset", "audit data quality", "spin up the data team", "have the data team look at...", or describes a data task that needs coordination. The argument is the data task to pass to the Accountant.
---

# Data Team Launcher

Launch the data team and hand off the user's data task to the Accountant.

The user's data task is the argument passed to this skill. If no argument was provided, ask what data work they need before proceeding.

## Team Composition

| Agent | Role | Spawning |
|-------|------|----------|
| **Accountant** (team lead) | Receives data tasks, decides sharding strategy, spawns minute-men, aggregates results, reports to user | Spawned at launch |
| **Minuteman** (worker) | Analyzes an assigned data shard, writes reports, flags tool gaps | Spawned on-demand by the Accountant |

Unlike the dev-team which spawns all 8 agents upfront, the data team only spawns the Accountant at launch. Minute-men are ephemeral — the Accountant spawns them per-task based on the work required.

## Launch Sequence

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
| Launch | All 8 agents spawned upfront | Only Accountant spawned; minute-men on-demand |
| Workers | Fixed roles (Implementer, Tester, etc.) | Generic minute-men, sharded by data |
| Pipeline | Sequential phases (build -> review -> usability) | Parallel shards -> aggregation |
| Output | Code on branches | Reports and findings files |
| Lifecycle | Agents persist through full pipeline | Minute-men are ephemeral per-task |
