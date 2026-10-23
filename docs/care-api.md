# Shared care API, version 1

Status: implemented development contract. Not a certified health-record service.

## Identity and access

`POST /v1/auth/register` accepts `{email,password,name}` and creates a patient only. Passwords are bcrypt hashes; passwords must contain 12–72 UTF-8 bytes. `POST /v1/auth/login` verifies the hash. Both return `{token,user:{id,name,role}}`; web also receives an HttpOnly SameSite=Strict cookie scoped to `/v1`, Secure in production. Tokens contain 256 random bits, are stored by SHA-256 digest, expire after 12 hours, and can be revoked with `POST /v1/auth/logout`. Native uses a bearer token. `GET /v1/me` verifies the current session.

Clinician accounts require operator provisioning. `GET /v1/patients` lists only self or explicitly granted patients. Every record/photo/export operation rechecks the subject–patient relationship. Invitation endpoints: clinician `POST /invitations`; authenticated `POST /invitations/preview` with `{code}`; patient `POST /invitations/accept` after reviewing the clinician. Codes are single use and expire after 15 minutes. `GET /care-team` and `DELETE /care-team/:subject` provide patient access review/revocation. Current grants cover all records; practice identity, granular scopes and proxies are not implemented.

## Versioned records

`GET /v1/patients/:patient/:kind` returns current records in database insertion order. `?history=true` returns all revisions. Allowed capture kinds are labs, symptoms, weekly-checkins, medications, vitals, meals, messages, requests, notes, appointments, care-plans and administrations. Account-deletion requests are also durable records.

`POST` to the same path accepts:

```json
{
  "id": "client-generated-UUID",
  "expectedVersion": 0,
  "fields": {"analyte":"Free T4","result":"<0.01","unit":"ng/dL","source":"Patient-entered report"}
}
```

Response: `{id,patientID,kind,version,recordedAt,authorID,fields}`. Author, patient, version and UTC entry time are server-owned. An observation date remains separately in `fields`. Missing values are absent/blank; no healthy defaults or zero substitutions are supplied.

The stable ID and expected version identify a write attempt. An exact same-author replay returns the saved version; changed input with a stale version returns 409. Corrections append revisions transactionally. Sent messages cannot be overwritten. A signed note cannot be overwritten: create an amendment linked to its ID. New ordinary notes require `visibility: patient`; legacy private notes are not imported. A clinician can respond to a patient request without changing its original question. Patient-authored notes and arbitrary role selection cannot produce signed clinical documentation.

The flexible `fields` envelope has per-kind validators, not a complete normalized clinical terminology schema. It needs refinement before interoperability or clinical release: panel IDs, analyte codes, assay identifiers, comparator representation, typed schedules, comprehensive provenance, structured vital contexts and validated conversions remain incomplete.

## Photos

First save a meal with a stable ID, actual meal date/time, description, and `hasPhoto:true`. `POST /v1/patients/:patient/meals/:meal/photo` accepts `{imageBase64}`. Only the meal's author can attach its first photo; identical retries succeed, different replacements conflict. A new meal ID is needed for a different photo in this version.

JPEG uploads are bounded to 8 MB and 8192×8192 pixels, checked structurally, and APP1/EXIF/XMP, APP13/IPTC and comment blocks are stripped. Clients render a normalized JPEG before upload. This does not claim a complete image-security scanner. `GET` on the same path returns `{mealID,mimeType,imageBase64}` only after current authorization. Server caches are disabled; media are not in the public directory. Native queues photos in protected account-scoped storage; web photo uploads currently require the form to remain open until success.

## Export and deletion initiation

`GET /v1/patients/:patient/export` returns schema version, export time, all record revisions and uploaded meal JPEGs. Missing pending photos are omitted; no data from other patients or security/session tables are exported. This is a machine-readable JSON export, not a finished visit-brief PDF.

`POST /v1/account-deletion` with a stable UUID record envelope stores a patient request. It does **not** erase the account. Identity review, operator workflow, retention determinations, notification/token/media cleanup and a response policy still need implementation.

## Storage and failure behavior

`CareDatabase.init` runs additive `CREATE TABLE IF NOT EXISTS` schema setup for accounts, sessions, grants, invitations, revisions, audit, and meal_photos. SQL values use bindings. Revision writes and invitation consumption are transactions. Errors propagate; there is no memory fallback that reports cloud success. Operational backups must include the SQLite database consistently with its WAL; restore drills have not been completed.

The native queue is persisted with complete file protection and excluded from device backup. Rejected entries remain editable; conflicts require review of the server revision. Account state is cleared on logout. Offline session restoration after process restart currently requires reconnecting to verify the token; offline continuity is therefore partial.

Both active clients poll at 15-second intervals and use cancellation/account identity checks. Polling is a development fallback, not a realtime SLA. Browser patient workspaces are keyed by user and patient. Full message read receipts, attachment moderation, server pagination, cursor recovery, thread participants and operational response policies remain incomplete.

## Release blockers

Rate limiting, MFA, account recovery/verification, stronger email validation, credential-rotation workflows, database encryption/key operations, backup/restore drills, authorization scope granularity, production monitoring, consent/vendor terms and legal note exceptions are not implemented. Do not describe the service as production-secure, HIPAA certified, or release-ready.
