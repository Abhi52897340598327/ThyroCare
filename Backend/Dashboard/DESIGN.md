# ThyroCare dashboard design handoff

The family workspace brings food records, thyroid results, reports, appointments, and care-team notes into one consistent interface. The clinician overview prioritizes record review and patient search. All displayed health records remain the existing demo fixtures.

## Design resources

[Figma working file](https://www.figma.com/design/hAXwwtaz2S46MmlCnMErhj)

The native file contains three pages: foundations, components, and dashboard screens. Foundations include semantic color variables, spacing/radius tokens, and IBM Plex Sans text styles. The component page includes buttons, status badges, metric cards, and navigation items. Family desktop and mobile layouts have been assembled. **Figma Starter's MCP quota prevented final visual QA and completion of the remaining native screens.** Those other frames are scaffolds, not completed designs. No library publication or Code Connect registration has been performed.

Complete rendered screen references are in `design/exports/`:

| Export                    | Route                  |
| ------------------------- | ---------------------- |
| `family.svg`              | `/family` desktop      |
| `family-mobile.svg`       | `/family` at 390px     |
| `family-reports.svg`      | `/family/reports`      |
| `family-appointments.svg` | `/family/appointments` |
| `family-settings.svg`     | `/family/settings`     |
| `providers.svg`           | `/providers`           |
| `clinician.svg`           | `/clinician`           |

Drag an SVG onto a Figma Design page to import it. These are editable text/vector layout references, with an embedded raster brand mark; imports do not preserve React behavior, native Figma component links, or auto-layout. They were generated from the rendered dashboard DOM. The browser implementation is authoritative for exact typography, shadows, responsive behavior, and interactions. Install IBM Plex Sans if Figma reports a missing font.

## Code map

| Design responsibility                                             | Code                                   |
| ----------------------------------------------------------------- | -------------------------------------- |
| Hover/focus sidebar, pinning, mobile drawer, workspace navigation | `components/DashboardShell.tsx`        |
| Headings, metric cards, panels, status labels                     | `components/DashboardUI.tsx`           |
| Colors, spacing, responsive rules, focus states                   | `app/globals.css`, `--tc-*` variables  |
| Family overview and member selection                              | `app/family/page.tsx`                  |
| PDF download and member filtering                                 | `app/family/reports/page.tsx`          |
| Appointment records and filtering                                 | `app/family/appointments/page.tsx`     |
| Browser preferences and display name                              | `app/family/settings/page.tsx`         |
| Location-based specialist search                                  | `components/EndocrinologistSearch.tsx` |
| Clinician search, status filter, and sorting                      | `app/clinician/page.tsx`               |

The existing detailed patient pages retain their content and inherit the shared shell. The patient record navigation becomes horizontally scrollable on smaller screens. The SwiftUI app, Vapor API, and the separate root-level `Dashboard` project were not modified.

## Interaction and accessibility

- Desktop sidebar expands on hover or keyboard focus; pin keeps it expanded.
- Mobile navigation opens with a labelled button, traps keyboard focus, closes with Escape, and restores focus to the opener.
- Active navigation uses `aria-current`; chart period buttons use `aria-pressed`.
- Chart includes a text summary of the actual displayed lab points.
- Inputs have labels; status colors also have text; table sorting exposes `aria-sort`.
- Reduced-motion preferences remove transitions. Mobile tables scroll inside their panel.
- Settings persist in localStorage and the saved display name updates the sidebar.

## Run locally and use alongside Xcode

```sh
cd Backend/Dashboard
npm ci
npm run dev
```

Open `http://localhost:3000/family` for the family workspace or `/clinician` for the clinician workspace. This dashboard is a Next.js web application; Xcode remains the tool for the separate SwiftUI mobile app. Pull this branch on your Mac to get the web changes and design resources.

## Data and integration boundaries

- Patient, appointment, food-log, and note content still comes from `lib/demoData.ts`. This change does not connect authentication, live patient data, family membership, messaging, appointment booking, or clinician prescribing workflows.
- Workspace switching is a demo navigation affordance, not role-based authorization.
- Reports use the existing jsPDF generator and download sample-record PDFs.
- Saved notification preferences do not send email or SMS.
- Doctor search uses a real Google Maps search URL based on an entered location or consented browser geolocation. No invented ratings, distances, or availability are shown. Set the existing `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` configuration to enable the optional Maps Embed search view; a live in-app Places results list is not implemented.

## Validation

- `npm run build`: successful production compilation, type checking, and generation of 181 pages. Existing image-optimization warnings in retained components and a Tailwind easing-class warning remain.
- Browser checks at 1440px, 768px, and 390px: family overview, reports, appointments, settings, provider search, clinician overview, family member detail, and clinician patient detail.
- Verified: no document-level horizontal overflow at 390px/768px; member and chart-period changes; mobile menu/Escape/focus restoration; filtered PDF download; preferences after reload; Google Maps query URL; clinician search, no-results state, and stable-status filter. No runtime page errors in that run.
- SVGs are layout references. Native Figma screenshot QA and remaining native screen completion are outstanding because of the account quota.
