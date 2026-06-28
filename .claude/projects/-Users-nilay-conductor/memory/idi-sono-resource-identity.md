---
name: idi-sono-resource-identity
description: "IDI sono = dedicated resource US 0 (id 346, TimeScale 10) at Spadina; detect by resource identity, not the SONO header (which is GUI-only)"
metadata: 
  node_type: memory
  type: project
  originSessionId: ea7e3865-fe40-421e-b42f-7ac3d5fea5f7
---

IDI "sono" (physician-supervised, pregnancy/obstetric ultrasound; Rachel: done by a physician ~1 day/week, 10-min slots, providers Dariia/Sonia alternate) is booked into a **dedicated Radiant resource** at SPADINA ULTRASOUND (clinic 2): `ResourceID=346, ResourceName="US 0", TimeScale=10` (regular rooms US 1/2/3 = ids 12/11/10, TimeScale 20).

Verified by read-only prod probe (2026-06-19, AUTO-869):
- `GetDailyResources` returns US 0 **only on sono days** (absent on non-sono weeks).
- US 0's open sono cells come back as ordinary **status 6** from `SearchResourceSchedule` — so they surface through the normal typed slot search.
- The green GUI header `SONO / DR WARDEN / DARIIA` is **GUI-rendered only — NOT in any WCF response**. `GetCalendarView` roster rows carry plain tech names (`SONIA`, `DARIIA`); searching for "SONO" text in WCF data returns nothing. So **detect the sono row by resource identity (name "US 0" / TimeScale 10), never by header text.**
- `GetCalendarView` quirk confirmed: windows >5 days drop the AllDay/status-21 roster rows (and it returned zero rows for the target Thursday even within a 5-day window) — unreliable for sono detection anyway.

**Latent bug this exposes:** on a sono day US 0 is in the modality-3 (`service_category_id=3`) resource set with status-6 cells and no rostered tech, so the current booking flow can offer/book a regular ultrasound caller into the physician's sono row as a tech-less fallback. The AUTO-869 symmetric filter (sono exams keep only US 0; regular US exams exclude US 0) fixes it. Feature logic is cloud/workflow-side — `get_daily_resources` already returns `ResourceName`+`TimeScale`; `_find_qualified_resources` (`workflow.py:1121`) just stops discarding the name. **Caveat (corrected):** no on-prem *logic* change, but `locations.py` now imports the new `sono.py`, and the on-prem Radiant worker imports `locations` — so the hand-maintained vendored mirror at `apps/tenant-idi/scripts/windows-deploy-package/src/.../phone_booking/` must include `sono.py` or a redeploy ImportErrors. AUTO-869 syncs it (the mirror had ALSO silently drifted on prior PRs — was missing `UPSTREAM_UNAVAILABLE_SYSTEM` + `KNOWN_LOCATIONS`; full-copy of `locations.py` cleared that too). The currently-running worker is unaffected (no redeploy needed for sono to work). See scope `2026-06-19-idi-sono-booking`.
