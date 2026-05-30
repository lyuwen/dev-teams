# Dev-Teams Agent Definition Review Report

**Date:** 2026-05-30
**Scope:** 10 agent definitions in `agents/`, 3 shared protocols in `shared/`, plus 2 `.bak` files
**Lines reviewed:** ~2,400

---

## 1. Critical Findings (act on these)

### 1.1 Stale `.bak` files contradict the current model
Two backup files still describe **Noob as a peer agent**, contradicting the current architecture where Noob is the Instructor's subagent:

- `agents/accountant.md.bak`
- `shared/cross-team-protocol.md.bak` — line 9: `"Dev Team | Architect | Implementer, Tester, Reviewer, Critique, Documenter, Instructor, Noob"` — wrong now.
- `shared/cross-team-protocol.md.bak` — line 36: `"Accountant does NOT message ... Instructor, or Noob directly"` — Noob isn't reachable at all in the current design.

**Recommendation:** Delete both `.bak` files. If history is needed, `git log` already preserves it. Their presence in the working tree creates a real risk that someone (or a future agent) reads them as current truth.

### 1.2 Orphaned bullet in `agents/accountant.md:384`
The file has a structured numbered `## What You Do NOT Do` section (items 1–6, lines 366–382) properly closed by the **"When in doubt"** sentence on line 382. Then on line 384 there is a single dangling bullet:

```
- Make software design decisions (raise with the Architect)
```

It sits outside the structured list, after the closing remark — a leftover from the previous flat-bullet style preserved in `.bak`. It's unclosed structurally (no preceding list it belongs to) and semantically duplicative of item 5 (`Make architectural decisions alone`).

**Recommendation:** Remove line 384. Item 5 already covers this.

### 1.3 Architect leaks into data-team's monitoring scope
`agents/architect.md:261`:
> **Minuteman (data team):** Check for analysis reports in `data-team-output/`

The Architect should never monitor data-team workers — that's the Accountant's job per `shared/cross-team-protocol.md` ("Architect does NOT message Implementer/Tester/... directly" applies symmetrically). The Architect's silent-completion checklist is enumerating agents *it* coordinates; including Minuteman here implies the Architect respawns or chases them, which violates the lead-to-lead boundary.

**Recommendation:** Remove the Minuteman line from the Architect's silent-completion checklist. Health monitoring of minute-men belongs to (and is already documented in) `agents/accountant.md` lines 262–294.

### 1.4 Decision Heuristics table duplicated inside `accountant.md`
The **same decision heuristics table** appears twice:

- Lines 148–154 (under "Work Classification")
- Lines 313–322 (under "Production vs. Ad-Hoc Code")

Rows overlap heavily; the second table just adds two rows ("One-time data transformation", "Recurring data pipeline component"). Two adjacent sections (Work Classification and Production vs. Ad-Hoc Code) are doing the same job — sorting incoming work into "spawn minute-men" vs "write PRD".

**Recommendation:** Merge the two sections into one. Keep one canonical decision tree and one table. The "Production vs Ad-Hoc Code" framing is the more precise label; the "Work Classification" tree can be inlined under it.

### 1.5 Architect health-monitoring largely duplicates `shared/operational-resilience.md`
`agents/architect.md` lines 244–301 (Team Health Monitoring) restates `shared/operational-resilience.md` lines 6–44 in expanded form. The Architect already declares it follows the team-lead section of operational-resilience (line 43), so most of this content is redundant.

The **non-redundant** parts worth keeping local to the Architect are:
- The agent-specific silent-completion paths (Reviewer files, feat/ commits, etc. — lines 254–263) — except for the Minuteman bug noted in §1.3.
- Graceful Degradation list (lines 297–301), which names specific agents.

The rest (first/second check-in cadence, declare-dead threshold, respawn protocol) is verbatim from the shared protocol.

**Recommendation:** Trim Architect §"Tracking Responsiveness", "Respawning Dead Agents", and "Pipeline Stall Detection" to a one-line pointer ("See `shared/operational-resilience.md` for the general protocol") and keep only the agent-specific additions.

---

## 2. Moderate Findings (worth fixing)

### 2.1 Unclosed loop: Critique's "validate plans before implementation"
`critique.md` description (line 4) advertises **plan validation before implementation begins**, with an explicit example (lines 24–31). But the body's `## Process` (lines 128–141) assumes code already exists on a `feat/` branch — step 4 says "Read the implementation — every file changed on the `feat/` branch."

There is no branch in the plan-validation use case. The Process section never handles it.

**Recommendation:** Either drop the third example from the description, or add a short "Plan Validation Mode" subsection that maps the same first-principles methodology onto plan-only review (no `feat/` or `test/` branches, no "run the code").

### 2.2 Reviewer's role in `cross-team-protocol.md` is named but never exercised
`reviewer.md` line 45 says: "you are a committee member (the Accountant may contact you for data/software intersection discussions)". `cross-team-protocol.md` line 14 lists Reviewer as a committee member. But neither file says **what the Reviewer actually does** when the Accountant pings it. The protocol surface is open but the action surface is empty.

**Recommendation:** Either add one paragraph in `reviewer.md` describing what to do when contacted by the Accountant (e.g., "respond with code-quality assessment of the contested module"), or remove Reviewer from the committee membership entirely if there's no real role.

### 2.3 Vague pointers in Architect's silent-completion checks
`architect.md`:
- Line 256: "Reviewer: Check for review files in `.claude/reviews/` or similar locations" — *"or similar locations"* is hand-wavy. There's no other place that documents where Reviewer writes files. The Reviewer's own format spec (lines 105–137) doesn't specify a path either.
- Line 259: "Instructor: Check for UX findings reports" — no path specified.

These checks are unactionable as written. An agent following them won't know where to look.

**Recommendation:** Either standardize output paths in each worker agent (e.g., `.claude/reviews/`, `.claude/critiques/`, `.claude/ux-findings/`) and reference them consistently, or drop the file-system-check step and rely solely on commit detection + status-check messages.

### 2.4 Color collisions
Three agents share **yellow** (`tester`, `noob`, `minuteman`) and two share **cyan** (`architect`, `instructor`). Yellow across two teams is acceptable, but `tester` and `noob` are both in the **dev team** and yellow, which makes log inspection ambiguous. Same for `architect` and `instructor`, both dev-team cyan.

**Recommendation:** Reassign `noob` and `instructor` to free colors (white? gray? a fresh hue?). README's "Agent Roster" table currently asserts these colors as ground truth, so changing the agents requires updating the README too.

### 2.5 Accountant has no Health-Monitoring counterpart for "What You Do NOT Do" exhaustion
The Accountant's "What You Do NOT Do" enumerates 6 items + a closing "When in doubt" + then the dangling bullet (§1.2). After fixing §1.2 the structure will be clean, but consider: the Architect ends its NOT-DO list with branch-lifecycle reminders that map to concrete failure modes. The Accountant's list is mostly philosophical. Adding "Spawn minute-men sequentially when parallel execution is possible" would mirror the structure better (it's already an emphatic NEVER at line 258 but absent from the NOT list).

**Recommendation:** Minor — promote the most-violated rules from the embedded ALWAYS/NEVER lists into the final NOT-DO list for retrieval consistency.

---

## 3. Minor Findings / Observations

### 3.1 Duplicated "Completion Protocol" block across non-lead agents
Implementer, Tester, Reviewer, Critique, Documenter, Instructor, and Minuteman each carry a near-identical "⚠️ CRITICAL: Completion Protocol" section. This duplication is **intentional** (each agent has a fresh context window and must see it inline) and **valuable** for preventing silent completion. Recommend keeping as-is, but consider extracting the **shared bullet pattern** into a snippet that each agent customizes only the "what to include in your message" portion of — easier to evolve.

### 3.2 Implementer/Tester `tools` not declared in frontmatter
Implementer and Tester have no `tools:` field, meaning they inherit the default (All tools). README confirms this is intentional ("All" in the table). No fix needed; flagging for completeness.

### 3.3 `instructor.md` description mentions Noob with lowercase `noob` (line 10)
> "I'll use the instructor agent to design user tasks and test usability with the noob."

Other places use `**Noob**`. Cosmetic — descriptions are user-facing example dialogue, so lowercase is fine.

### 3.4 README description of agent count is mismatched
`README.md` line 3: "An 8-agent development team..." — but the roster lists 8 agents *including* Noob, while Noob is now a subagent, not a peer. The architect description correctly says "coordinates six other peer agents" (architect.md:37). README is the lone holdout that still implies Noob is a peer.

**Recommendation:** Update README to "A 7-peer-agent dev team with 1 subagent (Noob, spawned by the Instructor)" or similar. (This is outside `agents/` strictly but directly contradicts the agent files.)

### 3.5 `operational-resilience.md` § "For Agents Without SendMessage" is intentionally vestigial
Lines 57–65 explicitly note this section currently has no consumers. It's labeled forward-compatible. This is acceptable, but if you want to keep the protocol minimal, the section could be removed and re-added when needed.

### 3.6 `architect.md` "Receive and evaluate PRDs from the Accountant" is responsibility #16 but is not in the description block
The description block (lines 4–31) gives 3 examples — all dev-internal. None mentions handling Accountant PRDs. A user invoking the architect agent for "evaluate this PRD from the data team" would have weaker triggering signal.

**Recommendation:** Add a fourth example to the architect description showing a PRD-evaluation invocation.

### 3.7 `documenter.md` frontmatter says `tools` is unset (All) but doesn't actually need write to test files
The Documenter writes docs. It could plausibly be tighter (e.g., Read, Write, Edit, Bash). Currently has full power. Defensible but worth questioning.

### 3.8 `instructor.md` frontmatter `tools: ["Read", "Grep", "Glob", "Bash"]` — no Write
This is correct (Instructor coordinates fixes via SendMessage; it doesn't write docs or code). The Task tool is implicitly available for subagent spawning regardless of the `tools` array. Confirmed by §"Phase 2" usage.

### 3.9 Cross-team-protocol has a slight inconsistency in Noob phrasing
- Line 9 (table): `"Noob is a subagent of Instructor, not a peer"` — clear.
- Line 36: `"and cannot reach Noob at all — it is the Instructor's subagent, not a peer"` — clear.

Good consistency in the current (non-`.bak`) version.

---

## 4. Structural / Closure Audit (no unclosed logic found, with one near-miss)

I traced every "if-then" / "wait-then-resume" flow in each agent:

| Agent | Loops audited | Closure status |
|---|---|---|
| Architect | Worker→Reviewer→Critique→merge→Doc→Instructor→fix-routing | ✅ All paths return to a defined next step or terminate at "Report completion" |
| Implementer | Receive→build→commit→message→complete | ✅ Closed |
| Tester | Receive→test→report→commit→message→complete | ✅ Closed |
| Reviewer | Receive→review→verdict→message | ✅ Closed |
| Critique | Receive→read plan/code/tests→verdict; intervention loop | ✅ Closed (intervention has explicit "Require Architect to acknowledge and act" termination) |
| Documenter | Initial-doc OR fix-from-instructor → commit → message | ✅ Closed; both entry paths terminate cleanly |
| Instructor | Phase1→Phase2 spawn→diagnose→route→wait→re-spawn→loop→Phase3 | ✅ Closed; loop has explicit "Wait for fix confirmation before re-testing" termination condition |
| Noob | Spawn→attempt→report-as-return-value | ✅ Closed (return-value-as-exit) |
| Accountant | Receive→shard→spawn→aggregate→report; health-monitor; tool-gap→PRD | ✅ Closed |
| Minuteman | Receive→analyze→write→message→complete | ✅ Closed |

**Near-miss:** Critique's "Plan Validation" mode (description) has no corresponding Process branch — see §2.1. The logic is "open" only in the sense that one advertised use case lacks an execution path.

---

## 5. Summary Table — Recommended Edits

| Priority | File | Change |
|---|---|---|
| P0 | `agents/accountant.md.bak`, `shared/cross-team-protocol.md.bak` | Delete |
| P0 | `agents/accountant.md:384` | Remove dangling orphaned bullet |
| P0 | `agents/architect.md:261` | Remove Minuteman from silent-completion checklist |
| P1 | `agents/accountant.md` | Merge "Work Classification" + "Production vs. Ad-Hoc Code" into one section; deduplicate the heuristics table |
| P1 | `agents/architect.md` lines 244–301 | Trim duplicates of operational-resilience.md; keep only agent-specific additions |
| P1 | `agents/critique.md` | Either drop "plan validation" example or add a Process branch for it |
| P2 | `agents/architect.md` description block | Add PRD-evaluation example |
| P2 | `agents/reviewer.md` / `cross-team-protocol.md` | Define what Reviewer does when pinged by Accountant, or remove from committee |
| P2 | `agents/architect.md:256, 259` | Standardize output paths for Reviewer/Critique/Instructor artifacts, or drop the file-check step |
| P3 | Frontmatter colors | Resolve dev-team color collisions (yellow x2, cyan x2) |
| P3 | `README.md` | Update agent count / Noob status to match current model |

---

## 6. Overall Assessment

The agent set is **well-architected and largely self-consistent** after the Noob-to-subagent refactor. The shared-protocol pattern is working — agents reference `shared/*.md` and add only domain-specific deltas. The Completion Protocol pattern (mandatory ✅ checklists for every non-lead agent) is a smart defense against silent completion and reads consistently across files.

The **main risks** are:
1. Two stale `.bak` files in the working tree that disagree with the current model.
2. One dangling line in `accountant.md` that suggests the file wasn't fully reformatted during its last edit.
3. The Architect duplicates a lot of the shared resilience protocol — drift risk if the shared file evolves.
4. Two clear duplicate sections in `accountant.md` (Work Classification vs Production-vs-Ad-Hoc) doing the same job.

No unclosed logic was found in any agent's process flow — every loop has a defined exit, every wait has a defined wake. The only "open" item is Critique's advertised-but-unimplemented plan-validation mode.
