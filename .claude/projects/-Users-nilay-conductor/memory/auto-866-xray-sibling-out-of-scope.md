---
name: auto-866-xray-sibling-out-of-scope
description: AUTO-866 mid-registration x-ray sibling trigger is out of scope by IDI architecture; track separately, not a one-line fix
metadata:
  type: project
---

AUTO-866 mid-registration x-ray sibling trigger is OUT OF SCOPE by architecture. IDI AgentTasks (CreatePatientTask etc.) run a narrowed `@function_tool` surface that excludes `start_xray_walkin`, and there is NO global/deterministic intent interrupt — task escapes are explicit per-task tools (`switch_to_returning`) routed on the `self.complete()` result.

**Why:** A mid-registration x-ray walk-in interrupt would need a new escape tool on every AgentTask + a new completion-result type + supervisor routing to `start_xray_walkin` — which risks the `update_tools()` / mid-call-handoff anti-patterns the IDI CLAUDE.md forbids.

**How to apply:** Track AUTO-866's mid-registration x-ray trigger as separate, scoped work — it is not a one-line fix. Do not wire it as a mid-call handoff.

Migrated from `bd remember` (key `auto-866-mid-registration-x-ray-sibling-trigger`) during the bd → native-memory consolidation.
