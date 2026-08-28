export type MedicationFrequency = "Daily" | "Weekly";

export interface MedicationLogEntry {
    id: string;
    medicationName: string;
    doseMicrograms: number;
    frequency: MedicationFrequency;
    dosesPerWeek: number;
    adherencePercent: number;
    minutesBeforeFood: number;
    separatesIronCalciumByFourHours: boolean;
}

export type BiologicalSex = "Female" | "Male" | "Intersex";
export type RaceEthnicity =
    | "Asian"
    | "Black"
    | "Hispanic/Latino"
    | "Native American"
    | "White"
    | "Multiracial"
    | "Not specified";

export interface DemographicProfile {
    age: number;
    biologicalSex: BiologicalSex;
    raceEthnicity: RaceEthnicity;
    weightKilograms: number;
    baselineTSH: number;
    targetTSH: number;
}

export interface TSHProjectionPoint {
    day: number;
    tsh: number;
}

export interface MedicationTSHProjection {
    points: TSHProjectionPoint[];
    projectedTSHAt90Days: number;
    targetTSH: number;
    summary: string;
    clinicalAssumptions: string[];
}

export interface AnalyzeTSHRequest {
    medications: MedicationLogEntry[];
    demographicProfile: DemographicProfile;
}

export async function POST(request: Request): Promise<Response> {
    const payload = (await request.json()) as AnalyzeTSHRequest;
    const projection = analyzeMedicationEffects(payload.medications, payload.demographicProfile);

    return Response.json(projection, {
        headers: {
            "Cache-Control": "no-store"
        }
    });
}

export function analyzeMedicationEffects(
    medications: MedicationLogEntry[],
    demographicProfile: DemographicProfile
): MedicationTSHProjection {
    const totalEffectiveDose = medications.reduce((sum, medication) => {
        return sum + effectiveDailyDose(medication);
    }, 0);

    const expectedReplacementDose = expectedDailyReplacementDose(demographicProfile);
    const referenceTarget = demographicAdjustedTargetTSH(demographicProfile);
    const targetTSH = clamp(demographicProfile.targetTSH, 0.4, Math.max(referenceTarget, 0.8));

    // Clinical assumption: TSH response trails levothyroxine exposure. A six-week time constant approximates
    // the usual post-dose-change monitoring window and avoids implying day-to-day diagnostic certainty.
    const responseTimeConstantDays = 42;

    // Clinical assumption: dose adequacy is a bounded ratio around an estimated replacement dose.
    // This prototype must be recalibrated with endocrinologist-reviewed longitudinal outcome data.
    const doseAdequacyRatio = totalEffectiveDose / Math.max(expectedReplacementDose, 1);
    const doseEffect = clamp(doseAdequacyRatio, 0.25, 1.55);
    const asymptoticTSH = targetTSH + (demographicProfile.baselineTSH - targetTSH) * (1 - doseEffect);
    const boundedAsymptote = clamp(asymptoticTSH, 0.05, 20);

    const points = [0, 15, 30, 45, 60, 75, 90].map((day) => {
        const responseFraction = 1 - Math.exp(-day / responseTimeConstantDays);
        const tsh = demographicProfile.baselineTSH
            + (boundedAsymptote - demographicProfile.baselineTSH) * responseFraction;
        return { day, tsh: roundTwo(tsh) };
    });

    const projectedTSHAt90Days = points[points.length - 1]?.tsh ?? demographicProfile.baselineTSH;

    return {
        points,
        projectedTSHAt90Days,
        targetTSH,
        summary: buildSummary({
            baselineTSH: demographicProfile.baselineTSH,
            projectedTSH: projectedTSHAt90Days,
            targetTSH,
            totalEffectiveDose,
            expectedReplacementDose
        }),
        clinicalAssumptions: [
            "Levothyroxine effect is modeled with a 42-day response time constant, reflecting delayed TSH stabilization after dose changes.",
            "Effective dose is reduced when medication is taken too close to food or iron/calcium supplements.",
            "Age, biological sex, and race/ethnicity adjust the reference target slightly; these offsets are statistical priors, not diagnostic rules.",
            "The model is for education and review only until validated against labeled clinical outcomes."
        ]
    };
}

function effectiveDailyDose(medication: MedicationLogEntry): number {
    const weeklyDose = medication.frequency === "Daily"
        ? medication.doseMicrograms * medication.dosesPerWeek
        : medication.doseMicrograms;
    const adherenceAdjustedDose = (weeklyDose / 7) * (medication.adherencePercent / 100);
    const foodAbsorptionFactor = medication.minutesBeforeFood >= 30 ? 1.0 : 0.86;
    const supplementAbsorptionFactor = medication.separatesIronCalciumByFourHours ? 1.0 : 0.78;

    return adherenceAdjustedDose * foodAbsorptionFactor * supplementAbsorptionFactor;
}

function demographicAdjustedTargetTSH(profile: DemographicProfile): number {
    let target = profile.targetTSH;

    // Clinical assumption: population studies show TSH upper reference limits tend to rise with age.
    if (profile.age >= 70) {
        target += 0.45;
    } else if (profile.age >= 50) {
        target += 0.20;
    }

    // Clinical assumption: reported thyroid-function distributions differ by sex and race/ethnicity.
    // These small offsets prevent one default reference interval from being treated as universal.
    if (profile.biologicalSex === "Female" || profile.biologicalSex === "Intersex") {
        target += 0.05;
    } else {
        target -= 0.05;
    }

    if (profile.raceEthnicity === "White") {
        target += 0.10;
    } else if (profile.raceEthnicity === "Black") {
        target -= 0.15;
    } else if (profile.raceEthnicity === "Hispanic/Latino") {
        target -= 0.05;
    }

    return clamp(target, 0.4, 4.8);
}

function expectedDailyReplacementDose(profile: DemographicProfile): number {
    let microgramsPerKilogram = 1.6;

    // Clinical assumption: older adults often require lower starting/replacement exposure because cardiac
    // and metabolic sensitivity changes with age. This is not a prescribing recommendation.
    if (profile.age >= 70) {
        microgramsPerKilogram = 1.1;
    } else if (profile.age >= 60) {
        microgramsPerKilogram = 1.3;
    }

    if (profile.biologicalSex === "Female") {
        microgramsPerKilogram *= 0.96;
    }

    return Math.max(profile.weightKilograms, 30) * microgramsPerKilogram;
}

function buildSummary(input: {
    baselineTSH: number;
    projectedTSH: number;
    targetTSH: number;
    totalEffectiveDose: number;
    expectedReplacementDose: number;
}): string {
    let trend = "stay relatively stable over the next few lab cycles";
    if (input.projectedTSH < input.baselineTSH - 0.4) {
        trend = "trend downward toward the selected target range";
    } else if (input.projectedTSH > input.baselineTSH + 0.4) {
        trend = "trend upward, which may mean the effective dose is not enough for this profile";
    }

    const doseContext = input.totalEffectiveDose >= input.expectedReplacementDose * 0.9
        ? "near the estimated replacement range"
        : "below the estimated replacement range";

    return `Based on the logged dose timing and demographic profile, the model expects TSH to ${trend}. `
        + `The effective daily exposure is about ${Math.round(input.totalEffectiveDose)} mcg/day, which is ${doseContext}. `
        + `If TSH moves closer to ${input.targetTSH.toFixed(1)} mIU/L, many patients report steadier energy, less cold intolerance, and improved mental clarity, but symptoms and dose changes should be reviewed with a clinician.`;
}

function clamp(value: number, lower: number, upper: number): number {
    return Math.min(Math.max(value, lower), upper);
}

function roundTwo(value: number): number {
    return Math.round(value * 100) / 100;
}
