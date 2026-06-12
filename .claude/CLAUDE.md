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
- `av sync --push=yes --prune=yes` to sync a healthy stack (no merged branches still in the chain)
- `av sync --push=yes --prune=yes --rebase-to-trunk` to pull latest main into a healthy stack. **Never run this while a merged branch is still in the stack** — it replays the merged commits onto a main that already has them squashed = conflict storm.
- **After the bottom of a stack is squash-merged** (GitHub retargets the next PR to main; av.db doesn't notice):
  1. `git fetch origin --prune`
  2. `av switch <next-branch-down>`
  3. `av reparent --parent main` — fixes metadata and rebases; patch-id detection drops the now-squashed commits.
  4. `av sync --all --push=no --prune=yes` to delete the merged branch locally.
  5. `av pr` (single branch) or `av sync --push=yes --prune=yes` (still stacked) to force-push.
- **Diagnostic when av seems broken:** `cat "$(git rev-parse --git-common-dir)/av/av.db"`. If any `parent.name` points to a MERGED PR, do the reparent dance above — don't reach for more `av sync` variants.

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
5. Self-review the staged diff (see below) — catch your own smells before CodeRabbit does

## Self-review before commit

Re-read the staged diff (`git diff --staged`) before any non-trivial commit. The smells that keep slipping through if I don't pause:

- **Single-letter loop vars** (`p`, `r`, `i`, `e`, `ca`) in comprehensions or `except` blocks — repo rule, no exceptions
- **Task-graph rot in comments** — `T<digit>`, "Theme N", "Stack N", scope-doc paths, external issue numbers (`#5150`, AUTO-XXX). They're correct today and meaningless next month
- **Comments naming classes / files / specialists I just deleted** — grep my diff for the names of anything in the delete-list and scrub the survivors
- **Comments narrating the code below them** — if the function is `_speak_greeting` and the comment is "speaks the greeting", delete the comment
- **Variable referenced outside the branch that defined it** — mentally trace every code path before assuming a name is in scope
- **Sibling code paths with mismatched instrumentation** — if the success path records an outcome / tool_call event, the FAILED and timeout paths must too. Asymmetry hides incidents
- **PHI in log args without redaction** — `patient_id`, full names, DOB, phone numbers, OHIP / health-card. Log only outcome-shape (`success: bool`, `count: int`); route any unavoidable PHI through `shared.logging`'s redactor
- **LLM behaviour gated by prompt rules where a state check would be deterministic** — Haiku ignores prompts under load. If correctness depends on the model following an instruction, replace it with a tool-side state check or a typed gate
- **AgentTask / specialist coupling re-introduced** — IDI's pivot was AWAY from mid-call `return Agent(...)` handoffs. Don't add new ones; speak-then-transition is the pattern
- **New deps added casually** — pinned versions exist for a reason (Temporal sandbox, livekit-agents API drift, Bedrock model versions). Justify in the commit body if adding

If anything looks off, fix it in place before committing — don't ship for CodeRabbit to catch.

For commits >50 LoC of substantive change, dispatch the `pr-review-toolkit:code-reviewer` subagent on the staged diff and apply its findings before the actual commit. Cheap insurance.

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
