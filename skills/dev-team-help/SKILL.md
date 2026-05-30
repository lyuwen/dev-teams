---
name: dev-team-help
description: |
  Explain how the dev-team system works. Use this when the user asks questions like "how does the dev team work?", "explain the agents", "what agents are available?", "how does the pipeline work?", "how do I use the dev team?", "what does the critique do?", "how does the memory system work?", or any question about the dev-team plugin's architecture, agents, or workflow. This skill does NOT launch agents — it just explains.
---

# Dev Team — How It Works

The user is asking about the dev-team system. Explain the following clearly and concisely. Do NOT launch any agents, create any teams, or run any commands. Just explain.

## What It Is

The dev-team is a coordinated team of 7 peer agents (Architect, Implementer, Tester, Reviewer, Critique, Documenter, Instructor) launched at startup, plus a Noob subagent that the Instructor spawns on demand for each usability task. You give it a requirement, and it designs, implements, tests, reviews, critiques, documents, and usability-tests the result. The user stays in the loop at every major decision point.

Launch it with: `/dev-team <your requirement>`

## The Agents

### Build Phase

- **Architect** (cyan, All tools) — Team lead. Receives the user's requirement, designs the approach, presents it for user approval, then decomposes it into tasks and coordinates all other agents. **Owns the entire branch lifecycle**: creates a `dev/<feature>` delivery branch, creates worker branches (`feat/`, `test/`) for agents, merges them after approval, and delivers a single PR-ready branch. Escalates high-level decisions to the user.

- **Implementer** (green, All tools) — Writes feature code on branches assigned by the Architect. Never creates branches itself. Follows the Architect's design strictly. Does not write tests or make design decisions.

- **Tester** (yellow, All tools) — Writes and runs tests on branches assigned by the Architect. Never creates branches itself. Works in parallel with the Implementer. Produces testing reports covering unit tests, e2e tests, edge cases, and coverage.

### Review Phase

- **Reviewer** (magenta, Read-only + Bash) — Quality gatekeeper. Reviews both the Implementer's code and the Tester's tests. Provides structured feedback with severity levels: blockers (must fix) vs. suggestions (nice to have). Cannot edit code — only provides feedback. Writes its review to `.claude/reviews/<feature>.md`.

- **Critique** (red, Read-only + Bash) — The harshest judge. Runs after the Reviewer approves (and can also be invoked earlier on the plan itself — see Plan Validation Mode below). Challenges every design decision from first principles ("why this, and not something simpler?"). Checks plan adherence, scrutinizes UX from the user's perspective, and flags unnecessary complexity. Has a special intervention protocol to break superficial fix loops — when the team keeps making shallow edits without solving the root problem, the Critique halts work and forces a redesign. Writes its critique to `.claude/critiques/<feature>.md`.

### Usability Phase

- **Documenter** (blue, All tools) — Writes all user-facing documentation after the Critique approves. The standard: documentation must be sufficient for someone with no source code access to use the software successfully.

- **Instructor** (purple, Read-only + Bash) — Codebase expert who designs realistic user tasks (basic to advanced), spawns a fresh Noob subagent (via the Task tool) for each one, reads the returned report, diagnoses root causes of usability failures, and produces a prioritized UX findings report at `.claude/ux-findings/<feature>.md`.

- **Noob** (orange, Bash only) — Subagent of the Instructor, not a peer teammate. Spawned on demand for each usability task and terminates after returning its report. Simulates a naive first-time user with zero codebase knowledge and limited coding ability. Attempts tasks using ONLY documentation, help text, and error messages. Never reads source code. Each invocation starts with a fresh context, so the Noob is authentically naive every time.

## Plan Validation Mode (Optional)

The Critique normally runs after implementation, but it can also be invoked earlier on the Architect's **plan** before any code exists. Use this when the requirement is risky or expensive to redo — the Critique applies the same first-principles methodology to the plan itself, surfaces bad assumptions before they become bad code, and writes its verdict to `.claude/critiques/<feature>-plan.md`. The Architect decides when to use this; it is not part of the default pipeline.

## Artifact Locations

Each non-lead agent writes a durable artifact to a standardized location, so the Architect can recover from a missed completion message and you can inspect what each agent produced:

| Agent | Artifact |
|-------|----------|
| Tester | `.claude/test-reports/<feature>.md` (plus committed test code) |
| Reviewer | `.claude/reviews/<feature>.md` |
| Critique | `.claude/critiques/<feature>.md` (or `<feature>-plan.md` in Plan Validation Mode) |
| Instructor | `.claude/ux-findings/<feature>.md` |
| Implementer, Documenter | Commits on the assigned branch (no separate artifact file) |

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
                -> Instructor (spawns Noob subagent per task; usability testing)
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
