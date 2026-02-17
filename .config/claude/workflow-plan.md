# AI Dev Workflow

## Overview

Personal AI-assisted development workflow built on:
- **Superpowers** — in-session process enforcement (brainstorm → plan → execute → review)
- **Beads** — cross-session task continuity (structured task DB, stealth mode, symlinked to ~/.beads/)
- **Custom archetype skills** — scope/refine, staff-swe, staff-sre
- **Git worktrees** — parallel sessions per task/PR (via `bd worktree`)
- **Configurable stacking tool** — gt (default), swappable to git-town/spr
- **Configurable task tracker** — beads (default), swappable

## Architecture

```
Linear (project planning)
  │
  ▼
Scope/Refine skill ← pulls Linear issue via CLI
  │
  ▼
Plan file (docs/plans/YYYY-MM-DD-feature.md)
  │
  ▼
plan-to-beads sync ← parses plan, creates bd tasks with deps
  │
  ▼
Beads (bd ready → agent picks next task)
  │
  ▼
Archetype skill (staff-sre or staff-swe) ← per-repo auto-detect
  │
  ▼
Subagent per task → verify → review → commit
  │
  ▼
Finish branch → $STACK_SUBMIT_CMD
```

## Setup

### New Machine
```bash
# 1. Clone dotfiles
yadm clone <repo>

# 2. Run bootstrap
~/.config/claude/bootstrap.sh

# 3. Auth
linear config          # opens browser
```

### New Repo
```bash
cd ~/new-repo
source ~/.config/claude/workflow.env

# Init beads (stealth + external DB)
mkdir -p ~/.beads/$BEADS_ORG/new-repo
bd init --stealth --db ~/.beads/$BEADS_ORG/new-repo/beads.db --prefix new-repo --skip-hooks
rm -rf .beads && ln -s ~/.beads/$BEADS_ORG/new-repo .beads

# Generate codebase map (in a Claude session)
# "Read the repo structure and generate a codebase map for ~/.claude/projects/<path>/CLAUDE.md"

# Add to workflow.env BEADS_REPOS
```

## Config

All config lives at `~/.config/claude/workflow.env`:

```bash
# Stacking tool — swap by changing these
STACK_TOOL=gt
STACK_SUBMIT_CMD="gt submit"
STACK_CREATE_CMD="gt create"
STACK_LOG_CMD="gt log"
STACK_RESTACK_CMD="gt restack"

# Task tracker — swap by changing these
TASK_TOOL=bd
TASK_LIST_CMD="bd ready"
TASK_CREATE_CMD="bd create"
TASK_CLAIM_CMD="bd update --claim"
TASK_CLOSE_CMD="bd close"
TASK_DEPS_CMD="bd dep tree"
TASK_WORKTREE_CMD="bd worktree create"

# Repos
BEADS_ORG=ph
BEADS_REPOS="$HOME/infrastructure,$HOME/conductor"
```

## Archetype Skills

| Skill | Trigger | Pipeline | Repos |
|-------|---------|----------|-------|
| `scope-refine` | "refine", AUTO-XXX | Linear pull → Socratic Q&A → approaches → scope doc | Any |
| `staff-swe` | App/agent work | Brainstorm → plan → TDD → app security → review → finish | conductor |
| `staff-sre` | Infra/terraform | Brainstorm → check ADRs → plan → tf validate/plan → infra security → review → update codebase map → finish | infrastructure |

Per-repo auto-detection via `~/.claude/projects/<path>/CLAUDE.md`.

## Worktrees + Parallel Sessions

```bash
# Beads creates worktrees with shared DB automatically
bd worktree create feat/oidc-variables
bd worktree create feat/oidc-helm-values

# Launch parallel Claude sessions
# Terminal 1: cd .worktrees/feat/oidc-variables && claude
# Terminal 2: cd .worktrees/feat/oidc-helm-values && claude

# Each session runs bd ready, claims a task, works, closes it

# When done
$STACK_RESTACK_CMD
$STACK_SUBMIT_CMD
bd worktree remove feat/oidc-variables
bd worktree remove feat/oidc-helm-values
```

## ADRs

Use MADR minimal format. Template at `adr/0000-template.md` in each repo.
ADR-worthy = "would someone make the wrong choice without knowing this?"

## Hooks (auto-configured)

| Hook | Trigger | Action |
|------|---------|--------|
| SessionStart | Session opens | `$STACK_LOG_CMD` (show PR stack) |
| SessionStart | Session opens | `bd prime` (inject workflow context) |
| PreCompact | Before context compression | `bd prime` (preserve workflow context) |
| PostToolUse | Edit/Write on *.tf | `terraform fmt` on the file |

## File Inventory

```
~/.claude/
├── CLAUDE.md                           # Global conventions
├── settings.json                       # Hooks
├── skills/
│   ├── scope-refine.md                 # Requirements refinement
│   ├── staff-swe.md                    # App dev (TDD + security)
│   └── staff-sre.md                    # Infra dev (tf validate + security)
├── scripts/
│   ├── plan-to-beads.sh                # Plan markdown → beads tasks
│   ├── linear-to-beads.sh              # Linear issue → beads parent task
│   └── worktree-setup.sh              # Create worktrees from plan/beads
└── projects/
    ├── -Users-nilay-infrastructure/
    │   └── CLAUDE.md                   # Codebase map, "use staff-sre"
    └── -Users-nilay-conductor/
        └── CLAUDE.md                   # Codebase map, "use staff-swe"

~/.config/claude/
├── workflow.env                        # Tool config (stacker, task tracker, repos)
├── workflow-plan.md                    # This file
└── bootstrap.sh                        # New machine setup

~/.beads/<org>/<repo>/                  # Beads DBs (symlinked from repo .beads/)
```

## Phases

### Phase 1 — Foundation [DONE]
- Beads installed + stealth init (infrastructure)
- Linear CLI installed + authenticated
- Superpowers plugin installed
- Codebase map generated (infrastructure)
- ADR template + directory created
- Bootstrap script + workflow.env created
- Hooks configured (gt log, bd prime, terraform fmt)

### Phase 2 — Archetype Skills
- Create scope-refine.md, staff-swe.md, staff-sre.md at ~/.claude/skills/
- Per-repo CLAUDE.md auto-detection
- yadm backup

### Phase 3 — Manual Play
- Test workflow on real tasks
- Refine skills based on friction

### Phase 4 — Worktrees + Parallel Sessions
- Use `bd worktree` for parallel Claude sessions
- Integrate with $STACK_TOOL for stacked PRs
- Helper script for setup/teardown

### Phase 5 — Glue Scripts
- plan-to-beads.sh (plan markdown → bd tasks)
- linear-to-beads.sh (Linear issue → bd parent task)
- Codebase map auto-update hook

### Phase 6 — Evaluate + Polish
- Entire.io (session provenance, once stable)
- Agent teams (once Claude Code stabilizes)
- Auto-post scope back to Linear
- Beads → Linear status sync
- Cross-repo `bd ready`

## Handoff Prompt

```
Read ~/.config/claude/workflow-plan.md and run bd ready.
I'm on phase [N]. Pick up where I left off.
```

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Beads stealth + symlink to ~/.beads/ph/ | Zero repo pollution, yadm-trackable |
| Superpowers over agent teams | Cheaper, reliable, no 5x token cost |
| workflow.env for tool abstraction | Swap stacker/tracker by changing one file |
| Per-project CLAUDE.md for auto-detect | No noise in shared repo files |
| MADR minimal for ADRs | Standard, concise, machine-readable |
| Worktrees deferred to phase 4 | Single-session workflow first |
