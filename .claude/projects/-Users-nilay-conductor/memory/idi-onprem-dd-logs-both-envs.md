---
name: idi-onprem-dd-logs-both-envs
description: "on-prem VM runs BOTH dev+prod Radiant workers, but setup-datadog.ps1 writes a single-env DD log source (overwrites) — need a both-env conf + agent restart"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0f3d1bc2-0a00-4958-9472-3253e15aa6ec
---

The on-prem VM (host `PocketHealthPC`) runs BOTH `IDIRadiantWorker-Dev` and `IDIRadiantWorker-Prod` NSSM services. But `setup-datadog.ps1` (in `windows-deploy-package`) writes `C:\ProgramData\Datadog\conf.d\idi_radiant.d\conf.yaml` for ONE env (`DEPLOY_ENV` from that package's `config.env`) via `Set-Content` — it OVERWRITES, and its docstring says "run once per VM" (assumes one worker). So running it from the dev package then the prod package clobbers the other env's log source — only the last-run env ships logs.

To get BOTH dev+prod on-prem logs into Datadog, the conf must list all 4 file sources (dev `stdout`/`stderr` → `env:development`, prod `stdout`/`stderr` → `env:production`, all `service:idi-radiant-worker`, `source: python`). Log paths: `C:\logs\idi-radiant-worker-{dev,prod}\{stdout,stderr}.log`. After editing the conf, you MUST `Restart-Service datadogagent` — the agent only loads conf.d changes on restart (this was the multi-hour gotcha: the file was correct but the running agent had the stale pre-edit config), and restart the worker so it emits a fresh line (agent tails from end). Verify via `agent.exe status` → Logs Agent → `idi_radiant`: all 4 sources `Status: OK`, prod `Bytes Read` > 0. Confirmed working 2026-06-19.

Same single-env overwrite limitation affects the OpenMetrics scrape (`conf.d/openmetrics.d/idi_radiant.yaml`, dev 8086 vs prod 8087). Follow-up: fix `setup-datadog.ps1` to emit BOTH env sources (logs + openmetrics) so this isn't hand-maintained. Pairs with the F service-name fix (PR #3827) + AUTO-706 env-tag. See [[idi-sip-dispatch-empty-timeout]] for the other on-prem-adjacent IDI fix from that batch.
