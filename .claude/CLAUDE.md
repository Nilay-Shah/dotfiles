# Personal Workflow

## Development Approach: Spike → Split

### Spike Phase
When I ask for a "spike" or "prototype":
- Build end-to-end working solution in current worktree
- Prioritize proving the approach over code cleanliness
- DON'T commit to main branches — this is a reference map
- When complete, identify natural seams (API boundaries, components, layers)
- Summarize the breakdown: which pieces are independent, which have dependencies

### Split Phase  
When I say "split" or "break into PRs":
- I'll create fresh git worktrees for each PR-sized piece
- Reimplement cleanly using spike as reference, not copy-paste
- Each PR: single concern, reviewable in <30 min, <400 lines
- Stack with `gt create` as pieces complete

### Worktree Commands
```bash
# Create worktree for a feature
git worktree add ../project-feature-name feature-name

# Clean up when done
git worktree remove ../project-feature-name
```

## Commit Conventions

Format: `type(scope): description`

Types:
- `feat` — new functionality
- `fix` — bug fix
- `refactor` — restructure without behavior change
- `test` — test additions/changes
- `docs` — documentation only
- `chore` — tooling, deps, config

Rules:
- Atomic commits (one logical change)
- Present tense ("add feature" not "added feature")
- No period at end
- Body for context if non-obvious

## Before Committing

1. Run tests relevant to changes
2. Run linter if configured
3. Flag any uncertainty or assumptions made
4. Verify PR stays under 400 lines — split if not

## Code Quality

- Prefer explicit over clever
- Extract when logic repeats 3+ times
- Comments explain WHY, not WHAT
- Handle errors explicitly, don't swallow

## Agent Teams

Use teams for:
- Spikes with multiple layers (backend + frontend + tests)
- Parallel exploration of competing approaches
- Code review from multiple angles

Don't use teams for:
- Sequential tasks
- Same-file edits
- Quick fixes

## Communication Style

- Be direct about tradeoffs and risks
- Ask clarifying questions upfront rather than assuming
- When stuck, explain what you've tried before asking for help
