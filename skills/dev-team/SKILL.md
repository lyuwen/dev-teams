---
name: dev-team
description: |
  Launch a coordinated development team with Architect, Implementer, Tester, Reviewer, Critique, Documenter, Instructor, and Noob agents. This skill should be used whenever the user wants to build a feature, start a project, implement something substantial, or delegate development work to a team of agents. Trigger this when the user says things like "launch the dev team", "spin up the team", "build this with the team", "use the dev team to...", "have the team implement...", or describes a development task and wants coordinated agents to handle it — even if they don't explicitly say "team" or "agents". If the user describes a multi-step development task (building a CLI tool, adding a module, creating a library), this skill is likely what they need. The argument is the requirement to pass to the Architect.
---

# Dev Team Launcher

Launch a coordinated 8-agent development team and hand off the user's requirement to the Architect.

The user's requirement is the argument passed to this skill. If no argument was provided, ask what they want the team to build before proceeding.

## Team Composition

| Agent | Role | Tools |
|-------|------|-------|
| **Architect** (team lead) | Designs architecture, decomposes tasks, coordinates agents, escalates design decisions to user | All |
| **Implementer** | Writes feature code on `feat/` worktree branches | All |
| **Tester** | Writes & runs tests on `test/` worktree branches, produces test reports | All |
| **Reviewer** | Reviews code & tests, provides structured feedback with severity levels | Read, Grep, Glob, Bash |
| **Critique** | Final gate — plan adherence, first-principles challenge, UX scrutiny | Read, Grep, Glob, Bash |
| **Documenter** | Writes/maintains user-facing documentation after implementation; docs must be self-sufficient for users with no source code | All |
| **Instructor** | Designs realistic user tasks, dispatches to Noob, diagnoses usability failures, produces UX report | Read, Grep, Glob, Bash |
| **Noob** | Simulates naive first-time user — tests software using ONLY docs, help text, and error messages (no source code) | Bash |

## Launch Sequence

### Step 1: Verify git

The team uses worktree branches for isolation, so the project needs a git repository. Run `git rev-parse --git-dir` to check. If there's no git repo, tell the user and offer to initialize one.

### Step 2: Create the team

Derive a **project-scoped** team name for the current repository and reuse it for the entire launch flow.

- Start with a readable base like `dev-team-<repo-basename>`
- If a team with that name already exists and points at the current repository, reuse it
- If it exists but points at a different repository/session, derive a suffixed variant and use that instead
- Use this same team name for `TeamCreate`, the Architect spawn, every teammate spawn, retries, and user-facing status updates

Use `TeamCreate` with that project-scoped team name. This creates the shared task list that all agents coordinate through.

### Step 3: Initialize team memory

Check if `.claude/team-memory/MEMORY.md` exists. If not, create the directory and seed file:

```
mkdir -p .claude/team-memory
```

Then create `.claude/team-memory/MEMORY.md` with the seed content:

```markdown
# Dev Team Shared Memory

All agents: read this file at the start of every task. User preferences here ALWAYS override defaults, conventions, and your own judgment.

Read individual memory files for details. Update this index and create new memory files when you learn new preferences.

<!-- Keep this index under 200 lines. Prune stale entries. -->
```

This ensures the memory directory exists before agents start reading it.

### Step 4: Create the initial requirement task

Use TaskCreate to capture the user's requirement as the first task on the shared task list. This is what the Architect picks up and decomposes.

### Step 5: Spawn the Architect

Spawn the Architect as a teammate using the Agent tool with the derived `team_name` and `name: "architect"`. Use the `architect` subagent_type.

Include in the prompt:
- The user's full requirement (verbatim)
- That seven teammates are available: `implementer`, `tester`, `reviewer`, `critique`, `documenter`, `instructor`, `noob`
- The workflow: Implementer and Tester work in parallel on separate worktree branches (`feat/` and `test/`), then Reviewer reviews both, then Critique does a final deep-dive, then Documenter writes docs, then Instructor+Noob run usability testing
- That high-level design decisions must be escalated to the user — present the technical approach before assigning work
- That BOTH the Reviewer and Critique must pass before proceeding to usability testing — Reviewer approval alone is not sufficient
- The derived `team_name` so the Architect can read the team config
- That the Architect should read `.claude/team-memory/MEMORY.md` before analyzing the requirement
- That the Architect must proactively update/index team memory when the user confirms preferences, decisions, or corrections

### Step 6: Spawn the remaining agents

Spawn all seven in parallel using the Agent tool, each with the derived `team_name`:

**Implementer** — `name: "implementer"`, subagent_type `implementer`
- Tell it the Architect is the team lead and will assign tasks
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It should check the task list for work and wait for assignment

**Tester** — `name: "tester"`, subagent_type `tester`
- Tell it the Architect is the team lead and will assign tasks
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It should check the task list for work and wait for assignment

**Reviewer** — `name: "reviewer"`, subagent_type `reviewer`
- Tell it the Architect is the team lead and will assign review tasks
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It should check the task list for work and wait for assignment

**Critique** — `name: "critique"`, subagent_type `critique`
- Tell it the Architect assigns critique tasks after Reviewer approval
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It is the final gate before usability testing begins

**Documenter** — `name: "documenter"`, subagent_type `documenter`
- Tell it the Architect assigns documentation tasks after implementation passes review
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It writes user-facing docs on the feat/ branch

**Instructor** — `name: "instructor"`, subagent_type `instructor`
- Tell it the Architect assigns usability testing tasks after Documenter finishes
- It should read `.claude/team-memory/MEMORY.md` at the start of each task
- It should create or update a focused memory topic file when it learns a reusable preference, correction, or decision, then message the Architect to index it
- It designs user tasks and dispatches them to the Noob

**Noob** — `name: "noob"`, subagent_type `noob`
- Tell it the Instructor will send tasks
- It should read `.claude/team-memory/MEMORY.md` before each task using Bash-only tools
- It should report reusable preference/correction findings back through the Instructor so the Architect can index them
- It works in an isolated temp directory, using only Bash
- It must never read source code

### Step 6a: Verify spawns and retry failures

After all spawn calls return, check the results. If any agent failed to spawn (400 error, timeout, or other failure):

1. **Retry** the failed spawn up to 2 more times
2. **If still failing**, tell the user which agent(s) could not be spawned and ask whether to:
   - Continue with a partial team (some agents are non-critical for early stages)
   - Retry all failed agents
   - Abort and investigate

Do NOT proceed to Step 7 until the Architect and at least the core build agents (Implementer, Tester, Reviewer) are confirmed alive. The usability agents (Documenter, Instructor, Noob) can be spawned later when needed if they fail at launch.

### Step 7: Report to user

Tell the user:
- The dev team is up and running (list which agents are alive)
- Which project-scoped team name is active for this repository
- If any agents failed to spawn, report which ones and what happened
- The Architect is analyzing their requirement and will present a technical approach for approval
- They'll be consulted on high-level design decisions before implementation begins
- They can message any agent by name if needed

## Workflow

```
User requirement
  → Architect (decomposes, designs, presents approach for user approval)
    → parallel: Implementer (feat/ branch) + Tester (test/ branch)
      → Reviewer (reviews code + tests, structured feedback)
        → Critique (plan adherence, first-principles challenge, UX scrutiny)
          → Documenter (writes/updates user-facing documentation)
            → Instructor + Noob (usability testing — Instructor dispatches tasks, Noob attempts them)
              → Architect (merges if usability passes, or routes findings for fixes)
```

## Key Rules

- The Architect presents its technical approach to the user BEFORE assigning work — the user approves first
- High-level design choices (library selection, API design, data formats) are escalated to the user
- The Reviewer provides structured feedback with severity levels: blockers (must fix) vs. suggestions (nice to have)
- If Reviewer requests changes, Architect routes feedback to the right agent, waits for fixes, then triggers re-review
- After Reviewer and Critique both approve, the Architect triggers the usability testing phase: Documenter writes docs, then Instructor+Noob test usability
- The Architect cannot claim final completion until usability testing passes
- After usability testing passes, Architect merges branches and reports completion
