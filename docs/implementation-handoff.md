# Redesign implementation handoff — 2026-10-23

## Status

This is a substantial development foundation, **not completion of the master brief**. It replaces the active prototype entry points with shared record workflows and gates unsupported predictions. Important product work, device/browser evidence and clinical/operational release dependencies remain below. No hosted deployment or production patient migration was performed.

The working branch was `main` with a clean tree at the start. No applicable repository AGENTS.md was found. Source changes remain uncommitted for review.

## Implemented source

- Native root: `ContentView` → `CareRootView` → five-tab `MainTabView`/`CareTabs`. Original views remain in source for migration review, but the prototype login, severity/percentile and forecast screens are not routed from the active app.
- Native data: `CareStore` uses server-verified sessions, Keychain, account-scoped protected caches, a durable pending-write/photo queue, truthful sync labels and generation checks. A rejection does not pretend to be a cloud save. Pending records can be reviewed/corrected or explicitly discarded. Conflict revisions are retained on the server.
- Backend: `CareRecords`, `CareDatabase`, `CareRoutes`, `CareMedia`. Private SQLite; transactional revisions and invitation consumption; bcrypt passwords and expiring hashed session tokens; authorized records/photos/exports; access revocation; request responses; patient-visible notes; server-derived appointment instants; deletion-review requests.
- Web: canonical `Backend/Dashboard`. New `CarePortal`, forms, charts, photo viewer and CSS tokens use the shared API. Independent patient and clinician roles come from the server. Roster sorting is numeric, excludes cancelled/past appointments and uses stable name/ID ties. Old routes are either aliases to the authorized workspace, external provider search, or explicitly unavailable. They are not all distinct finished products.
- Meals: manual entries, optional native photo selection/confirmation, normalized JPEG upload, durable native drafts and authorized photo display on both surfaces. No invented kcal/micronutrients. Analysis jobs and AI summaries are not connected.
- Symptoms: custom anchored 0–4 diary, separate seven-day weekly recall, per-symptom native/web point plots, source-linked descriptive clinician draft summary and stale-source indication on web. This is a template, not an LLM-generated treatment recommendation or validated score.
- Reminders: durable acknowledged plans, separate categories, native permission handling, bounded calendar scheduling, pause/resume, generic lock-screen text, current-plan check on notification open, explicit taken/skipped logs, completion suppression and logout cleanup. See `reminders.md` for important limitations.
- Research: 73 verified files; frozen analysis plan, locked membership, full preprocessing artifact, honest held-out evaluation. Unsupported clinical forecasts remain unavailable.

## Native screen migration map

| Previous view | Active destination / status |
| --- | --- |
| Landing/Login/SignUp | `CareAccountView`, server registration/login; old local identity flow unused |
| Verification/ForgotPassword | Explicitly unavailable; server email/recovery integration still needed |
| Description/VerifiedUser | Today and account-context copy; no separate completed-home variants |
| Dashboard | Today measured records/tasks and actual sync state |
| Questionnaire | Five-step questionnaire opens after registration; Today/Track resume saved progress. Reuses structured record forms; optional context remains unknown when skipped |
| Summary/Prediction | Trends and shared notes; unsupported numerical forecasts gated |
| MedicationLog | Track medication records plus reminder center; full reconciliation/signed-plan workflow incomplete |
| Picture | Meals descriptions/photo import/history; camera and AI workflow incomplete |
| Profile/logout | Profile and settings with reminders, sharing, export and deletion-review initiation |

Old AppStorage/locally remembered profile data have not been assigned a verified server identity or reinterpreted. Old iron/calcium booleans and private notes are not silently migrated. Migration requires explicit clarification/review.

## Design implementation

Native semantic grouped surfaces and text colors support dark appearance; teal adjusts by appearance. `CareSection` uses 16 pt corners/padding, 20 pt page margins, consistent hierarchy and semantic text styles. Forms are single-column. Web `care.css` defines neutral canvas/surface/text/border/action tokens, 12 px cards, readable 16 px body text, contained tables, visible focus and a narrow layout. Core navigation removes pulsing rings, arbitrary progress, floating organs and rotating plates.

Charts use Swift Charts and ECharts 6.1 Canvas respectively. Measured lab values have actual collection dates; censored/unknown-date observations stay in the data list and are not plotted as exact results. Symptoms use discrete daily points. Data-table alternatives are present. No smooth interpolated hormone curves are drawn. Web unchanged polling does not replay lab animation. Chart completeness remains partial: native period controls, changing reference bands, clinician-target bands, small multiples across vitals, and full screen-reader chart testing remain outstanding.

## Checks and evidence

- Xcode baseline and subsequent native builds passed, including the current reminder/photo work after correcting a chart access-level error.
- Backend: existing five XCTest tests plus seven new Swift Testing tests passed. New tests cover restart durability, idempotency, history/conflicts, patient isolation, invitations/revocation, session revocation, exact messages, invalid inputs, private photo restart/revocation/metadata stripping, and reminder plan validation.
- `Scripts/check_care_api.py`: every collection route, meal collection/export and export isolation, separate synthetic HTTP sessions, patient-to-clinician message and reply, shared signed note, clinician request answer, backend process restart, revoked grants and logout. Result: `api-integration-result.json`. This does not establish the native-device/browser messaging acceptance test.
- `Scripts/check_roster.mjs`: passed upcoming order, cancelled/past exclusion, timezone offsets, missing dates and stable ties.
- Canonical Next.js production build passed. Existing unused legacy-component image/lint warnings remain; no blanket lint-disable was introduced.
- Simulator: a subagent observed readable signed-out login and registration on iPhone 17/iOS 27. The launch tool returned an inconsistent session error, and unexpected autofill/user interaction appeared. No account was submitted; the session was closed. Current-binary provenance, loading/errors, authenticated flows, dark/large text and VoiceOver were **not verified**. Registration captures contained personal autofill and must not be published.
- Browser: `Scripts/check_care_browser.mjs` passed in local Chrome with separate authenticated patient/clinician contexts: reviewed invitation, censored lab without invented dates/ranges, exact two-way messages, patient-visible signed note, 390 px overflow check, backend restart/session persistence and second-patient access denial. Synthetic screenshots/results are under `docs/qa`. This does not establish native messaging or full accessibility/device acceptance. The first run needed sandbox launch permission; subsequent failures exposed the collection-route bug and imprecise form names, both corrected.
- Full accessibility/contrast audit, screenshots of all screens, interaction recordings, notifications with app closed/Focus/DST/travel, two physical devices, backup restore and hostile-upload/security review are outstanding.

A browser-run regression exposed a routing collision: the nested meal-photo path shadowed the generic meal collection route, failing the combined refresh after a successful lab save. Collection routes are now registered explicitly; the HTTP regression checks each collection and meal persistence/export. Native reminder opening also verifies current plan dates and account continuity.

## Reproducible checks

```sh
swift test --package-path Backend --disable-sandbox --build-system native \
  --cache-path /tmp/thyrocare-swift-cache \
  -Xswiftc -module-cache-path -Xswiftc /tmp/thyrocare-module-cache
python3 Scripts/check_care_api.py
node --experimental-strip-types Scripts/check_roster.mjs
npm run build --prefix Backend/Dashboard
```

Use Xcode Build for the native target. Browser QA needs Playwright and Chrome:

```sh
npm install --prefix /tmp/thyrocare-browser playwright --ignore-scripts
node Scripts/check_care_browser.mjs
```

The script starts a temporary synthetic backend, uses separate browser contexts, and writes synthetic-only screenshots/results under `docs/qa` if it succeeds. It must run in an environment that permits launching Chrome. No real care-team message is sent.

## Remaining software work (not external clinical gates)

1. Restore the richer canonical dashboard shell around these connected screens; fully finish each route rather than relying on workspace aliases. Add practice inbox, monitoring, search, users, reports, clinical alerts and authorized audit UI. Add server-side pagination/filtering and complete roster sort/filter preferences scoped to workspace.
2. Extend questionnaire and normalized clinical models: lab panels/codes, assay/accession metadata, OCR confirmation, date/time/provenance history UI, reviewed conversions, explicit diagnosis context, calculated BMI, separate temporal BP/HR charts and supplement migration.
3. Medication terminology/formulation/tablet counts, alternating dose structures, duplicate/overlap checks, medication reconciliation and clinician signed plan/amendment workflow. Do not interpret free text as a dose instruction.
4. Full camera flow; durable browser photo drafts; media replacement/version/deletion; food recognition/portion review; source-backed nutrient estimation; versioned jobs and invalidation; external-AI consent; grounded detailed meal summaries. No AI credentials should be added until data-sharing consent and vendor arrangements are determined.
5. Rich daily calendar/coverage, clinician-configured symptoms, weekly overview, stronger prevention/reconciliation of duplicate-day entries, medication/lab/vital context and source-linked clinical summary review/sign-off.
6. Reminder editing/snooze/stop, quiet hours, APNs, multi-device ownership/deduplication, complete plan/slot UI, clinician-recommended plans and acknowledgements, and real device validation. No guaranteed notification delivery is claimed.
7. Message threads/recipients/read status/attachments, reliable cursor-based recovery, abuse/report controls, response policy, granular request ownership and state transitions, practice administration and patient/proxy distinctions.
8. Email verification/recovery, stronger clinician authentication, rate limiting, session-management UI, consent/privacy/settings, actual account-deletion processing, safe backup restore, granular scopes, clinician identity verification and protected operational hosting. Native offline re-entry currently requires an online session check.
9. Finished visit briefs/PDF reports and native revision-history browsing. JSON export exists; exports have not yet been exercised in device/browser UI.
10. Reviewed migration of historical records and private-note exceptions; no implicit private-to-public republishing.

## Remaining external/data/clinical gates

Intended-use review, supported patient ages/regions and provider relationship; clinical rules and interaction-source review; legally governed note exceptions and minor/proxy confidentiality; AI/cloud vendor agreements and privacy terms; consented longitudinal symptom/lab/treatment data; survey-methods weighting review; external/prospective model validation; deployment security/operational agreements; current App Review/privacy/SDK requirements at submission. None are completed by the passing builds or the exploratory R² result.

## Master acceptance coverage

| Criteria | Evidence / remaining scope |
| --- | --- |
| 1–4 Labs | Distinct names/units/dates/censored strings/optional intervals and revisions implemented; full panels, OCR, conversions, target effective dates and complete cross-surface interaction evidence pending |
| 5 Vitals | Dated source entry implemented; calculated BMI and complete vital charts pending |
| 6–8 Medicines/supplements | Exact/range/unknown capture and amiodarone alias; no equivalent dose; separate supplements. Full inventory/reconciliation/migration pending |
| 9–12 Meals | Confirmed private photos/manual entries persist, isolation/restart tested. No nutrient estimates, recognition, AI summaries or complete failed-browser-draft recovery |
| 13–14 Symptoms | Daily/weekly records, point plots and descriptive source draft; not validated forecasting; full calendar/context and device proof pending |
| 15–20 Reminders | Scheduling code, acknowledgement, permission status, generic notifications, version checks and logs implemented; device delivery and complete scheduling acceptance suite not passed |
| 21–22 Communication | HTTP and separate-browser messaging/restart, shared notes and HTTP request response tested; native/device proof pending |
| 23–24 Notes | Shared notes, signed immutability and amendments supported; legal exceptions/proxies/migration not implemented |
| 25–27 Isolation/sync | Backend authorization/revocation/restart/idempotency tests pass; client cancellation/generation guards present; slow-response interaction/offline conflict tests incomplete |
| 28 Roster | Numeric appointment/lab sorting edge tests pass; full filtering/pagination/preferences and interaction evidence incomplete |
| 29–31 Design/charts/accessibility | Builds and limited signed-out observation; full route, visual, device, keyboard, contrast and assistive-tech audit pending |
| 32 Privacy operations | JSON export, deletion-request persistence, private media and revocation primitives; deletion processing, photo deletion, backups/restore and interaction tests pending |
| 33–34 Research | Downloads/checksums, fixed 80/20 membership, fold-only preprocessing, full artifact and honest failed 0.85 ambition. Survey-aware inference and external validation not complete |
| 35 Summaries | Deterministic source-linked symptom draft cannot change treatment; LLM/meal summaries and adversarial AI evaluation not implemented |
| 36 Release | Not release-ready; gates listed above |

## Questionnaire and sample-data follow-up

Questionnaire now opens after new native registration and remains accessible from Today/Track. Save-and-continue and finish-later persist progress/context as a versioned authorized `questionnaire` record, with device pending-queue support. Labs, medicines, vitals and symptoms use existing record forms. Simulated sample records are isolated, read-only fixtures in `CareSampleDataView`; they never enter the patient sync queue or clinician records. This does not complete OCR, validated conversions or every questionnaire field in the master brief.

Validation for this follow-up: native Xcode build, canonical web production build, backend tests and HTTP questionnaire restart check passed. Simulator touch verification was attempted through the required device-interaction agent but stopped at its usage limit; questionnaire navigation and automatic post-signup presentation are not yet device-verified.
