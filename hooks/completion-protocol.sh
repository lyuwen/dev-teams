#!/bin/bash
# dev-teams: completion-protocol Stop hook.
#
# When a non-lead agent (critique/reviewer/tester/implementer) finishes a turn
# that wrote a workflow artifact (a file under .claude/critiques/ or
# .claude/reviews/ or .claude/tests/), the same turn MUST also:
#   - call TaskUpdate with status="completed"
#   - call SendMessage to the architect (or to its assigned recipient)
#
# Otherwise the pipeline stalls silently: architect has no signal, the task
# tracker still says pending, and the agent goes idle thinking it's done.
#
# This hook inspects the just-finished turn in the transcript. If an artifact
# write is present but the two closing tool calls are missing, it blocks the
# stop and injects a reminder telling the agent to make the missing calls.
#
# Conservative-by-default: any parse failure or unexpected shape exits 0
# (allow stop). The hook should NEVER falsely block routine work.

set -uo pipefail

HOOK_INPUT=$(cat)

# Need jq; if it's missing, don't block.
command -v jq >/dev/null 2>&1 || exit 0

TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
[[ -f "$TRANSCRIPT_PATH" ]] || exit 0

# Only enforce for dev-team non-lead agents. We detect this by team name on
# the most recent assistant line — the lead agent's transcript does not carry
# a teamName matching our pattern in the same way (lead drives the team and
# already messages itself). We match dev-team-* teams here.
TEAM_NAME=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 1 \
  | jq -r '.teamName // ""' 2>/dev/null || echo "")

# If no team, this is a solo session — don't enforce.
[[ -n "$TEAM_NAME" ]] || exit 0
case "$TEAM_NAME" in
  dev-team-*) ;;
  *) exit 0 ;;
esac

# Pull only the last turn's assistant lines. A "turn" is bounded by the most
# recent user/system message in the transcript. We approximate by taking
# everything after the last user line.
LAST_USER_LINENO=$(grep -n '"type":"user"' "$TRANSCRIPT_PATH" | tail -n 1 | cut -d: -f1)
if [[ -z "$LAST_USER_LINENO" ]]; then
  TURN_LINES=$(cat "$TRANSCRIPT_PATH")
else
  TURN_LINES=$(tail -n +"$LAST_USER_LINENO" "$TRANSCRIPT_PATH")
fi

# Only inspect this turn's assistant lines.
ASSISTANT_LINES=$(echo "$TURN_LINES" | grep '"role":"assistant"' || true)
[[ -n "$ASSISTANT_LINES" ]] || exit 0

# Did the agent write an artifact under .claude/critiques|reviews|tests/ ?
WROTE_ARTIFACT=$(echo "$ASSISTANT_LINES" | jq -rs '
  [ .[] | .message.content[]?
    | select(.type == "tool_use")
    | select(.name == "Write" or .name == "Edit")
    | (.input.file_path // .input.path // "")
  ]
  | map(select(test("\\.claude/(critiques|reviews|tests)/")))
  | length
' 2>/dev/null || echo "0")
[[ "$WROTE_ARTIFACT" =~ ^[0-9]+$ ]] || exit 0
[[ "$WROTE_ARTIFACT" -gt 0 ]] || exit 0

# Did the agent call TaskUpdate with status="completed" this turn?
DID_TASKUPDATE=$(echo "$ASSISTANT_LINES" | jq -rs '
  [ .[] | .message.content[]?
    | select(.type == "tool_use")
    | select(.name == "TaskUpdate")
    | (.input.status // "")
  ]
  | map(select(. == "completed"))
  | length
' 2>/dev/null || echo "0")
[[ "$DID_TASKUPDATE" =~ ^[0-9]+$ ]] || DID_TASKUPDATE=0

# Did the agent send a message to architect (or any teammate) this turn?
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
  MISSING+="• TaskUpdate(taskId=<your task id>, status=\"completed\")\n"
fi
if [[ "$DID_SENDMSG" -eq 0 ]]; then
  MISSING+="• SendMessage(to=\"architect\", message=\"<verdict / summary / next step>\")\n"
fi

REASON=$(printf 'COMPLETION PROTOCOL VIOLATION\n\nYou wrote a workflow artifact this turn (under .claude/critiques|reviews|tests/) but did not close the loop. The pipeline will stall unless you make these tool calls before stopping:\n\n%s\nMake the missing calls now, then stop.\n' "$MISSING")

jq -n --arg reason "$REASON" '{
  "decision": "block",
  "reason": $reason,
  "systemMessage": "dev-teams: blocked stop — completion protocol not satisfied"
}'
exit 0
