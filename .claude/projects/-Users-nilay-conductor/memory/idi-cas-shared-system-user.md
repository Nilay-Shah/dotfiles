---
name: idi-cas-shared-system-user
description: "IDI booking CAS owner-predicate uses a shared SYSTEM_USER_ID=567, so it can't distinguish two concurrent voice callers from each other"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3f37f9d6-38cb-4932-b1b9-807286b8646d
---

In `apps/tenant-idi/.../phone_booking/activities.py`, every agent booking writes
the same module constant `SYSTEM_USER_ID = 567` ("AUTOBOOKING") as the slot's
`SystemUserId`. The hold/book/block/release compare-and-swap predicates key on
this id, so the owner check distinguishes the voice agent from a **front-desk
clerk** (different id) but **NOT two concurrent voice callers from each other**
(both write 567).

Consequence: the loser of a same-cell race between two callers no-ops its UPDATE
but a status+SystemUserId re-read would falsely confirm it. Fixed at the BOOK
verify by ALSO re-reading `PatientId` (`_slot_owner`) — the booked PatientId is
the other caller's, so the loser fails closed (review of PR #3922, bd auto-cp-688).
The HOLD verify still can't tell two agents apart (both see status 23 + SU 567),
but that's harmless because the book verify catches the loser.

**Why:** any future CAS / concurrency work on IDI booking must remember the
owner id is shared across all agent writes — SystemUserId alone is never enough
to prove "this is OUR booking" against another agent call; pair it with PatientId
(or another per-booking discriminator).

**How to apply:** when reasoning about IDI hold/book/cancel races, treat
`SYSTEM_USER_ID` as a constant, not a per-call identity. Related: [[idi-patient-id-not-phi]].
