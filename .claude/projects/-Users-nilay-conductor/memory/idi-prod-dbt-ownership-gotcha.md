---
name: idi-prod-dbt-ownership-gotcha
description: "Manual prod dbt builds create human-owned UC objects that the hourly SP can't CREATE OR REPLACE — silently fails the prod pipeline"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5fd69b24-1f18-4fd2-b586-b8369271aba3
---

The conductor-analytics prod hourly dbt job (`conductor-analytics-dbt-pipeline-hourly-prod_cac1`, Databricks job 528441821118600) runs as service principal **`data-engineers-dbt-runner`** (`e6aff8db-c90b-4e42-8d67-c2805a6e3228`), which has ALL PRIVILEGES on the prod catalogs.

**The gotcha (hit 2026-06-18):** enabling idi in prod (`idi_enabled=true`) made every hourly run FAIL with `PERMISSION_DENIED: User does not have MANAGE on Table conductor_prod_cac1_idi...`. Root cause was NOT a missing grant — it was that someone (nilay) had run a manual prod `dbt build` as themselves earlier, so all 6 idi objects were owned by `nilay@pocket.health`. The hourly SP can create NEW objects but cannot `CREATE OR REPLACE` ones owned by another principal, even with catalog-level ALL PRIVILEGES. CMI models still built (PASS=67) but the one idi failure made `dbt build` exit non-zero → whole job red, idi tables never refreshed. Silent: CMI data stayed fresh so nobody noticed; only DD job-failure alerting (if wired) would catch it.

**Fix applied:** `ALTER TABLE/VIEW ... OWNER TO \`<SP appId>\`` for the 5 managed tables; the VIEW transfer is blocked for non-metastore-admins ("can only transfer ownerships for views to groups the owner is a member of") so DROP the view instead and let the SP recreate it. Then `databricks jobs run-now`. Verified: PASS=75 ERROR=0.

**Side effect:** transferring ownership to the SP means the previous human owner LOSES access — the prod idi catalog grants list only the SP, so `nilay` can no longer SELECT the idi tables. If humans/BI need to read `conductor_{dev,prod}_cac1_idi`, a SELECT grant to a group must be added (pre-existing under-provisioning, not caused by this).

**How to apply:** never run manual prod `dbt build` as a human against shared catalogs — run as the SP, or `--exclude` the affected models. When a prod dbt model fails on MANAGE/ownership, check object owner with `DESCRIBE EXTENDED` before assuming a grant is missing. Same provisioning-gaps-surface-late theme as [[idi-cloud-provisioning-gaps]].
