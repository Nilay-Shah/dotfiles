---
name: idi-cloud-provisioning-gaps
description: IDI cloud (EKS) infra was provisioned piecemeal — worker role keeps missing grants that surface only on real calls
metadata: 
  node_type: memory
  type: project
  originSessionId: 85b7df09-5357-4d8f-ac9a-b83195bd50f8
---

The IDI cloud path (EKS Temporal worker, `role-{dev,prod}-cac1-idi-worker`) has been provisioned incrementally, and each missing IAM/infra grant only surfaces when a real cloud call exercises it (the team historically tested via the local rig with `.env`, so dev-cloud gaps went unnoticed). Recurring instances:

- **RDS IAM + DATABASE_URL** missing on the dev worker → bookings died at first persistence activity. Fixed: conductor #3636 + infra #242.
- **Bedrock InvokeModel** missing on dev+prod worker → `IDISummarize` AccessDenied, post-call summaries silently NULL (~220/48h prod). Fixed live + infra PR #246 (adds `bedrock-access` mirroring `kmh_worker_bedrock`). Confirmed 2026-06-18.

**Why:** the worker dispatches activities (persistence, summarize) that need grants the voice-agent module already has, but the worker role was scoped minimally and grows reactively.

**How to apply:** when adding a worker activity that calls an AWS service (Bedrock, RDS, S3, SM), check `terraform/environments/{dev,prod}/...idi*.tf` worker role FIRST — and add to BOTH envs, not just where the error shows. Mirror the equivalent `kmh_worker_*` or `voice-agent-iam` grant. Related: [[auto-706-wide-events-plan]], [[idi-call-id-is-phi]].
