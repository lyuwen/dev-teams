# Data Team Workflow Example: Side-by-Side Comparison

This example shows the same data quality audit task executed in both agents mode and workflow mode.

## Setup

**Dataset:** `data/train.jsonl` — 100,000 instruction-tuning records
**Task:** Audit for quality issues, duplicates, empty fields, format problems

## Agents Mode

### Launch Command
```
/data-team Audit train.jsonl for quality issues - empty fields, duplicates, format problems
```

### Execution Trace

**T+0s: Launcher**
```
✓ Git repository verified
✓ Team created: data-team
✓ Team memory initialized: .claude/team-memory/MEMORY.md
✓ Output directory created: data-team-output/
✓ Task created on shared task list
✓ Spawning Accountant...
```

**T+3s: Accountant (analyzing task)**
```
[Accountant] Reading task requirements...
[Accountant] Discovering data location: data/train.jsonl
[Accountant] File size: 2.3GB, estimated 100K records
[Accountant] Decision: shard by record range (10 shards of 10K records each)
[Accountant] Spawning minuteman-001 for records 0-9999...
[Accountant] Spawning minuteman-002 for records 10000-19999...
...
[Accountant] Spawning minuteman-010 for records 90000-99999...
[Accountant] 10 minutemen launched. Waiting for results...
```

**T+5s: Minutemen (parallel analysis)**
```
[minuteman-001] Analyzing records 0-9999...
[minuteman-002] Analyzing records 10000-19999...
...
[minuteman-010] Analyzing records 90000-99999...
```

**T+45s: Minuteman-003 (reports to Accountant)**
```
SendMessage to: accountant

Shard 003 done. 10,000 records analyzed.

Top findings:
1. 41% empty response fields (4,100 records)
2. Math category dominates this shard (87% of records)
3. 23 exact duplicate instructions

Full report: data-team-output/shard-003/report.md

Note: I wrote a custom script for duplicate detection — this should be a proper tool.
```

**T+47s: All minutemen complete**
```
[Accountant] Received reports from all 10 shards
[Accountant] Aggregating findings...
[Accountant] Cross-shard pattern detected: math category has 5x higher empty response rate
[Accountant] Tool gap identified: duplicate detection flagged by 5/10 minutemen
[Accountant] Writing aggregated report...
```

**T+50s: Accountant reports to user**
```
SendMessage to: user

23% of records have empty response fields. Concentrated in math category (41% empty vs 8% elsewhere).

Full report: data-team-output/REPORT.md

3 other issues found. Want details?
```

**T+51s: User follows up**
```
User: Yes, show me the other issues

[Accountant] Reading aggregated-findings.jsonl...

2. 847 exact duplicate instructions (0.8%) — evenly distributed across shards
3. 12 records with UTF-8 BOM encoding artifacts
4. Format is clean — no malformed JSON

Tool gap: duplicate detection came up 5 times. Writing PRD for dev-team...
```

**T+55s: Accountant writes PRD**
```
[Accountant] Writing docs/prd/2026-06-03-duplicate-detector.md...
[Accountant] Sending PRD to Architect...

SendMessage to: architect

PRD ready for duplicate detection tool. Current workaround: minutemen write custom scripts per-task. Happens 5+ times per data audit.

See: docs/prd/2026-06-03-duplicate-detector.md
```

**T+58s: Cross-team coordination**
```
[Architect] Received PRD. Reviewing...
[Architect] This is straightforward — content-addressing with bloom filter. Will add to next sprint.

SendMessage to: accountant

PRD approved. Implementer will build it this week. ETA 2-3 days.
```

### Result

- **Output files:** `data-team-output/REPORT.md`, aggregated findings, 10 shard reports
- **Cross-team:** PRD sent to dev-team, tool will be built
- **Team state:** Accountant still running, can handle follow-up tasks
- **Memory update:** Accountant writes quality baseline to `.claude/team-memory/data-quality-baseline.md`

### Follow-up Task (Same Session)

```
User: Now profile the token distributions in the non-empty records

[Accountant] New task received. Filtering to non-empty response records...
[Accountant] 77,000 records qualify (77%)
[Accountant] Decision: shard by category (8 shards)
[Accountant] Spawning minuteman-011 for math category...
...
```

**Accountant persists across multiple tasks in the same session.**

---

## Workflow Mode

### Launch Command
```
/data-team mode: workflow, task: Audit train.jsonl for quality issues, maxWorkers: 10
```

### Execution Trace

**T+0s: Launcher**
```
✓ Git repository verified
✓ Output directory created: data-team-output/
✓ Launching workflow: skills/data-team/workflows/data-team.ts
✓ Args: {task: "Audit train.jsonl...", maxWorkers: 10}
```

**T+1s: Workflow Phase 1 (plan)**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: plan
Accountant: Analyzing task and planning sharding strategy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[coordinator] Discovering data location: data/train.jsonl
[coordinator] File size: 2.3GB, ~100K records
[coordinator] Sharding strategy: by-range (10 shards of 10K records)
[coordinator] Writing decomposition.json...
[coordinator] Sharding decision: 10 shards, by-range strategy
```

**T+4s: Workflow Phase 2 (execute)**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: execute
Spawning 10 minutemen for parallel analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[worker-000] Analyzing shard-001: records 0-9999
[worker-001] Analyzing shard-002: records 10000-19999
[worker-002] Analyzing shard-003: records 20000-29999
...
[worker-009] Analyzing shard-010: records 90000-99999
```

**T+47s: Phase 2 complete (all workers done)**
```
[worker-000] ✓ Shard 001 complete: data-team-output/shard-001/
[worker-001] ✓ Shard 002 complete: data-team-output/shard-002/
[worker-002] ✓ Shard 003 complete: data-team-output/shard-003/
...
[worker-009] ✓ Shard 010 complete: data-team-output/shard-010/
```

**T+48s: Workflow Phase 3 (aggregate)**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 3: aggregate
Accountant: Synthesizing findings across all shards
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[coordinator] Reading shard reports...
[coordinator] Parsing findings.jsonl from 10 shards...
[coordinator] Cross-shard pattern: math category has 41% empty vs 8% elsewhere
[coordinator] Deduplicating issues...
[coordinator] Writing aggregated-findings.jsonl...
[coordinator] Writing tool-gaps.md...
[coordinator] Writing aggregation-summary.json...
```

**T+52s: Workflow Phase 4 (report)**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 4: report
Accountant: Writing final report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[coordinator] Reading aggregated findings...
[coordinator] Writing REPORT.md...
[coordinator] Report complete: data-team-output/REPORT.md

Executive Summary:
23% of records have empty response fields. Concentrated in math category.
```

**T+54s: Workflow complete**
```
✓ Workflow complete: data-team-workflow
✓ Output: data-team-output/REPORT.md
✓ Phases: plan → execute → aggregate → report
✓ Duration: 54s
```

### Result

- **Output files:** Same structure as agents mode
- **Cross-team:** Tool gaps listed in `tool-gaps.md`, but NOT sent to dev-team
- **Team state:** No persistent agents, workflow terminated
- **Memory:** No updates to `.claude/team-memory/`

### Follow-up Task (New Workflow)

```
User: Now profile the token distributions in the non-empty records

[Launcher] Launching new workflow...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: plan
...
```

**Each task requires a new workflow invocation. No persistent state.**

---

## Side-by-Side Output Comparison

### data-team-output/REPORT.md

**Both modes produce similar reports:**

```markdown
# Data Analysis Report

23% of records have empty response fields. Concentrated in math category (41% empty vs 8% elsewhere).

## Summary Statistics
- Total records: 100,000
- Records analyzed: 100,000
- Quality issues: 4 types
- Problematic records: 23,847 (23.8%)

## Key Findings
1. **Empty response fields** - 23,000 records (23%), math category at 41%
2. **Duplicate instructions** - 847 exact duplicates (0.8%)
3. **Encoding issues** - 12 records with UTF-8 BOM
4. **Malformed JSON** - 0 records

## Quality Issues
| Issue | Severity | Count | % | Notes |
|-------|----------|-------|---|-------|
| Empty responses | High | 23,000 | 23.0% | Math: 41%, Code: 18%, Other: 8% |
| Duplicates | Medium | 847 | 0.8% | Evenly distributed |
| Encoding | Low | 12 | 0.01% | UTF-8 BOM |

## Patterns
- Math category has 5x higher empty response rate than other categories
- Duplicates are evenly distributed (no single shard outlier)
- Recent records (80K+) have better quality than early records

## Tool Gaps
Duplicate detection flagged by 5/10 workers — see tool-gaps.md for details.

## Methodology
- Sharding strategy: by-range
- Shards analyzed: 10
- Records per shard: ~10,000
```

**Difference:**
- **Agents:** Accountant may add additional context from team memory
- **Workflow:** Purely based on current analysis

### data-team-output/tool-gaps.md

**Agents mode:**
```markdown
# Tool Gaps

## PRD Status
- **duplicate-detector**: PRD sent to Architect on 2026-06-03, approved, ETA 2-3 days

## Priority 1: Blocking
- **Duplicate detection tool** — flagged by 5/10 minutemen
  - Current workaround: custom scripts per-task
  - Impact: 20-30 min overhead per audit
  - PRD: docs/prd/2026-06-03-duplicate-detector.md
```

**Workflow mode:**
```markdown
# Tool Gaps

## Priority 1: Blocking
- **Duplicate detection tool** — flagged by 5/10 workers
  - Current workaround: custom scripts per-task
  - Impact: 20-30 min overhead per audit
  - Recommendation: Build reusable tool with content-addressing
```

**Difference:**
- **Agents:** PRD written and sent to dev-team automatically
- **Workflow:** Listed for manual follow-up

---

## Performance Comparison

| Metric | Agents | Workflow |
|--------|--------|----------|
| **Total time** | 58s (including PRD and cross-team messaging) | 54s (no cross-team coordination) |
| **Startup** | 3s (TeamCreate + spawn Accountant) | 1s (direct to phase 1) |
| **Analysis** | 47s (parallel minutemen) | 47s (parallel workers) |
| **Aggregation** | 5s (Accountant reads + aggregates) | 4s (coordinator reads + aggregates) |
| **Reporting** | 3s (Accountant writes + messages user + writes PRD) | 2s (coordinator writes report only) |

**Analysis phase is identical** — both spawn workers in parallel. Difference is in coordination overhead.

---

## Decision Matrix

| If you need... | Use... |
|----------------|--------|
| One-shot analysis with no follow-up | Workflow |
| Multiple related data tasks in one session | Agents |
| Tool gaps automatically sent to dev-team | Agents |
| Deterministic phases for progress tracking | Workflow |
| Adaptive sharding during execution | Agents |
| Committee participation for cross-team decisions | Agents |
| Team memory updates with quality baselines | Agents |
| Lowest coordination overhead | Workflow |
| Persistent Accountant for follow-up questions | Agents |

**Default recommendation:** Start with agents unless you explicitly need workflow's determinism. Agents are more flexible and can handle follow-up work without relaunching.
