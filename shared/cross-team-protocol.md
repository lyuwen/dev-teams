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


## Delegation Boundaries

Clear boundaries prevent scope creep and ensure each team focuses on its strengths.

### Data Team Scope

The Accountant and minute-men handle:
- Data analysis, profiling, quality auditing
- Dataset investigation and characterization
- Ad-hoc scripts for one-off tasks (lives in `data-team-output/`)
- Identifying tool gaps and writing PRDs
- Aggregating findings and reporting to user

### Dev Team Scope

The Architect and dev-team agents handle:
- Production tools, libraries, CLI commands
- Reusable infrastructure code
- Anything that needs tests, documentation, and maintenance
- Code that lives in the main codebase (not `data-team-output/`)

### Boundary Enforcement Rules

1. **The Accountant NEVER writes production code**, even if it seems simple or quick
2. If the user asks the Accountant to "build a tool", "consolidate code", or "make it reusable" → Accountant writes PRD, does NOT implement
3. If minute-men report the same workaround 3+ times → Accountant writes PRD for a proper tool
4. Ad-hoc scripts in `data-team-output/` are OK; code in the main codebase is NOT
5. When in doubt, write a PRD and consult the Architect

### Violation Examples

❌ **WRONG:** User asks "consolidate these data processing scripts into production code" → Accountant writes the code

✅ **RIGHT:** User asks "consolidate these data processing scripts into production code" → Accountant writes PRD, sends to Architect

---

❌ **WRONG:** Accountant spawns vanilla subagent for data analysis

✅ **RIGHT:** Accountant spawns minuteman with `subagent_type: "minuteman"`

---

❌ **WRONG:** Minute-men report needing a CSV parser 5 times → Accountant writes a one-off parser each time

✅ **RIGHT:** Minute-men report needing a CSV parser 3+ times → Accountant writes PRD for a reusable CSV parsing tool

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
