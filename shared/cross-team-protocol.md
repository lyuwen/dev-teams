# Cross-Team Protocol

This protocol governs communication between teams. It applies to team leads and committee members.

## Teams

| Team | Lead | Members |
|------|------|---------|
| Dev Team | Architect | Implementer, Tester, Reviewer, Critique, Documenter, Instructor, Noob |
| Data Team | Accountant | Minute-men (dynamically spawned) |

## The Committee

**Members:** Accountant, Architect, Critique, Reviewer.

The committee convenes when data concerns and software concerns intersect:

- Data team discovers systematic tool failures or missing capabilities
- Dev team ships a tool that needs data-team validation
- Ambiguous issues: data bug vs. software bug
- Architectural decisions that affect data pipelines

Committee discussions happen via SendMessage between the members. Either lead can initiate.

## Communication Rules

### Lead-to-Lead

- Accountant and Architect communicate directly via SendMessage
- Neither lead speaks for the other's domain without consulting first
- Cross-team requests include context: what's needed, why, and urgency

### Lead-to-Committee-Member

- Accountant can message Critique and Reviewer directly for committee discussions
- Accountant does NOT message Implementer, Tester, Documenter, Instructor, or Noob directly
- Architect can message Accountant directly

### Workers

- Minute-men do NOT communicate with dev-team agents
- Dev-team workers do NOT communicate with data-team agents
- All cross-team communication routes through the leads

## Product Requirement Document (PRD) Flow

When the data team needs a new tool or tool improvement:

1. **Minute-men** flag ad-hoc workarounds in their reports to the Accountant
2. **Accountant** collects, deduplicates, and prioritizes tool needs
3. **Accountant** writes a PRD to `docs/prd/YYYY-MM-DD-<topic>.md` with:
   - Problem statement
   - Current workaround (what the minute-men are doing ad-hoc)
   - Expected behavior (what the tool should do)
   - Priority (blocking / important / nice-to-have)
4. **Accountant** sends the PRD to the Architect via SendMessage
5. **Architect** evaluates, may push back or request clarification
6. Once agreed, **Architect** decomposes into dev-team tasks

### PRD Format

```
# PRD: [Tool/Feature Name]

**Date:** YYYY-MM-DD
**Priority:** [blocking | important | nice-to-have]
**Requested by:** Accountant (data team)

## Problem

[What the data team is struggling with]

## Current Workaround

[What ad-hoc scripts/approaches the minute-men are using]

## Expected Behavior

[What the tool should do — inputs, outputs, interface]

## Context

[Relevant data characteristics, scale, frequency of use]
```

## User Interaction

The user is the boss. Both leads report to the user:

- **Accountant:** Brief, focused, most-important-issue-first. Does not elaborate unless asked.
- **Architect:** Same style as currently defined.
- User can address either lead directly
- Neither lead speaks for the other's domain without consulting first
- The user always has the final say on committee decisions
