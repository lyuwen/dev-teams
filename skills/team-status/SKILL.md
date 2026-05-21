---
name: team-status
description: |
  Check the status of long-running agent teams and identify stuck agents. Use this skill when the user asks for a "status check", "status report", "team status", "how's the team doing", "what's the progress", or similar questions about ongoing agent work. Also use when the user mentions agents being slow, stuck, or wants to know what agents are currently doing. This skill works with dev-team (8-agent development pipeline), data-team (Accountant + minute-men), nested teams (data-team that spawned dev-team), and vanilla agent teams. Triggers even if the user doesn't explicitly say "team" - phrases like "what's happening", "any progress", "are they done yet" when agents are active should invoke this skill.
---

# Team Status Checker

Check the status of active agent teams, identify stuck agents, and help users nudge progress forward.

## Overview

This skill monitors agent teams in the current session and provides status reports tailored to the team type:
- **Dev-team**: Pipeline stage + individual agent statuses
- **Data-team**: Accountant status + minute-men aggregate stats
- **Nested teams**: Data-team with embedded dev-team (Accountant delegates dev-team status to Architect)
- **Vanilla teams**: Simple list of all agent statuses

## Workflow

### Step 1: Check for Active Teams

Use the task list and agent spawning history to determine if any agents are currently active in this session.

If no agents are active:
```
No active teams running.
```

Stop here.

### Step 2: Detect Team Type

Examine the active agents to classify the team:

**Dev-team indicators:**
- Presence of: architect, implementer, tester, reviewer, critique, documenter, instructor, noob
- If you see 6+ of these agents → dev-team

**Data-team indicators:**
- Presence of: accountant + one or more minuteman agents
- If you see accountant → data-team

**Nested team (data-team + dev-team):**
- Accountant is present AND architect is present
- This means data-team spawned dev-team for production tool development
- Accountant is the top-level leader

**Vanilla team:**
- Any other combination of agents

### Step 3: Determine Team Age

Check when the team was launched (earliest agent spawn time or team creation time).

If the team is **less than 2 minutes old**, skip stuck detection in Step 5 — agents are just getting started.

### Step 4: Gather Agent Activity Data

For each active agent, collect:
- **Last message timestamp**: When did this agent last send a message?
- **Assigned tasks**: What tasks are assigned to this agent? (Check task list with `TaskList`)
- **Task status**: Are tasks pending, in_progress, or completed?
- **Task update timestamp**: When was the task last updated?

Use **passive monitoring only** — do NOT ping agents or send them messages. Pinging could disrupt complex reasoning or long-running operations.

### Step 5: Identify Stuck Agents

An agent is considered **stuck** if ALL of these conditions are met:
1. Has a task marked `in_progress`
2. No message sent in the last 5 minutes
3. Task not updated in the last 5 minutes
4. Team age > 2 minutes (skip stuck detection for new teams)

**Important:** Only flag agents as stuck if you're 100% certain based on timestamps. If unclear, just report whether the agent is "active" or "idle" without making stuck claims.

### Step 6: Generate Status Report

The report format depends on team type.

#### Dev-Team Report

Ask the **Architect** for a status report using `SendMessage`:

```
to: architect
message: "Status check requested by user. Please provide a brief status report covering: current pipeline stage, progress on assigned tasks, any blockers, and which agents are active/idle. Keep it concise - user can ask for details if needed."
```

Wait for the Architect's response, then present it to the user.

Additionally, append your own analysis:
- List each of the 8 agents with their current status (active/idle/stuck)
- Highlight any stuck agents identified in Step 5
- Show task completion stats (X/Y tasks completed)

**Format:**
```
## Dev-Team Status

[Architect's response]

### Agent Status
- Architect: [active/idle/stuck] - [brief task description if active]
- Implementer: [active/idle/stuck] - [brief task description if active]
- Tester: [active/idle/stuck] - [brief task description if active]
- Reviewer: [active/idle/stuck] - [brief task description if active]
- Critique: [active/idle/stuck] - [brief task description if active]
- Documenter: [active/idle/stuck] - [brief task description if active]
- Instructor: [active/idle/stuck] - [brief task description if active]
- Noob: [active/idle/stuck] - [brief task description if active]

### Task Progress
X of Y tasks completed

[If any stuck agents:]
⚠️ Stuck agents detected: [list agent names]
```

#### Data-Team Report

Ask the **Accountant** for a status report using `SendMessage`:

```
to: accountant
message: "Status check requested by user. Please provide a brief status report covering: current work phase, minute-men status (how many active/completed/stuck), any blockers, and overall progress. Keep it concise - user can ask for details if needed."
```

Wait for the Accountant's response, then present it to the user.

Additionally, append your own analysis:
- Accountant status (active/idle/stuck)
- Minute-men aggregate stats:
  - Total spawned
  - Currently active
  - Completed
  - Stuck (if any)
- Task completion stats

**Format:**
```
## Data-Team Status

[Accountant's response]

### Team Overview
- Accountant: [active/idle/stuck] - [brief task description if active]
- Minute-men: X active, Y completed, Z stuck (out of N total)

### Task Progress
X of Y tasks completed

[If Accountant or minute-men stuck:]
⚠️ Stuck agents detected: [list details]
```

#### Nested Team Report (Data-Team + Dev-Team)

The Accountant is the top-level leader. Ask the Accountant for status, and the Accountant will delegate the dev-team portion to the Architect.

Send to **Accountant**:
```
to: accountant
message: "Status check requested by user. Please provide a brief status report covering: your current work phase, minute-men status, and the dev-team's progress (delegate to Architect for dev-team details). Keep it concise - user can ask for details if needed."
```

Wait for the Accountant's response (which should include dev-team status from Architect), then present it.

Additionally, append your own analysis:
- Accountant status
- Minute-men stats
- Dev-team summary (agent count, stuck agents if any)
- Task completion stats

**Format:**
```
## Data-Team Status (with Dev-Team)

[Accountant's response, including dev-team status from Architect]

### Team Overview
- Accountant: [active/idle/stuck]
- Minute-men: X active, Y completed, Z stuck
- Dev-team: 8 agents, [N stuck if any]

### Task Progress
X of Y tasks completed

[If any stuck agents:]
⚠️ Stuck agents detected: [list details]
```

#### Vanilla Team Report

For teams that don't match dev-team or data-team patterns, provide a simple list:

**Format:**
```
## Team Status

### Active Agents
- [agent-name]: [active/idle/stuck] - [brief task description if active]
- [agent-name]: [active/idle/stuck] - [brief task description if active]
...

### Task Progress
X of Y tasks completed

[If any stuck agents:]
⚠️ Stuck agents detected: [list agent names]
```

### Step 7: Offer Next Actions

After presenting the status report, ask the user:

```
Would you like me to:
1. Nudge stuck agents (send reminder messages to team lead)
2. Respawn unresponsive agents (if they appear crashed)
3. Get more details on a specific agent or task
4. Nothing - just checking in
```

Wait for the user's choice and act accordingly.

## Key Principles

- **Passive monitoring only**: Never ping agents directly. Use timestamps and task status.
- **Brief by default**: Lead with summaries. User can ask for elaboration.
- **Certainty over speculation**: Only flag agents as "stuck" if you're 100% certain based on data. When unclear, use "active" or "idle".
- **Respect team hierarchy**: Always ask team leads (Architect/Accountant) for their perspective first.
- **Skip stuck detection for new teams**: Teams < 2 minutes old are just getting started.
- **User decides next steps**: Present options, don't auto-nudge.

## Edge Cases

**No active teams**: Report "No active teams running." and stop.

**Team just launched (< 2 min)**: Skip stuck detection, just show which agents are active.

**Agent with no assigned tasks**: Report as "idle" (not stuck).

**Task completed but agent still active**: Report as "active" with current task if any, or "idle" if no current work.

**Multiple teams in history but only one active**: Only report on the currently active team.
