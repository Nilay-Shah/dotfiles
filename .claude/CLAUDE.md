# Personal Workflow

## Skill Precedence

My custom skills (`scope-refine`, `staff-swe`, `staff-sre`) replace the superpowers scoping/planning phases. Do NOT separately invoke `superpowers:brainstorming` or `superpowers:writing-plans` — `scope-refine` already produces a combined scope+plan. The remaining superpowers skills (TDD, subagent-driven-development, verification, code-review, finishing-branch, systematic-debugging) still apply as-is.

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
- Stack with `av branch` / `av pr` as pieces complete

### Worktree Commands
```bash
# Create worktree for a feature
git worktree add ../project-feature-name feature-name

# Clean up when done
git worktree remove ../project-feature-name
```

## Stacking & Git Tools

**Stacking:** Use `av` (Aviator CLI) for all branch/PR operations. The `av-cli` skill has full reference.
- `av branch <name>` to create stacked branches
- `av commit -m "msg"` instead of `git commit` (auto-restacks children)
- `av pr --draft --title "..." --body "..."` to create PRs (always draft unless told otherwise)
- `av sync --push=yes --prune=yes` to sync stacks
- `av sync --push=yes --prune=yes --rebase-to-trunk` to fetch latest main and rebase the stack onto it (use this instead of manual `git pull origin main` + `git rebase main`)
- After PR merges: `av sync --all --push=no --prune=yes`

**Absorbing fixups into earlier commits:** Use `git absorb` when fixes need to land in specific earlier commits rather than as new commits. It auto-matches hunks to the right commit. Prefer `git absorb` over creating new fixup commits on stacked branches — it avoids restack conflicts by amending the right commit directly.

**Conflict memory:** `git rerere` is enabled — Git remembers conflict resolutions and auto-applies them on repeated rebases.

## PR Creation

**Defaults:** Always create PRs as **draft**. Always assign to me (`--assignee nilay` or equivalent).

**PR description template:**
```markdown
## Summary
[2-3 bullet points: what changed and why]

## What reviewers should watch for
- [Specific area of concern or risk]
- [Design decision that might be controversial]

## Test plan
- [ ] [How this was verified]

## TODO (if draft)
- [ ] [Remaining work before marking ready]
```

When creating PRs with `av pr`, also leave **inline review comments** on the PR for areas flagged in "what reviewers should watch for" — point reviewers directly to the relevant code.

## Branch Naming

Always prefix branches with `nil/` (e.g., `nil/feature-name`, `nil/fix-deploy-bug`).

## Commits

Conventional Commits. Format: `TICKET-ID type(scope): description`

Types: `feat` `fix` `refactor` `test` `docs` `chore` `ci` `perf` `build` `revert`

- Ticket prefix when known (e.g., `AUTO-490 feat(idi): add booking agent`). Omit if none.
- Always include a body — WHY not WHAT, 2-3 sentences.
- **NEVER add `Co-Authored-By` lines.**
- One logical change per commit. Present tense. No trailing period.
- Breaking changes: `feat!:` or `BREAKING CHANGE:` in footer.

## Before Committing

1. Run tests relevant to changes
2. Run linter if configured
3. Flag any uncertainty or assumptions made
4. Verify PR stays under 400 lines — split if not

## After Completing Work

Update the scope/plan doc if scope changed during implementation. Update the project CLAUDE.md codebase map if interfaces changed. This takes 30 seconds and saves future agents minutes of exploration.

## Pushing & Publishing

**NEVER push to origin or create PRs without explicit user approval.** Commits are local and safe — push freely there. But pushing, creating PRs, or any action visible to others requires the user to say "push it" or "create the PR."

**Never push directly to main.** Always work on a feature branch (`nil/*`) and create a PR.

## AWS Profiles

Always use the appropriate profile — never run AWS commands without one:
- **`dev-admin`** — default for all dev work (account 553015941472, ca-central-1)
- **`prod-admin`** — production (account 601699042842, ca-central-1)
- **`mgmt-admin`** — management account (account 681109473189)

Use `AWS_PROFILE=dev-admin` prefix or `--profile dev-admin`. If unsure which profile, ask.

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
