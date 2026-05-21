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

### Step 1: Detect Active Teams

Check for running agent teams by looking for team directories:

```bash
ls ~/.claude/teams/
```

Common team names:
- `dev-team-*` (dev teams)
- `data-team-*` (data teams)
- Other team names

If no team directories exist or all are empty:
```
No active teams running.
```

Stop here.

### Step 2: Identify Team Type and Lead

For each active team, check which agents are present by looking at inbox files:

```bash
ls ~/.claude/teams/<team-name>/inboxes/
```

**Dev-team indicators:**
- Has `architect.json` inbox → dev-team (lead: architect)

**Data-team indicators:**
- Has `accountant.json` inbox → data-team (lead: accountant)

**Nested team:**
- Has both `accountant.json` and `architect.json` → nested (lead: accountant)

**Vanilla team:**
- Other combinations → vanilla (no specific lead)

### Step 3: Query Team Lead for Status

Spawn a temporary status-checker agent that joins the team and queries the lead:

**For dev-team:**
```
Agent({
  description: "Query dev-team status",
  team_name: "<detected-team-name>",
  name: "status-checker",
  prompt: "Send a message to the architect asking for a brief status report. Include: current pipeline stage, progress on tasks, any blockers, which agents are active/idle/stuck. Wait for their response and report it back. Keep it concise."
})
```

**For data-team:**
```
Agent({
  description: "Query data-team status",
  team_name: "<detected-team-name>",
  name: "status-checker",
  prompt: "Send a message to the accountant asking for a brief status report. Include: current work phase, minute-men status (active/completed/stuck), any blockers, overall progress. Wait for their response and report it back. Keep it concise."
})
```

**For nested team:**
```
Agent({
  description: "Query nested team status",
  team_name: "<detected-team-name>",
  name: "status-checker",
  prompt: "Send a message to the accountant asking for a status report covering both the data-team and dev-team. The accountant should delegate dev-team details to the architect. Wait for the response and report it back."
})
```

**For vanilla team:**
Use `TaskList` to check task status directly and report on agent activity.

### Step 4: Present Status to User

Wait for the status-checker agent to complete and return the team lead's response.

Present the status report to the user in a clear format.

### Step 5: Offer Next Actions

After presenting the status report, ask the user if they want to:

1. **Get more details** on a specific agent or task
2. **Nudge stuck agents** (if any were reported as stuck)
3. **Check again** in a few minutes
4. **Nothing** - just checking in

Wait for the user's choice and act accordingly.

## Key Principles

- **Delegate to team leads**: Always ask the architect/accountant for their perspective first
- **Use temporary agents**: Spawn a status-checker agent to join the team and query the lead
- **Brief by default**: Team leads should provide concise summaries
- **User decides next steps**: Present options, don't auto-nudge

## Edge Cases

**No active teams**: Report "No active teams running." and stop.

**Multiple teams**: Report status for each team separately.

**Team lead unresponsive**: If the status-checker agent doesn't get a response within 30 seconds, report that the team lead is unresponsive and offer to check task files directly.

**Vanilla team (no recognized lead)**: Use `TaskList` to check task status directly and report on agent activity without querying a lead.
