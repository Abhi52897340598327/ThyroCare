# ThyroCare

[![iOS](https://img.shields.io/badge/iOS-17%2B-111827.svg)](#prerequisites)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138.svg)](#tech-stack)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000.svg)](#tech-stack)
[![TypeScript](https://img.shields.io/badge/TypeScript-5%2B-3178C6.svg)](#tech-stack)
[![License](https://img.shields.io/badge/license-MIT-0f766e.svg)](#license)

ThyroCare is an end-to-end clinical telemetry and diagnostic engine built for the Congressional App Challenge. It addresses latency in endocrine management by converting adherence behavior, dietary disruptors, biometric context, and lab baselines into real-time clinical telemetry.

## Problem Statement

### The Clinical Gap

Endocrine management, specifically Levothyroxine adherence, suffers from a critical latency problem. Because thyroid metabolism relies on highly sensitive pharmacokinetics, hidden dietary disruptors such as unmeasured calcium, iron, or soy, and erratic medication timing can silently derail a patient's baseline weeks before the next endocrinologist visit.

Current patient data collection is severely fragmented and relies on high-friction manual logging. This leaves providers blind to a patient's biological momentum and reacting to outdated laboratory panels rather than real-time physiological trends.

### The ThyroCare Architecture

ThyroCare engineers a continuous, low-friction telemetry pipeline to eliminate this clinical blind spot. The native iOS client acts as a patient-side biometric sensor node, using a Vision-Language Model for heuristic dietary risk analysis and natural language processing for frictionless habit logging.

This data is processed through a deterministic Shannon Entropy-Weighted TOPSIS diagnostic engine, trained on clinical datasets, to synthesize a real-time geometric severity score. Through an enterprise-grade Next.js clinical dashboard, providers receive instantaneous visibility into patient risk progression, predictive metabolic trendlines, and actionable telemetry events, transforming retrospective thyroid management into proactive care.

## System Architecture

ThyroCare is structured as a clinical telemetry pipeline with three primary execution surfaces:

1. The native iOS client captures patient intake, biometric context, dietary evidence, and lab baseline inputs.
2. The diagnostic engine normalizes clinical features and computes a deterministic 0-100 severity score.
3. Firebase Firestore synchronizes telemetry state to the Next.js clinical dashboard in real time.

```text
┌─────────────────────────────────────┐
│ iOS Client                           │
│ Swift, AVFoundation, intake workflow │
└──────────────────┬──────────────────┘
                   │
                   │ telemetry payload
                   ▼
┌─────────────────────────────────────┐
│ Next.js Route Handler                │
│ /api/telemetry                       │
│ validation, authorization, ingestion │
└──────────────────┬──────────────────┘
                   │
                   │ secure write
                   ▼
┌─────────────────────────────────────┐
│ Firebase Firestore                   │
│ telemetry collection, patient state  │
└──────────────────┬──────────────────┘
                   │
                   │ real-time listener
                   ▼
┌─────────────────────────────────────┐
│ Clinical Dashboard                   │
│ Next.js, React, Tailwind, Recharts   │
└─────────────────────────────────────┘
```

The dashboard subscribes to Firestore with a real-time listener. When the iOS client or simulator posts telemetry to the ingestion route, the dashboard updates without a page refresh.

## Core Diagnostic Engine

The diagnostic engine uses a deterministic Shannon Entropy-Weighted TOPSIS model trained against clinical priors derived from the Garvan Institute dataset. Shannon entropy weighting assigns feature importance by measuring dispersion across normalized clinical criteria, reducing subjective bias in multi-criteria decision analysis.

TOPSIS then ranks patient state against ideal and anti-ideal clinical baselines. The resulting geometric proximity coefficient is projected onto a 0-100 severity scale for dashboard triage, longitudinal trend analysis, and alert classification.

The iOS client also integrates AVFoundation with a GPT-4o mini Vision-Language Model workflow for heuristic dietary risk analysis. Image-derived dietary signals are treated as auxiliary risk evidence and should not override validated laboratory baselines, clinician review, or deterministic severity computation.

## Tech Stack

- Swift 5.9+
- iOS 17+
- Xcode 15+
- AVFoundation
- Gemini 3.5 Flash mini Vision-Language Model integration
- Next.js 14 App Router
- React 18
- TypeScript 5+
- Tailwind CSS
- Shadcn UI component conventions
- Recharts
- Firebase Firestore
- Firebase Admin SDK

## Directory Structure

```text
ThyroCare/
├── Mobile_App/                     # iOS client source
│   └── ThyroCare/
│       ├── Authetication/          # Authentication flows
│       ├── Buttons/                # SwiftUI button primitives
│       ├── Logos+Fields/           # SwiftUI fields and brand components
│       ├── Main/                   # App entry points and root navigation
│       ├── Pages/                  # Primary and secondary app screens
│       └── Util/                   # Shared constants and utilities
├── ThyroCare.xcodeproj/            # Xcode project
├── Dashboard/                      # Web dashboard source
│   ├── app/
│   │   ├── api/
│   │   │   └── telemetry/
│   │   │       └── route.ts        # Telemetry ingestion endpoint
│   │   ├── globals.css             # Tailwind global styles
│   │   ├── layout.tsx              # App Router root layout
│   │   └── page.tsx                # Clinical Mission Control dashboard
│   ├── components/
│   │   └── ui/                     # Shadcn-style UI primitives
│   ├── lib/
│   │   ├── firebase-admin.ts       # Server-side Firebase Admin client
│   │   ├── firebase-client.ts      # Browser Firestore client
│   │   └── utils.ts                # Shared UI utilities
│   ├── package.json
│   └── tailwind.config.ts
└── README.md
```

Recommended long-term monorepo naming:

```text
ThyroCare/
├── ios/                            # Native Swift client
└── web/                            # Next.js dashboard
```

## Prerequisites

- Node.js 20 LTS or newer
- npm 10 or newer
- Xcode 15 or newer
- Swift 5.9 or newer
- iOS 17 SDK or newer
- CocoaPods 1.15 or newer, if native dependencies are introduced through Pods
- Firebase project with Firestore enabled
- Firebase service account with write access to the target Firestore database

## Installation & Quick Start

Clone the repository:

```bash
git clone https://github.com/<owner>/ThyroCare.git
cd ThyroCare
```

Install dashboard dependencies:

```bash
cd Dashboard
npm install
```

Create the dashboard environment file:

```bash
cp .env.example .env.local
```

Configure `Dashboard/.env.local`:

```bash
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=

FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

TELEMETRY_INGEST_TOKEN=
```

Run the dashboard locally:

```bash
npm run dev
```

Open the dashboard:

```text
http://localhost:3000
```

Verify telemetry ingestion:

```bash
curl -X POST http://localhost:3000/api/telemetry \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"TC-90210","severity_score":85,"hr_variability":42}'
```

If `TELEMETRY_INGEST_TOKEN` is set, include the authorization header:

```bash
curl -X POST http://localhost:3000/api/telemetry \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"patient_id":"TC-90210","severity_score":85,"hr_variability":42}'
```

Run production validation:

```bash
npm run lint
npm run build
```

Run the iOS client:

```bash
cd ..
open ThyroCare.xcodeproj
```

If CocoaPods are added to the iOS target:

```bash
cd Mobile_App
pod install
open ThyroCare.xcworkspace
```

## Security & Privacy

ThyroCare should be operated under a privacy-first clinical architecture. Patient intake and image analysis should remain on device whenever possible, with the network boundary limited to the minimum telemetry required for physician review and longitudinal state synchronization.

Production deployments must enforce:

- authenticated telemetry ingestion
- least-privilege Firebase service accounts
- strict Firestore security rules
- transport encryption
- audit logging for clinical access events
- environment-scoped secrets
- no protected health information in client logs, analytics, or crash reports

HIPAA compliance is not conferred by this repository alone. Any production clinical deployment requires a formal compliance program, signed business associate agreements where applicable, access controls, data retention policies, incident response procedures, and independent legal and security review.

## License

MIT License

Copyright (c) 2026 ThyroCare

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
