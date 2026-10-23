# ThyroCare

ThyroCare is a native patient app and shared patient/clinician record workspace. The redesign is **in development, not ready for clinical deployment or App Store submission**. It does not measure thyroid hormones from meals or symptoms and does not recommend medication doses.

The native app now opens a five-tab workspace: Today, Track, Meals, Trends and Care. Authenticated `/v1` APIs persist records and revisions in SQLite. The patient and clinician web entry points use those same APIs. Legacy fixture APIs and the global meal feed are retired.

## Canonical applications

- Native app: `ThyroCare.xcodeproj`, sources under `Mobile_App/ThyroCare`.
- Backend: `Backend`, Swift 6 / Vapor, private SQLite storage.
- **Canonical web application: `Backend/Dashboard`.** `Backend/Dockerfile` builds this directory. The older root `Dashboard` scripts delegate to it; do not develop another dashboard copy.
- Research: `Research` and `Scripts/evaluate_nhanes_baseline.py`. Research artifacts are never served as clinical predictions.

The Xcode project currently requires **iOS 26.5 or later**. Earlier iOS 17 support claims were incorrect. The installed SDK/build tool version is a separate requirement; compatibility has not been backported.

## Local development

Use synthetic accounts and records. Production authentication operations, clinician MFA, abuse prevention, backup/restore operations, vendor agreements, clinical governance and release review remain incomplete.

```sh
cd Backend
swift test --disable-sandbox --build-system native
swift run --disable-sandbox --build-system native Run
```

The native SwiftPM build system avoids a local Xcode signing problem observed with dependency resource bundles. If caches are restricted, use the explicit cache arguments in `docs/implementation-handoff.md`.

In another terminal:

```sh
cd Backend/Dashboard
npm ci
NEXT_PUBLIC_VAPOR_API_BASE_URL=http://localhost:8080 npm run dev
```

The backend defaults to port 8080. Set `CARE_WEB_ORIGIN=http://localhost:3000` for this development setup. Both browser endpoints must use the same site hostname for the strict session cookie. Web tokens are not stored in localStorage. Native tokens use Keychain.

For **Xcode Debug simulator runs**, `ThyroCareSimulatorBackendBaseURL` is `http://localhost:8080`. Start the updated backend on your Mac and keep the terminal open:

```sh
bash Scripts/start_simulator_backend.sh
```

Then run the app with Xcode (⌘R). Simulator accounts and records persist in `Backend/CareData`; restarting the process does not reset them. This is local storage on your Mac, not the hosted service. If port 8080 is already occupied, stop the previous ThyroCare backend before starting another.

Physical-device and Release builds use `ThyroCareBackendBaseURL` in `ThyroCare-Info.plist`; set it to the server that runs this branch. The existing hosted URL is **not evidence that these new routes have been deployed**. No hosted deployment was performed during this implementation. Build the native app with Xcode.

Patient accounts can register through the native or web form. Clinician roles cannot be selected through the public registration API. To provision an independently verified development clinician, set `CARE_PROVISION_CLINICIAN=1`, `CARE_CLINICIAN_EMAIL`, `CARE_CLINICIAN_NAME`, and `CARE_CLINICIAN_PASSWORD` in the operator's environment, then run the backend once. Remove these provisioning variables before normal startup. Never commit credentials. Clinicians generate a one-use 15-minute invitation; patients review the clinician and explicitly accept all-record access. Practice identity, granular scopes and MFA remain release dependencies.

## Durable storage and deployment

`CARE_DATA_DIRECTORY` defaults to `CareData` within the backend working directory. It must be on a private persistent volume. An ephemeral hosting filesystem is not durable deployment. SQLite uses WAL and FULL synchronous writes; the actor serializes access and commits before acknowledging saves. This is a single-instance foundation, not a horizontally scaled database service. Private JPEGs reside in the same database and are fetched through authorization checks; there are no public photo URLs.

```sh
docker build -t thyrocare Backend
```

Configure a writable persistent directory for UID 10001, `CARE_DATA_DIRECTORY`, an exact `CARE_WEB_ORIGIN`, HTTPS termination and the production Vapor environment. Do not deploy this development build with real health records until the documented release gaps are resolved.

## Verification

```sh
python3 Scripts/check_care_api.py
node --experimental-strip-types Scripts/check_roster.mjs
npm run build --prefix Backend/Dashboard
```

The API check starts isolated temporary storage and synthetic accounts, exercises authorization and bidirectional messages, restarts the backend process, and verifies persistence and revoked access. It is not a substitute for two-device/browser interaction testing.

See [implementation handoff](docs/implementation-handoff.md), [API contract](docs/care-api.md), [reminder specification](docs/reminders.md), and [route coverage](docs/web-route-coverage.json).

## Research result

All 36 requested NHANES XPT files, 36 accompanying codebooks and the UCI archive were downloaded and checksummed in `Research/data-manifest.json`. Raw public downloads are ignored by Git. Recreate them using:

```sh
python3 Scripts/fetch_research_data.py
```

The first locked held-out benchmark used 6,996 development and 1,750 test participants. R² was **0.02377 for log TSH, 0.21602 for Free T3, and 0.00873 for Free T4**; their equally weighted mean was **0.08284**, below the 0.85 ambition. These are unweighted cross-sectional prediction results, not population causal effects or clinical validation. The script refuses to overwrite an existing test evaluation. See [research report](Research/REPORT.md).

The old R coefficient exporter is retired because its fitted-data statistics and normalized mixed-unit coefficients were not valid serving predictions. A consented longitudinal symptom/lab/treatment cohort, survey-methods review, external clinical validation and intended-use/regulatory assessment remain necessary.
