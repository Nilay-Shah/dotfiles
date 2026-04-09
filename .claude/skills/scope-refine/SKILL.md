---
name: scope-refine
description: Use when scoping work, refining requirements, or when a Linear/issue tracker ID is mentioned (e.g., AUTO-XXX). Produces a persistent scope+plan document through Socratic questioning, then saves it for agents to reference.
---

# Scope & Plan

Understand the problem, then plan the solution. One skill, one output doc, persisted to disk.

## When to Use

- User says "scope", "plan", "let's think about", or "refine"
- A Linear issue ID is mentioned (e.g., AUTO-XXX)
- Requirements are vague or starting a new feature/epic
- **Skip when:** User says "just build it" or scope is already clear

## Pipeline

1. **Pull context** — If issue ID detected, run `linear issue view AUTO-XXX`. Read the codebase map. Don't ask the user to paste things.
2. **Socratic Qs** — One question at a time. 2-5 questions max. Ask about success criteria, interfaces, scope boundaries, constraints. Don't ask implementation details.
3. **Propose approaches** — 2-3 options in a comparison table with a recommendation. If only one approach makes sense, say so.
4. **Produce the doc** — After user picks an approach, output the combined scope+plan (template below).
5. **Save to disk** — `~/.claude/projects/<project-path>/scopes/YYYY-MM-DD-<feature-name>.md`. Never save into the repo.

## Output Template

```markdown
# [Feature Name]

**Issue:** [ID if available]
**Goal:** [One sentence]
**Approach:** [Chosen approach, 2-3 sentences]

## Scope
### In Scope
- [Deliverable 1]
- [Deliverable 2]

### Out of Scope
- [Excluded 1]

### Success Criteria
Use [EARS patterns](https://alistairmavin.com/ears/) for unambiguous criteria:
- [ ] When [trigger], the [system] shall [response]
- [ ] While [state], when [action], the [system] shall [response]

### Key Scenarios
Use [Given/When/Then](https://cucumber.io/docs/gherkin/reference/) for concrete behavior (agents translate these directly to tests):
```
Given [precondition]
When [action]
Then [expected outcome]
```

## Plan
### PR Breakdown
1. **PR 1:** [Contents, what it enables]
2. **PR 2:** [Contents, dependencies]

### Tasks
For each PR, the implementation steps:

#### PR 1: [Name]
- [ ] Task 1 — files to touch, what to do, how to verify
- [ ] Task 2 — files to touch, what to do, how to verify

#### PR 2: [Name]
- [ ] Task 3 — depends on Task 1
- [ ] Task 4

## Open Questions
- [Unresolved items]

## Dependencies
- [External: teams, services, credentials]
```

## After Saving

Offer:
1. **Execute** — Create bd issues from the tasks: `~/.claude/hooks/bd-create-from-plan.sh <saved-scope-doc-path>`, then start working
2. **Defer** — Pick this up in another session
3. **Refine** — Keep iterating

Do NOT auto-chain into anything. This is a checkpoint.

## Rules

- One question at a time. Be conversational.
- Always have a recommendation.
- Success criteria must be verifiable commands/outcomes, not "works correctly."
- Tasks must name specific files and verification steps.
- No code in this doc — implementation details go in the code, not the plan.
