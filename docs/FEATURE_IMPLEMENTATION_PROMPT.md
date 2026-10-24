# ThyroCare — feature implementation prompt; preserve the existing design

Prepared October 23, 2026. This is an implementation specification, not a claim of completed functionality, clinical validation or release approval.

## 1. Mandate and non-negotiable design boundary

Act as the senior native iOS engineer, web/backend architect, clinical informatics engineer and applied ML researcher for ThyroCare. Implement the workflows below in the existing product. Aim for exceptional reliability, clarity and usefulness. Awards, Apple collaboration and App Store acceptance are aspirations, never promised outcomes or marketing claims.

**DO NOT REDESIGN THE MOBILE APP OR DASHBOARD.** Preserve the restored original screens, navigation, seven mobile tabs, typography, colors, gradients, artwork, card styling, spacing conventions, dashboard layout and existing web shell. Do not replace pages with CarePortal, introduce a new home screen, consolidate tabs, replace the questionnaire with a wizard, or hide the requested features in a separate replacement application. Add necessary fields, actions, statuses and evidence inside their existing sections using existing components. Charts may change their rendering implementation and data source while retaining the surrounding visual design. Accurate labels and removal of unsupported factual claims are content corrections, not permission to redesign.

Capture a baseline of every affected screen before editing. Compare before/after screenshots at the same size and state. Only requested controls, values, error states and narrowly necessary accessibility fixes should differ. Do not use this brief to reverse the user's dashboard/questionnaire rollback. Never delete patient records to reset the UI.

## 2. Inspect and build on the actual repository

Repository: Abhi52897340598327/ThyroCare. Inspect the working branch, uncommitted changes and applicable instructions. The original design reference is commit `fbf5c2f5645431b50b1e313bb9ef9ad1c6d1801e`; subsequent commits and local rollback changes contain working features that must be retained selectively.

Keep `Backend/Dashboard` canonical. The backend Docker build consumes it. Do not implement changes only in root `Dashboard`. Preserve `QuestionairePage.swift`, `DashboardPage.swift`, `PicturePage.swift`, `MedicationLogPage.swift` and the existing clinician/patient page composition. Correct the visible spelling to Questionnaire without breaking routing/source references.

Audit and reuse `CareStore`, `CareDatabase`, `CareRoutes`, `CareRecords`, `CareMedia`, reminder components, shared API tests and research artifacts. These provide a foundation, not proof that restored legacy screens use them. Reconnect the existing screens to the shared records; replace their unrelated fixtures and local-only saves without altering their presentation. Preserve and explicitly migrate legacy data; never infer that a locally remembered name authenticates a patient.

Debug simulator configuration currently uses localhost:8080. Physical iPhone and released web/native builds require the updated deployed HTTPS API and durable storage. Verify registration, login, API version compatibility and authenticated record access at the configured URL before calling a build usable. A passing local test does not prove the hosted backend was updated. Do not silently fall back to a prototype endpoint or in-memory save.

## 3. Questionnaire additions inside the original form

Extend the existing Labs, Treatment history and body/context sections. Keep their visual style and page organization. Preserve entered fields when navigating away, retrying a save or restarting. Show whether data are saved on device, queued, synchronized or rejected. Allow incomplete panels and unknown answers.

Each lab observation must contain:

- Explicit analyte: TSH, Free T4, Free T3, total T4 or total T3. Free and total forms are never interchangeable.
- Original result string, decimal numeric value when applicable, and optional < or > comparator. Preserve censored values.
- Report unit, analyte-specific selection, original unit/value and reviewed conversion provenance if converted.
- Blood collection date/time when known, result-received date separately, and report-issued date if supplied. Do not prefill collection date with today. A received-date proxy requires acknowledgement and a visible proxy label.
- Laboratory reference interval: optional lower/upper bounds, units, lab/report and assay source.
- Endocrinologist-recommended target: separate optional bounds, clinician/source, effective dates. Do not overwrite the laboratory interval or call the target a universal normal range.
- Patient-entered/document-extracted/imported/clinician-verified provenance, attachment, result status and auditable revisions.

Validate finite values, compatible units, ordered bounds, impossible dates and possible duplicates. Missing intervals remain missing. Different assay scales are not biologically equivalent merely because units or interval positions were normalized. If a range-position display is used, label it as position within that report's interval, not disease severity.

Add current weight with kg/lb, date and source; height when known; calculated BMI only with adequate height/weight; and an optional manually entered BMI with source/date. Preserve entered/calculated distinctions and discrepancies. Add optional systolic/diastolic BP in mmHg, measurement time and home/office/physical/device context. Add measured heart rate in bpm with resting/activity context. Save every observation longitudinally instead of overwriting one profile value. Unknown BP is valid; palpitations do not become measured heart rate.

Use the exact question title **Do you take an iron supplement?** Record calcium separately in the supplement inventory. Preserve old combined iron/calcium answers as ambiguous historical data and ask for clarification. Collect condition/context as patient reported, clinician diagnosed or unknown, plus relevant surgery, pregnancy/postpartum, pituitary and treatment context without automatically diagnosing.

## 4. Medication and uncertain-dose contract

Use one structured dose component everywhere medication is entered: questionnaire, medication screen, imports, reconciliation and clinician edits. Preserve the existing container styling.

Support Exact dose / Patient-estimated range / Not sure. A 50–75 mcg entry remains an interval, never an instruction to choose a dose. Store original wording, lower/upper bounds in the same unit, ingredient, formulation, route, tablet strength, tablet count, total amount per administration, schedule, effective dates, prescription source, prescriber and confirmation state. Distinguish prescribed regimen from actual taken/skipped observations. Support day-specific alternating doses, weekly and PRN medicines; no automatic daily conversion.

Include levothyroxine, liothyronine, methimazole, propylthiouracil, lithium and amiodarone. Accept “amiodorone” as a search alias, then display Amiodarone. Keep amiodarone mg separate from thyroid-replacement mcg. Amiodarone can be associated with both hypo- and hyperthyroid abnormalities; a universal direction or levothyroxine-equivalent dose is inappropriate. Use reviewed formulation-specific interaction rules rather than the existing generic absorption multipliers. [DailyMed prescribing information](https://dailymed.nlm.nih.gov/dailymed/fda/fdaDrugXsl.cfm?setid=c536e0ad-2758-4022-8242-f5e9b6aca1e2&type=display).

Version every rule with source, evidence date, applicability, wording and uncertainty. Do not automatically stop or change prescription medicines. Do not assume the midpoint or a distribution for an uncertain dose. If a validated model supports scenarios, label its scenario envelope accurately; it is not automatically a confidence interval. Otherwise explain that the model cannot use the uncertain dose and request reconciliation.

## 5. Food capture, analysis and summaries in the existing Food Analysis screen

Add optional free text labelled **Diet or eating pattern, if you know it**. Blank is valid. Store it as dated patient-reported context, not an inferred diagnosis.

Implement physical-iPhone live camera capture, photo-library import and manual entry. Request permission when needed and support denial. Capture → preview/retake/discard → explicit confirmation → durable patient-owned meal draft → food/portion recognition → editable review → nutrient estimation → explanation → saved version. Confirmed photos must survive a failed upload/analysis job; incidental camera frames and discarded retakes must not upload. Record actual meal time separately from capture time, meal slot, eaten/planned status, ingredients, portions, preparation and notes.

Every photo has a stable meal ID and server-authorized patient owner. Store privately with authenticated or short-lived authorized access. Strip unnecessary metadata. Version ingredient/portion edits and analyses; visibly invalidate summaries based on older inputs. Logging must work when AI is unavailable. Do not claim an analysis step is running unless a real job is running.

Show the actual photo, recognized foods/portions, estimated kcal, protein/carbohydrate/fat/fiber/sugars in grams, and available thyroid-relevant micronutrients with appropriate units: iron/calcium/zinc/sodium/potassium in mg; iodine/selenium/vitamin D in µg; vitamin A in µg RAE where supported; individual B vitamins in their own units. Micronutrients are not all grams. Unknown iodine or hidden ingredients remain unknown, never zero. Retain USDA item ID, data type, serving basis, lookup/version and patient corrections.

Automatically generate a concise AI summary only after explicit third-party-AI consent and successful analysis. State foods, portions, estimates, material unknowns and applicable reviewed medication-timing context. Distinguish recognition, portion, composition-data and hormone-model uncertainty.

Add **Generate detailed meal summary** on the mobile result and existing patient-specific clinician nutrition tab. Persist sections: confirmed observations; nutrients/missingness; relevance to documented regimen/diet; permitted population associations; supported adjustments; care-team questions; evidence, input versions, model/prompt versions and uncertainty. No universal forbidden-food lists, unsolicited supplements or precise individual hormone change from one photograph. Unsupported NHANES output must show unavailable/research-only, not invented percentages.

## 6. Daily symptoms, weekly check-ins and clinician review

Add quick daily symptom logging through an existing screen/action, without a navigation redesign. Use anchored custom 0–4 ratings plus Not assessed for fatigue, concentration, mood, sleep, temperature intolerance, palpitations, tremor, bowel, muscle and skin/hair concerns. Include optional interference, onset/frequency and context. Store patient, symptom/scale version, local observation date/timezone, entry timestamp, source and revisions. Do not copy yesterday's ratings into today. Missing days are gaps, not zero.

Provide a separate weekly check-in with explicit seven-day recall window: symptom burden, interference, missed doses/changes, side effects, illness and questions. Display existing daily entries for review. Never manufacture seven daily records from a weekly answer. A custom diary is not ThyPRO or a validated diagnostic score; licensed instruments require correct permission, wording, scoring and recall period.

In the existing patient-specific Symptoms tab, show last daily/weekly entries, coverage, rating definitions, per-symptom trends, measured labs and relevant BP/heart-rate trends, actual lab dates and medication-change markers. Display model availability and data-sufficiency state.

Add **Generate clinical symptom summary**. Ground the persistent draft in authorized source entries/versions. Describe reported changes, measured-lab agreement/disagreement, missing data, confounders, alternative explanations and discussion/testing questions. Medication output is evidence-linked **draft considerations for the treating clinician**, with review/signature before a treatment plan reaches the patient. No symptom-only model or LLM chooses a dose, starts a medicine or modifies reminders autonomously. Signed plans and amendments remain patient-visible.

## 7. Meal plans and separate medication notifications

Add **Log every meal** within the existing Food Analysis page. Support patient-chosen and clinician-recommended plans with purpose, recommender, start/end/review dates and patient acknowledgement. Setup collects anticipated breakfast/lunch/dinner times and timezone. Enable app preferences on confirmation; request OS authorization then. If denied, retain the plan and show notifications disabled with a Settings action.

Show meal-slot states: Logged, Due, Skipped, Not eaten/fasting, Not logged. Deep-link reminders to the exact date/slot. Associated logging suppresses follow-ups. Support manual entries, snooze, edit, pause, stop and expiry. Missing photographs alone are not emergencies and never block care access.

Medication reminders are separate and follow a patient-confirmed current regimen, including actual weekdays and alternating schedules. PRN does not become daily. Unknown doses open reconciliation and never select a guessed amount. Only an explicit Taken/Skipped action creates an administration log. Regimen changes invalidate obsolete schedules.

Use UserNotifications for local schedules and APNs for authorized remote events where implemented. Stable IDs include patient, version, occurrence and device. Handle scheduling limits, DST, travel timezone policy, quiet hours, permission changes, stale/offline reminders, logout, revocation, reinstall and multiple devices. Generic lock-screen text is the default. Verify the current plan when opening a reminder; avoid stale dose instructions. Explain actual scheduling horizon and delivery limitations. Never claim guaranteed exact delivery or always-running background execution.

## 8. Existing clinician dashboard: data and behavior changes only

Retain the original shell, cards and patient table. Default sort: next non-cancelled future appointment ascending; patients without one follow, sorted by latest blood collection descending; stable name/ID ties. Show absolute appointment date/time/timezone/status. Past appointments are distinct; unknown dates sort last.

Add a sort/filter control within existing table controls: upcoming appointment, newest/oldest blood collection, unreviewed labs, unread requests/messages and name. Persist preference per authorized workspace. Use real dates and authorized server-side pagination/filtering. Counts and search must describe the same population; a role selector is never authorization.

Within the existing clinical/vitals tab, add timestamp-scaled weight/BMI, systolic/diastolic BP and measured heart-rate trends, with physical/home/office/device sources. Preserve units, gaps, source dates and data-table alternatives. Use Swift Charts natively and a production chart engine on web without changing the surrounding dashboard design. Do not silently invent measurements, causal labels or universal priority rankings.

The existing patient-specific Meals/Nutrition tab must show that patient's exact photo, meal time, kcal/nutrients, uncertainty, analysis versions, review state and summaries. Never use a global latest-meal feed. Switch patient while requests are delayed and prove old-patient responses/subscriptions cannot populate the new workspace.

## 9. Open notes and care coordination

Product policy: ordinary saved patient-related clinical notes, clinician-to-clinician care discussions and generated clinical summaries are visible to that patient by default, including clearly labelled unsigned drafts. Preserve author/role, observation/creation/signature dates, linked records, original text, versions and amendments. Signed content is immutable; corrections append amendments. Patient annotations stay distinct.

Implement narrowly governed, legally reviewed exceptions with authorized reason/scope/audit/review, not a general private-note toggle. Do not automatically republish legacy private records. Patient access is separate from proxy/family permission and minor-confidentiality requirements. Determine actual information-blocking applicability rather than treating OpenNotes as a universal override. [OpenNotes access guidance](https://opennoteslabs.org/about/federal-open-notes-rule-open-notes-labs).

Add Connect care team / Sync with dashboard using expiring one-use invitations or verified linking. Show practice/clinician, scope and revocation. No typed patient ID or matching display name grants access.

Native, patient web and clinician web use the same durable thread/message records, stable IDs, authenticated participants, server ordering, timestamps, delivery/read state and attachments. Pending becomes Sent only after server acknowledgement. Retry idempotently; recover missed messages after reconnect. Use subscriptions or tested reliable polling. State practice response expectations and emergency limitations. No autonomous AI message sending.

Add structured requests for result clarification, interval confirmation, dose/schedule confirmation, reports and appointment questions. Store recipient/owner, linked records, attachments, timestamps and Submitted → Received/Assigned → In review → Answered → Closed states, plus cancellation/clarification. Replies update the original request. A sent notification is not an answered request. Free-text replies do not silently modify prescriptions.

## 10. Shared schema and synchronization

Use stable IDs, server-verified identity, explicit revocable care-team/proxy grants and authorization on every record/media operation. Persist labs/panels, vitals, regimens/administrations, symptoms/check-ins, meals/photos/versions/jobs, summaries, notes, appointments, plans/reminders, requests/messages and consent. Every clinical record needs patient owner, observation context, recorded UTC time, original timezone, provenance and version.

Use durable transactional storage, private media, protected local caches, idempotency keys, conflict handling and restart tests. An in-memory fallback is a failed shared save. Cancel stale callbacks/subscriptions and clear account-scoped access on switch/logout. Maintain compatibility/version migrations and parity between native/web calculations. Reconnect old screens to these contracts without replacing their designs. Never leave the app pointing to an undeployed API version.

## 11. Model research: ambition without manipulated evaluation

Separate food recognition, nutrition estimation, cross-sectional diet/lab association, longitudinal symptom forecast and treatment support. They have different labels, data and validation requirements. NHANES cannot establish an individual's before/after response to a meal or create daily hormone ground truth.

Target average held-out R² ≥0.85 for a prespecified multi-output regression, or ≥85% accuracy for a separately defined classification task. Neither is guaranteed; R² is not classification accuracy. Specify analytes, transforms, weighting and each output's score. Never let one strong target conceal another failing target.

Lock 80% development /20% test before modelling; their difference is 0.60 of the dataset. Tune only within development folds. A 75/25 split also meets a 0.50 difference, but changing splits after observing test results contaminates evaluation. Do not shop seeds, fractions, exclusions or labels. An already inspected test set is no longer untouched for further development; use fresh external validation or disclose it as exploratory.

Join NHANES by cycle and SEQN, never array row position. Keep physical nutrient units separate. Evaluate missingness, duplicate cohorts, assays, eligibility, confounders and survey sampling. Choose joint-sample weights using cycle-specific CDC guidance with survey-methods review. Do not replace invalid weights with 1. Fit imputation, scaling, feature selection and tuning inside training folds only. Prevent future labs, target-derived diagnoses and post-outcome treatment leakage.

Compare mean/median or last-lab baselines, regularized regression, justified additive/mixed models and boosted trees. Use neural networks only if independent sample size and validation support improvement. More epochs cannot supply missing longitudinal evidence. Report R²/MAE/RMSE per outcome and original units, uncertainty/calibration, clinically relevant errors, subgroup results and learning curves. Classification additionally requires prevalence, confusion matrix, sensitivity/specificity, macro F1, balanced accuracy and calibration against a majority baseline.

Freeze the complete preprocessing/model artifact, feature definitions, units, dependencies, seeds, membership hashes and model card. Test serving parity and unavailable-input handling. Clinical forecasts require independent external/prospective validation and intended-use review; a numerical score alone is insufficient.

**Existing repository result:** the locked unweighted feasibility benchmark used 6,996 development and 1,750 test participants. R²: log TSH 0.02377; Free T3 0.21602; Free T4 0.00873; equally weighted mean 0.08284. It did not meet 0.85. Preserve `Research/evaluation.json`, the locked split and report; do not overwrite them to manufacture success. This is not survey-aware clinical validation. Continue honest research and ship useful logging/education independently.

For symptoms, obtain consented longitudinal patients with daily ratings, separate weekly recall, serial measured TSH/Free T4/Free T3, baseline labs, verified regimen/adherence/uncertainty, illness and relevant context. Prespecify prediction time and horizon. Split patients before windows; use time-aware validation and assess 7/14/28-day coverage/change features. Compare last-lab+treatment/context against the same baseline plus symptoms to measure incremental value. Never interpolate sparse blood draws into daily labels. Abstain for insufficient coverage, stale labs or unsupported populations. No verified unrestricted dataset with the complete required combination is currently established in this project.

## 12. Exact research downloads

Existing `Scripts/fetch_research_data.py` and `Research/data-manifest.json` document 36 NHANES XPT files, their 36 codebooks and the UCI archive. Verify local checksums before downloading duplicates. The table below supplies exact URLs; each codebook uses the same URL with `.htm` instead of `.xpt`. Retain checksums, access dates, licenses and cycle-specific analytic notes.

| File family | 2007–2008 | 2009–2010 | 2011–2012 |
| --- | --- | --- | --- |
| THYROD | [THYROD_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/THYROD_E.xpt) | [THYROD_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/THYROD_F.xpt) | [THYROD_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/THYROD_G.xpt) |
| DEMO | [DEMO_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/DEMO_E.xpt) | [DEMO_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/DEMO_F.xpt) | [DEMO_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/DEMO_G.xpt) |
| BMX | [BMX_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/BMX_E.xpt) | [BMX_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/BMX_F.xpt) | [BMX_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/BMX_G.xpt) |
| DR1TOT | [DR1TOT_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/DR1TOT_E.xpt) | [DR1TOT_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/DR1TOT_F.xpt) | [DR1TOT_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/DR1TOT_G.xpt) |
| DR2TOT | [DR2TOT_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/DR2TOT_E.xpt) | [DR2TOT_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/DR2TOT_F.xpt) | [DR2TOT_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/DR2TOT_G.xpt) |
| RXQ_RX | [RXQ_RX_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/RXQ_RX_E.xpt) | [RXQ_RX_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/RXQ_RX_F.xpt) | [RXQ_RX_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/RXQ_RX_G.xpt) |
| BPX | [BPX_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/BPX_E.xpt) | [BPX_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/BPX_F.xpt) | [BPX_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/BPX_G.xpt) |
| DPQ | [DPQ_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/DPQ_E.xpt) | [DPQ_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/DPQ_F.xpt) | [DPQ_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/DPQ_G.xpt) |
| SLQ | [SLQ_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/SLQ_E.xpt) | [SLQ_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/SLQ_F.xpt) | [SLQ_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/SLQ_G.xpt) |
| MCQ | [MCQ_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/MCQ_E.xpt) | [MCQ_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/MCQ_F.xpt) | [MCQ_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/MCQ_G.xpt) |
| UIO | [UIO_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/UIO_E.xpt) | [UIO_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/UIO_F.xpt) | [UIO_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/UIO_G.xpt) |
| VID | [VID_E.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/VID_E.xpt) | [VID_F.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2009/DataFiles/VID_F.xpt) | [VID_G.xpt](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2011/DataFiles/VID_G.xpt) |

Core: THYROD thyroid analytes; DEMO survey design/demographics; BMX anthropometry; DR1TOT/DR2TOT dietary totals; RXQ_RX medication inventory; BPX examination BP/vital context. Optional DPQ, SLQ, MCQ, UIO and VID are context modules, not daily thyroid symptoms or measurements of food-photo iodine/vitamin D. Prescription inventory does not guarantee dose/timing fields. Independent cycles are cross-sectional samples, not follow-up visits. Free and total analytes are explicitly distinct in the [CDC thyroid codebook](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2007/DataFiles/THYROD_E.htm). Review [weighting guidance](https://wwwn.cdc.gov/nchs/nhanes/tutorials/weighting.aspx) and [analytic guidelines](https://wwwn.cdc.gov/nchs/nhanes/analyticguidelines.aspx).

Secondary benchmark: [UCI Thyroid Disease ZIP](https://archive.ics.uci.edu/static/public/102/thyroid+disease.zip), with [official documentation and license](https://archive.ics.uci.edu/dataset/102/thyroid+disease). The archive contains different historical tasks and potential source overlap; inspect individual files and known problems. Classification success here does not validate daily symptoms, meal effects or medication recommendations.

Longitudinal access lead, **not a verified direct training download**: [Winther et al. ThyPRO study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0156925) and [DDA-23924 archive DOI](https://doi.org/10.5279/DK-SA-DDA-23924). Verify availability, terms, actual variables and suitability. It is not an established daily-diary dataset. If unsuitable, secure an appropriate clinical/research cohort with ethics/consent/data agreements. Use routine clinically indicated labs; do not order unnecessary blood draws. Synthetic data can test software, not clinical performance.

## 13. Release evidence and operational gates

Treat this as a release checklist to investigate and satisfy, not a compliance certificate. Assume an initial US launch only until ages, jurisdictions, clinical uses, provider relationships and business model are explicitly established. Record owner, evidence, review date and blocking status for each gate.

- Complete a function-by-function intended-use assessment for logging, education, forecasts, triage and treatment support with qualified clinical/regulatory reviewers. Determine whether each function needs device authorization or qualifies for an exclusion. Clinician-facing labels and educational disclaimers are insufficient by themselves. Keep blocked functions out of released clinical workflows. [FDA CDS guidance, January 2026](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/clinical-decision-support-software).
- Recheck current App Review rules for medical accuracy/dosing, complete functionality, truthful metadata, privacy, AI sharing, account deletion and conditional messaging/login/payment requirements. Obtain explicit permission before sending personal data to third-party AI. Supply accurate screenshots, review accounts, live backend, support/privacy URLs and evidence for medical claims. Recheck SDK upload requirements separately from minimum supported OS. These are submission gates, not a promise of approval. [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/) and [current upload requirements](https://developer.apple.com/news/upcoming-requirements/).
- Inventory actual data flows and vendors: labs, medicines, symptoms, vitals, photos, messages, model outputs, device identifiers and diagnostics. Determine applicable HIPAA/business-associate, FTC consumer-health/breach, state privacy/retention and any international obligations with counsel. Obtain applicable contracts and vendor agreements. Do not assert HIPAA certification or assume encryption alone establishes compliance. [FTC health-data guidance](https://www.ftc.gov/business-guidance/resources/collecting-using-or-sharing-consumer-health-information-look-hipaa-ftc-act-health-breach).
- Separate optional AI processing consent, research consent and ordinary care/account terms. Explain recipient, purpose, retention and revocation; offer manual/non-AI workflows. Do not train general models on identifiable care records through vague bundled consent.
- Provide export and account-deletion initiation, identity confirmation, processing status and actual operational handling. Explain legally retained records; logout is not deletion. Revoke sessions, access grants and device tokens; clear sensitive notifications and caches.
- Resolve adolescent consent, confidentiality and proxy scope before allowing those populations. Model eligibility, research participation and store age rating are separate controls.
- Implement supported authentication, session revocation, stronger clinician authentication, least privilege, authorization tests, rate limiting, private media, secure transport, encrypted storage, protected caches, access audits, backup/restore drills and incident handling. Remove production debug paths and prototype credentials. No health content in analytics, crash logs, URLs or lock-screen payloads.
- Treat OCR, uploaded documents, food labels and messages as untrusted inputs. They cannot override system rules. Ground summaries in authorized record IDs/versions and approved references. Validate structured output and reject unsupported numbers. AI cannot execute prescription changes, send messages or change access grants. Preserve generation/reviewer history and error reporting.
- Verify camera/photo/notification permission descriptions and graceful denial; applicable privacy manifests and dependency declarations; accessibility with VoiceOver, Dynamic Type, contrast, keyboard access, Reduce Motion, dark mode and chart tables. Make narrowly scoped accessibility corrections within the existing design. Do not declare compliance without observed tests.
- Run TestFlight and representative physical-device tests, including camera analysis and background notifications. Keep production and simulator backend environments visibly distinct and test real endpoint compatibility. Deploy only reviewed software with durable storage and operational ownership.

## 14. Implementation order without a redesign

1. Record visual baseline and route map; audit existing working backend/client features and deploy/configure compatibility checks. Preserve rollback and patient data.
2. Extend the original questionnaire and all dose-entry surfaces; connect these exact controls to shared versioned records. Add unit/date/range validation and migration tests.
3. Reconnect original clinician/patient screens to authorized shared records, preserving components/layout. Add requested roster sorting and dated vital charts.
4. Integrate persistent notes, care-team linking, requests and exact bidirectional messages into existing screens, including native entry points.
5. Complete actual camera/photo/manual capture, durable patient-owned meal jobs, source-backed nutrients and consented versioned summaries. Implement analysis failure/retry behavior before polished success states.
6. Add daily/weekly logging, clinician symptom review and separate acknowledged reminder plans. Validate on physical devices and document delivery limits.
7. Conduct research using appropriate data and uncontaminated evaluation. Keep unsupported forecasts gated; release useful supported workflows independently.
8. Finish cross-surface, accessibility, security, migration and release evidence. Do not stop after a homepage, a mock, an isolated API or a working alternate portal disconnected from original screens.

## 15. Required acceptance evidence

For every test, record build/commit, environment, accounts/roles, steps, expected result, actual result and artifact. Use synthetic accounts for evidence; do not expose personal screenshots. Separate build success, automated integration success, observed interactions and clinical/regulatory review.

1. Before/after comparison proves unchanged dashboard shells, mobile tabs, original questionnaire layout, typography and visual styling except requested additive fields/content. No replacement wizard or generic portal appears.
2. Original questionnaire saves separate TSH, Free T4, Free T3, total T4/total T3, actual units, collected/received dates, report interval and separate clinician target to native and web. Missing intervals/Free T3 remain missing; censored values and corrections survive reload.
3. Weight, entered/calculated BMI, home/office BP and measured heart rate retain dates/sources and appear in the existing clinical view. Invalid combinations are rejected without inventing normal values.
4. Every medication-entry surface preserves exact/range/unknown modes; amiodorone resolves to Amiodarone; amiodarone and thyroid therapy stay distinct. Iron question omits calcium; legacy combined answers are not reinterpreted.
5. On a physical iPhone, take and confirm a real meal photo, leave diet blank, review portions, and see the identical patient-owned image/meal, kcal, available nutrients and uncertainty in clinician view. Missing iodine stays unknown.
6. Fail upload and analysis separately, relaunch/reconnect, recover the draft without duplication, and retrieve history beyond 20 records. Portion edits version the analysis and invalidate old summaries. No global patient mixing.
7. Generate/retrieve detailed meal and symptom summaries with actual source IDs/versions, limitations and reviewer state. Injection text cannot alter prescriptions, access or messages. Unsupported forecast output is explicitly unavailable.
8. Daily diary includes a missing day and retrospective revision; weekly recall remains separate. Coverage and charts use real dates, gaps and definitions. Clinician sees exactly the same entries.
9. Meal-plan setup schedules acknowledged breakfast/lunch/dinner slots. Denied notification permission retains the plan and reports disabled. Completion, snooze, skip, pause, expiry and date/slot deep links behave correctly.
10. Daily/alternating/weekly/PRN medicines produce only appropriate confirmed reminders. Changes cancel old versions; notifications never mark Taken. Verify DST, travel, closed app, Focus, reinstall, offline stale plans, logout and multiple devices without guaranteed-delivery claims.
11. Send **I received my Free T4 result today** from native; see that exact message in clinician web; reply there; see the identical reply in native and patient web after refresh, relogin and backend restart using separate authenticated sessions. A visual role switch is insufficient.
12. Submit a linked information request, assign/review/answer it, and see the real status/answer on native and patient web. Free text does not silently change a regimen.
13. Clinician-to-clinician ordinary notes and generated clinical summaries are patient-visible; drafts, signatures and amendments are identifiable. Test governed exceptions, proxy isolation and audited legacy-private migration.
14. Switch patient during slow requests/live updates; no prior-patient record is displayed. Alter patient/resource IDs and media access; unauthorized and revoked users are denied. Offline writes deduplicate and conflicts preserve evidence.
15. Roster sorting handles future, past, cancelled and absent appointments, missing lab dates, timezone offsets and stable ties; selected filters/order persist per workspace.
16. Empty/single/multiple/censored/irregular-date charts preserve source data and equivalent tables. Check every affected route's loading/error/empty/long-content states. No fixture results masquerade as production measurements.
17. Reproduce data manifest/preprocessing/splits. Report per-output true held-out metrics and uncertainty; failed ambition produces an honest report, never a changed split disguised as untouched evaluation.
18. Validate export, deletion handling, consent/revocation, backup restore, actual deployment and release gates. No source-code-only claim counts as completed App Store readiness.

## 16. Handoff and completion rules

Deliver implemented source changes, design-preservation comparisons, route/feature coverage, data/API migrations, model cards and honest evaluations, exact downloadable-data manifest, notification behavior/limitations, meaningful automated and observed tests, deployment/run instructions, and a named list of remaining engineering versus external clinical/data/legal dependencies.

Do not say “done,” “App Store ready,” “validated,” “85% accurate,” or “fully synchronized” unless the relevant evidence exists. If a tool, device, vendor, deployment or dataset is unavailable, identify exactly what was implemented and tested and what remains blocked. Do not use a beta label to excuse broken basic workflows. Do not substitute a prompt or a plan for implementation when the user authorizes implementation. Preserve the existing design throughout.
