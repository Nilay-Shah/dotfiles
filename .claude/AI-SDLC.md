# AI Development Playbook

How I use AI agents to ship code. Practical steps first, conceptual diagram at the bottom.

## Quick Start: "I have a thing to build"

### 1. Scope it
```
You: "Let's scope AUTO-XXX" (or just describe the work)
```
Claude invokes `scope-refine` → Socratic Qs → a scope+plan doc (EARS criteria, Given/When/Then, PR breakdown) saved to `~/.claude/projects/<path>/scopes/`. Skip it for a one-sentence / single-file / trivial change — plan-first is for multi-file or uncertain work.

### 2. Architect the contract (the design gate)
Claude (Opus) turns the scope into a **shared contract** — the interfaces + data models every piece must honor, the design principles (no bandaids, build for extensibility, the target system shape), and a set of disjoint work-items. **You review and lock it** before any code is written. This is where your judgment has the most leverage: a tight contract is what lets the implementers run in parallel without colliding.

### 3. Fan out
```
You: "execute the plan" / "fan this out"
```
The `execute-plan` skill invokes the `fanout-implement` workflow: one worktree-isolated implementer per work-item (coding against the contract, TDD), a separate skeptic verifies each against the contract before it can merge, a serial dependency-ordered merge (semantic conflicts flagged, never clobbered), the full test suite, then a pre-PR review pass (bugs / simplify / arch / impl). Returns a report on one integration branch. For a single tightly-coupled change, skip the fan-out and use TDD directly.

### 4. Triage
Review the report: which items passed verify, what's flagged, any merge conflicts that need you, test + review findings. Fix or re-run the flagged items (the workflow resumes — completed items are cached). You decide what ships.

### 5. PR + merge
```
av branch nil/feature-name
av pr --draft --title "..." --body "..."
```
Draft PR, assigned to me, with a "what reviewers should watch" section. The `git-pr-workflow` skill carries the PR template + the av stacking dances. The human merges.

### 6. Harness engineer
Something go wrong? Fix the harness so it can't happen again:
- Bad pattern → add a rule to CLAUDE.md — or a deterministic hook / deny-rule if a prompt rule isn't enough (Haiku ignores prompts under load)
- Missing context → update the codebase map or write a native memory note
- Wrong tool → update the skill instructions

---

## Spike Mode: "I need to prove this works first"

```
You: "Let's spike this"
```
- Build end-to-end in the current worktree, prioritize proving the approach over cleanliness
- DON'T commit to main branches — this is a reference map
- When done: "split this into PRs" → fresh worktrees per PR, reimplement cleanly (not copy-paste)

---

## Entry Points (start from wherever makes sense)

| I have... | Start at... |
|-----------|-------------|
| A vague idea | Step 1 (scope) |
| A Linear ticket | Step 1 — Claude pulls the ticket via the `linear` CLI |
| A clear scope doc already | Step 2 (architect) |
| An approved contract + work-items | Step 3 (fan out) |
| A bug list from debugging | Step 2/3 — feed the list in as the work source |
| Code written, need to ship | Step 5 (PR) |
| Something to explore/research | Spike mode |

---

## Parallel work

When the work decomposes into 2+ independent pieces, `fanout-implement` runs them concurrently — each implementer in its own worktree, coding against the shared contract, checked by a separate skeptic before merge. The deterministic workflow owns dispatch, dependency-ordered merge, and worktree cleanup; you own the two gates (lock the contract before, triage the report after). Parallelism only pays when the pieces are genuinely independent — that's what the contract + disjoint work-items buy you.

---

## Tools Reference

| Stage | Tool | Command / Notes |
|-------|------|-----------------|
| Issue tracking (coarse) | Linear | `linear issue view AUTO-XXX` |
| Scoping + planning | scope-refine skill | → `~/.claude/projects/<path>/scopes/*.md` |
| Architect + fan-out | execute-plan skill → fanout-implement workflow | contract gate → parallel implementers → triage |
| Execution (app) | staff-swe skill | TDD + security review |
| Execution (infra) | staff-sre skill | validate + plan + security review |
| Branch stacking / PRs | av CLI + git-pr-workflow skill | `av branch`, `av pr --draft`; PR template + dances in the skill |
| Code review | pr-review-toolkit | `superpowers:requesting-code-review` |
| Cross-session memory | native `~/.claude` memory | `projects/<path>/memory/*.md` indexed by `MEMORY.md` |
| Permanent rules | CLAUDE.md | `~/.claude/CLAUDE.md` |

> `bd` / beads is **retired** — task tracking is `TodoWrite`, cross-session knowledge is native memory.

---

## Principles

**[Harness engineering](https://mitchellh.com/writing/my-ai-adoption-journey):** Every agent mistake becomes a permanent fix. The harness gets smarter every session. Compound returns.

**[Staleness detection](https://github.com/cortex-tms/cortex-tms):** When code changes but docs don't, agents drift. Periodically check: is the codebase map accurate? Are old scope docs still referenced?

**Catch errors early:** Gates between phases (contract before fan-out, triage after). Fixing at the contract saves undoing N implementations.

**Specs reduce ambiguity:** Use [EARS patterns](https://alistairmavin.com/ears/) for criteria ("When X, the system shall Y") and [Given/When/Then](https://cucumber.io/docs/gherkin/reference/) for scenarios. Agents translate these directly to tests.

**Boring levers beat flashy ones:** deny-rules/hooks, a populated memory layer, and a lean CLAUDE.md have better ROI than elaborate multi-agent fan-out (which costs many× the tokens). Invest there first; reach for fan-out only when the work is genuinely parallelizable.

---

## Architecture Diagram

```
LINEAR ISSUE (coarse) · a vague idea · a bug list
    │
    ▼
SCOPE + PLAN (scope-refine)            EARS criteria + Given/When/Then + PR breakdown
    │
    ▼
ARCHITECT → SHARED CONTRACT        ◆ you lock interfaces + data models
    │
    ▼
FAN OUT  (fanout-implement workflow)
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │ impl i1  │ │ impl i2  │ │ impl i3  │   worktree each, code to contract, TDD
  └────┬─────┘ └────┬─────┘ └────┬─────┘
       └── verify-item (skeptic) ──┘        fail → 1 redo, else flagged
                  │
                  ▼
       MERGE (serial, dep-ordered; semantic conflict → flag, never clobber)
                  │
                  ▼
       TEST → PRE-PR REVIEW (bugs / simplify / arch / impl)
    │
    ▼
TRIAGE                              ◆ you review the report → fix / re-run flagged
    │
    ▼
PR (av pr --draft, structured desc, auto-assign) → HUMAN MERGE → harness-engineer any mistakes
```
