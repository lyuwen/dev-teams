#!/bin/bash
# dev-teams: completion-protocol Stop hook.
#
# Goal: prevent silent stalls where a non-lead agent finishes its work but
# fails to close the loop with TaskUpdate(completed) + SendMessage(...) —
# leaving the task tracker showing the gate still open and the architect
# with no signal that anything happened.
#
# Trigger model:
#   Look up this agent's name (from its transcript), then check the team's
#   task list for tasks where owner == this agent and status == "in_progress"
#   (or status == "pending" that the agent has been working on). If such a
#   task exists and the just-finished turn did not call TaskUpdate(completed)
#   OR SendMessage(to=...), block the stop with a targeted reminder.
#
# This catches the common case regardless of whether the agent wrote a file
# artifact — including dev-team agents who deliver verdicts purely in
# messages without writing under .claude/{critiques,reviews,tests}/.
#
# Conservative-by-default: any parse failure or unexpected shape exits 0
# (allow stop). The hook should NEVER falsely block routine work.
#
# Excludes: team-lead (drives the team and may legitimately end turns
# without any closing tool call).

set -uo pipefail

HOOK_INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
[[ -f "$TRANSCRIPT_PATH" ]] || exit 0

# Identify which agent and team this stop belongs to from the most recent
# assistant line on the transcript.
LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 1)
[[ -n "$LAST_ASSISTANT" ]] || exit 0

TEAM_NAME=$(echo "$LAST_ASSISTANT" | jq -r '.teamName // ""')
AGENT_NAME=$(echo "$LAST_ASSISTANT" | jq -r '.agentName // ""')

# Only enforce inside dev-team-* teams.
case "$TEAM_NAME" in
  dev-team-*) ;;
  *) exit 0 ;;
esac

# Skip the team lead — it has no agentName on its lines and may end turns
# without closing calls (driving the team, replying to user, etc.).
[[ -n "$AGENT_NAME" ]] || exit 0
[[ "$AGENT_NAME" != "team-lead" ]] || exit 0

# Locate the team's task list and find tasks currently assigned to this agent.
TASK_DIR="$HOME/.claude/tasks/$TEAM_NAME"
[[ -d "$TASK_DIR" ]] || exit 0

# Tasks where owner == this agent and status is in_progress or pending.
# "pending" is included because the team-lead protocol assigns the owner
# before the agent transitions to in_progress; if the agent finishes a
# turn that touched the task, the closing calls are still required.
OPEN_TASK_IDS=$(jq -r --arg owner "$AGENT_NAME" '
  select((.owner // "") == $owner)
  | select((.status // "") == "in_progress" or (.status // "") == "pending")
  | .id
' "$TASK_DIR"/*.json 2>/dev/null | tr '\n' ' ' | sed 's/ $//')

# Nothing assigned → nothing to enforce.
[[ -n "$OPEN_TASK_IDS" ]] || exit 0

# Inspect only the last turn's assistant tool calls. A "turn" starts at the
# most recent user line in the transcript.
LAST_USER_LINENO=$(grep -n '"type":"user"' "$TRANSCRIPT_PATH" | tail -n 1 | cut -d: -f1)
if [[ -z "$LAST_USER_LINENO" ]]; then
  TURN_LINES=$(cat "$TRANSCRIPT_PATH")
else
  TURN_LINES=$(tail -n +"$LAST_USER_LINENO" "$TRANSCRIPT_PATH")
fi
ASSISTANT_LINES=$(echo "$TURN_LINES" | grep '"role":"assistant"' || true)
[[ -n "$ASSISTANT_LINES" ]] || exit 0

# Did this turn call TaskUpdate(status="completed") on one of the open tasks?
DID_TASKUPDATE=$(echo "$ASSISTANT_LINES" | jq -rs --arg ids "$OPEN_TASK_IDS" '
  ($ids | split(" ")) as $open
  | [ .[] | .message.content[]?
      | select(.type == "tool_use")
      | select(.name == "TaskUpdate")
      | select((.input.status // "") == "completed")
      | (.input.taskId // "")
    ]
  | map(select(. as $t | $open | index($t)))
  | length
' 2>/dev/null || echo "0")
[[ "$DID_TASKUPDATE" =~ ^[0-9]+$ ]] || DID_TASKUPDATE=0

# Did this turn send any message to a teammate?
DID_SENDMSG=$(echo "$ASSISTANT_LINES" | jq -rs '
  [ .[] | .message.content[]?
    | select(.type == "tool_use")
    | select(.name == "SendMessage")
    | (.input.to // .input.recipient // "")
  ]
  | map(select(. != ""))
  | length
' 2>/dev/null || echo "0")
[[ "$DID_SENDMSG" =~ ^[0-9]+$ ]] || DID_SENDMSG=0

# Both closing calls present → allow stop.
if [[ "$DID_TASKUPDATE" -gt 0 ]] && [[ "$DID_SENDMSG" -gt 0 ]]; then
  exit 0
fi

# Build a targeted reminder describing exactly what's missing.
MISSING=""
if [[ "$DID_TASKUPDATE" -eq 0 ]]; then
  MISSING+="• TaskUpdate(taskId=\"<id from list above>\", status=\"completed\")\n"
fi
if [[ "$DID_SENDMSG" -eq 0 ]]; then
  MISSING+="• SendMessage(to=\"architect\", message=\"<verdict / result / next step>\")\n"
fi

REASON=$(printf 'COMPLETION PROTOCOL VIOLATION\n\nYou are the owner of open task(s): %s\nbut this turn did not close the loop. The pipeline will stall unless you make these tool calls before stopping:\n\n%s\nIf the work is actually finished, make the missing calls now and stop.\nIf you are still mid-task and intend to continue next turn, send a brief status SendMessage so the team lead and architect know you are alive — silence is what stalls the pipeline.\n' "$OPEN_TASK_IDS" "$MISSING")

jq -n --arg reason "$REASON" '{
  "decision": "block",
  "reason": $reason,
  "systemMessage": "dev-teams: blocked stop — completion protocol not satisfied"
}'
exit 0
