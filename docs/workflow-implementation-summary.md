# Summary: Data Team Workflow Implementation

## What We Built

Converted the data-team's Accountant + minutemen structure into a dynamic workflow system and integrated it with the existing plugin.

## Files Created

### Core Workflow Implementation
- **`skills/data-team/workflows/data-team.js`** — 4-phase workflow (plan → execute → aggregate → report) that mirrors the Accountant + minutemen agent pattern

### Documentation
- **`docs/data-team-modes.md`** — Comprehensive comparison of agents vs workflow modes
- **`docs/examples/data-team-workflow-comparison.md`** — Side-by-side execution traces showing both modes
- **`docs/workflows-overview.md`** — Technical overview of all workflows in the plugin

### Updated Files
- **`skills/data-team/SKILL.md`** — Updated to support both agents and workflow modes with clear decision guidance

### Fixed Files
- **`skills/data-analysis-workflow/workflows/data-analysis.js`** — Renamed from `.ts` and removed TypeScript syntax
- **`skills/data-analysis-workflow/SKILL.md`** — Updated to reference `.js` file

## Key Features

### Dual-Mode Support
The data-team skill now supports two execution modes:

**Agents Mode (default):**
- Dynamic coordination via Accountant agent
- On-demand minuteman spawning
- Cross-team integration (committee, PRDs)
- Team memory updates
- Persistent state for follow-up tasks

**Workflow Mode:**
- Deterministic 4-phase pipeline
- All workers spawn at once in phase 2
- No cross-team coordination
- Lower overhead
- One-shot execution

### Mode Selection
```javascript
// Default (agents)
/data-team Analyze this dataset

// Explicit workflow
/data-team mode: workflow, task: Analyze this dataset

// Natural language detection
"Run a data quality workflow" → workflow mode
"Launch the data team" → agents mode
```

### Output Structure
Both modes produce the same output structure:
```
data-team-output/
  REPORT.md
  aggregated-findings.jsonl
  tool-gaps.md
  shard-001/, shard-002/, ...
```

### Workflow Implementation Details

**Phase 1: Plan**
- Accountant-persona agent analyzes task
- Decides sharding strategy (by-file, by-range, by-category, by-sample)
- Writes decomposition.json

**Phase 2: Execute (parallel)**
- Spawns N minuteman-persona agents via `parallel()`
- Each analyzes assigned shard
- Writes report.md, findings.jsonl, summary.json

**Phase 3: Aggregate**
- Accountant-persona reads all shard outputs
- Identifies cross-shard patterns
- Deduplicates findings
- Writes aggregated-findings.jsonl and tool-gaps.md

**Phase 4: Report**
- Accountant-persona writes REPORT.md
- Brief, focused, most-important-finding-first style
- Points to detailed shard reports

## Technical Decisions

### JavaScript (not TypeScript)
Per workflow documentation, workflows must be `.js` files. Converted both:
- `data-team.ts` → `data-team.js`
- `data-analysis.ts` → `data-analysis.js`

Removed TypeScript syntax:
- `string;` → `string,`
- `?: type` → removed type annotations
- `: Promise<string>` → removed return types
- `(param: type)` → `(param)`

### Persona vs Registered Agents
**Workflows:** Use persona prompts ("You are the Accountant...") with `subagent_type: "claude"`
**Agents:** Use registered agents with `subagent_type: "accountant"` or `subagent_type: "minuteman"`

This distinction allows workflows to operate independently without requiring the full agent infrastructure.

### File Structure
```
skills/data-team/
  SKILL.md              # Dual-mode launcher
  workflows/
    data-team.js        # Workflow implementation

skills/data-analysis-workflow/
  SKILL.md              # Workflow-only launcher
  workflows/
    data-analysis.js    # Simpler 3-phase version
```

## Comparison: data-team-workflow vs data-analysis-workflow

| Aspect | data-team-workflow | data-analysis-workflow |
|--------|-------------------|------------------------|
| Phases | 4 (plan → execute → aggregate → report) | 3 (decompose → analyze → aggregate) |
| Persona | Full Accountant framing | Simple coordinator role |
| Report phase | Separate phase 4 | Included in phase 3 |
| Communication style | Accountant's terse style | Generic reporting |
| Use case | Full data-team experience | Lightweight analysis |

## Usage Examples

### Quality Audit (Agents)
```bash
/data-team Audit train.jsonl for quality issues

# Accountant spawns minutemen dynamically
# Can adapt strategy mid-flight
# Writes PRDs if tool gaps found
# Participates in committee
# Persists for follow-up work
```

### Quality Audit (Workflow)
```bash
/data-team mode: workflow, task: Audit train.jsonl for quality issues

# Fixed 4-phase pipeline
# All workers spawn at once
# Tool gaps listed in tool-gaps.md
# No cross-team integration
# Terminates after completion
```

## Integration with Existing Plugin

The workflow integrates seamlessly with the existing dev-teams plugin:

- **Shared output directory:** `data-team-output/` (same as agents mode)
- **Shared protocols:** Workflow implements same communication style as Accountant
- **Shared documentation:** All docs reference both modes
- **No breaking changes:** Agents mode remains default, workflow is opt-in

## Benefits

### For Users
- **Choice:** Pick agents for flexibility, workflow for determinism
- **Compatibility:** Same output structure regardless of mode
- **Easy switching:** Can try both modes on same task
- **Clear guidance:** Documentation explains when to use each

### For Development
- **Reusable patterns:** Workflow can be templated for other teams
- **Lower barrier:** Workflow is simpler to understand than agent coordination
- **Performance:** Workflow has lower overhead for one-shot tasks
- **Testability:** Deterministic phases are easier to test

## Next Steps

### Immediate
1. Test both modes on real datasets
2. Verify workflow script execution
3. Document any edge cases

### Future Enhancements
1. Add more sharding strategies (by-hash, by-time-range)
2. Create workflow for dev-team (Architect + workers pattern)
3. Add workflow resume capability for long-running analyses
4. Build workflow templates for common data tasks

## Files to Review

Priority order:
1. `skills/data-team/SKILL.md` — Updated skill with mode selection logic
2. `skills/data-team/workflows/data-team.js` — Core workflow implementation
3. `docs/data-team-modes.md` — Comprehensive comparison guide
4. `docs/examples/data-team-workflow-comparison.md` — Side-by-side examples

## Verification Checklist

- [x] Workflow file is `.js` not `.ts`
- [x] No TypeScript syntax in workflow files
- [x] Skill file references correct `.js` path
- [x] Documentation covers both modes
- [x] Examples show both execution patterns
- [x] Plugin manifest doesn't need updates (workflows auto-discovered)
- [x] Output structure matches agents mode
- [x] Communication style matches Accountant persona

## Summary

Successfully converted the data-team agent structure into a workflow while maintaining full backward compatibility. Users can now choose between agents (flexible, adaptive) and workflow (deterministic, structured) based on their needs. The implementation is clean, well-documented, and ready for testing.
