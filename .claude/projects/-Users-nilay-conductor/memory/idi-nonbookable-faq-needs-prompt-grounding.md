---
name: idi-nonbookable-faq-needs-prompt-grounding
description: "IDI agent fields non-bookable/FAQ requests conversationally at the greeting — deterministic render changes don't reach callers unless ALSO grounded in the prompt"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 767553e8-8460-41f2-834f-5a1ab4539a54
---

The IDI voice agent answers "obviously can't book this" requests (mammogram, doppler, non-Spadina location) and FAQs **conversationally at the greeting — 0 tool calls** — from its prompt knowledge, instead of routing into `start_booking` → the deterministic render path. So a change made ONLY in `render_unsupported_request` (or any tool-side render) is **bypassed**, and the LLM falls back to stale phrasing (e.g. the mammogram "connect you with our team" line that survived a render-only fix and failed the rig).

Working pattern (x-ray duration, mammogram redirect, Coxwell location all do this): the fact lives ONCE in the catalog/renderer (single source) AND is grounded into the greeting prompt (`idi_voice_agent._GREETING_SECTION` / `_PHASE_SECTIONS`) from that same renderer — e.g. `render_mammogram_redirect()` feeds both the `NON_BOOKABLE_EXAM` render branch and `_MAMMOGRAM_GROUNDING`. **One source, two surfaces** (deterministic render backstop + prompt grounding). You can't force the LLM to call a tool, so grounding is required for the conversational path — it's not prompt cruft, it's the same single-source discipline. Rig-verified 2026-06-18. See [[idi-local-rig-dispatch-contention]].
