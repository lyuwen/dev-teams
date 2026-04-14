---
name: dev-team
description: |
  Launch a coordinated development team with Architect, Implementer, Tester, and Reviewer agents. This skill should be used whenever the user wants to build a feature, start a project, implement something substantial, or delegate development work to a team of agents. Trigger this when the user says things like "launch the dev team", "spin up the team", "build this with the team", "use the dev team to...", "have the team implement...", or describes a development task and wants coordinated agents to handle it — even if they don't explicitly say "team" or "agents". If the user describes a multi-step development task (building a CLI tool, adding a module, creating a library), this skill is likely what they need. The argument is the requirement to pass to the Architect.
---

# Dev Team Launcher

Launch a coordinated 4-agent development team and hand off the user's requirement to the Architect.

The user's requirement is the argument passed to this skill. If no argument was provided, ask what they want the team to build before proceeding.

## Team Composition

| Agent | Role | Tools |
|-------|------|-------|
| **Architect** (team lead) | Designs architecture, decomposes tasks, coordinates agents, escalates design decisions to user | All |
| **Implementer** | Writes feature code on `feat/` worktree branches | All |
| **Tester** | Writes & runs tests on `test/` worktree branches, produces test reports | All |
| **Reviewer** | Reviews code & tests, provides structured feedback with severity levels | Read, Grep, Glob, Bash |

## Launch Sequence

### Step 1: Verify git

The team uses worktree branches for isolation, so the project needs a git repository. Run `git rev-parse --git-dir` to check. If there's no git repo, tell the user and offer to initialize one.

### Step 2: Create the team

Use TeamCreate with team name `dev-team`. This creates the shared task list that all agents coordinate through.

### Step 3: Create the initial requirement task

Use TaskCreate to capture the user's requirement as the first task on the shared task list. This is what the Architect picks up and decomposes.

### Step 4: Spawn the Architect

Spawn the Architect as a teammate using the Agent tool with `team_name: "dev-team"` and `name: "architect"`. Use the `architect` subagent_type.

Include in the prompt:
- The user's full requirement (verbatim)
- That three teammates are available: `implementer`, `tester`, `reviewer`
- The workflow: Implementer and Tester work in parallel on separate worktree branches (`feat/` and `test/`), then Reviewer reviews both
- That high-level design decisions must be escalated to the user — present the technical approach before assigning work
- The team name (`dev-team`) so the Architect can read the team config

### Step 5: Spawn the remaining agents

Spawn all three in parallel using the Agent tool, each with `team_name: "dev-team"`:

**Implementer** — `name: "implementer"`, subagent_type `implementer`
- Tell it the Architect is the team lead and will assign tasks
- It should check the task list for work and wait for assignment

**Tester** — `name: "tester"`, subagent_type `tester`
- Tell it the Architect is the team lead and will assign tasks
- It should check the task list for work and wait for assignment

**Reviewer** — `name: "reviewer"`, subagent_type `reviewer`
- Tell it the Architect is the team lead and will assign review tasks
- It should check the task list for work and wait for assignment

### Step 6: Report to user

Tell the user:
- The dev team is up and running
- The Architect is analyzing their requirement and will present a technical approach for approval
- They'll be consulted on high-level design decisions before implementation begins
- They can message any agent by name if needed

## Workflow

```
User requirement
  → Architect (decomposes, designs, presents approach for user approval)
    → parallel: Implementer (feat/ branch) + Tester (test/ branch)
      → Reviewer (reviews code + tests, structured feedback)
        → Architect (merges if approved, or routes feedback for fixes)
```

## Key Rules

- The Architect presents its technical approach to the user BEFORE assigning work — the user approves first
- High-level design choices (library selection, API design, data formats) are escalated to the user
- The Reviewer provides structured feedback with severity levels: blockers (must fix) vs. suggestions (nice to have)
- If Reviewer requests changes, Architect routes feedback to the right agent, waits for fixes, then triggers re-review
- After Reviewer approves, Architect merges branches and reports completion
