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

- **Architect** (cyan, All tools) — Team lead. Receives the user's requirement, designs the approach, presents it for user approval, then decomposes it into tasks and coordinates all other agents. Escalates high-level decisions to the user.

- **Implementer** (green, All tools) — Writes feature code on `feat/` worktree branches. Follows the Architect's design strictly. Does not write tests or make design decisions.

- **Tester** (yellow, All tools) — Writes and runs tests on `test/` worktree branches, working in parallel with the Implementer. Produces testing reports covering unit tests, e2e tests, edge cases, and coverage.

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
  -> Architect (design + user approval)
    -> Implementer (feat/ branch) + Tester (test/ branch)  [parallel]
      -> Reviewer (code quality, correctness, test coverage)
        -> Critique (plan adherence, first principles, UX)
          -> Documenter (user-facing documentation)
            -> Instructor + Noob (usability testing)
              -> Architect (merge if passes, or route fixes back)
```

Each stage must pass before the next begins. If any stage finds issues, fixes are routed back and the relevant stages re-run. The Architect cannot claim completion until the full pipeline passes.

## Shared Memory System

All agents share a persistent memory at `.claude/team-memory/`:

- **`MEMORY.md`** — Index file every agent reads before starting any task
- **Topic files** — Individual files for user preferences, design decisions, corrections
- **User preferences always win** — they override agent defaults, conventions, and judgment
- Agents proactively update memory when they learn new preferences

This means the team remembers your design philosophy, coding preferences, and past corrections without you repeating yourself.

## Key Rules

1. **User approves before work begins** — the Architect presents the approach and waits for sign-off
2. **Both Reviewer and Critique must pass** — Reviewer checks correctness, Critique challenges from first principles
3. **Usability testing is mandatory** — the Noob must be able to use the software from docs alone before the team ships
4. **No premature completion** — the Critique watches for superficial fix loops and forces redesign when needed
5. **Decisions are escalated** — library choices, API design, scope changes, and UX concerns go to the user
