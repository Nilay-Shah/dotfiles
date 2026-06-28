---
name: idi-sip-dispatch-empty-timeout
description: "IDI dev+prod SIP dispatch rules now have empty/departure timeouts set (LiveKit-side, not in repo) to auto-GC abandoned rooms"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0f3d1bc2-0a00-4958-9472-3253e15aa6ec
---

As of 2026-06-19, both IDI SIP dispatch rules carry room GC timeouts, set via `lk sip dispatch update` (LiveKit Cloud config — NOT in any repo, so not derivable from git):
- dev `idi-dev-inbound-dispatch` (`SDR_55inQ26wKpWp`) and prod `idi-prod-inbound-dispatch` (`SDR_nE3AHkN63yqp`): `emptyTimeout=60`, `departureTimeout=20`.

Why: prod was leaking "zombie" rooms — caller hangs up, agent session closes + workflow completes, but the LiveKit room is never deleted (LK Console shows ACTIVE for hours; RoomService returns `not_found` so `lk room delete` can't touch them). Root cause: `delete_room()` only ran on the agent-initiated sign-off path, not on caller-hangup, and no room timeout was configured. The timeouts are the belt-and-suspenders; the code half (`delete_room()` on every `run_voice_agent` exit) is in PR #3827 ([[auto-706-wide-events-plan]] is unrelated). Existing ghost rooms from before the fix need a LiveKit-support purge — timeouts only prevent new ones. Updating a dispatch rule is in-place (preserves the rule id/createdAt) and does NOT affect in-progress calls (room_config applies at room creation).
