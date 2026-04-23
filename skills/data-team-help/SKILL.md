---
name: data-team-help
description: |
  Explain how the data-team system works. Use this when the user asks questions like "how does the data team work?", "explain the data agents", "what does the accountant do?", "how do minute-men work?", "how does the data team coordinate with the dev team?", or any question about the data-team's architecture, agents, or workflow. This skill does NOT launch agents — it just explains.
---

# Data Team — How It Works

The user is asking about the data-team system. Explain the following clearly and concisely. Do NOT launch any agents, create any teams, or run any commands. Just explain.

## What It Is

The data team is a dynamic analysis team for data-intensive work in LLM training pipelines. Give it a data task — quality auditing, dataset profiling, data synthesis, pattern detection — and it parallelizes the work across multiple worker agents. The Accountant (team lead) decides how to split the work, spawns workers, and aggregates results into a concise report.

Launch it with: `/data-team <your data task>`

## The Agents

### Accountant (Team Lead)

- **Color:** cyan | **Tools:** All
- Receives data tasks from the user
- Analyzes scope and decides how to shard the work
- Spawns minute-men dynamically (could be 2 for a quick check or 10 for a full audit)
- Aggregates findings across all shards
- Reports to the user — brief, focused, most-important-issue-first
- Interfaces with the dev team via PRDs when tools are missing
- Part of the cross-team committee (Accountant, Architect, Critique, Reviewer)

### Minuteman (Data Worker)

- **Color:** yellow | **Tools:** All
- Spawned on-demand by the Accountant — not launched upfront
- Receives a specific data shard to analyze
- Writes ad-hoc Python/bash scripts for analysis
- Reports findings via files (durable) and messages (summary)
- Flags tool gaps back to the Accountant
- Ephemeral — terminates after completing its shard

## The Workflow

```
User gives data task
  → Accountant (analyzes scope, decides sharding)
    → Spawns N minute-men in parallel (one per shard)
      → Each minuteman analyzes its shard independently
      → Writes report files + sends summary message
    → Accountant aggregates across all shards
  → Brief, focused report to user
```

## Cross-Team Integration

The data team works alongside the dev team:

- **The dev team** builds tools and infrastructure
- **The data team** uses those tools to do actual data work
- When tools are missing, the Accountant writes a **Product Requirement Document (PRD)** and sends it to the Architect
- The **committee** (Accountant, Architect, Critique, Reviewer) discusses issues at the intersection of data and software

Communication rules:
- Only team leads talk cross-team (Accountant ↔ Architect)
- Minute-men never contact dev-team agents
- Dev-team workers never contact data-team agents

## Shared Memory

Both teams share `.claude/team-memory/`:
- Both Accountant and Architect can write to `MEMORY.md` (with atomic write protocol)
- Topic files use prefixes: `data-*` for data team, `dev-*` for dev team
- User preferences always override defaults

## Key Differences from Dev Team

| Aspect | Dev Team | Data Team |
|--------|----------|-----------|
| Structure | 8 fixed agents, sequential pipeline | 1 lead + dynamic workers, parallel shards |
| Launch | All agents spawned upfront | Only Accountant; workers on-demand |
| Output | Code on branches | Reports and data findings |
| Workers | Specialized roles | Generic data analysts |
