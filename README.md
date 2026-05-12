# dev-teams

A Claude Code plugin that provides two specialized multi-agent teams:

- **dev-team**: An 8-agent development team that designs, implements, tests, reviews, critiques, documents, and usability-tests software — with user approval at every major decision point.
- **data-team**: A dynamic data analysis team with an Accountant lead who spawns minute-men workers for parallel data analysis, quality auditing, and dataset investigation.

---

## Dev Team

## Usage

```
/dev-team <requirement>
```

Example:

```
/dev-team Build a CLI tool that converts datasets between parquet and jsonl formats
```

The Architect will analyze your requirement, present a technical approach for approval, then coordinate the team through the full pipeline.

To understand how the system works without launching anything:

```
/dev-team-help
```

## Agent Roster

| Agent | Color | Tools | Role |
|-------|-------|-------|------|
| **Architect** | cyan | All | Team lead. Designs architecture, decomposes tasks, coordinates all agents, escalates decisions to user. |
| **Implementer** | green | All | Writes feature code on `feat/` worktree branches. |
| **Tester** | yellow | All | Writes and runs tests on `test/` worktree branches in parallel with the Implementer. |
| **Reviewer** | magenta | Read-only + Bash | Quality gatekeeper. Reviews code and tests with structured feedback and severity levels. |
| **Critique** | red | Read-only + Bash | Final gate. Challenges every decision from first principles. Checks plan adherence, simplicity, and UX. Intervenes when the team is stuck in superficial fix loops. |
| **Documenter** | blue | All | Writes user-facing documentation. Docs must be self-sufficient for users with no source code access. |
| **Instructor** | cyan | Read-only + Bash | Designs realistic user tasks, dispatches them to the Noob, diagnoses usability failures, produces UX findings report. |
| **Noob** | yellow | Bash only | Simulates a naive first-time user. Tests software using ONLY documentation, help text, and error messages. Never reads source code. |

## Pipeline

```
User requirement
  -> Architect (design + user approval)
    -> Implementer (feat/ branch) + Tester (test/ branch)  [parallel]
      -> Reviewer (code quality, correctness, test coverage)
        -> Critique (plan adherence, first principles, UX scrutiny)
          -> Documenter (user-facing documentation)
            -> Instructor + Noob (usability testing)
              -> Architect (merge if passes, or route fixes back)
```

The Architect cannot claim completion until every stage passes. If the Reviewer, Critique, or usability testing finds issues, fixes are routed back and the relevant stages re-run.

## Shared Team Memory

All agents share a persistent memory system at `.claude/team-memory/`.

- **`MEMORY.md`** — Index file that every agent reads before starting any task
- **Topic files** — Individual `.md` files for user preferences, design decisions, and past corrections
- **User preferences always override** agent defaults, conventions, and judgment
- The Architect proactively indexes reusable preferences and decisions; other agents create topic files and notify the Architect to index them
- Dev-team launches use a project-scoped runtime team so memory stays attached to the current repository instead of leaking across stale sessions

This means agents remember your design philosophy, coding preferences, and past corrections across tasks without you repeating yourself.

## Key Design Principles

- **User-in-the-loop**: The Architect presents its approach and waits for approval before assigning work. High-level design choices are escalated to the user.
- **First-principles critique**: The Critique questions every decision back to the user's actual need. Convention and "best practice" are not justification.
- **Usability before completion**: Passing tests is the floor, not the ceiling. The Noob must be able to use the software from documentation alone before the team can ship.
- **No premature completion**: The Critique watches for superficial fix loops and forces the team to step back and redesign when incremental patches aren't working.
- **Memory-driven consistency**: User preferences persist across tasks via the shared memory system. You shouldn't have to explain the same thing twice.

---

## Data Team

A dynamic data analysis team for parallel dataset investigation, quality auditing, and data synthesis.

### Usage

```
/data-team <data task>
```

Example:

```
/data-team Audit this training dataset for quality issues, inconsistencies, and potential problems
```

The Accountant will analyze your task, decide on a sharding strategy, spawn minute-men workers to parallelize the analysis, then aggregate results into a focused report.

### Agent Roster

| Agent | Color | Tools | Role |
|-------|-------|-------|------|
| **Accountant** | cyan | All | Team lead. Receives data tasks, decomposes into parallelizable work, spawns minute-men, aggregates findings, reports to user. |
| **Minuteman** | yellow | All | Data analysis worker. Analyzes assigned data shard, finds patterns/issues/characteristics, writes reports, flags tool gaps. |

### Architecture

Unlike the dev-team which spawns all 8 agents upfront, the data-team only spawns the Accountant at launch. Minute-men are ephemeral — the Accountant spawns them on-demand based on the work required.

```
User data task
  -> Accountant (analyze scope, decide sharding strategy)
    -> Spawn minute-men [parallel, one per shard]
      -> Each minuteman analyzes its shard independently
      -> Each writes report files and messages summary back
    -> Accountant aggregates cross-shard findings
    -> Brief, focused report to user (lead with most important finding)
```

### Communication Style

The Accountant reports directly to the user with extreme brevity:

- **Lead with the single most important finding** — not a summary, not context
- **Numbers over narrative** — "23% of records have empty response fields" beats "a significant portion has quality issues"
- **No filler** — no "I analyzed the data and found..." Just state the finding
- **Do not elaborate unless asked** — if the user wants details, they'll ask

Example good report:
```
23% of records have empty response fields. Concentrated in the math category (41% empty there vs 8% elsewhere).

3 other issues found. Want details?
```

### Work Classification

The Accountant classifies incoming work:

- **Data Analysis** → Spawn minute-men for parallel analysis (audit, profile, investigate, check patterns)
- **Production Code** → Write PRD and send to dev-team Architect (build tool, create library, consolidate scripts)
- **Coordination** → Handle directly (cross-team communication, memory updates)

### Cross-Team Integration

The data-team and dev-team share:

- **Team memory** at `.claude/team-memory/` — both teams read/write user preferences and context
- **Cross-team protocol** — Accountant and Architect communicate via SendMessage for:
  - Tool gap PRDs (minute-men report missing tools → Accountant collects → sends PRD to Architect)
  - Committee discussions (data/software intersection issues)
  - Shared context (both teams aware of ongoing work)

### Output Structure

Minute-men write to `data-team-output/shard-{id}/`:

- **report.md** — Human-readable analysis with scope, key findings, statistics, quality issues, patterns
- **findings.jsonl** (optional) — Machine-readable findings for aggregation
- **SendMessage summary** to Accountant — brief top findings with report location

### Key Design Principles

- **Parallel by default**: Shard data for concurrent analysis whenever possible
- **Brief, focused reporting**: Lead with the most important finding, elaborate only when asked
- **Tool gap tracking**: Flag ad-hoc workarounds as candidates for production tools
- **Cross-team coordination**: Route production code requests to dev-team via PRDs
- **Memory-driven consistency**: Share user preferences and context with dev-team

---

## Project Structure

```
dev-teams/
  agents/                          # Agent definitions (plugin auto-discovery)
    # Dev team agents
    architect.md
    implementer.md
    tester.md
    reviewer.md
    critique.md
    documenter.md
    instructor.md
    noob.md
    # Data team agents
    accountant.md
    minuteman.md
  shared/                          # Shared protocols for both teams
    team-memory-protocol.md
    operational-resilience.md
    cross-team-protocol.md
  .claude-plugin/
    plugin.json
  skills/
    dev-team/
      SKILL.md                     # Dev team launcher
    dev-team-help/
      SKILL.md                     # Dev team explainer
    data-team/
      SKILL.md                     # Data team launcher
  tests/
    validate_usability_agents.sh
```
