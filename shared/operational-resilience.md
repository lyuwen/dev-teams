# Operational Resilience Protocol

This protocol applies to all agents across all teams. It ensures the pipeline keeps moving and failures are detected early.

## For Team Leads

As team lead, you must keep yourself and your team visible:

1. **Report progress to the user** — send periodic status updates, especially during long-running coordination
2. **Report errors immediately** — if a tool fails or an agent is unresponsive, tell the user what happened and your recovery plan
3. **Never go silent** — if you're stuck or waiting, say so. The user should never wonder if you're alive.

### Tracking Responsiveness

After assigning a task to an agent, expect acknowledgment (a message or task status change). If an agent goes quiet:

1. **First check-in:** Send a message: "Status check — are you working on [task]? Reply with your current progress."
2. **Second check-in:** If no response, send again: "No response received. Please reply immediately with your status."
3. **Declare dead:** If 2 consecutive check-ins get no response, consider the agent dead or crashed.

### Respawning Dead Agents

When an agent is dead:

1. **Update the task:** Set the dead agent's task back to `pending` and clear the owner
2. **Respawn:** Use the Agent tool to spawn a fresh instance with the same `name`, `subagent_type`, and `team_name`. Include in the prompt:
   - That this is a respawn — the previous instance died
   - The agent should check TaskList for unfinished work assigned to it
   - The team name so it can read the team config
3. **Reassign:** After the new instance is alive, reassign the pending task
4. **If respawn fails:** Retry once. If it fails again, escalate to the user: "[Agent] has died and cannot be respawned. Options: continue without it, retry later, or abort."

### Pipeline Stall Detection

If the pipeline has made no visible progress for an extended period:

1. Send a check-in message to every agent that should be active
2. Identify which agents are responsive and which are dead
3. Respawn dead agents or escalate to the user
4. Report the situation: which agents are alive, which tasks are stalled, what the recovery plan is

### Graceful Degradation

Not all agents are needed at all times. If a non-critical agent dies during a phase where it's not active, defer respawning until its phase begins.

## For Non-Lead Agents

Your team lead monitors team health. Help by being communicative:

1. **Report when starting** — message your team lead when you begin work on a task
2. **Report progress on long tasks** — if work takes more than a few minutes, send a brief status update
3. **Report errors immediately** — if you hit an error (API failure, tool failure, unexpected state), message your team lead with what happened rather than silently failing
4. **Never go silent** — if you're stuck, blocked, or confused, say so. Silence stalls the pipeline.
5. **Respond to check-ins** — if your team lead asks for a status check, respond immediately with your current state

## For Agents Without SendMessage (e.g., Noob)

If you cannot use SendMessage, you must still be communicative:

1. **Work visibly** — produce output with every step so your observer can monitor progress
2. **Report errors in your output** — if something fails, describe what happened, what you expected, and what you tried next
3. **Never go silent** — if you're stuck, write what confused you
