export interface LabRecord {
  id: string;
  date: string;
  tsh: number;
  ft4: number;
  ft3: number;
  tpoAb?: number;
  labName: string;
  referenceRanges: {
    tsh: string;
    ft4: string;
    ft3: string;
  };
  status: "Normal" | "Elevated" | "Suppressed" | "Review";
}

export interface MedicationRecord {
  id: string;
  name: string;
  dose: string;
  frequency: string;
  timing: string;
  started: string;
  relevance: string;
  status: "Active" | "Changed" | "Discontinued";
}

export interface FoodLogItem {
  id: string;
  date: string;
  food: string;
  confidence: number;
  constituent: string;
  relevance: string;
}

export interface SymptomMatrixItem {
  name: string;
  present: boolean;
  frequency: string;
  severity: "None" | "Mild" | "Moderate" | "Severe";
  interference: string;
}

export interface TimelineEvent {
  id: string;
  date: string;
  title: string;
  detail: string;
  type: "LAB" | "MEDICATION" | "NUTRITION" | "SYMPTOM" | "REPORT" | "APPOINTMENT";
}

export interface ReviewAlert {
  id: string;
  category: "NEW LAB" | "TREND CHANGE" | "FOLLOW-UP" | "MEDICATION EVENT" | "PATIENT MESSAGE" | "REPORT AVAILABLE";
  title: string;
  date: string;
  detail: string;
  reviewed: boolean;
}

export interface PatientReport {
  id: string;
  title: string;
  date: string;
  type: string;
}

export interface AppointmentRecord {
  id: string;
  date: string;
  time: string;
  provider: string;
  type: string;
  status: "Upcoming" | "Completed" | "Recommended";
  recommendedReason?: string;
}

export interface ClinicalNote {
  id: string;
  date: string;
  author: string;
  type: "patient-visible" | "private";
  text: string;
}

export interface FamilyAccessRecord {
  id: string;
  name: string;
  relation: string;
  accessLevel: string;
  email: string;
}

export interface AuditRecord {
  id: string;
  timestamp: string;
  actor: string;
  action: string;
  ip: string;
}

export interface PatientProfile {
  id: string;
  name: string;
  mrn?: string;
  age: number;
  sex: "Female" | "Male";
  condition: string;
  relationship?: string;
  latestTSH: number;
  latestFT4: number;
  latestFT3: number;
  lastLabDate: string;
  nextVisit: string;
  status: "STABLE" | "REVIEW SUGGESTED" | "NEW LAB RESULT" | "FOLLOW-UP REQUESTED" | "TREND CHANGE" | "INSUFFICIENT DATA";
  trend: "Increasing" | "Stable" | "Decreasing" | "Variable";
  labs: LabRecord[];
  medications: MedicationRecord[];
  nutritionSummary: {
    periodDays: number;
    patterns: string[];
    detailedLogs: FoodLogItem[];
  };
  symptoms: SymptomMatrixItem[];
  symptomHistory: { date: string; fatigue: number; coldIntolerance: number }[];
  timeline: TimelineEvent[];
  alerts: ReviewAlert[];
  reports: PatientReport[];
  appointments: AppointmentRecord[];
  notes: ClinicalNote[];
  familyAccess: FamilyAccessRecord[];
  sharingSettings: {
    hipaaConsentSigned: boolean;
    researchShareOptIn: boolean;
    externalEHRIntegration: boolean;
  };
  auditHistory: AuditRecord[];
}

export const MOCK_PATIENTS: PatientProfile[] = [
  {
    id: "p1",
    name: "Eleanor Vance",
    mrn: "THY-84920",
    age: 48,
    sex: "Female",
    condition: "Primary Hypothyroidism",
    relationship: "Mother",
    latestTSH: 6.2,
    latestFT4: 1.1,
    latestFT3: 2.8,
    lastLabDate: "Sep 20, 2026",
    nextVisit: "Oct 12, 2026",
    status: "REVIEW SUGGESTED",
    trend: "Increasing",
    labs: [
      { id: "l1", date: "Sep 20, 2026", tsh: 6.2, ft4: 1.1, ft3: 2.8, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Elevated" },
      { id: "l2", date: "Jul 15, 2026", tsh: 4.8, ft4: 1.2, ft3: 3.0, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Review" },
      { id: "l3", date: "Apr 10, 2026", tsh: 3.9, ft4: 1.3, ft3: 3.1, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" },
      { id: "l4", date: "Jan 12, 2026", tsh: 3.7, ft4: 1.3, ft3: 3.2, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" },
      { id: "l5", date: "Oct 05, 2025", tsh: 3.5, ft4: 1.4, ft3: 3.2, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" },
    ],
    medications: [
      { id: "m1", name: "Levothyroxine", dose: "75 mcg", frequency: "Daily", timing: "07:00 AM (Fasting)", started: "Oct 2024", relevance: "Primary Synthetic T4 Replacement", status: "Active" },
      { id: "m2", name: "Omeprazole", dose: "20 mg", frequency: "Daily", timing: "07:30 AM", started: "Jul 03, 2026", relevance: "PPI — Decreases gastric acidity; potential T4 absorption inhibitor", status: "Changed" },
      { id: "m3", name: "Calcium Carbonate", dose: "600 mg", frequency: "Daily", timing: "08:00 AM", started: "May 2025", relevance: "Cation binder — Chelation risk if taken within 4 hours of T4", status: "Active" },
    ],
    nutritionSummary: {
      periodDays: 30,
      patterns: [
        "8 Calcium-rich breakfast meals logged near Levothyroxine administration window",
        "2 High-soy intake days noted in past month",
        "Overall dietary logging consistency: 88%"
      ],
      detailedLogs: [
        { id: "f1", date: "Sep 18, 2026", food: "Fortified Almond Milk Oatmeal", confidence: 0.94, constituent: "Calcium & Iron", relevance: "Potential chelation risk with T4" },
        { id: "f2", date: "Sep 12, 2026", food: "Greek Yogurt Bowl", confidence: 0.91, constituent: "Calcium", relevance: "30 mins after Levothyroxine dose" },
      ]
    },
    symptoms: [
      { name: "Fatigue", present: true, frequency: "Daily", severity: "Moderate", interference: "Moderate" },
      { name: "Cold Intolerance", present: true, frequency: "Intermittent", severity: "Mild", interference: "Mild" },
      { name: "Heat Intolerance", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Weight Change (+4 lbs)", present: true, frequency: "Constant", severity: "Mild", interference: "None" },
      { name: "Palpitations", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Tremor", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Sleep Disturbances", present: true, frequency: "Nightly", severity: "Mild", interference: "Mild" },
      { name: "Mood Changes", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Constipation", present: true, frequency: "3x / week", severity: "Mild", interference: "None" },
      { name: "Diarrhea", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Muscle Weakness", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Concentration (Brain Fog)", present: true, frequency: "Intermittent", severity: "Moderate", interference: "Moderate" },
      { name: "Neck Swelling", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Dry Skin / Hair Thinning", present: true, frequency: "Constant", severity: "Mild", interference: "None" },
      { name: "Menstrual Irregularity", present: false, frequency: "N/A", severity: "None", interference: "None" },
    ],
    symptomHistory: [
      { date: "May 2026", fatigue: 2, coldIntolerance: 1 },
      { date: "Jun 2026", fatigue: 2, coldIntolerance: 1 },
      { date: "Jul 2026", fatigue: 3, coldIntolerance: 2 },
      { date: "Aug 2026", fatigue: 3, coldIntolerance: 2 },
      { date: "Sep 2026", fatigue: 4, coldIntolerance: 3 },
    ],
    timeline: [
      { id: "t1", date: "Sep 20, 2026", title: "New Lab Result Processing", detail: "TSH 6.2 mIU/L (Elevated above reference ceiling 4.5)", type: "LAB" },
      { id: "t2", date: "Sep 18, 2026", title: "Patient Food Logged", detail: "Calcium fortified almond milk logged 30 min post-dose", type: "NUTRITION" },
      { id: "t3", date: "Jul 03, 2026", title: "Medication Addition", detail: "Omeprazole 20mg started by PCP for Acid Reflux", type: "MEDICATION" },
    ],
    alerts: [
      { id: "a1", category: "NEW LAB", title: "TSH Elevated (6.2 mIU/L)", date: "Sep 20, 2026", detail: "TSH increased +67% from 3.7 mIU/L baseline over 8 months. Co-occurs with Omeprazole initiation.", reviewed: false },
      { id: "a2", category: "MEDICATION EVENT", title: "PPI Timing Proximity Flag", date: "Jul 05, 2026", detail: "Omeprazole co-prescribed; patient dosing logs show < 30 min separation from Levothyroxine.", reviewed: false }
    ],
    reports: [
      { id: "r1", title: "Comprehensive Thyroid Report — Sep 2026", date: "Sep 20, 2026", type: "Comprehensive Thyroid Report" },
      { id: "r2", title: "Thyroid Baseline Report — Jan 2026", date: "Jan 12, 2026", type: "Initial Thyroid Summary" }
    ],
    appointments: [
      { id: "ap1", date: "Oct 12, 2026", time: "10:30 AM", provider: "Dr. Jane Smith", type: "Endocrinology Follow-Up", status: "Upcoming" }
    ],
    notes: [
      { id: "n1", date: "Jul 15, 2026", author: "Dr. Jane Smith", type: "private", text: "Discussed PPI interaction risk. Will monitor TSH in 8 weeks before considering T4 dose increase." },
      { id: "n2", date: "Jan 12, 2026", author: "Dr. Jane Smith", type: "patient-visible", text: "Continue Levothyroxine 75mcg daily on an empty stomach with a full glass of water." }
    ],
    familyAccess: [
      { id: "f1", name: "Suresh Venigalla", relation: "Son", accessLevel: "Full Access Delegate", email: "suresh@example.com" }
    ],
    sharingSettings: {
      hipaaConsentSigned: true,
      researchShareOptIn: false,
      externalEHRIntegration: true
    },
    auditHistory: [
      { id: "au1", timestamp: "2026-09-20 14:32:01", actor: "Dr. Jane Smith", action: "Viewed Patient Thyroid Summary", ip: "192.168.1.42" }
    ]
  },
  {
    id: "p2",
    name: "Marcus Thorne",
    mrn: "THY-84921",
    age: 52,
    sex: "Male",
    condition: "Post-Thyroidectomy Hypothyroidism",
    relationship: "Father",
    latestTSH: 2.1,
    latestFT4: 1.4,
    latestFT3: 3.1,
    lastLabDate: "Sep 14, 2026",
    nextVisit: "Nov 04, 2026",
    status: "STABLE",
    trend: "Stable",
    labs: [
      { id: "l21", date: "Sep 14, 2026", tsh: 2.1, ft4: 1.4, ft3: 3.1, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" },
      { id: "l22", date: "Mar 10, 2026", tsh: 2.2, ft4: 1.4, ft3: 3.0, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [
      { id: "m21", name: "Levothyroxine", dose: "125 mcg", frequency: "Daily", timing: "06:30 AM", started: "2022", relevance: "Full Replacement Post-Thyroidectomy", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: ["Consistent morning fasting protocol maintained"], detailedLogs: [] },
    symptoms: [
      { name: "Fatigue", present: false, frequency: "None", severity: "None", interference: "None" },
      { name: "Cold Intolerance", present: false, frequency: "None", severity: "None", interference: "None" }
    ],
    symptomHistory: [],
    timeline: [
      { id: "t21", date: "Sep 14, 2026", title: "Routine Lab Result", detail: "TSH 2.1 mIU/L — Well controlled", type: "LAB" }
    ],
    alerts: [],
    reports: [
      { id: "r21", title: "Annual Thyroid Evaluation — Sep 2026", date: "Sep 14, 2026", type: "Annual Summary" }
    ],
    appointments: [
      { id: "ap21", date: "Nov 04, 2026", time: "09:00 AM", provider: "Dr. Jane Smith", type: "Routine Checkup", status: "Upcoming" }
    ],
    notes: [
      { id: "n21", date: "Sep 14, 2026", author: "Dr. Jane Smith", type: "patient-visible", text: "Labs remain well target-controlled on Levothyroxine 125mcg." }
    ],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: [
      { id: "au21", timestamp: "2026-09-14 09:15:00", actor: "Dr. Jane Smith", action: "Signed Off Annual Labs", ip: "192.168.1.42" }
    ]
  },
  {
    id: "p3",
    name: "Sophia Martinez",
    mrn: "THY-84922",
    age: 34,
    sex: "Female",
    condition: "Hashimoto's Thyroiditis",
    relationship: "Sister",
    latestTSH: 14.8,
    latestFT4: 0.6,
    latestFT3: 1.9,
    lastLabDate: "Sep 22, 2026",
    nextVisit: "Sep 29, 2026",
    status: "REVIEW SUGGESTED",
    trend: "Increasing",
    labs: [
      { id: "l31", date: "Sep 22, 2026", tsh: 14.8, ft4: 0.6, ft3: 1.9, tpoAb: 480, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Elevated" },
      { id: "l32", date: "Jun 02, 2026", tsh: 3.2, ft4: 1.2, ft3: 2.9, tpoAb: 450, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [
      { id: "m31", name: "Levothyroxine", dose: "50 mcg", frequency: "Daily", timing: "08:00 AM", started: "Jan 2025", relevance: "T4 Replacement", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: ["Patient notes severe gluten sensitivity flair"], detailedLogs: [] },
    symptoms: [
      { name: "Fatigue", present: true, frequency: "Constant", severity: "Severe", interference: "Severe" },
      { name: "Cold Intolerance", present: true, frequency: "Constant", severity: "Severe", interference: "Moderate" },
      { name: "Concentration (Brain Fog)", present: true, frequency: "Daily", severity: "Severe", interference: "Severe" }
    ],
    symptomHistory: [
      { date: "Jun 2026", fatigue: 1, coldIntolerance: 1 },
      { date: "Sep 2026", fatigue: 5, coldIntolerance: 4 }
    ],
    timeline: [
      { id: "t31", date: "Sep 22, 2026", title: "Rapid TSH Flare", detail: "TSH rose from 3.2 to 14.8 mIU/L; FT4 dropped to 0.6 ng/dL", type: "LAB" }
    ],
    alerts: [
      { id: "a31", category: "TREND CHANGE", title: "Acute TSH Spike (14.8 mIU/L)", date: "Sep 22, 2026", detail: "Rapid loss of control in Hashimoto's patient. Immediate evaluation recommended.", reviewed: false }
    ],
    reports: [
      { id: "r31", title: "Urgent Hashimotos Flare Assessment", date: "Sep 22, 2026", type: "Urgent Lab Report" }
    ],
    appointments: [
      { id: "ap31", date: "Sep 29, 2026", time: "11:00 AM", provider: "Dr. Jane Smith", type: "Urgent Consult", status: "Upcoming" }
    ],
    notes: [
      { id: "n31", date: "Sep 22, 2026", author: "Dr. Jane Smith", type: "private", text: "Likely autoimmune destruction flare or complete non-adherence. Contacted patient." }
    ],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: [
      { id: "au31", timestamp: "2026-09-22 16:00:00", actor: "Dr. Jane Smith", action: "Flagged High Priority Review", ip: "192.168.1.42" }
    ]
  },
  {
    id: "p4",
    name: "Arthur Pendelton",
    mrn: "THY-84923",
    age: 67,
    sex: "Male",
    condition: "Hyperthyroidism (Subclinical)",
    relationship: "Grandfather",
    latestTSH: 0.12,
    latestFT4: 1.7,
    latestFT3: 3.9,
    lastLabDate: "Aug 30, 2026",
    nextVisit: "Oct 20, 2026",
    status: "TREND CHANGE",
    trend: "Decreasing",
    labs: [
      { id: "l41", date: "Aug 30, 2026", tsh: 0.12, ft4: 1.7, ft3: 3.9, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Suppressed" },
      { id: "l42", date: "Feb 15, 2026", tsh: 0.48, ft4: 1.5, ft3: 3.4, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [
      { id: "m41", name: "Methimazole", dose: "5 mg", frequency: "Daily", timing: "09:00 AM", started: "Mar 2026", relevance: "Antithyroid Medication", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: ["High seafood / iodine intake noted"], detailedLogs: [] },
    symptoms: [
      { name: "Palpitations", present: true, frequency: "Intermittent", severity: "Mild", interference: "Mild" },
      { name: "Heat Intolerance", present: true, frequency: "Daily", severity: "Mild", interference: "None" }
    ],
    symptomHistory: [],
    timeline: [
      { id: "t41", date: "Aug 30, 2026", title: "TSH Suppression Flag", detail: "TSH suppressed to 0.12 mIU/L", type: "LAB" }
    ],
    alerts: [
      { id: "a41", category: "NEW LAB", title: "Suppressed TSH (0.12 mIU/L)", date: "Aug 30, 2026", detail: "Subclinical hyperthyroidism progression. Consider Methimazole dose adjustment.", reviewed: false }
    ],
    reports: [
      { id: "r41", title: "Hyperthyroid Surveillance Report", date: "Aug 30, 2026", type: "Subclinical Evaluation" }
    ],
    appointments: [
      { id: "ap41", date: "Oct 20, 2026", time: "02:30 PM", provider: "Dr. Jane Smith", type: "Endocrinology Follow-Up", status: "Upcoming" }
    ],
    notes: [
      { id: "n41", date: "Aug 30, 2026", author: "Dr. Jane Smith", type: "private", text: "Evaluate ECG for atrial fibrillation risk given age and TSH suppression." }
    ],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: false, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p5",
    name: "Clara Oswald",
    mrn: "THY-84924",
    age: 29,
    sex: "Female",
    condition: "Thyroid Nodule (Benign)",
    relationship: "Cousin",
    latestTSH: 2.4,
    latestFT4: 1.2,
    latestFT3: 2.9,
    lastLabDate: "Aug 12, 2026",
    nextVisit: "Feb 12, 2027",
    status: "STABLE",
    trend: "Stable",
    labs: [
      { id: "l51", date: "Aug 12, 2026", tsh: 2.4, ft4: 1.2, ft3: 2.9, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [],
    nutritionSummary: { periodDays: 30, patterns: ["Balanced diet logged"], detailedLogs: [] },
    symptoms: [
      { name: "Neck Swelling", present: true, frequency: "Constant", severity: "Mild", interference: "None" }
    ],
    symptomHistory: [],
    timeline: [
      { id: "t51", date: "Aug 12, 2026", title: "Ultrasound & TSH Normal", detail: "TSH 2.4 mIU/L; Nodule stable at 1.1cm", type: "LAB" }
    ],
    alerts: [],
    reports: [
      { id: "r51", title: "Thyroid Ultrasound & Lab Summary", date: "Aug 12, 2026", type: "Ultrasound Report" }
    ],
    appointments: [
      { id: "ap51", date: "Feb 12, 2027", time: "10:00 AM", provider: "Dr. Jane Smith", type: "6-Month Nodule Follow-Up", status: "Upcoming" }
    ],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p6",
    name: "Benjamin Sisko",
    mrn: "THY-84925",
    age: 55,
    sex: "Male",
    condition: "Post-RAI Hypothyroidism",
    relationship: "Uncle",
    latestTSH: 4.1,
    latestFT4: 1.1,
    latestFT3: 2.7,
    lastLabDate: "Sep 01, 2026",
    nextVisit: "Dec 01, 2026",
    status: "STABLE",
    trend: "Stable",
    labs: [
      { id: "l61", date: "Sep 01, 2026", tsh: 4.1, ft4: 1.1, ft3: 2.7, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [
      { id: "m61", name: "Levothyroxine", dose: "100 mcg", frequency: "Daily", timing: "06:00 AM", started: "2023", relevance: "Post-RAI Ablation Replacement", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: [], detailedLogs: [] },
    symptoms: [],
    symptomHistory: [],
    timeline: [],
    alerts: [],
    reports: [],
    appointments: [],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: false, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p7",
    name: "Diana Prince",
    mrn: "THY-84926",
    age: 41,
    sex: "Female",
    condition: "Hypothyroidism on Armour Thyroid",
    relationship: "Aunt",
    latestTSH: 1.8,
    latestFT4: 0.9,
    latestFT3: 3.4,
    lastLabDate: "Jul 28, 2026",
    nextVisit: "Nov 15, 2026",
    status: "STABLE",
    trend: "Stable",
    labs: [
      { id: "l71", date: "Jul 28, 2026", tsh: 1.8, ft4: 0.9, ft3: 3.4, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Normal" }
    ],
    medications: [
      { id: "m71", name: "Armour Thyroid", dose: "60 mg (1 grain)", frequency: "Daily", timing: "07:00 AM", started: "2024", relevance: "Desiccated Thyroid Extract (T4 + T3)", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: [], detailedLogs: [] },
    symptoms: [],
    symptomHistory: [],
    timeline: [],
    alerts: [],
    reports: [],
    appointments: [],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p8",
    name: "Lucas Scott",
    mrn: "THY-84927",
    age: 28,
    sex: "Male",
    condition: "Subclinical Hypothyroidism",
    relationship: "Brother",
    latestTSH: 5.4,
    latestFT4: 1.2,
    latestFT3: 3.0,
    lastLabDate: "Sep 10, 2026",
    nextVisit: "Oct 30, 2026",
    status: "NEW LAB RESULT",
    trend: "Increasing",
    labs: [
      { id: "l81", date: "Sep 10, 2026", tsh: 5.4, ft4: 1.2, ft3: 3.0, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Elevated" }
    ],
    medications: [],
    nutritionSummary: { periodDays: 30, patterns: [], detailedLogs: [] },
    symptoms: [
      { name: "Fatigue", present: true, frequency: "Intermittent", severity: "Mild", interference: "Mild" }
    ],
    symptomHistory: [],
    timeline: [],
    alerts: [
      { id: "a81", category: "NEW LAB", title: "Subclinical Elevated TSH (5.4 mIU/L)", date: "Sep 10, 2026", detail: "First repeat lab confirming mild TSH elevation with normal FT4.", reviewed: false }
    ],
    reports: [],
    appointments: [],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p9",
    name: "Hannah Abbott",
    mrn: "THY-84928",
    age: 36,
    sex: "Female",
    condition: "Postpartum Thyroiditis",
    relationship: "Sister-in-Law",
    latestTSH: 0.25,
    latestFT4: 1.8,
    latestFT3: 4.1,
    lastLabDate: "Aug 18, 2026",
    nextVisit: "Oct 05, 2026",
    status: "FOLLOW-UP REQUESTED",
    trend: "Variable",
    labs: [
      { id: "l91", date: "Aug 18, 2026", tsh: 0.25, ft4: 1.8, ft3: 4.1, labName: "LabCorp", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Suppressed" }
    ],
    medications: [],
    nutritionSummary: { periodDays: 30, patterns: [], detailedLogs: [] },
    symptoms: [
      { name: "Palpitations", present: true, frequency: "Daily", severity: "Moderate", interference: "Mild" },
      { name: "Mood Changes", present: true, frequency: "Daily", severity: "Moderate", interference: "Moderate" }
    ],
    symptomHistory: [],
    timeline: [],
    alerts: [
      { id: "a91", category: "FOLLOW-UP", title: "Postpartum Thyrotoxic Phase", date: "Aug 18, 2026", detail: "4 months postpartum; monitoring for transition from thyrotoxic to hypothyroid phase.", reviewed: false }
    ],
    reports: [],
    appointments: [],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: false, externalEHRIntegration: true },
    auditHistory: []
  },
  {
    id: "p10",
    name: "Victor Stone",
    mrn: "THY-84929",
    age: 44,
    sex: "Male",
    condition: "Primary Hypothyroidism",
    relationship: "Brother",
    latestTSH: 8.9,
    latestFT4: 0.8,
    latestFT3: 2.4,
    lastLabDate: "Sep 23, 2026",
    nextVisit: "Oct 02, 2026",
    status: "REVIEW SUGGESTED",
    trend: "Increasing",
    labs: [
      { id: "l101", date: "Sep 23, 2026", tsh: 8.9, ft4: 0.8, ft3: 2.4, labName: "Quest Diagnostics", referenceRanges: { tsh: "0.45-4.5 mIU/L", ft4: "0.8-1.8 ng/dL", ft3: "2.3-4.2 pg/mL" }, status: "Elevated" }
    ],
    medications: [
      { id: "m101", name: "Levothyroxine", dose: "100 mcg", frequency: "Daily", timing: "07:00 AM", started: "2023", relevance: "Primary Synthetic T4 Replacement", status: "Active" }
    ],
    nutritionSummary: { periodDays: 30, patterns: ["Variable morning dosing routine reported"], detailedLogs: [] },
    symptoms: [
      { name: "Fatigue", present: true, frequency: "Constant", severity: "Severe", interference: "Moderate" }
    ],
    symptomHistory: [],
    timeline: [],
    alerts: [
      { id: "a101", category: "NEW LAB", title: "TSH 8.9 mIU/L — Under-replaced", date: "Sep 23, 2026", detail: "TSH elevated with FT4 at lower bound of normal. Evaluate dose increase or compliance.", reviewed: false }
    ],
    reports: [],
    appointments: [],
    notes: [],
    familyAccess: [],
    sharingSettings: { hipaaConsentSigned: true, researchShareOptIn: true, externalEHRIntegration: true },
    auditHistory: []
  }
];

export function getPatientById(id: string): PatientProfile {
  return MOCK_PATIENTS.find(p => p.id === id) || MOCK_PATIENTS[0];
}
