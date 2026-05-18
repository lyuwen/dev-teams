---
name: dev-team-help
description: |
  Explain how the dev-team system works. Use this when the user asks questions like "how does the dev team work?", "explain the agents", "what agents are available?", "how does the pipeline work?", "how do I use the dev team?", "what does the critique do?", "how does the memory system work?", or any question about the dev-team plugin's architecture, agents, or workflow. This skill does NOT launch agents — it just explains.
---

# Dev Team — How It Works

The user is asking about the dev-team system. Explain the following clearly and concisely. Do NOT launch any agents, create any teams, or run any commands. Just explain.

## What It Is

The dev-team is a coordinated 8-agent development team. You give it a requirement, and it designs, implements, tests, reviews, critiques, documents, and usability-tests the result. The user stays in the loop at every major decision point.

Launch it with: `/dev-team <your requirement>`

## The 8 Agents

### Build Phase

- **Architect** (cyan, All tools) — Team lead. Receives the user's requirement, designs the approach, presents it for user approval, then decomposes it into tasks and coordinates all other agents. **Owns the entire branch lifecycle**: creates a `dev/<feature>` delivery branch, creates worker branches (`feat/`, `test/`) for agents, merges them after approval, and delivers a single PR-ready branch. Escalates high-level decisions to the user.

- **Implementer** (green, All tools) — Writes feature code on branches assigned by the Architect. Never creates branches itself. Follows the Architect's design strictly. Does not write tests or make design decisions.

- **Tester** (yellow, All tools) — Writes and runs tests on branches assigned by the Architect. Never creates branches itself. Works in parallel with the Implementer. Produces testing reports covering unit tests, e2e tests, edge cases, and coverage.

### Review Phase

- **Reviewer** (magenta, Read-only + Bash) — Quality gatekeeper. Reviews both the Implementer's code and the Tester's tests. Provides structured feedback with severity levels: blockers (must fix) vs. suggestions (nice to have). Cannot edit code — only provides feedback.

- **Critique** (red, Read-only + Bash) — The harshest judge. Runs after the Reviewer approves. Challenges every design decision from first principles ("why this, and not something simpler?"). Checks plan adherence, scrutinizes UX from the user's perspective, and flags unnecessary complexity. Has a special intervention protocol to break superficial fix loops — when the team keeps making shallow edits without solving the root problem, the Critique halts work and forces a redesign.

### Usability Phase

- **Documenter** (blue, All tools) — Writes all user-facing documentation after the Critique approves. The standard: documentation must be sufficient for someone with no source code access to use the software successfully.

- **Instructor** (cyan, Read-only + Bash) — Codebase expert who designs realistic user tasks (basic to advanced), dispatches them one at a time to the Noob, observes the results, diagnoses root causes of usability failures, and produces a prioritized UX findings report.

- **Noob** (yellow, Bash only) — Simulates a naive first-time user with zero codebase knowledge and limited coding ability. Attempts tasks using ONLY documentation, help text, and error messages. Never reads source code. Reports exactly what was tried, what was expected, what happened, and where confusion occurred.

## The Pipeline

```
User requirement
  -> Architect (design + branching strategy + user approval)
    -> Architect creates dev/<feature> delivery branch + worker branches
      -> Implementer (feat/ branch) + Tester (test/ branch)  [parallel]
        -> Reviewer (code quality, correctness, test coverage)
          -> Critique (plan adherence, first principles, UX)
            -> Architect merges worker branches into dev/<feature>
              -> Documenter (user-facing documentation on dev/<feature>)
                -> Instructor + Noob (usability testing)
                  -> Architect (finalizes dev/<feature>, cleans up worker branches)
```

Each stage must pass before the next begins. If any stage finds issues, fixes are routed back and the relevant stages re-run. The Architect cannot claim completion until the full pipeline passes and `dev/<feature>` is ready to PR into main.

## Branch Management

The Architect is the **sole owner** of all branches. No other agent creates, merges, or deletes branches.

- **`dev/<feature>`** — The delivery branch. Created by the Architect from main. This is where all work is aggregated and is the final PR target.
- **`feat/<feature>`** — Worker branch for the Implementer. Created by the Architect from `dev/<feature>`.
- **`test/<feature>`** — Worker branch for the Tester. Created by the Architect from `dev/<feature>`.

After Reviewer + Critique approve, the Architect merges `feat/` and `test/` into `dev/<feature>`, runs tests on the merged branch, then proceeds to documentation and usability testing. At the end, worker branches are cleaned up and only `dev/<feature>` remains as the deliverable.

## Shared Memory System

All agents share a persistent memory at `.claude/team-memory/`:

- **`MEMORY.md`** — Index file every agent reads before starting any task
- **Topic files** — Individual files for user preferences, design decisions, corrections
- **User preferences always win** — they override agent defaults, conventions, and judgment
- The Architect proactively indexes reusable preferences and decisions; other agents create topic files and notify the Architect to add index entries
- Dev-team launches use a project-scoped runtime team so shared memory stays attached to the current repository

This means the team remembers your design philosophy, coding preferences, and past corrections without you repeating yourself.

## Key Rules

1. **User approves before work begins** — the Architect presents the approach (including branching strategy) and waits for sign-off
2. **Architect owns all branches** — creates `dev/<feature>` delivery branch, worker branches, merges, and cleanup. Sub-agents never create branches.
3. **Single deliverable** — the final output is always one `dev/<feature>` branch ready to PR into main
4. **Both Reviewer and Critique must pass** — Reviewer checks correctness, Critique challenges from first principles
5. **Usability testing is mandatory** — the Noob must be able to use the software from docs alone before the team ships
6. **No premature completion** — the Critique watches for superficial fix loops and forces redesign when needed
7. **Decisions are escalated** — library choices, API design, scope changes, and UX concerns go to the user
