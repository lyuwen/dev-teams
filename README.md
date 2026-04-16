# dev-team

A Claude Code plugin that launches a coordinated 8-agent development team. Give it a requirement, and the team designs, implements, tests, reviews, critiques, documents, and usability-tests the result — with user approval at every major decision point.

## Usage

```
/dev-team <requirement>
```

Example:

```
/dev-team Build a CLI tool that converts datasets between parquet and jsonl formats
```

The Architect will analyze your requirement, present a technical approach for approval, then coordinate the team through the full pipeline.

To understand how the system works without launching anything:

```
/dev-team-help
```

## Agent Roster

| Agent | Color | Tools | Role |
|-------|-------|-------|------|
| **Architect** | cyan | All | Team lead. Designs architecture, decomposes tasks, coordinates all agents, escalates decisions to user. |
| **Implementer** | green | All | Writes feature code on `feat/` worktree branches. |
| **Tester** | yellow | All | Writes and runs tests on `test/` worktree branches in parallel with the Implementer. |
| **Reviewer** | magenta | Read-only + Bash | Quality gatekeeper. Reviews code and tests with structured feedback and severity levels. |
| **Critique** | red | Read-only + Bash | Final gate. Challenges every decision from first principles. Checks plan adherence, simplicity, and UX. Intervenes when the team is stuck in superficial fix loops. |
| **Documenter** | blue | All | Writes user-facing documentation. Docs must be self-sufficient for users with no source code access. |
| **Instructor** | cyan | Read-only + Bash | Designs realistic user tasks, dispatches them to the Noob, diagnoses usability failures, produces UX findings report. |
| **Noob** | yellow | Bash only | Simulates a naive first-time user. Tests software using ONLY documentation, help text, and error messages. Never reads source code. |

## Pipeline

```
User requirement
  -> Architect (design + user approval)
    -> Implementer (feat/ branch) + Tester (test/ branch)  [parallel]
      -> Reviewer (code quality, correctness, test coverage)
        -> Critique (plan adherence, first principles, UX scrutiny)
          -> Documenter (user-facing documentation)
            -> Instructor + Noob (usability testing)
              -> Architect (merge if passes, or route fixes back)
```

The Architect cannot claim completion until every stage passes. If the Reviewer, Critique, or usability testing finds issues, fixes are routed back and the relevant stages re-run.

## Shared Team Memory

All agents share a persistent memory system at `.claude/team-memory/`.

- **`MEMORY.md`** — Index file that every agent reads before starting any task
- **Topic files** — Individual `.md` files for user preferences, design decisions, and past corrections
- **User preferences always override** agent defaults, conventions, and judgment
- Agents update memory when they learn new preferences from the user

This means agents remember your design philosophy, coding preferences, and past corrections across tasks without you repeating yourself.

## Key Design Principles

- **User-in-the-loop**: The Architect presents its approach and waits for approval before assigning work. High-level design choices are escalated to the user.
- **First-principles critique**: The Critique questions every decision back to the user's actual need. Convention and "best practice" are not justification.
- **Usability before completion**: Passing tests is the floor, not the ceiling. The Noob must be able to use the software from documentation alone before the team can ship.
- **No premature completion**: The Critique watches for superficial fix loops and forces the team to step back and redesign when incremental patches aren't working.
- **Memory-driven consistency**: User preferences persist across tasks via the shared memory system. You shouldn't have to explain the same thing twice.

## Project Structure

```
dev-teams/
  .claude/
    agents/
      architect.md
      implementer.md
      tester.md
      reviewer.md
      critique.md
      documenter.md
      instructor.md
      noob.md
    team-memory/
      MEMORY.md
  .claude-plugin/
    plugin.json
  skills/
    dev-team/
      SKILL.md          # Launcher — spawns the team
    dev-team-help/
      SKILL.md          # Explains how the system works
  tests/
    validate_usability_agents.sh
```
