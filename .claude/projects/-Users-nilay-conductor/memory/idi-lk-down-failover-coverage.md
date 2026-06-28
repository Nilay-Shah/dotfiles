---
name: idi-lk-down-failover-coverage
description: "AUTO-811 — Twilio trunk failover canNOT catch \"no agent\"; LK accepts SIP 200 OK independent of agent health, so the likely outage (our EKS deploy down) needs a health-gated inbound"
metadata: 
  node_type: memory
  type: project
  originSessionId: 931e6a57-f848-4f69-b018-d659e5e44598
---

AUTO-811 (IDI voice-agent failover when LiveKit/agent is down). The app-layer sub-scope (AUTO-811b, honest "scheduling system down" when Radiant is unreachable) shipped in PR #3573. The deferred ops track was scoped 2026-06-20.

**Key non-obvious finding:** Twilio Elastic SIP Trunk failover / Disaster-Recovery URL only fires when LK's SIP edge is *fully unreachable*. On inbound SIP, LiveKit answers (`200 OK`) and creates the room **independent of agent health** — there is no native LK setting to return SIP busy/503 when no agent is available (confirmed via LK docs). So the **most likely** outage — our own `idi-voice-agent` EKS deployment down (bad deploy/OOM/KEDA-zero) → caller in a silent room — is NOT auto-caught by Twilio, and NOT caught by an agent-side watchdog either (no agent process runs).

**Decided approach (scope: 2026-06-20-idi-lk-down-auto-failover.md):**
- **D (primary):** health-gated inbound — a Twilio Function probes LK mgmt API + worker availability on each call, dials the **general IDI reception line** if unhealthy. Twilio is hand-configured in the console (no Terraform), so D = Function source + console steps, not a repo PR.
- **C (complement):** agent-side `on("error")` + dead-air watchdog → cold SIP REFER to the **same general line**, for the sliver where the worker is registered but inference is silently dead.
- **Failover dest = general IDI line, NOT per-clinic.** Multi-clinic resolves the clinic from the called DID *inside the agent* — which is down in a failover. Replicating a DID→staff map in Twilio = a 2nd source of truth that drifts; a routing API would have to survive the outage. The central line is staffed to triage to any clinic, so infra-failure → general line; healthy-path business escalations stay per-clinic via `transfer_number_for`. New env var `IDI_INFRA_FAILOVER_NUMBER` (C) + Twilio Function env (D). Constraint: the general line must NOT Ooma-forward back into Twilio→LK (loop).
- **Dropped:** manual runbook (A), Twilio trunk DR-URL (B, redundant w/ D), all Layer-1 detection (DD monitor already exists; Slack hook + canary "not worth it" per nilay).
- Failover target reuses the existing in-call escalation destination — see the inert-failover comment at voice_tools.py ~4558 ("add it alongside the config when a fallback staff line exists").

Related: [[idi-local-rig-dispatch-contention]] (scale-to-0 trick for the dev outage drill), [[idi-sip-dispatch-empty-timeout]] (empty_timeout interplay during rollover).
