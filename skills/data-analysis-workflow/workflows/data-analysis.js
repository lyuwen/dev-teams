export const meta = {
  name: "data-analysis",
  description: "Parallel data analysis workflow: coordinator analyzes task, spawns workers for shards, aggregates results",
  phases: ["decompose", "analyze", "aggregate"]
};

/**
 * Data Analysis Workflow
 *
 * Converts the Accountant + minutemen agent structure into a dynamic workflow.
 *
 * Input args shape:
 * {
 *   task: string,              // The data analysis task
 *   dataPath: string,          // Optional: path to data (can be discovered)
 *   shardingStrategy: string,  // Optional: how to shard ("auto", "by-file", "by-range", "by-category")
 *   maxWorkers: number         // Optional: cap on parallel workers (default: 10)
 * }
 */

// Phase 1: Decompose the task
phase("decompose", "Task decomposition and sharding strategy");

const decomposition = await agent({
  prompt: `You are the data analysis coordinator. Analyze this task and decide the sharding strategy.

Task: ${args.task}
Data path: ${args.dataPath || "to be discovered"}
Sharding strategy preference: ${args.shardingStrategy || "auto"}

Your job:
1. Understand the data analysis task
2. Discover or verify the data location
3. Analyze the data structure (files, size, format)
4. Decide optimal sharding strategy:
   - by-file: one worker per file
   - by-range: split large files into record ranges
   - by-category: shard by data field (e.g., category, type)
   - by-sample: random sample shards for quick profiling
5. Determine shard count (respect maxWorkers: ${args.maxWorkers || 10})

Output a JSON object with this structure:
{
  "strategy": "by-file" | "by-range" | "by-category" | "by-sample",
  "shardCount": number,
  "shards": [
    {
      "id": "shard-001",
      "scope": "description of what this shard covers",
      "files": ["file paths"],
      "recordRange": "0-10000" (if applicable),
      "category": "category name" (if applicable)
    }
  ],
  "objectives": ["what to look for in the data"],
  "outputDir": "data-team-output"
}

Write the JSON to decomposition.json and report the sharding decision.`,
  opts: {
    subagent_type: "claude"
  }
});

const decompositionData = JSON.parse(await readFile("decomposition.json"));

// Phase 2: Parallel shard analysis
phase("analyze", `Analyzing ${decompositionData.shardCount} shards in parallel`);

const workerResults = await parallel(
  decompositionData.shards.map((shard, idx) =>
    agent({
      prompt: `You are a data analysis worker. Analyze your assigned shard.

Shard ID: ${shard.id}
Scope: ${shard.scope}
Files: ${shard.files?.join(", ") || "N/A"}
Record range: ${shard.recordRange || "all"}
Category filter: ${shard.category || "none"}

Objectives:
${decompositionData.objectives.map((obj) => `- ${obj}`).join("\n")}

Process:
1. Read the data in your shard scope
2. Write analysis scripts as needed (Python/bash/etc)
3. Find characteristics, patterns, issues, flaws, inconsistencies
4. Generate statistics, distributions, quality metrics

Output to: ${decompositionData.outputDir}/${shard.id}/

Required files:
- report.md: human-readable analysis report with key findings
- findings.jsonl: machine-readable findings for aggregation
- summary.json: brief top-level stats and top 3 findings

Include in findings.jsonl:
- Quality issues (empty fields, malformed data, encoding problems)
- Statistical patterns (distributions, outliers, clusters)
- Consistency problems (duplicates, contradictions)
- Tool gaps (if you wrote a custom script that should be a proper tool)

Be thorough but focused on your shard. The coordinator will aggregate across all shards.`,
      opts: {
        subagent_type: "claude",
        name: `worker-${idx.toString().padStart(3, "0")}`
      }
    })
  )
);

// Phase 3: Aggregate results
phase("aggregate", "Aggregating findings across all shards");

const report = await agent({
  prompt: `You are the data analysis coordinator. Aggregate findings from all shard workers.

Task: ${args.task}
Sharding strategy: ${decompositionData.strategy}
Shards analyzed: ${decompositionData.shardCount}

Output directory: ${decompositionData.outputDir}

Your job:
1. Read all shard reports from ${decompositionData.outputDir}/shard-*/
2. Parse findings.jsonl from each shard
3. Identify cross-shard patterns that no single worker could see
4. Deduplicate issues that appear in multiple shards
5. Prioritize findings by severity and impact
6. Synthesize into a concise executive report

Communication style:
- Lead with the single most important finding
- Use numbers over narrative ("23% empty fields" not "significant portion")
- Be terse - don't elaborate unless asked
- Know what matters most at all times

Output files:
1. ${decompositionData.outputDir}/REPORT.md - executive summary for the user
2. ${decompositionData.outputDir}/aggregated-findings.jsonl - all findings with cross-shard context
3. ${decompositionData.outputDir}/tool-gaps.md - deduplicated list of missing tools (if any)

Format for REPORT.md:
\`\`\`markdown
# Data Analysis Report

[Single most important finding - lead with this, no preamble]

## Summary Statistics
[High-level numbers across all shards]

## Key Findings
1. [Most important - already stated above]
2. [Second most important]
3. [Third most important]

## Quality Issues
[Prioritized list with severity, count, percentage]

## Patterns
[Notable cross-shard patterns]

## Tool Gaps
[Missing tools that would improve future analysis - if any]

## Methodology
Sharding strategy: ${decompositionData.strategy}
Shards analyzed: ${decompositionData.shardCount}
[Any relevant context about the analysis approach]
\`\`\`

After writing the report, print the executive summary (just the top finding and summary stats) to stdout.`,
  opts: {
    subagent_type: "claude"
  }
});

// Helper function to read files
async function readFile(path) {
  // Workflow runtime provides file I/O primitives
  return ""; // Placeholder - actual implementation uses workflow runtime
}
