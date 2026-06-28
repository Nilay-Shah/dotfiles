---
name: git-pr-workflow
description: Personal stacked-PR / worktree / PR-creation workflow with the av CLI — the av command dances (incl. the post-squash-merge reparent sequence + the av.db diagnostic), git absorb, git rerere, worktree create/cleanup, and the PR description template + inline-comment practice. Use when creating/stacking/restacking PRs, reparenting after a squash-merge, managing git worktrees, or writing a PR description.
---

# Git / PR / Stacking Workflow

Reference for stacked-PR work, worktrees, and PR conventions. Generic `av` usage is in the `av-cli` skill; this holds my conventions + the specific hard-won dances. The always-on rules (draft PRs, `nil/*` branches, never-push-without-approval) stay in CLAUDE.md.

## Worktree Commands

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
