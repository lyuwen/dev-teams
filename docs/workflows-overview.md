# Workflows in dev-teams Plugin

This plugin includes two workflow implementations that convert agent-based patterns into deterministic, phase-based orchestration.

## Available Workflows

### 1. data-team-workflow (`skills/data-team/workflows/data-team.js`)

**Purpose:** Accountant + minutemen structure as a 4-phase workflow

**Phases:**
1. **plan** — Accountant analyzes task, decides sharding strategy
2. **execute** — Minutemen analyze shards in parallel
3. **aggregate** — Accountant synthesizes findings across shards
4. **report** — Accountant writes final report

**When to use:** One-shot data analysis with deterministic execution, no cross-team coordination needed

**Launch via:** `/data-team mode: workflow, task: <task>`

**Key difference from agents:** Fixed pipeline, no committee participation, no PRDs to dev-team

### 2. data-analysis-workflow (`skills/data-analysis-workflow/workflows/data-analysis.js`)

**Purpose:** Simpler 3-phase parallel analysis workflow

**Phases:**
1. **decompose** — Coordinator analyzes task, decides sharding
2. **analyze** — Workers analyze shards in parallel
3. **aggregate** — Coordinator synthesizes results

**When to use:** Lightweight data analysis without the full Accountant persona

**Launch via:** `/data-analysis-workflow <task>`

**Key difference from data-team-workflow:** Simpler coordinator role, no "Accountant" framing, 3 phases instead of 4

## Workflow vs Agents Comparison

| Aspect | Workflow | Agents |
|--------|----------|--------|
| **Execution model** | Deterministic phases | Dynamic coordination |
| **Spawning** | All workers at once (phase 2) | On-demand by team lead |
| **Adaptation** | Fixed after phase 1 | Can adjust mid-flight |
| **Cross-team** | No dev-team integration | Committee participation, PRDs |
| **Memory** | Read-only | Updates `.claude/team-memory/` |
| **State** | Ephemeral (terminates after completion) | Persistent agents |
| **Overhead** | Lower (no inter-agent messaging) | Higher (SendMessage coordination) |
| **Progress tracking** | Explicit phase boundaries | Task-based updates |
| **Follow-up** | Requires new workflow invocation | Agents persist for more tasks |

## File Structure

```
skills/
  data-team/
    SKILL.md                           # Supports both agents and workflow modes
    workflows/
      data-team.js                     # 4-phase Accountant + minutemen workflow
  data-analysis-workflow/
    SKILL.md                           # Workflow-only skill
    workflows/
      data-analysis.js                 # 3-phase coordinator + workers workflow

docs/
  data-team-modes.md                   # Detailed comparison of agents vs workflow
  examples/
    data-team-workflow-comparison.md   # Side-by-side execution traces
    data-analysis-workflow-example.md  # Usage examples
```

## Workflow Script Format

All workflows are written in **JavaScript** (not TypeScript) with this structure:

```javascript
export const meta = {
  name: "workflow-name",
  description: "Brief description",
  phases: ["phase1", "phase2", "phase3"]
};

// Phase 1
phase("phase1", "Phase 1 description");
const result1 = await agent({
  prompt: `...`,
  opts: { subagent_type: "claude" }
});

// Phase 2 (parallel)
phase("phase2", "Phase 2 description");
const results = await parallel(
  items.map((item) =>
    agent({
      prompt: `...`,
      opts: { subagent_type: "claude" }
    })
  )
);

// Phase 3
phase("phase3", "Phase 3 description");
const final = await agent({
  prompt: `...`,
  opts: { subagent_type: "claude" }
});
```

## Output Structure

Both workflows produce similar output:

```
data-team-output/
  REPORT.md                      # Executive summary (read this first)
  aggregated-findings.jsonl      # Machine-readable findings
  tool-gaps.md                   # Missing tools (if any)
  decomposition.json             # Sharding plan from phase 1
  shard-001/
    report.md                    # Detailed shard report
    findings.jsonl               # Shard-specific findings
    summary.json                 # Top-level shard stats
  shard-002/
    ...
```

## Implementation Notes

### Agent Spawning

Workflows use the `agent()` function with `opts.subagent_type: "claude"` (or other agent types).

**Key difference from agent-based teams:**
- Workflows spawn agents with **persona prompts** (e.g., "You are the Accountant...")
- Agent-based teams spawn **actual registered agents** via `subagent_type: "accountant"` or `subagent_type: "minuteman"`

### Parallelization

Use `parallel()` to spawn multiple agents at once:

```javascript
const results = await parallel(
  shards.map((shard, idx) =>
    agent({
      prompt: `Analyze shard ${shard.id}...`,
      opts: {
        subagent_type: "claude",
        name: `worker-${idx}`,
        description: `Worker analyzing ${shard.scope}`
      }
    })
  )
);
```

All workers execute simultaneously, then the workflow continues when all complete.

### File I/O

Workflows can read files via `readFile()` helper (provided by runtime):

```javascript
const data = JSON.parse(await readFile("path/to/file.json"));
```

Agents write files via normal Write/Edit tools during their execution.

## Choosing Between Workflows

### Use data-team-workflow when:
- You want the full Accountant persona and communication style
- 4-phase structure fits your needs (plan → execute → aggregate → report)
- You're already using the data-team skill and want workflow mode

### Use data-analysis-workflow when:
- You want simpler coordinator role without Accountant framing
- 3-phase structure is sufficient (decompose → analyze → aggregate)
- You're building a new workflow-only skill

### Use agents (data-team skill, default mode) when:
- Task may spawn follow-up work
- Tool gaps should trigger dev-team PRDs
- You need committee participation
- Multiple related tasks in one session
- You want adaptive coordination

## Migration Path

**Agents → Workflow:**
```
/data-team mode: workflow, task: <task>
```

**Workflow → Agents:**
```
/data-team mode: agents, task: <task>
```

Both modes can coexist. Use agents for ongoing work, workflows for one-shot analysis.

## Testing Workflows

To test a workflow locally:

1. Ensure you're in a git repository
2. Create the output directory: `mkdir -p data-team-output`
3. Launch via skill with `mode: workflow`
4. Monitor progress: `/workflows`
5. Check output: `data-team-output/REPORT.md`

## References

- **Workflow documentation:** [https://code.anthropic.com/docs/en/workflows.md](https://code.anthropic.com/docs/en/workflows.md)
- **Agent-based data-team:** `skills/data-team/SKILL.md` (agents mode section)
- **Comparison guide:** `docs/data-team-modes.md`
- **Examples:** `docs/examples/data-team-workflow-comparison.md`
