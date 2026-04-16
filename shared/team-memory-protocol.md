# Team Memory Protocol

This protocol applies to all agents across all teams. Read this before starting any task.

## Overview

Shared memory lives at `.claude/team-memory/`. It stores user preferences, design decisions, past corrections, and cross-team context. User preferences from memory **ALWAYS take priority** over defaults, conventions, and your own judgment.

## Reading Memory

1. At the start of every task, read `.claude/team-memory/MEMORY.md`
2. Read any linked memory files relevant to your current work
3. User preferences from memory **ALWAYS take priority** over defaults, conventions, and your own judgment

## Who Can Write to MEMORY.md

Only **team leads** (Architect, Accountant) write to the `MEMORY.md` index file. This prevents race conditions when agents run in parallel.

- **Architect** owns entries prefixed with `dev-*`
- **Accountant** owns entries prefixed with `data-*`

### Atomic Write Protocol for Team Leads

When updating `MEMORY.md`:

1. Read current `MEMORY.md`
2. Write updated content to `.claude/team-memory/.MEMORY.md.tmp`
3. Atomic `mv .claude/team-memory/.MEMORY.md.tmp .claude/team-memory/MEMORY.md`
4. If the `mv` fails (another writer won), re-read and retry

### When to Update Memory (Team Leads)

**Proactively** write to memory whenever any of these happen — do not wait to be asked:
- The user corrects an approach, rejects a suggestion, or expresses a preference
- The user approves a non-obvious design decision (record what was approved and why)
- An architectural or data quality choice is made that future tasks should follow
- You discover a project constraint, convention, or pattern worth preserving
- The user gives feedback on any agent's output (style, format, approach)
- **Another agent messages you to index a new memory file** — verify the file exists, then add it promptly

### Memory File Format

```
---
name: <descriptive name>
type: <preference | decision | correction>
updated: <YYYY-MM-DD>
---
<content>
```

## Updating Memory (Non-Lead Agents)

Non-lead agents create topic files but do NOT edit `MEMORY.md` directly.

**Proactively** create memory files whenever:
- The user or your team lead corrects your approach
- A decision is made that future tasks should follow
- You discover a constraint, convention, or pattern worth preserving
- You receive feedback on your output

To write a memory:
1. Check if an existing memory file covers the topic — if yes, update it
2. If no, create a new `.md` file in `.claude/team-memory/` using the format above
3. **Message your team lead** to add the index entry
4. Keep individual memory files focused — one topic per file

## Topic File Naming Convention

To prevent collisions between teams:
- `dev-*` — owned by dev-team agents
- `data-*` — owned by data-team agents
