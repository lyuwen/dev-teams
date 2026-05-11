# Completion Protocol Fix

**Date:** 2026-05-11  
**Branch:** `worktree-fix-agent-completion-protocol`  
**Commit:** b21ecd7

## Problem Statement

Both dev-team and data-team agents were stalling mid-workflow. Investigation revealed a systematic issue:

**Agents complete their work (write files, commit code) but forget to send completion messages to team leads.**

### Real-World Example: Warren Dev-Team

The Reviewer agent:
1. ✅ Completed all Phase 2 reviews (3 branches, ~12,000 lines)
2. ✅ Wrote detailed review documents to `.claude/reviews/`
3. ❌ **Never sent a message to the Architect**

Result: The Architect kept asking "Where are your findings?" while the Reviewer had already finished and gone silent. The pipeline stalled completely.

### Root Cause

Agent instructions had "Message the team lead" as step 6 in a process list, but:
- Not emphasized as critical
- No explicit warning that work is incomplete without the message
- Team leads had no protocol for detecting silent completion vs. dead agents

## Solution

### 1. Explicit Completion Protocols for Non-Lead Agents

Added prominent **⚠️ CRITICAL: Completion Protocol** sections to all non-lead agents:

**Affected agents:**
- `reviewer.md` - Reviews code/tests, writes review files
- `minuteman.md` - Analyzes data shards, writes reports
- `tester.md` - Writes tests, writes testing reports
- `critique.md` - Deep-dive review, writes critique documents
- `documenter.md` - Writes documentation
- `instructor.md` - Runs usability testing, writes UX findings
- `implementer.md` - Writes feature code

**Protocol structure:**
```markdown
## ⚠️ CRITICAL: Completion Protocol

Your work is NOT complete until you complete ALL of these steps:

1. ✅ **[Primary work]** (write files, run tests, etc.)
2. ✅ **[Secondary work]** (commit, review, etc.)
3. ✅ **Send a message to [Team Lead]** with [specific content]
4. ✅ **Update task status to completed**

**The [Team Lead] is waiting for your message.** Writing files alone is not sufficient. 
If you write files but don't send a message, the pipeline will stall.

Your message must include:
- [Specific required content for this agent type]
```

### 2. Enhanced Team Lead Monitoring

Updated team leads (Architect, Accountant) to detect silent completion:

**New protocol:**
1. After assigning work, expect a completion message
2. If agent goes quiet, **check for completed work BEFORE declaring dead**:
   - Reviewer: Check `.claude/reviews/` for review files
   - Tester: Check for test commits and reports
   - Implementer: Check for feature commits
   - Minuteman: Check `data-team-output/shard-{id}/` for reports
3. If completed work found: "I found your completed work in [location]. Please send me a summary message."
4. If no work found: Proceed with standard dead-agent protocol

**Why this matters:**
- Prevents unnecessary respawns when work is actually complete
- Unblocks the pipeline immediately
- Teaches agents the correct completion behavior

## Changes Summary

### Files Modified (9 total)

**Non-lead agents (added Completion Protocol):**
1. `agents/reviewer.md` - 20 lines added
2. `agents/minuteman.md` - 22 lines added
3. `agents/tester.md` - 21 lines added
4. `agents/critique.md` - 23 lines added
5. `agents/documenter.md` - 22 lines added
6. `agents/instructor.md` - 23 lines added
7. `agents/implementer.md` - 19 lines added

**Team leads (enhanced monitoring):**
8. `agents/architect.md` - 28 lines added
9. `agents/accountant.md` - 43 lines added

**Total:** 193 insertions, 12 deletions

## Expected Impact

### Immediate Benefits

1. **Prevents pipeline stalls** - Agents now know messaging is mandatory
2. **Faster recovery** - Team leads detect silent completion instead of waiting for timeout
3. **Better visibility** - Explicit completion messages provide clear status updates

### Long-Term Benefits

1. **Reduced debugging time** - Clear protocol violations vs. actual failures
2. **Improved agent reliability** - Completion becomes a checklist, not an afterthought
3. **Better user experience** - Pipeline moves forward predictably

## Testing Recommendations

1. **Dev-team test:** Assign a review task to Reviewer, verify completion message is sent
2. **Data-team test:** Spawn minutemen for data analysis, verify all send completion messages
3. **Silent completion test:** Manually create output files without messaging, verify team lead detects and prompts
4. **Dead agent test:** Verify team leads still detect truly dead agents (no work, no message)

## Rollout Plan

1. **Review this branch** - Verify changes are correct
2. **Merge to main** - Apply fixes to production agents
3. **Monitor next team run** - Watch for completion message behavior
4. **Document learnings** - Add to team memory if patterns emerge

## Related Documentation

- `shared/operational-resilience.md` - Team health monitoring protocols
- `shared/team-memory-protocol.md` - Team lead vs. non-lead responsibilities
- `shared/cross-team-protocol.md` - Cross-team communication rules

## Notes

This fix addresses a **systematic coordination failure**, not a one-off bug. The pattern (complete work → write files → forget to message) is likely to occur in any multi-agent system where:
- Agents produce durable artifacts (files)
- Team leads coordinate via messages
- Completion requires both artifact + message

The solution (explicit completion protocols + silent completion detection) should be considered a **best practice for multi-agent coordination**.
