---
name: idi-create-intake-confirm-consolidation
description: Deferred IDI work — collapse the new-patient intake confirm into one code-emitted readback to kill the ~11s LLM-turn latency; the constraints a fresh agent must not regress
metadata: 
  node_type: memory
  type: project
  originSessionId: ea3ef080-c962-48c6-9a6e-6a3430a93104
---

Deferred follow-up from the IDI booking-correctness work (NOT yet ticketed — user
said hold in memory, 2026-06-21). The new-patient intake/confirm flow is the last
big LLM-orchestrated multi-turn holdout: collect name/DOB/sex/phone/HCN, then
reconfirm DOB + phone + HCN as SEPARATE Haiku turns, then a batch "all correct?",
then create — ~8–10 sequential turns. Each carries Bedrock latency; the gaps
produced ~11s silences in rig testing that an impatient caller bailed on. Evidence
it's LLM-turn latency, NOT Radiant: the VM log showed create_patient=77ms,
search_patient=228ms — every Radiant activity <250ms.

**Fix direction (regime-2 → regime-1):** replace the per-field reconfirm turns with
ONE code-composed demographics readback — same code-emit pattern as the
booking-confirmation beat (compose the whole "name, DOB, sex, phone, health card —
all correct?" in code, `session.say` + `StopResponse`, act on one yes/no). Fewer
turns → less latency, off-LLM.

**This is NOT AUTO-891.** AUTO-891 is DONE (the HCN HealthCardNo→Migration
persistence fix). The consolidation is unticketed; give it its own ticket
(AUTO/Conductor team, "Insight Diagnostic Imaging" project) when picked up.

**CONSTRAINTS a fresh agent MUST preserve (or it silently regresses hardening):**
AUTO-891 (create writes Migration+HealthCardVer split); OHIP MOD-10 check-digit
validation (`is_valid_ohip`) + invalid-OHIP single-reconfirm-then-flag; the
multi-turn HCN digit accumulator + the partial-HCN digit-count re-ask (commit
cb130af7b) + the create-loop cap (`create_loop_break_escalate`); dedupe-at-create;
name spell-and-confirm (AUTO-877/881); code-emit doctrine (no new strict_message,
no PHI in logs). Files: `create_patient.py` (the confirm sequence),
`facts/renderers.py` (add a demographics-readback renderer), tests
`test_create_patient_task.py` / `test_intake_create_flow.py`. Touches the
AUTO-891-hardened intake → TDD + rig-validate with a PATIENT persona. See also
[[idi-onprem-mirror-discipline]] is NOT needed (create_patient is cloud-only).
