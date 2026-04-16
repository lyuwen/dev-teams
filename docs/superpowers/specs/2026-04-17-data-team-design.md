# Data Team Design Spec

**Date:** 2026-04-17
**Status:** Approved
**Scope:** Add a data team (Accountant + minute-men swarm) to the dev-teams plugin, with shared infrastructure extraction.

## Context

The existing dev-teams plugin provides an 8-agent development team (Architect, Implementer, Tester, Reviewer, Critique, Documenter, Instructor, Noob) organized as a sequential pipeline. The organization needs a second team -- the data team -- focused on data synthesis, analysis, and quality work for LLM training pipelines. The two teams must coordinate through their leads.

## Design Decisions

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Plugin scope | Mono-plugin with shared infra | Avoids duplication. Both teams share coordination protocols. Adding future teams (eval, deploy) is incremental. |
| Cross-team model | Separate teams, linked leads | Each team owns its task list and workers. Scales linearly to N teams -- adding a team means adding a TeamCreate + lead + agents, not restructuring. A meta-orchestrator can be layered on top later if needed at 4+ teams. |
| Minute-men scaling | Dynamic, Accountant decides | The Accountant determines shard count per task. Could be 2 for a quick check or 10 for a full dataset audit. No artificial cap. |
| Data format | Format-agnostic | Minute-men handle whatever they're given (JSONL, Parquet, CSV, HF datasets, etc.). |
| Reporting | Hybrid (files + messages) | Structured results go to files (durable record). Brief summaries go via SendMessage (in-context aggregation). |
| Team memory | Both leads write to shared MEMORY.md | Atomic write protocol (temp file + mv) prevents race conditions. Naming prefix convention (`data-*`, `dev-*`) prevents topic file collisions. |

## Plugin Structure

```
dev-teams/
  .claude-plugin/
    plugin.json                    # v2.0.0: multi-team org plugin
  agents/
    # Dev team (existing, updated to reference shared/)
    architect.md
    implementer.md
    tester.md
    reviewer.md
    critique.md
    documenter.md
    instructor.md
    noob.md
    # Data team (new)
    accountant.md
    minuteman.md
  shared/
    team-memory-protocol.md        # Extracted from all agents
    operational-resilience.md      # Extracted from all agents
    cross-team-protocol.md         # NEW: committee & lead-to-lead communication
  skills/
    dev-team/SKILL.md              # Existing launcher
    dev-team-help/SKILL.md         # Existing explainer
    data-team/SKILL.md             # NEW: data team launcher
    data-team-help/SKILL.md        # NEW: data team explainer
  .claude/
    team-memory/MEMORY.md          # Shared org-wide memory
```

## Agent Definitions

### Accountant (Data Team Lead)

**Role:** Receives user inquiries about data work, decomposes problems, spawns minute-men to parallelize analysis, aggregates results, and reports back to the user.

**Tools:** All tools.

**Key behaviors:**

- **User-facing communication:** Terse by default. Leads with the single most important finding. No elaboration unless the user asks. Think "executive dashboard" not "research paper."
- **Problem decomposition:** When given a data task, decides how to shard -- by file, by category, by data field, by sample range -- and spawns that many minute-men in parallel.
- **Dynamic spawning:** Uses the Agent tool with `subagent_type: "minuteman"` and `team_name: "data-team"`. Each spawn prompt includes the specific shard assignment, analysis objectives, and output path.
- **Aggregation:** After minute-men complete, reads their output files and synthesizes across shards. Identifies cross-shard patterns that no single minuteman could see.
- **Cross-team interface:** Collects tool gaps from minute-men, deduplicates, prioritizes, and writes a Product Requirement Document (PRD) to `docs/prd/YYYY-MM-DD-<topic>.md`. Sends to Architect via SendMessage.
- **Committee participation:** Initiates or joins committee discussions with Architect, Critique, and Reviewer on data/software intersection issues.
- **Memory:** Reads and writes `.claude/team-memory/MEMORY.md` with atomic write protocol. Tracks data quality trends, known dataset quirks, recurring issues.

**Does NOT:**

- Write production tooling (dev team's job)
- Elaborate to the user unprompted
- Forward raw minuteman output without synthesis
- Talk to minute-men about software architecture

### Minuteman (Data Expert Worker)

**Role:** General-purpose data analyst that dives deep into an assigned shard. Finds characteristics, patterns, issues, flaws, inconsistencies, and bugs.

**Tools:** All tools.

**Key behaviors:**

- **Shard-scoped:** Receives a specific assignment from the Accountant -- a subset of files, a range of records, a particular field to audit. Stays focused on that scope.
- **Format-agnostic analysis:** Reads any data format. Writes ad-hoc Python/bash scripts for statistics, anomaly detection, consistency checks, sampling.
- **Hybrid reporting:**
  - Files: Writes structured results to `data-team-output/shard-{id}/report.md` and `data-team-output/shard-{id}/findings.jsonl` (relative to the working directory where the data lives, not the plugin repo).
  - Messages: Sends brief summary to Accountant via SendMessage -- top findings, urgency flags, pointer to full report.
- **Ad-hoc scripting:** When existing tools don't cover a need, writes one-off scripts. Flags to Accountant: "I had to write a custom script for X, this should probably be a proper tool."

**Does NOT:**

- Communicate with the dev team
- Communicate with other minute-men
- Make decisions about overall data strategy
- Write production-quality tools
- Report directly to the user

## Cross-Team Protocol

### The Committee

**Members:** Accountant, Architect, Critique, Reviewer.

**Triggers:**

- Data team discovers systematic tool failures or missing capabilities
- Dev team ships a tool that needs data-team validation
- Ambiguous issues: data bug vs. software bug
- Architectural decisions that affect data pipelines

### Communication Flow

```
User
 |
 |-- (data work) --> Accountant --> minute-men (swarm)
 |                      |
 |-- (dev work) ------> Architect --> implementer, tester, etc.
 |
 |  Cross-team (leads only):
 |  Accountant <---SendMessage---> Architect
 |  Accountant <---SendMessage---> Critique
 |  Accountant <---SendMessage---> Reviewer
```

### PRD Flow

1. Minute-men flag ad-hoc workarounds in their reports
2. Accountant collects, deduplicates, and prioritizes
3. Accountant writes PRD to `docs/prd/YYYY-MM-DD-<topic>.md` with: problem statement, current workaround, expected behavior, priority
4. Accountant sends PRD to Architect via SendMessage
5. Architect evaluates, may push back or request clarification
6. Once agreed, Architect decomposes into dev-team tasks

### Memory Sharing

Both leads write to `.claude/team-memory/MEMORY.md`. Race-condition protocol:

1. Read current MEMORY.md
2. Write updated content to `.claude/team-memory/.MEMORY.md.tmp`
3. Atomic `mv` to replace MEMORY.md
4. If `mv` fails (another writer won), re-read and retry

Topic files in `.claude/team-memory/` use naming prefixes to prevent collisions:
- `data-*` -- owned by Accountant
- `dev-*` -- owned by Architect

### User Interaction

The user is the boss. Both leads report to the user:
- Accountant: brief, focused, most-important-issue-first
- Architect: same style as currently defined
- User can address either lead directly
- Neither lead speaks for the other's domain without consulting first

## Data Team Launcher

### Launch Sequence (`/data-team <task>`)

1. Verify git repo
2. `TeamCreate` with name `data-team`
3. Initialize team memory if `.claude/team-memory/MEMORY.md` doesn't exist
4. `TaskCreate` -- capture the user's data task
5. Spawn the Accountant (`subagent_type: "accountant"`, `team_name: "data-team"`)
6. Accountant takes over -- analyzes task, decides shard count, spawns minute-men

**Only the Accountant is spawned at launch.** Minute-men are ephemeral -- the Accountant spawns them per-task based on the work required.

### Minute-men Lifecycle

```
Accountant receives task
  -> analyzes scope, decides shard count (N)
  -> spawns N minute-men in parallel
  -> minute-men work, report back (files + messages)
  -> Accountant aggregates
  -> minute-men terminate naturally
  -> next task may spawn a different number
```

## Shared Infrastructure Extraction

### Files to Extract

| File | Source | Content |
|------|--------|---------|
| `shared/team-memory-protocol.md` | Inline in all 8 dev-team agents | Generalized: "team lead" replaces "Architect". Both leads can write. Naming prefix convention. Atomic write protocol. |
| `shared/operational-resilience.md` | Inline in all 8 dev-team agents | Health monitoring, check-in protocol, respawn, graceful degradation. Unchanged in substance. |
| `shared/cross-team-protocol.md` | New | Committee membership, PRD flow, lead-to-lead messaging, memory sharing rules. |

### Dev-Team Agent Updates

Each existing agent's inline protocol sections get replaced with:

```markdown
## Shared Protocols
Follow the protocols defined in:
- `shared/team-memory-protocol.md`
- `shared/operational-resilience.md`
```

The Architect additionally references `shared/cross-team-protocol.md` and gains one new responsibility: "Receive and evaluate PRDs from the Accountant."

### plugin.json Update

```json
{
  "name": "dev-teams",
  "version": "2.0.0",
  "description": "Multi-team AI organization: dev-team (8 agents) + data-team (Accountant + minute-men swarm). Shared coordination infrastructure."
}
```
