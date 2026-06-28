---
name: idi-local-rig-dispatch-contention
description: "Local IDI rig — scale dev idi-voice-agent to 0 first, or inbound calls route to the cloud worker"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 767553e8-8460-41f2-834f-5a1ab4539a54
---

The local IDI rig's `voice_worker` registers on the SAME dev LiveKit Cloud project (`idi-m2pkn3sz`, agent_name `idi-dev-voice-agent`) as the dev EKS `idi-voice-agent` deployment. LiveKit dispatches an inbound call to ANY registered worker — so with dev up, the call lands on a cloud replica (which writes to the dev DB) and the local worker never gets the job; your **local DB poll finds NO call row**.

Fix before a rig test: `AWS_PROFILE=dev-admin kubectl --context dev-cac1 -n idi scale deploy idi-voice-agent --replicas=0`, wait for `0/0`, then fire. There is NO HPA/KEDA on it. **ArgoCD resyncs it back to 2** on its next sync, so (a) you needn't manually restore it, but (b) you MUST re-scale to 0 before EACH rig test. Confirm dispatch hit local via the voice_worker log line `received job request`.

⚠️ The kube current-context defaults to **`prod-idi` (PRODUCTION)** — ALWAYS pass `--context dev-cac1` explicitly; a blind `kubectl scale` would take down prod voice. See [[idi-nonbookable-faq-needs-prompt-grounding]].
