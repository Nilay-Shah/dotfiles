---
name: idi-call-id-is-phi
description: "IDI runtime call_id is now room.sid (PHI-free); the caller phone is room_name / calls.session_id (PHI). The earlier call_id==phone Datadog leak has been fixed."
metadata:
  node_type: memory
  type: reference
  originSessionId: 39d08035-d4be-4bc1-94ae-bee8d050906b
---

**Updated 2026-06-23 (AUTO-874 doc audit):** the room.sid migration described in the historical note below has SHIPPED. Verify against `libs/conductor/shared-idi/src/idi_shared/persistence/models.py` + `phone_booking/voice_agent.py` / `voice_tools.py` before asserting.

Current code (`voice_agent.py` `IDIVoiceContext(call_id=lk_session_id, room_name=room_name, lk_session_id=lk_session_id, ...)`; `voice_tools.py:397` ToolState `call_id`) sets the runtime `call_id` to `lk_session_id` (== `room.sid`):

- **PHI-free:** `call_id` / `lk_session_id` / `room.sid` — the runtime correlation key, what capability tokens bind to, what flows to Datadog. NOT a persisted DB column.
- **PHI:** the caller phone is in `room_name`, persisted as **`calls.session_id`**. Never log it, never join on it.
- `call_events.call_id` is a UUID FK to `calls.id` — safe to join on.
- Patient identity persists as `caller.patient_ref` (eager-loaded via `call.caller`) — NOT PHI ([[idi-patient-id-not-phi]]).

**Historical (pre-fix, ~2026-06-15):** `call_id` used to equal `room_name` (the LiveKit room name, which embeds the caller phone on prod SIP dispatch) and was leaking caller phone numbers into Datadog — flagged as a leak to FIX since Datadog is not PHI-permitted. That fix is the room.sid migration now in place. See [[auto-706-wide-events-plan]].
