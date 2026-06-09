# Data Team: Agents vs Workflow

The data-team skill supports two execution modes: **agents** and **workflow**. Both implement the same Accountant + minutemen structure but with different coordination models.

## Quick Comparison

| Aspect | Agents | Workflow |
|--------|--------|----------|
| **Coordination** | Dynamic — Accountant adapts mid-flight | Deterministic — fixed 4-phase pipeline |
| **Spawning** | On-demand — Accountant decides when/how many | All at once — phase 2 spawns all workers |
| **State** | Task-based, flexible, persistent | Phase-based, structured, ephemeral |
| **Cross-team** | Accountant joins committee, writes PRDs | No dev-team integration |
| **Memory** | Updates `.claude/team-memory/` | Read-only team memory |
| **Adaptation** | Can change strategy during execution | Strategy fixed after phase 1 |
| **Follow-up** | Accountant persists for more tasks | Terminates after report |
| **Tool gaps** | PRDs sent to Architect for implementation | Listed in tool-gaps.md file |

## When to Use Each

### Use Agents When:
- Task scope is open-ended or may evolve
- You expect follow-up work or iterations
- Tool gaps should trigger dev-team PRDs
- Accountant needs to participate in committee decisions
- Multiple related data tasks in the same session
- You want flexible, adaptive coordination

### Use Workflow When:
- Task is well-defined, one-shot analysis
- You want explicit phase boundaries for progress tracking
- No cross-team coordination needed
- User explicitly requests "workflow mode"
- You prefer deterministic execution over flexibility

## Example: Quality Audit

### User Request
```
Audit train.jsonl for quality issues - empty fields, duplicates, format problems
```

### Agents Approach

**Launch:**
```
/data-team Audit train.jsonl for quality issues - empty fields, duplicates, format problems
```

**What Happens:**

1. **Launcher** creates team, spawns Accountant
2. **Accountant** analyzes task, discovers train.jsonl (100K records)
3. **Accountant** decides sharding strategy: 10 shards of 10K records each
4. **Accountant** spawns 10 minutemen via Agent tool (on-demand, may spawn more if needed)
5. **Minutemen** analyze shards, send summaries to Accountant
6. **Accountant** aggregates, writes report, messages user

**User receives:**
```
23% of records have empty response fields. Concentrated in math category (41% empty vs 8% elsewhere).

Full report: data-team-output/REPORT.md

3 other issues found. Want details?
```

**Flexibility:**
- Accountant can spawn additional minutemen if initial sharding wasn't optimal
- If user asks follow-up ("fix the empty fields"), Accountant coordinates that too
- If systematic tool gaps emerge, Accountant writes PRD to Architect

**State:**
- Accountant and minutemen show up in session's agent list
- Can message Accountant directly for clarifications
- Team persists until explicitly shut down

### Workflow Approach

**Launch:**
```
/data-team mode: workflow, task: Audit train.jsonl for quality issues
```

**What Happens:**

1. **Launcher** invokes Workflow tool with script at `skills/data-team/workflows/data-team.ts`
2. **Phase 1 (plan):** Accountant-persona agent analyzes task, writes `decomposition.json`
3. **Phase 2 (execute):** 10 minuteman-persona agents spawn in parallel via `parallel()`
4. **Phase 3 (aggregate):** Accountant-persona agent reads shard outputs, writes aggregated findings
5. **Phase 4 (report):** Accountant-persona agent writes `REPORT.md`

**User receives:**
Workflow completion notification pointing to `data-team-output/REPORT.md`:

```markdown
# Data Analysis Report

23% of records have empty response fields. Concentrated in math category (41% empty vs 8% elsewhere).

## Summary Statistics
- Total records: 100,000
- Records analyzed: 100,000
- Quality issues: 4 types
- Problematic records: 23,847 (23.8%)

## Key Findings
1. **Empty response fields** - 23,000 records (23%), math category at 41%
2. **Duplicate instructions** - 847 exact duplicates (0.8%)
3. **Encoding issues** - 12 records with UTF-8 BOM
4. **Malformed JSON** - 0 records

...
```

**Structure:**
- Fixed 4-phase pipeline
- All workers spawn at once in phase 2
- Deterministic execution path
- Workflow terminates after completion

**Follow-up:**
- If user asks "fix the empty fields", need to launch a new workflow or spawn agents
- Tool gaps are listed in `tool-gaps.md` but not sent to dev-team
- No cross-team integration

## Example: Dataset Profiling

### User Request
```
Profile token distributions, category balance, and response length patterns in my instruction dataset
```

### Agents: Dynamic Sharding

```
/data-team Profile token distributions, category balance, and response patterns
```

**Accountant's decision:**
- Discovers 8 categories in the data
- Decides: shard by category (8 shards)
- Spawns 8 minutemen, one per category
- If a category is massive, may spawn additional minutemen to split it further

**Result:** Accountant adapts sharding based on what it discovers in the data.

### Workflow: Upfront Planning

```
/data-team mode: workflow, task: Profile token distributions and category balance, shardingStrategy: by-category
```

**Phase 1 decision:**
- Coordinator discovers 8 categories
- Writes decomposition.json with 8 shards
- Phase 2 spawns exactly 8 workers
- No adaptation if categories are imbalanced

**Result:** Sharding plan is fixed after phase 1, execution is deterministic.

## Example: Tool Gap Discovery

### Scenario
Minutemen keep writing ad-hoc CSV parsing scripts because there's no reusable tool.

### Agents: PRD to Dev Team

**Flow:**
1. **Minutemen** flag the workaround in their reports (3+ times)
2. **Accountant** collects, deduplicates, prioritizes
3. **Accountant** writes PRD to `docs/prd/2026-06-03-csv-parser.md`
4. **Accountant** sends PRD to Architect via SendMessage
5. **Committee discussion:** Accountant, Architect, Critique discuss implementation
6. **Dev team** builds the tool
7. **Next data task:** Minutemen use the new tool instead of ad-hoc scripts

**Cross-team integration:** Tool gap → PRD → implementation → reuse

### Workflow: Tool Gaps Listed

**Flow:**
1. **Minutemen** flag the workaround in their reports
2. **Accountant** aggregates to `data-team-output/tool-gaps.md`
3. **Workflow completes**

**tool-gaps.md content:**
```markdown
# Tool Gaps

## Priority 1: Blocking
- **CSV parser with error handling** — minutemen wrote custom parsers in 5/10 shards

## Priority 2: Important
- **Duplicate detection across large files** — current scripts are slow
```

**No cross-team integration:** User must manually launch dev-team to address tool gaps.

## Output Structure

Both modes produce similar output files:

```
data-team-output/
  REPORT.md                      # Executive summary
  aggregated-findings.jsonl      # Machine-readable findings
  tool-gaps.md                   # Missing tools (if any)
  shard-001/
    report.md                    # Detailed shard analysis
    findings.jsonl               # Shard findings
    summary.json                 # Shard summary
  shard-002/
    ...
```

**Difference:**
- **Agents:** Accountant may update files dynamically, can add more shards
- **Workflow:** File structure is fixed after phase 1, deterministic

## Communication Style

Both modes inherit the Accountant's communication style:
- Lead with the single most important finding
- Numbers over narrative
- Brief and focused
- No filler or preamble

**Agents:** Messages come from the Accountant agent (can reply to it)
**Workflow:** Report written to `REPORT.md` (no interactive agent)

## Migration Path

Easy to switch between modes:

**Agents → Workflow:**
If you've been using agents but want deterministic execution for a specific task, just specify `mode: workflow` in args.

**Workflow → Agents:**
If workflow output reveals follow-up work or tool gaps that need dev-team coordination, launch agents mode for the next task.

Both modes can coexist — use agents for ongoing work, workflow for one-shot analysis.

## Performance Characteristics

### Agents
- **Startup:** Slower (TeamCreate, spawn Accountant, wait for Accountant to spawn minutemen)
- **Execution:** Flexible (can adapt mid-flight)
- **Overhead:** Higher (team coordination, SendMessage between agents)
- **Best for:** Ongoing work, multiple related tasks

### Workflow
- **Startup:** Faster (direct to phase 1)
- **Execution:** Fixed (deterministic pipeline)
- **Overhead:** Lower (no inter-agent messaging in phase 2)
- **Best for:** One-shot analysis, batch processing

## Implementation Notes

### Agents
- Uses TeamCreate, Agent tool with `team_name: "data-team"`
- Accountant spawns minutemen via Agent tool with `subagent_type: "minuteman"`
- Minutemen send summaries via SendMessage
- Accountant updates `.claude/team-memory/MEMORY.md`

### Workflow
- Uses Workflow tool with `scriptPath: "${CLAUDE_PLUGIN_ROOT}/dev-teams/skills/data-team/workflows/data-team.ts"`
- Four phases: plan, execute, aggregate, report
- Each phase spawns agents with persona prompts (Accountant-persona, minuteman-persona)
- No persistent agents — each phase's agents terminate after completion
- Uses `parallel()` for phase 2 to spawn all minutemen at once

## Choosing the Right Mode

Ask these questions:

1. **Is this a one-shot task?** → Workflow
2. **Will there be follow-up work?** → Agents
3. **Do tool gaps need dev-team integration?** → Agents
4. **User explicitly requested workflow?** → Workflow
5. **Need deterministic phases for tracking?** → Workflow
6. **Multiple related data tasks?** → Agents
7. **Want adaptive coordination?** → Agents
8. **Still unclear?** → Default to agents (more flexible)

## Example Invocations

### Default (agents)
```
/data-team Analyze training dataset for quality issues
```

### Explicit agents
```
/data-team mode: agents, task: Profile this dataset
```

### Explicit workflow
```
/data-team mode: workflow, task: Audit data/, shardingStrategy: by-file, maxWorkers: 10
```

### Natural language (will infer mode)
```
User: "Run a data quality audit on train.jsonl"
Skill: [defaults to agents unless user says "workflow"]
```

```
User: "Run a data quality workflow on train.jsonl"
Skill: [detects "workflow" keyword, uses workflow mode]
```
