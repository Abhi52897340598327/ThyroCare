"use client";
import { FormEvent, useRef, useState } from "react";
import { CareRecord, Kind, analyteUnits, careAPI, kindNames, symptomNames } from "@/lib/care-api";
import { normalizeMealPhoto } from "./CareMealPhoto";
type Field = { key: string; label: string; required?: boolean; options?: string[]; type?: string };
const field = (key: string, label: string, required = false, type = "text"): Field => ({ key, label, required, type });
export default function CareRecordForm({ patientID, kind, original, onSaved, onCancel }: { patientID: string; kind: Kind; original?: CareRecord; onSaved: () => void; onCancel: () => void }) {
    const [values, setValues] = useState<Record<string,string>>(original?.fields ?? { ...(kind === "labs" ? { analyte: "TSH", unit: "mIU/L" } : {}), ...(kind === "medications" ? { doseMode: "unknown", unit: "mcg" } : {}), timezone: Intl.DateTimeFormat().resolvedOptions().timeZone, scaleVersion: "custom-0-4-v1", visibility: "patient", state: "draft", status: kind === "appointments" ? "confirmed" : "Submitted" });
    const [error, setError] = useState("");
    const [saving, setSaving] = useState(false);
    const [photo, setPhoto] = useState<string>();
    const [preparingPhoto, setPreparingPhoto] = useState(false);
    const photoRevision = useRef(0);
    const stableID = useRef(original?.id ?? crypto.randomUUID());
    let fields: Field[] = [];
    if (kind === "labs") fields = [
        { key: "analyte", label: "Analyte", options: Object.keys(analyteUnits), required: true }, field("result", "Result (preserve < or >)", true),
        { key: "unit", label: "Report unit", options: analyteUnits[values.analyte] ?? [], required: true },
        field("collectedDate", "Blood collected (unknown may be blank)", false, "date"), field("receivedDate", "Result received", false, "date"),
        field("source", "Laboratory / report source", true), field("referenceLower", "Report interval lower bound"), field("referenceUpper", "Report interval upper bound"),
        field("targetLower", "Separate clinician target lower bound"), field("targetUpper", "Separate clinician target upper bound"), field("targetSource", "Clinician target source") ];
    if (kind === "symptoms") fields = [field("observedDate", "Observation date", true, "date"), ...Object.entries(symptomNames).map(([key,label]) => ({ key, label, options: ["", "0", "1", "2", "3", "4"] })), field("interference", "Daily-life interference"), field("context", "Context")];
    if (kind === "weekly-checkins") fields = [field("recallStart", "Recall window start", true, "date"), field("recallEnd", "Recall window end", true, "date"), field("body", "Weekly burden, medicine changes, missed doses, side effects, illness and questions", true)];
    if (kind === "medications") fields = [field("name", "Medicine / supplement name (amiodarone is separate from thyroid replacement)", true), field("formulation", "Formulation / route"), { key: "doseMode", label: "Dose certainty", options: ["unknown", "exact", "range"] }, ...(values.doseMode === "unknown" ? [] : [field("doseLower", "Exact dose or patient-estimated lower bound", true), ...(values.doseMode === "range" ? [field("doseUpper", "Patient-estimated upper bound", true)] : []), { key: "unit", label: "Dose unit", options: ["mcg", "mg", "g", "mL", "tablet"] }]), field("schedule", "Recorded days / times / PRN schedule", true), field("source", "Prescription source"), field("context", "Original wording / notes")];
    if (kind === "vitals") fields = [{ key: "type", label: "Measurement", options: ["weight", "height", "BMI", "bloodPressure", "heartRate"] }, field("value", "Value (systolic for BP)", true), ...(values.type === "bloodPressure" ? [field("diastolic", "Diastolic pressure", true)] : []), field("unit", "Unit: kg, lb, cm, in, kg/m², mmHg or bpm", true), field("observedDate", "Measurement date", true, "date"), field("source", "Source: home, office, device", true), field("context", "Resting / activity / measurement context")];
    if (kind === "meals") fields = [field("description", "Foods, portions and preparation", true), field("observedDate", "Actual meal date", true, "date"), field("mealTime", "Actual meal time", true, "time"), field("diet", "Diet or eating pattern, if you know it (optional)"), field("context", "Notes")];
    if (kind === "messages") fields = [field("body", "Message to this patient's connected care thread", true)];
    if (kind === "requests") fields = [field("requestType", "Request type", true), field("body", "Question", true), field("linkedRecordID", "Linked record ID (optional)"), ...(original ? [{ key: "status", label: "Status", options: ["Submitted", "Received/Assigned", "In review", "Answered", "Closed", "Cancelled", "Clarification needed"] }, field("response", "Clinician response"), field("owner", "Assigned owner")] : [])];
    if (kind === "notes") fields = [field("body", "Patient-visible clinical documentation", true), { key: "state", label: "State", options: ["draft", "signed", "amendment"] }, field("linkedRecordID", "Linked original note / source record")];
    if (kind === "appointments") fields = [field("observedDate", "Appointment date", true, "date"), field("time", "Time", true, "time"), field("timezone", "IANA timezone", true), { key: "status", label: "Status", options: ["confirmed", "cancelled", "completed"] }, field("source", "Scheduling source", true)];
    async function save(event: FormEvent) {
        event.preventDefault(); setSaving(true); setError("");
        try { await careAPI(`patients/${patientID}/${kind}`, "POST", { id: stableID.current, expectedVersion: original?.version ?? 0, fields: { ...values, ...(photo ? { hasPhoto: "true" } : {}) } });
            if (photo) await careAPI(`patients/${patientID}/meals/${stableID.current}/photo`, "POST", { imageBase64: photo });
            onSaved(); }
        catch (e) { setError((e as Error).message); }
        finally { setSaving(false); }
    }
    return <form className="care-card" onSubmit={save}>
        <h2>{original ? "Correct" : "Add"} {kindNames[kind].toLowerCase()}</h2>
        {kind === "symptoms" && <p>Custom scale: 0 None · 1 Mild · 2 Moderate · 3 Severe · 4 Very severe. Not assessed remains missing. This is not a validated diagnostic score.</p>}
        {kind === "medications" && <p>Patient-estimated ranges are recorded uncertainty, never a recommendation to choose a dose. Iron, calcium and biotin are separate supplement entries.</p>}
        {kind === "labs" && <p>Dates and intervals remain unknown when blank. Free and total hormones are distinct. Interval bounds use the selected report unit.</p>}
        {kind === "weekly-checkins" && <p>This custom weekly recollection is separate from daily observations. Enter a seven-day recall window.</p>}
        {kind === "meals" && !original && <div><label>Optional meal photo<input type="file" accept="image/*" disabled={saving} onChange={async e => {
            const file = e.target.files?.[0]; const revision = ++photoRevision.current;
            setPhoto(undefined); if (!file) return;
            setPreparingPhoto(true);
            try { const jpeg = await normalizeMealPhoto(file); if (revision === photoRevision.current) setPhoto(jpeg); }
            catch(e) { setError((e as Error).message); }
            finally { if (revision === photoRevision.current) setPreparingPhoto(false); }
        }} /></label>{preparingPhoto && <p role="status">Preparing photo…</p>}{photo && <><img src={"data:image/jpeg;base64," + photo} alt="Meal photo to confirm" style={{ maxHeight: 260, maxWidth: "100%" }} /><p>Save confirms this photo belongs to your meal and shares it with the connected care team. No external AI analysis is performed.</p><button type="button" onClick={() => setPhoto(undefined)}>Discard photo</button></>}</div>}
        <div className="care-form-grid">{fields.map(f => <label key={f.key}>{f.label}{f.required && " *"}{f.options ? <select aria-label={f.label} required={f.required} value={values[f.key] ?? ""} onChange={e => setValues(v => ({ ...v, [f.key]: e.target.value, ...(f.key === "analyte" ? { unit: analyteUnits[e.target.value][0] } : {}) }))}><option value="" disabled={!f.options.includes("")}>{f.options.includes("") ? "Not assessed" : "Select"}</option>{f.options.filter(Boolean).map(o => <option key={o}>{o}</option>)}</select> : f.key === "body" ? <textarea aria-label={f.label} required value={values[f.key] ?? ""} onChange={e => setValues(v => ({ ...v, [f.key]: e.target.value }))} rows={5} /> : <input aria-label={f.label} type={f.type} required={f.required} value={values[f.key] ?? ""} onChange={e => setValues(v => ({ ...v, [f.key]: e.target.value }))} />}</label>)}</div>
        {error && <p role="alert">{error}</p>}
        <div className="care-controls"><button className="care-primary" disabled={saving || preparingPhoto}>{saving ? "Saving…" : "Save record"}</button><button type="button" onClick={onCancel} disabled={saving}>Cancel</button></div>
    </form>;
}
