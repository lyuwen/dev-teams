# Instructor-Noob-Documenter Workflow Redesign

**Date:** 2026-05-11  
**Branch:** `worktree-fix-agent-completion-protocol`  
**Commit:** a7f6343

## Problem Statement

The original usability testing workflow was **too slow and indirect**:

```
Old workflow:
Instructor → finds issue → Architect → Documenter → Architect → Instructor → re-test
```

**Issues:**
1. Every doc fix required 4 message hops
2. Architect became a bottleneck for simple doc updates
3. No iterative testing — all issues batched into one report
4. Slow feedback loop meant multiple rounds of "find all issues → fix all issues → re-test all"

## New Workflow

**Direct communication between Instructor and Documenter:**

```
New workflow:
Instructor ←→ Documenter (direct, iterative)
Instructor → Architect (only for implementation issues)
```

### Detailed Flow

1. **Instructor** designs user tasks based on implementation
2. **Instructor** dispatches first task to **Noob**
3. **Noob** attempts task using only docs, reports back
4. **Instructor** diagnoses immediately:
   - **Doc issue?** → Send fix request directly to **Documenter**
   - **Implementation issue?** → Report to **Architect**
5. **Documenter** fixes docs, commits, messages **Instructor** directly
6. **Instructor** re-tests same task with **Noob**
7. **Iterate** until task passes
8. **Move to next task** (repeat steps 2-7)
9. **Final report** to Architect when all critical tasks pass

## Key Changes

### Instructor Agent

**New responsibilities:**
- Diagnose issues in real-time (not batch at end)
- Send fix requests directly to Documenter via SendMessage
- Iterate on each task until it passes before moving to next
- Only report implementation issues to Architect

**New process:**
- Phase 1: Preparation (study code, design tasks)
- Phase 2: Iterative testing (test → diagnose → fix → re-test per task)
- Phase 3: Final report (after all tasks pass)

**Message format to Documenter:**
```
Doc fix needed: [specific issue]

Evidence from Noob:
- Task: [what Noob tried to do]
- What failed: [exact command/step]
- Why: [what was missing/unclear]

Required fix:
- [specific section to add/update]
- [exact information to include]

After fixing, commit and message me so I can re-test.
```

### Documenter Agent

**New responsibilities:**
- Accept tasks from both Architect (initial docs) and Instructor (usability fixes)
- Respond to Instructor's fix requests immediately
- Message Instructor directly when fix is ready for re-testing

**New process:**
- Two modes: Initial documentation (from Architect) and Documentation fixes (from Instructor)
- For fixes: Read request → Apply fix → Commit → Message Instructor immediately

**Message format to Instructor:**
```
Doc fix applied: [brief description]

Files updated:
- [file1]: [what changed]
- [file2]: [what changed]

The issue "[specific issue]" should now be resolved. Ready for re-testing.
```

### Architect Agent

**Updated workflow:**
- Step 12: Trigger usability testing, note that Instructor handles doc fixes directly
- Step 13: Only handle implementation issues from Instructor
- Added guidance on when to use full usability testing

**When to use usability testing:**

✅ **Required for:**
- User-facing tools with extensive interaction (CLI, APIs, config systems)
- New features introducing new workflows
- Projects where UX is critical (tools for non-developers)
- Examples: Warren, dataset converters, training pipelines

❌ **Skip for:**
- Bug fixes (no new workflows)
- Internal refactoring (no user-facing changes)
- Algorithm optimization (no interface changes)
- Small improvements to existing features
- Backend-only changes

## Benefits

### Speed
- **Before:** 4 message hops per doc fix (Instructor → Architect → Documenter → Architect → Instructor)
- **After:** 2 message hops per doc fix (Instructor → Documenter → Instructor)
- **Result:** 2x faster iteration on doc issues

### Efficiency
- **Before:** Batch all findings, fix all at once, re-test all
- **After:** Fix issues incrementally as discovered, verify each fix immediately
- **Result:** Fewer wasted cycles, faster convergence to working docs

### Architect Overhead
- **Before:** Architect routes every doc fix request
- **After:** Architect only handles implementation issues
- **Result:** Architect can focus on coordination and design decisions

### Documentation Quality
- **Before:** Issues discovered in batch, context lost between rounds
- **After:** Issues fixed immediately with full context from Noob's struggle
- **Result:** More targeted, effective doc improvements

## Example Scenario

**Task:** "Install the tool and run your first conversion"

### Old Workflow (3 hours)
1. Noob tries, fails (missing installation steps)
2. Instructor collects finding
3. Noob tries next task, fails (unclear flag syntax)
4. Instructor collects finding
5. After all tasks, Instructor writes report → Architect
6. Architect routes to Documenter
7. Documenter fixes both issues → Architect
8. Architect tells Instructor to re-test
9. Instructor re-tests both tasks
10. **Total time:** ~3 hours (multiple message hops, batched fixes)

### New Workflow (45 minutes)
1. Noob tries, fails (missing installation steps)
2. Instructor diagnoses → sends fix request to Documenter
3. Documenter adds installation section → messages Instructor
4. Instructor re-tests same task with Noob → passes
5. Instructor moves to next task
6. Noob tries, fails (unclear flag syntax)
7. Instructor diagnoses → sends fix request to Documenter
8. Documenter adds flag examples → messages Instructor
9. Instructor re-tests → passes
10. **Total time:** ~45 minutes (direct communication, incremental fixes)

## Implementation Notes

### Message Routing

**Instructor can now send messages to:**
- Documenter (for doc fixes)
- Architect (for implementation issues)
- Noob (for task assignments)

**Documenter can now receive messages from:**
- Architect (initial documentation tasks)
- Instructor (usability fix requests)

### Iteration Protocol

**Critical rule:** Instructor MUST NOT move to next task until current task passes.

This ensures:
- Each task is validated before moving forward
- Documentation is incrementally improved
- No accumulation of unresolved issues

### Completion Criteria

**Instructor completes when:**
- All critical tasks pass (P0 issues resolved)
- All major tasks pass or have documented workarounds (P1 issues)
- Final report sent to Architect with iteration log

**Not when:**
- All tasks attempted once (old behavior)
- All findings collected in one report (old behavior)

## Testing Recommendations

1. **Test direct communication:** Verify Instructor can send messages to Documenter
2. **Test iteration:** Verify Instructor re-tests after each doc fix
3. **Test task blocking:** Verify Instructor doesn't move to next task until current passes
4. **Test Architect bypass:** Verify doc fixes don't route through Architect
5. **Test implementation escalation:** Verify implementation issues still go to Architect

## Related Documentation

- `agents/instructor.md` - Updated process with iterative testing
- `agents/documenter.md` - Added documentation fixes mode
- `agents/architect.md` - Updated workflow and usability testing guidance
- `docs/completion-protocol-fix.md` - Related completion protocol improvements

## Notes

This redesign is **essential for user-facing projects** like Warren where:
- User experience is critical
- Documentation must be comprehensive
- Workflows must be intuitive
- Fast iteration on usability issues is required

For simpler projects (bug fixes, optimizations), the full usability testing workflow can be skipped entirely.
