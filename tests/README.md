# Validation Scripts

This directory contains validation scripts for the dev-teams project.

## Available Scripts

### validate_accountant_delegation.sh

Validates that the Accountant agent follows delegation boundaries correctly.

**What it checks:**
- Static structure: Verifies required sections exist in `agents/accountant.md`
- Cross-team protocol: Verifies delegation boundaries in `shared/cross-team-protocol.md`
- Git history: Checks for production code violations (Accountant committing outside `data-team-output/`)
- Session logs: Parses `.claude/sessions/*.jsonl` for spawn correctness (vanilla vs minuteman spawns)

**Usage:**
```bash
./tests/validate_accountant_delegation.sh
```

**Exit codes:**
- 0: All checks passed
- 1: One or more violations found

**When to run:**
- After modifying Accountant instructions
- After data-team tasks to verify correct delegation
- As part of CI/CD pipeline for regression testing

