export type Identity = { id: string; name: string; role: "patient" | "clinician" };
export type CareRecord = { id: string; patientID: string; kind: string; version: number; recordedAt: string; authorID: string; fields: Record<string, string> };
export const kinds = ["labs", "symptoms", "weekly-checkins", "medications", "vitals", "meals", "messages", "requests", "notes", "appointments", "care-plans", "administrations", "questionnaire"] as const;
export type Kind = typeof kinds[number];
export const kindNames: Record<Kind, string> = { labs: "Labs and trends", symptoms: "Daily symptoms", "weekly-checkins": "Weekly check-ins", medications: "Medications", vitals: "Vitals", meals: "Meals / Nutrition", messages: "Messages", requests: "Information requests", notes: "Shared notes", appointments: "Appointments", "care-plans": "Care plans", administrations: "Dose logs", questionnaire: "Questionnaire" };
export const analyteUnits: Record<string, string[]> = { TSH: ["mIU/L", "µIU/mL"], "Free T4": ["ng/dL", "pmol/L"], "Free T3": ["pg/mL", "pmol/L"], "Total T4": ["µg/dL", "nmol/L"], "Total T3": ["ng/dL", "nmol/L"] };
export const symptomNames: Record<string, string> = { fatigue: "Fatigue / low energy", concentration: "Concentration", mood: "Mood", sleep: "Sleep", temperature: "Temperature intolerance", palpitations: "Palpitations (reported)", tremor: "Tremor", bowel: "Bowel changes", muscle: "Muscle symptoms", skinHair: "Skin / hair concerns" };
export async function careAPI<T>(path: string, method = "GET", body?: unknown, signal?: AbortSignal): Promise<T> {
    const base = (process.env.NEXT_PUBLIC_VAPOR_API_BASE_URL ?? "").replace(/\/$/, "");
    const response = await fetch(`${base}/v1/${path}`, { method, credentials: "include", cache: "no-store", signal,
        headers: { "Content-Type": "application/json" }, body: body === undefined ? undefined : JSON.stringify(body) });
    if (response.status === 404 && path.startsWith("auth/")) {
        throw new Error("Account service is unavailable on the configured server. Deploy the current ThyroCare backend before creating an account or signing in.");
    }
    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.reason ?? "The request failed. No server save was confirmed.");
    }
    return response.status === 204 ? undefined as T : response.json();
}

export function observationDate(record: CareRecord) { return record.fields.collectedDate || record.fields.observedDate || record.fields.recallEnd || "Date not recorded"; }
export function recordTitle(record: CareRecord) { return record.fields.analyte || record.fields.name || record.fields.type || record.fields.description || kindNames[record.kind as Kind] || record.kind; }
export function symptomSummary(records: CareRecord[]) {
    const daily = records.filter(r => r.kind === "symptoms");
    const dates = daily.map(r => r.fields.observedDate).filter(Boolean).sort();
    const lines = ["Descriptive diary review — unsigned clinician draft. No symptom-to-hormone prediction or dosing recommendation.", `Observation window: ${dates[0] ?? "not recorded"} to ${dates[dates.length - 1] ?? "not recorded"}. ${new Set(dates).size} distinct recorded dates.`];
    for (const [key, name] of Object.entries(symptomNames)) {
        const assessed = daily.filter(r => r.fields[key] !== undefined && r.fields[key] !== "");
        if (assessed.length) lines.push(`${name}: ${assessed.filter(r => Number(r.fields[key]) >= 3).length} of ${assessed.length} recorded entries rated severe or very severe (custom 0–4 scale).`);
    }
    lines.push("Coverage counts recorded entries only; missing days are not symptom-free. Confirm observation windows, medication changes, illness and other explanations with the patient. Individual hormone forecasting is not validated.");
    lines.push("Sources: " + daily.map(r => `${r.id} v${r.version} (${r.fields.observedDate})`).join(", "));
    return lines.join("\n\n");
}
