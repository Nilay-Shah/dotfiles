---
name: idi-patient-id-not-phi
description: "IDI patient_id is a Radiant-internal unique ID, NOT PHI — safe to log unredacted"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 767553e8-8460-41f2-834f-5a1ab4539a54
---

In IDI, `patient_id` is an opaque Radiant-internal unique identifier. It is **NOT PHI** and is safe to log unredacted (e.g. `activities.py` booking/heartbeat logs). The AUTO-698 / AUTO-817-cleanup bullet asking for a `redact_patient_id` helper is therefore invalid — don't redact it.

This overrides the generic "patient_id is PHI" line in the global self-review rules for the IDI tenant specifically.

Contrast: [[idi-call-id-is-phi]] — `call_id` == LiveKit room_name == the caller's phone number, which IS PHI. Real PHI to keep out of logs: names, DOB, phone numbers (incl. call_id), OHIP/health-card, and transcript/message content. The genuine "PHI in logs" audit (AUTO-698) targets transcript content (`conversation_item_added`, `user_input_transcribed`, transcript persistence), not patient_id.
