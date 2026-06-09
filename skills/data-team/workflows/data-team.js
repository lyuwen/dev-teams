export const meta = {
  name: "data-team-workflow",
  description: "Data team workflow: Accountant coordinates, spawns minutemen for parallel analysis, aggregates findings",
  phases: ["plan", "execute", "aggregate", "report"]
};

/**
 * Data Team Workflow
 *
 * Converts the Accountant + minutemen agent structure into a deterministic workflow.
 *
 * This workflow mirrors the agent-based data-team structure:
 * - Phase 1 (plan): Accountant analyzes the task and decides sharding strategy
 * - Phase 2 (execute): Minutemen analyze shards in parallel
 * - Phase 3 (aggregate): Accountant synthesizes findings across shards
 * - Phase 4 (report): Accountant writes final report and identifies tool gaps
 *
 * Input args shape:
 * {
 *   task: string,              // The data task from the user
 *   dataPath: string,          // Optional: path to data (can be discovered)
 *   shardingStrategy: string,  // Optional: "auto", "by-file", "by-range", "by-category", "by-sample"
 *   maxWorkers: number         // Optional: cap on parallel workers (default: 10)
 * }
 */

// Phase 1: Accountant plans the work
phase("plan", "Accountant: Analyzing task and planning sharding strategy");

const decomposition = await agent({
  prompt: `You are the **Accountant** — the data team lead. Analyze this task and decide how to shard it for parallel execution.

**Task:** ${args.task}
**Data path:** ${args.dataPath || "to be discovered"}
**Sharding preference:** ${args.shardingStrategy || "auto"}
**Max workers:** ${args.maxWorkers || 10}

## Your Job

1. **Understand the task** — what kind of analysis is needed?
2. **Discover/verify data location** — find the files if path not provided
3. **Analyze data structure** — check format, size, schema, natural partitions
4. **Decide sharding strategy:**
   - **by-file**: one minuteman per file (good for multi-file datasets)
   - **by-range**: split large files into record ranges (good for single large files)
   - **by-category**: shard by data field value (good for categorical data)
   - **by-sample**: random sample shards (good for quick profiling)
5. **Determine shard count** — balance parallelism vs overhead (respect maxWorkers cap)
6. **Define objectives** — what should minutemen look for in the data?

## Output

Write a JSON file to \`data-team-output/decomposition.json\` with this structure:

\`\`\`json
{
  "strategy": "by-file" | "by-range" | "by-category" | "by-sample",
  "shardCount": <number>,
  "shards": [
    {
      "id": "shard-001",
      "scope": "description of what this shard covers",
      "files": ["file paths"] or null,
      "recordRange": "0-10000" or null,
      "category": "category name" or null,
      "sampleSize": <number> or null
    }
  ],
  "objectives": [
    "what minutemen should look for in the data"
  ],
  "outputDir": "data-team-output",
  "taskSummary": "brief description of the overall task"
}
\`\`\`

## Communication Style

You report to an impatient user who expects:
- Lead with the single most important finding (not in this phase, but remember for later)
- No filler or preamble
- Numbers over narrative
- Brief and focused

After writing the JSON, report your sharding decision: strategy chosen, shard count, rationale.`,
  opts: {
    subagent_type: "claude",
    description: "Accountant planning phase"
  }
});

// Load the decomposition plan
const decompositionData = JSON.parse(await readFile("data-team-output/decomposition.json"));

// Phase 2: Minutemen execute parallel analysis
phase("execute", `Spawning ${decompositionData.shardCount} minutemen for parallel analysis`);

const workerResults = await parallel(
  decompositionData.shards.map((shard, idx) =>
    agent({
      prompt: `You are a **Minuteman** — a data analysis worker on the data team.

**Assignment:**
- Shard ID: ${shard.id}
- Scope: ${shard.scope}
- Files: ${shard.files?.join(", ") || "N/A"}
- Record range: ${shard.recordRange || "all"}
- Category filter: ${shard.category || "none"}
- Sample size: ${shard.sampleSize || "N/A"}

**Objectives:**
${decompositionData.objectives.map((obj) => `- ${obj}`).join("\n")}

**Overall task:** ${decompositionData.taskSummary}

## Your Job

1. **Read your assigned data shard** — stay within your scope
2. **Write ad-hoc analysis scripts** as needed (Python, bash, whatever works)
3. **Find everything worth finding:**
   - Characteristics, distributions, statistics
   - Quality issues (empty fields, malformed data, encoding problems)
   - Consistency problems (duplicates, contradictions)
   - Patterns, anomalies, outliers
   - Format inconsistencies
4. **Flag tool gaps** — if you write a custom script that should be a proper tool, note it

## Output Requirements

Write to: \`${decompositionData.outputDir}/${shard.id}/\`

**Required files:**

1. **report.md** — Human-readable analysis with structure:
   \`\`\`markdown
   # Shard Analysis Report

   ## Scope
   [What data was analyzed]

   ## Key Findings
   1. [Most important — with numbers]
   2. [Second most important]
   3. [...]

   ## Statistics
   [Distributions, counts, percentages]

   ## Quality Issues
   [Problems found, with severity]

   ## Patterns
   [Notable patterns or anomalies]

   ## Tool Gaps
   [Scripts that should be proper tools]
   \`\`\`

2. **findings.jsonl** — Machine-readable findings for aggregation:
   \`\`\`jsonl
   {"type": "quality_issue", "severity": "high", "field": "response", "description": "Empty response", "count": 234, "percentage": 2.34}
   {"type": "pattern", "description": "Math category has 5x higher empty rate", "evidence": {...}}
   \`\`\`

3. **summary.json** — Top-level stats:
   \`\`\`json
   {
     "shardId": "${shard.id}",
     "recordsAnalyzed": <number>,
     "topFindings": ["finding 1", "finding 2", "finding 3"],
     "toolGaps": ["gap 1", "gap 2"] or []
   }
   \`\`\`

## Format Handling

Be format-agnostic. Use whatever tools work:
- JSONL: jq, python json module
- Parquet: pandas, pyarrow
- CSV: pandas, csvkit, awk
- HuggingFace datasets: datasets library

Write ad-hoc scripts as needed. Flag recurring patterns as tool gaps.`,
      opts: {
        subagent_type: "claude",
        name: `minuteman-${idx.toString().padStart(3, "0")}`,
        description: `Minuteman analyzing ${shard.scope}`
      }
    })
  )
);

// Phase 3: Accountant aggregates findings
phase("aggregate", "Accountant: Synthesizing findings across all shards");

const aggregation = await agent({
  prompt: `You are the **Accountant** — the data team lead. All minutemen have completed their shard analysis. Now aggregate their findings.

**Task:** ${args.task}
**Sharding strategy:** ${decompositionData.strategy}
**Shards analyzed:** ${decompositionData.shardCount}
**Output directory:** ${decompositionData.outputDir}

## Your Job

1. **Read all minuteman reports** from \`${decompositionData.outputDir}/shard-*/\`
2. **Parse findings.jsonl** from each shard
3. **Identify cross-shard patterns** that no single minuteman could see:
   - Issues that appear across multiple shards
   - Trends across the data partitions
   - Category-specific patterns
   - Distributional insights
4. **Deduplicate findings** — many shards may report the same issue type
5. **Prioritize by severity and impact**
6. **Collect tool gaps** — if 3+ minutemen flag the same ad-hoc workaround, it's a tool gap

## Output Requirements

Write these files:

1. **\`${decompositionData.outputDir}/aggregated-findings.jsonl\`**
   All findings with cross-shard context added:
   \`\`\`jsonl
   {"type": "quality_issue", "severity": "high", "description": "Empty response fields", "totalCount": 23000, "percentage": 23.0, "shardBreakdown": {"shard-001": 2300, "shard-002": 2150, ...}, "pattern": "Concentrated in math category"}
   \`\`\`

2. **\`${decompositionData.outputDir}/tool-gaps.md\`**
   Deduplicated list of missing tools (if any):
   \`\`\`markdown
   # Tool Gaps

   ## Priority 1: Blocking
   [Tools that minutemen repeatedly work around]

   ## Priority 2: Important
   [Tools that would significantly improve efficiency]

   ## Priority 3: Nice-to-have
   [Tools that would be convenient]
   \`\`\`

3. **\`${decompositionData.outputDir}/aggregation-summary.json\`**
   High-level aggregated stats:
   \`\`\`json
   {
     "totalRecordsAnalyzed": <number>,
     "shardsAnalyzed": <number>,
     "topCrossSh ardFindings": ["finding 1", "finding 2", "finding 3"],
     "toolGapCount": <number>
   }
   \`\`\`

After writing these files, output a JSON summary to stdout with the structure:
\`\`\`json
{
  "aggregationComplete": true,
  "topFinding": "single most important finding with numbers",
  "findingCount": <number>,
  "toolGapCount": <number>
}
\`\`\``,
  opts: {
    subagent_type: "claude",
    description: "Accountant aggregating findings"
  }
});

// Phase 4: Accountant writes final report
phase("report", "Accountant: Writing final report");

const finalReport = await agent({
  prompt: `You are the **Accountant** — the data team lead. Write the final report for the user.

**Task:** ${args.task}
**Shards analyzed:** ${decompositionData.shardCount}
**Output directory:** ${decompositionData.outputDir}

## Your Job

Read your aggregated findings and write the executive summary that the user will read first.

## Communication Style

The user is an impatient boss. They want:
- **Lead with the single most important finding** — no preamble, no setup, just the #1 thing they need to know
- **Numbers over narrative** — "23% empty fields" not "significant quality issues"
- **No filler** — don't say "I analyzed" or "I found several issues", just state the finding
- **Brief and focused** — don't elaborate unless asked

## Output

Write **\`${decompositionData.outputDir}/REPORT.md\`**:

\`\`\`markdown
# Data Analysis Report

[Single most important finding — lead with this, no preamble]

## Summary Statistics
[High-level numbers across all shards]

## Key Findings
1. [Most important — already stated above]
2. [Second most important]
3. [Third most important]

## Quality Issues
[Table with severity, count, percentage, notes]

| Issue | Severity | Count | % | Notes |
|-------|----------|-------|---|-------|
| ... | ... | ... | ... | ... |

## Patterns
[Notable cross-shard patterns that wouldn't be visible in a single shard]

## Tool Gaps
[If any — brief summary, point to tool-gaps.md for details]

## Methodology
- Sharding strategy: ${decompositionData.strategy}
- Shards analyzed: ${decompositionData.shardCount}
- [Any relevant context about the approach]
\`\`\`

After writing REPORT.md, output a brief message to stdout summarizing the top finding and pointing to the report file.`,
  opts: {
    subagent_type: "claude",
    description: "Accountant writing final report"
  }
});

/**
 * Helper function to read files (provided by workflow runtime)
 */
async function readFile(path) {
  // Workflow runtime provides file I/O
  return "";
}
