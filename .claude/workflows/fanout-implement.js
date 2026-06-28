export const meta = {
  name: 'fanout-implement',
  description: 'Fan out one implementer per work-item in isolated worktrees, verify each against the contract before it may merge, serially merge in dependency order into one named integration worktree, run the full test suite, run a pre-PR review pass, then prune the scratch worktrees. Architect + human gates live in the calling skill, not here.',
  phases: [
    { title: 'Implement', detail: 'one worktree-isolated agent per work-item, each commits to its own branch' },
    { title: 'Verify item', detail: 'a skeptic checks each item against contract + spec before it may merge; one auto-redo on failure, else flagged' },
    { title: 'Merge', detail: 'serial dependency-ordered merge of verified items into one named integration worktree' },
    { title: 'Test', detail: 'run the full test suite on the integration branch' },
    { title: 'Pre-PR review', detail: 'code-review + simplify + arch sanity + impl sanity, fanned out by lens (budget-gated)' },
    { title: 'Clean up', detail: 'remove the disposable wf_* scratch worktrees; branches and the named integration worktree persist' },
  ],
}

// The Workflow tool may hand `args` over as a parsed object OR (in the Claude Code CLI) as a
// JSON string. Normalize once so the rest of the script reads fields the same way either way.
const parsedArgs = typeof args === 'string' ? JSON.parse(args) : (args || {})

// Model per stage. Defaults to Opus everywhere; the calling skill passes overrides in as
// args.models ONLY when you ask to tier a stage down — no separate config file to maintain.
const MODELS = {
  implement: parsedArgs.models?.implement || 'opus',
  verify:    parsedArgs.models?.verify    || 'opus',
  merge:     parsedArgs.models?.merge      || 'opus',
  test:      parsedArgs.models?.test       || 'opus',
  review:    parsedArgs.models?.review     || 'opus',
  cleanup:   parsedArgs.models?.cleanup    || 'opus',
}

const repo     = parsedArgs.repoPath
const base     = parsedArgs.baseBranch || 'main'
const feature  = parsedArgs.feature || 'feature'
const contract = parsedArgs.sharedContract || '(no shared contract provided)'
const items    = parsedArgs.workItems || []
const integrationBranch   = `nil/${feature}-integration`
const integrationWorktree = `${repo}-${feature}-integration`   // named, NOT wf_<runid> — survives cleanup

// Skip the (optional) pre-PR review fan-out if the turn's token budget is nearly spent.
const REVIEW_FLOOR = 60_000

if (!repo)         return { error: 'args.repoPath is required' }
if (!items.length) { log('No work-items passed — nothing to do.'); return { error: 'no work-items' } }

// ---- schemas: validated at the tool layer, so agents retry until they match ----
const IMPL_SCHEMA = {
  type: 'object',
  properties: {
    id:                 { type: 'string' },
    branch:             { type: 'string' },
    status:             { type: 'string', enum: ['done', 'partial', 'failed'] },
    filesTouched:       { type: 'array', items: { type: 'string' } },
    testsAdded:         { type: 'integer' },
    contractViolations: { type: 'array', items: { type: 'string' } },
    summary:            { type: 'string' },
  },
  required: ['id', 'branch', 'status', 'summary'],
}
const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    passes:           { type: 'boolean' },
    contractAdherent: { type: 'boolean' },
    specMet:          { type: 'boolean' },
    issues:           { type: 'array', items: { type: 'string' } },
    detail:           { type: 'string' },
  },
  required: ['passes', 'detail'],
}
const MERGE_SCHEMA = {
  type: 'object',
  properties: {
    integrationBranch: { type: 'string' },
    mergedClean:       { type: 'array', items: { type: 'string' } },
    conflicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          items:      { type: 'array', items: { type: 'string' } },
          files:      { type: 'array', items: { type: 'string' } },
          kind:       { type: 'string', enum: ['syntactic', 'semantic'] },
          resolution: { type: 'string', enum: ['auto-resolved', 'flagged-for-human'] },
          detail:     { type: 'string' },
        },
        required: ['items', 'kind', 'resolution', 'detail'],
      },
    },
    summary: { type: 'string' },
  },
  required: ['integrationBranch', 'mergedClean', 'conflicts', 'summary'],
}
const TEST_SCHEMA = {
  type: 'object',
  properties: {
    passed:   { type: 'boolean' },
    command:  { type: 'string' },
    failures: { type: 'array', items: { type: 'string' } },
    summary:  { type: 'string' },
  },
  required: ['passed', 'summary'],
}
const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    lens: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['blocker', 'high', 'medium', 'low'] },
          title:    { type: 'string' },
          file:     { type: 'string' },
          detail:   { type: 'string' },
        },
        required: ['severity', 'title', 'detail'],
      },
    },
    summary: { type: 'string' },
  },
  required: ['lens', 'findings', 'summary'],
}
const CLEANUP_SCHEMA = {
  type: 'object',
  properties: {
    removed:        { type: 'integer' },
    branchesIntact: { type: 'boolean' },
    summary:        { type: 'string' },
  },
  required: ['removed', 'branchesIntact', 'summary'],
}

// ---- Stages 1+2 (pipelined, no barrier): each item is implemented in its own worktree,
//      then a skeptic verifies it against the contract + spec BEFORE it is eligible to merge.
//      One auto-redo on failure; still-failing items are flagged and kept out of the merge. ----
const processed = (await pipeline(
  items,
  it => agent(implementPrompt(it), {
    label: `impl:${it.id}`, phase: 'Implement', model: MODELS.implement, isolation: 'worktree', schema: IMPL_SCHEMA,
  }),
  async (impl, it) => {
    if (!impl || impl.status === 'failed') return { item: it, impl, verdict: { passes: false, detail: 'implementer failed' } }
    let verdict = await agent(verifyItemPrompt(it, impl), {
      label: `verify:${it.id}`, phase: 'Verify item', model: MODELS.verify, schema: VERDICT_SCHEMA,
    })
    if (verdict && !verdict.passes) {
      const redo = await agent(redoPrompt(it, verdict), {
        label: `redo:${it.id}`, phase: 'Implement', model: MODELS.implement, isolation: 'worktree', schema: IMPL_SCHEMA,
      })
      verdict = await agent(verifyItemPrompt(it, redo || impl), {
        label: `reverify:${it.id}`, phase: 'Verify item', model: MODELS.verify, schema: VERDICT_SCHEMA,
      })
      return { item: it, impl: redo || impl, verdict }
    }
    return { item: it, impl, verdict }
  }
)).filter(Boolean)

const mergeable = processed.filter(p => p.verdict?.passes)
const flagged   = processed.filter(p => !p.verdict?.passes)
log(`${mergeable.length}/${items.length} items verified clean; ${flagged.length} flagged for you`)
if (!mergeable.length) return { error: 'no items passed verification', flagged }

// ---- Stage 3: serial, dependency-ordered merge of the verified items into ONE named
//      integration worktree (not a wf_* scratch dir). Semantic conflicts are flagged. ----
phase('Merge')
const mergeOrder = topoSort(mergeable.map(p => p.item))
const merge = await agent(mergePrompt(mergeOrder), {
  label: 'merge:refinery', phase: 'Merge', model: MODELS.merge, schema: MERGE_SCHEMA,
})

// ---- Stage 4: run the real test suite inside the integration worktree. ----
phase('Test')
const test = await agent(testPrompt(), {
  label: 'test', phase: 'Test', model: MODELS.test, schema: TEST_SCHEMA,
})

// ---- Stage 5: pre-PR review, one lens per agent, read-only against the diff. Budget-gated. ----
let review = []
if (budget.total && budget.remaining() < REVIEW_FLOOR) {
  log(`Skipping pre-PR review — only ${Math.round(budget.remaining() / 1000)}k tokens left (floor ${REVIEW_FLOOR / 1000}k).`)
} else {
  phase('Pre-PR review')
  const LENSES = [
    ['bugs',     'Review the diff for correctness bugs ONLY — logic errors, edge cases, missing error handling, races. High-confidence findings only.'],
    ['simplify', 'Review the diff for reuse, simplification, dead code, and needless complexity. Quality only, not bugs.'],
    ['arch',     `Check the diff against the shared contract and design principles below. Flag bandaids, contract violations, and anything that fights extensibility or the intended system shape.\n\n--- shared contract ---\n${contract}`],
    ['impl',     `Check that the diff actually satisfies each work-item's spec / acceptance criteria. Flag anything partial, stubbed, or off-spec.\n\n--- work-items ---\n${items.map(it => `[${it.id}] ${it.title}: ${it.spec || ''}`).join('\n')}`],
  ]
  review = (await parallel(LENSES.map(([key, lens]) => () =>
    agent(reviewPrompt(key, lens), { label: `review:${key}`, phase: 'Pre-PR review', model: MODELS.review, schema: REVIEW_SCHEMA })
  ))).filter(Boolean)
}

// ---- Stage 6: prune the disposable wf_* scratch worktrees. Branches + the named
//      integration worktree persist, so this only removes clutter. Always runs. ----
phase('Clean up')
const cleanup = await agent(cleanupPrompt(), {
  label: 'cleanup', phase: 'Clean up', model: MODELS.cleanup, schema: CLEANUP_SCHEMA,
})

return {
  feature,
  resultBranch: integrationBranch,
  integrationWorktree,
  inspect: `the result is on branch ${integrationBranch} (checked out at ${integrationWorktree}). For a fresh copy elsewhere: git -C ${repo} worktree add ../${feature}-integration ${integrationBranch}`,
  implemented: processed.map(p => ({ id: p.item.id, branch: branchOf(p.item), status: p.impl?.status, passedVerify: !!p.verdict?.passes })),
  flagged: flagged.map(p => ({ id: p.item.id, why: p.verdict?.detail, issues: p.verdict?.issues || [] })),
  merge,
  test,
  review,
  cleanup,
}

// ============================ helpers ============================

function branchOf(it) { return `nil/${feature}-${it.id}` }

function topoSort(list) {
  const byId = new Map(list.map(it => [it.id, it]))
  const seen = new Set(), order = []
  function visit(it) {
    if (seen.has(it.id)) return
    seen.add(it.id)
    for (const dep of (it.depends_on || [])) if (byId.has(dep)) visit(byId.get(dep))
    order.push(it)
  }
  for (const it of list) visit(it)
  return order
}

function implementPrompt(it) {
  return [
    `You are implementing ONE work-item in an isolated git worktree of the repo at ${repo} (branched from ${base}).`,
    ``,
    `WORK-ITEM [${it.id}] ${it.title}`,
    it.spec ? `Spec:\n${it.spec}` : '',
    it.interface ? `Interface you must expose:\n${it.interface}` : '',
    (it.files && it.files.length)
      ? `Stay within these files/areas — touch nothing else (that keeps the parallel merge clean):\n${it.files.join('\n')}`
      : '',
    ``,
    `SHARED CONTRACT — honor these interfaces and data models exactly. Code against the contract, NOT against other work-items (their code is not present in this worktree):`,
    contract,
    ``,
    `DISCIPLINE (staff-swe / staff-sre):`,
    `- Verification: follow the method named in the shared contract — TDD (failing test first) for application code, or validate → plan → fmt for infrastructure. No unverified changes.`,
    `- No bandaids, no leftover stubs, no service locators / hidden globals. Build for extensibility per the contract.`,
    `- Errors handled explicitly. Comments explain WHY, not WHAT. No single-letter loop/except vars.`,
    `- Conventional Commits; body explains WHY. NO Co-Authored-By lines.`,
    ``,
    `WHEN DONE: commit to a branch named exactly "${branchOf(it)}". Do NOT push, do NOT open a PR. (Your worktree is disposable — the branch is what survives.)`,
    `Return the schema: branch name, status, files touched, tests added, any contract violations you were forced into, and a 1-2 line summary.`,
  ].filter(Boolean).join('\n')
}

function verifyItemPrompt(it, impl) {
  return [
    `Skeptically review the implementation of work-item [${it.id}] "${it.title}" on branch "${branchOf(it)}" in the repo at ${repo}.`,
    `Inspect the diff: \`git -C ${repo} diff ${base}...${branchOf(it)}\`.`,
    ``,
    `Your job is to find why this should NOT merge. Check:`,
    `1. Contract adherence — does it match the agreed interfaces and DATA MODELS exactly?`,
    `2. Spec — does it actually meet the work-item's acceptance criteria below?`,
    `3. Quality — bandaids, leftover stubs, untested paths, swallowed errors?`,
    ``,
    `--- shared contract ---`,
    contract,
    ``,
    it.spec ? `--- work-item spec ---\n${it.spec}` : '',
    ``,
    `Default to passes=false if you find a real problem. Only passes=true if it genuinely honors the contract AND meets the spec.`,
    `Return the schema: passes, contractAdherent, specMet, the list of issues, and a concrete detail explaining the verdict.`,
  ].filter(Boolean).join('\n')
}

function redoPrompt(it, verdict) {
  return [
    `Your first attempt at work-item [${it.id}] "${it.title}" was REJECTED by a reviewer.`,
    `Check out the existing branch "${branchOf(it)}" in a worktree of ${repo} and FIX it — do not start over.`,
    ``,
    `Reviewer's verdict: ${verdict.detail}`,
    (verdict.issues && verdict.issues.length) ? `Specific issues:\n${verdict.issues.map(s => `- ${s}`).join('\n')}` : '',
    ``,
    `SHARED CONTRACT (honor interfaces + data models exactly):`,
    contract,
    ``,
    `Keep the verification discipline from the contract. Commit your fixes to the SAME branch "${branchOf(it)}". Do not push.`,
    `Return the schema.`,
  ].filter(Boolean).join('\n')
}

function mergePrompt(order) {
  const branches = order.map(it => `${branchOf(it)}  (item ${it.id}: ${it.title})`).join('\n')
  return [
    `Act as a serial merge queue (the "Refinery") for the repo at ${repo}.`,
    ``,
    `STEP 1 — create one clean, well-named integration worktree (this is the durable result the human inspects, NOT a throwaway):`,
    `- If anything already exists there from a prior run, remove it first: \`git -C ${repo} worktree remove --force "${integrationWorktree}"\` (ignore the error if it's absent).`,
    `- Create it fresh on the integration branch: \`git -C ${repo} worktree add -B ${integrationBranch} "${integrationWorktree}" ${base}\`.`,
    ``,
    `STEP 2 — working inside "${integrationWorktree}", merge these item branches INTO ${integrationBranch} IN THIS ORDER (dependency-sorted), one at a time:`,
    branches,
    ``,
    `After EACH merge: run the repo's fast build/test check. If it breaks, you've isolated the offending branch — record it as a conflict and continue with the rest where you can.`,
    `CRITICAL: when two branches make INCOMPATIBLE semantic changes to the same code, do NOT pick a winner / last-writer-wins. Record a {kind:"semantic", resolution:"flagged-for-human"} conflict with enough detail for a human to resolve. Only auto-resolve trivial syntactic conflicts (imports, adjacent additions).`,
    ``,
    `LEAVE the integration worktree in place when done. Local only — never push.`,
    `Return the schema: integration branch name, which items merged clean, the conflict list, and a summary.`,
  ].join('\n')
}

function testPrompt() {
  return [
    `Run the FULL test suite for the merged result, which is checked out at "${integrationWorktree}" (branch ${integrationBranch}).`,
    `Work inside that directory. Find the real test command (package.json scripts, Makefile, pytest, nx affected, etc.) — do not assume.`,
    `Return the schema: passed (bool), the exact command you ran, failing tests/areas, and a summary. Do not fix anything — just report.`,
  ].join('\n')
}

function reviewPrompt(key, lens) {
  return [
    `Pre-PR review, "${key}" lens, on branch "${integrationBranch}" in the repo at ${repo}.`,
    `Inspect the diff: \`git -C ${repo} diff ${base}...${integrationBranch}\`.`,
    ``,
    lens,
    ``,
    `Return the schema with lens="${key}". Each finding: severity, title, file, concrete detail. No filler. If clean, return an empty findings array and say so in the summary.`,
  ].join('\n')
}

function cleanupPrompt() {
  return [
    `Tidy up the workflow's disposable scratch git worktrees in the repo at ${repo}.`,
    ``,
    `Run \`git -C ${repo} worktree list --porcelain\`. Remove EVERY worktree whose directory basename starts with "wf_" — these are the per-item / scratch checkouts this workflow created, and the branches they hold (nil/${feature}-*) persist independently in the repo, so the worktrees are safe to delete.`,
    `For each one: \`git -C ${repo} worktree remove --force <path>\`. Then run \`git -C ${repo} worktree prune\`.`,
    ``,
    `Do NOT remove the main worktree. Do NOT remove the integration worktree at "${integrationWorktree}". Do NOT delete any branch.`,
    ``,
    `Confirm afterward:`,
    `- \`git -C ${repo} worktree list\` should now show only the main worktree + "${integrationWorktree}".`,
    `- \`git -C ${repo} branch --list 'nil/${feature}-*'\` must still list the item branches + ${integrationBranch}.`,
    `Return the schema: how many scratch worktrees you removed, whether the nil/${feature}-* branches all survive (branchesIntact), and a 1-line summary.`,
  ].join('\n')
}
