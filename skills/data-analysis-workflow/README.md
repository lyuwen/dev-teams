# Data Analysis Workflow Skill

This skill provides workflow-based parallel data analysis as an alternative to the agent-based data-team.

## Structure

```
skills/data-analysis-workflow/
  SKILL.md                        # Skill definition (launch instructions)
  README.md                       # This file
  workflows/
    data-analysis.ts              # The workflow script
```

## How It Works

When the skill is invoked:

1. **Skill (SKILL.md)** handles the launch sequence:
   - Parses user arguments
   - Verifies git repository
   - Creates output directory
   - Invokes the workflow via the Workflow tool with `scriptPath`

2. **Workflow (workflows/data-analysis.ts)** orchestrates the analysis:
   - Phase 1: Coordinator decomposes task and decides sharding
   - Phase 2: Workers analyze shards in parallel
   - Phase 3: Coordinator aggregates findings

## Plugin Distribution

The workflow script is distributed with the plugin, so when users install the dev-teams plugin, they get:
- Agent definitions (Accountant, Minuteman)
- Skills (data-team, data-analysis-workflow)
- Workflow scripts (workflows/data-analysis.ts)

The skill references the workflow by relative path from the plugin root.

## Usage

```
/data-analysis-workflow Audit train.jsonl for quality issues
```

Or with explicit args:

```
/data-analysis-workflow {"task": "Audit dataset", "dataPath": "data/", "maxWorkers": 10}
```

See `docs/examples/data-analysis-workflow-example.md` for detailed examples.

## Workflow Script Path Resolution

The skill uses `scriptPath: "skills/data-analysis-workflow/workflows/data-analysis.ts"` which resolves relative to:
- The plugin installation directory (when invoked via skill)
- The current working directory (if the plugin is in the current project)

This allows the workflow to be portable across different plugin installation locations.

## Comparison with Agent-Based Approach

| Feature | Workflow (this skill) | Agents (data-team skill) |
|---------|----------------------|--------------------------|
| Structure | Fixed 3-phase pipeline | Dynamic coordination |
| State | Phase outputs (files) | Task list + team memory |
| Cross-team | None | Committee + PRDs |
| Lifecycle | Completes and exits | Persistent agents |
| Best for | Bounded analysis | Ongoing coordination |

See `docs/data-analysis-approaches.md` for detailed comparison.

## Output

After workflow completion:

```
data-team-output/
  REPORT.md                      # Executive summary
  aggregated-findings.jsonl      # Machine-readable findings
  tool-gaps.md                   # Missing tools (if any)
  shard-001/
    report.md
    findings.jsonl
    summary.json
  shard-002/
    ...
```

## Development

To modify the workflow:

1. Edit `workflows/data-analysis.ts`
2. Test by invoking the skill
3. The workflow script is loaded from the plugin directory at runtime

No compilation or build step needed - workflow scripts are TypeScript source files executed by the workflow runtime.
