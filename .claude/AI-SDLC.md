# AI Development Playbook

How I use AI agents to ship code. Practical steps first, conceptual diagram at the bottom.

## Quick Start: "I have a thing to build"

### 1. Scope it
```
You: "Let's scope AUTO-XXX" (or just describe the work)
```
Claude invokes `scope-refine` → Socratic Qs → scope+plan doc saved to `~/.claude/projects/<path>/scopes/`.

### 2. Create issues from the plan
```
~/.claude/hooks/bd-create-from-plan.sh ~/.claude/projects/<path>/scopes/2026-04-09-feature-name.md
```
Or tell Claude: "create bd issues from this plan." Issues get created with deps.

### 3. Execute
```
bd ready          # see what's unblocked
bd show <id>      # review the task
```
Then tell Claude to work on it. For parallel work, dispatch multiple agents (each gets a bd issue + worktree).

### 4. Checkpoint
After each task, Claude shows you `git diff --stat` + test results. You review. If good → `bd close`. If not → fix first.

### 5. PR + merge
```
av branch nil/feature-name
av pr --draft --title "..." --body "..."
```
Claude creates a structured PR description with "what reviewers should watch" section.

### 6. Harness engineer
Something go wrong? Fix the harness so it can't happen again:
- Bad pattern → add rule to CLAUDE.md
- Missing context → update codebase map
- Wrong tool → update skill instructions

---

## Spike Mode: "I need to prove this works first"

```
You: "Let's spike this"
```
- Build end-to-end in current worktree, prioritize proving the approach
- DON'T commit to main branches
- When done: "split this into PRs" → fresh worktrees per PR, reimplement cleanly

---

## Entry Points (start from wherever makes sense)

| I have... | Start at... |
|-----------|-------------|
| A vague idea | Step 1 (scope) |
| A Linear ticket | Step 1 — Claude pulls the ticket context automatically |
| A clear scope doc already | Step 2 (create issues) |
| bd issues already created | Step 3 (execute) |
| Code written, need to ship | Step 5 (PR) |
| Something to explore/research | Spike mode |

---

## Parallel Agents: "Multiple things at once"

When the plan has independent tasks across PRs:
1. Create bd issues from plan (step 2)
2. Tell Claude: "execute the plan" (invokes `execute-plan` skill)
3. Claude runs `bd ready`, filters by scope doc, shows you the batch
4. You confirm → agents dispatched in parallel (worktree-isolated)
5. Each agent: claims issue → implements → commits → reports back
6. You review each checkpoint, close issues, next batch fires

---

## Tools Reference

| Stage | Tool | Command |
|-------|------|---------|
| Issue tracking (coarse) | Linear | `linear issue view AUTO-XXX` |
| Scoping + planning | scope-refine skill | Produces `~/.claude/projects/<path>/scopes/*.md` |
| Task tracking (granular) | bd | `bd create`, `bd ready`, `bd close` |
| Batch issue creation | Script | `~/.claude/hooks/bd-create-from-plan.sh <doc>` |
| Parallel dispatch | execute-plan skill | `bd ready` → agents in worktrees → checkpoint |
| Execution (app) | staff-swe skill | TDD + security review |
| Execution (infra) | staff-sre skill | validate + plan + security review |
| Branch stacking | av CLI | `av branch`, `av pr --draft` |
| Code review | pr-review-toolkit | `superpowers:requesting-code-review` |
| Cross-session memory | bd remember | `bd remember "insight"` |
| Permanent rules | CLAUDE.md | `~/.claude/CLAUDE.md` |

---

## Principles

**[Harness engineering](https://mitchellh.com/writing/my-ai-adoption-journey):** Every agent mistake becomes a permanent fix. The harness gets smarter with every session. Compound returns.

**[Staleness detection](https://github.com/cortex-tms/cortex-tms):** When code changes but docs don't, agents drift. Periodically check: is the codebase map accurate? Are old scope docs still referenced?

**Catch errors early:** Checkpoint gates between tasks. Fixing at task 2 saves undoing tasks 3-6.

**Specs reduce ambiguity:** Use [EARS patterns](https://alistairmavin.com/ears/) for criteria ("When X, the system shall Y") and [Given/When/Then](https://cucumber.io/docs/gherkin/reference/) for scenarios. Agents translate these directly to tests.

---

## Architecture Diagram

```
LINEAR ISSUE (coarse, stakeholder-visible)
    │
    ▼
SCOPE + PLAN (scope-refine skill)
  Socratic Qs → scope doc with EARS criteria + Given/When/Then + PR breakdown + tasks
  Saved to ~/.claude/projects/<path>/scopes/
    │
    ▼
CREATE BD ISSUES (bd-create-from-plan.sh)
  Parse plan → bd create per task → bd dep add for ordering
    │
    ▼
DISPATCH AGENTS (parallel, isolated worktrees)
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ Agent A  │  │ Agent B  │  │ Agent C  │
  │ claim    │  │ claim    │  │ claim    │
  │ code     │  │ code     │  │ code     │
  │ test     │  │ test     │  │ test     │
  │ verify   │  │ verify   │  │ verify   │
  └────┬─────┘  └────┬─────┘  └────┬─────┘
       ▼             ▼             ▼
CHECKPOINT GATE
  Show diff + results → human reviews → bd close if good
       │
       ▼
SECURITY + CODE REVIEW → UPDATE SCOPE DOC + CODEBASE MAP
       │
       ▼
CREATE PR (av pr --draft, structured description, auto-assign)
       │
       ▼
HUMAN REVIEW + MERGE → harness engineer any mistakes
```
