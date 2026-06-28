---
name: idi-sono-exam-definition-unverified
description: "FIXED (branch nil/idi-sono-sonohysterography, pending PR) — IDI \"sono\" / US-0 books ONLY sonohysterography, NOT obstetric; AUTO-869 mis-modeled it; obstetric now routes to a regular US"
metadata: 
  node_type: memory
  type: reference
  originSessionId: ea3ef080-c962-48c6-9a6e-6a3430a93104
---

CONFIRMED by Rachel (2026-06-22): the US-0 / "SONO / DR WARDEN" room books
**"Only sonos" = sonohysterography**, NOT obstetric. Obstetrical ultrasound is a
SEPARATE IDI service. AUTO-869 + the prep-naming commit (37beb936f, now merged in
#3922) mis-modeled US-0 as obstetric/full-bladder — a live clinical bug.

**FIX SHIPPED TO PROD (2026-06-22)** — AUTO-869. Conductor PR ph-conductor/conductor#3938
merged to main (squash `760fcaea9`). conductor-tools scenarios PR
ph-conductor/conductor-tools#17 (branch `nil/idi-synth-scenarios`). Deployed: dev auto on
merge; **prod via deploy PRs #3945 (worker) + #3944 (voice-agent)** merged → ArgoCD rolled
prod idi-worker + idi-voice-agent to `1a77c219c` (verified live). On-prem prod Radiant
worker redeployed (nilay cp'd src/+vendor/+lib/+pyproject, restarted, clean logs). So the
full prod path (cloud worker+voice-agent + on-prem) has the fix.
Rig-validated end-to-end (5 synthetic calls + VM run_local logs + ElevenLabs transcripts):
sono→US-0 Thu 10-min cell w/ no-bladder prep; obstetric→regular US Tue 20-min cell w/
full-bladder prep; multi-exam defers the sono. Decision taken: obstetric =
**option (b), a regular bookable US** (not escalate).
Deploy mechanics learned: idi cloud workers deploy via GHA (deploy-temporal-worker.yml →
idi maps to default `worker`; deploy-idi-voice-agent.yml) on push-to-main = DEV (direct
commit bump); PROD = manual `workflow_dispatch environment=prod` which opens a deploy PR
that must be merged → ArgoCD. Local rig uses LOCAL Temporal (localhost:7233) + Postgres
5433, NOT Temporal Cloud — so cloud idi-worker is irrelevant to the local rig; only the
LiveKit voice dispatch matters (cloud idi-voice-agent must be 0 so the local voice_worker
gets the call). What landed:
- `sono.py` (ON-PREM → mirrored + **requires VM redeploy**): `SONO_EXAM_PATTERNS`
  narrowed to `{sonohyster, hysterosono, saline infusion, saline sono}` + a
  word-anchored bare-"sono" guard (`\bsono\b`, so it can't catch
  sonogram/sonography/sonographer/ultrasonography). Obstetric/pregnancy/fetal dropped.
  `is_sono_resource` / US-0 identity UNCHANGED ([[idi-sono-resource-identity]]).
- `exam_config.py` (cloud): OB family (ob/obstetric/obstetrics/pregnancy + new `fetal`
  alias) → `prep_key="ultrasound-obstetric"`, `required_skill="obs"`, label OB, 40-min.
  These OB configs were effectively DEAD before (is_sono_exam short-circuited them).
- `prep_resolver.py` + new `prep_instructions/ultrasound-sonohysterography.md` (cloud):
  `_SONO_PREP_KEY` → `ultrasound-sonohysterography` (NO full bladder, full meal,
  400 mg ibuprofen/acetaminophen ~1h before, sanitary pad). `ultrasound-obstetric.md`
  kept for obstetric. Display names split obstetric vs sonohysterography.
- `stt_factory.py` (cloud): added "sonohysterography" keyterm (rare word, easily
  mistranscribed to "sonography").
- `_filter_and_tier_slots` symmetry verified: sono keeps only US-0; obstetric (now a
  regular US) is excluded from US-0 like every other US.

**Non-obvious finding:** the skill sheet / `SonographerSkills` already has a dedicated
**`sono` boolean column** (held by ~5 techs), DISTINCT from `obs` (held by ~everyone)
and `nt`. This independently confirms sonohysterography ≠ obstetric. US-0 routing
SKIPS credential gating (membership IS the gate), so the `sono` skill column is NOT
wired to US-0 routing — left untouched, out of scope.

**Still TODO (separate, flagged to user):** conductor-tools PR #16 uses "pregnancy
ultrasound" as the sono term in `multi-exam-sono-plus-us` / `book-sono` scenarios —
must switch to "sonohysterography" (separate repo at /Users/nilay/conductor-tools).
Rig validation (costs $, needs VM re-cp of sono.py/locations.py) not yet run.
