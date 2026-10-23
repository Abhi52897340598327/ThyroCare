"use client";
import { FormEvent, useCallback, useEffect, useRef, useState } from "react";
import { CareRecord, Identity, Kind, careAPI, kinds, kindNames, observationDate, recordTitle, symptomSummary } from "@/lib/care-api";
import CareChart from "./CareChart";
import CareSymptomChart from "./CareSymptomChart";
import { compareRoster, nextAppointment } from "@/lib/care-roster";
import CareMealPhoto from "./CareMealPhoto";
import CareRecordForm from "./CareRecordForm";
import "./care.css";

export default function CarePortal() {
    const [user, setUser] = useState<Identity>();
    const [checking, setChecking] = useState(true);
    const [patients, setPatients] = useState<Identity[]>([]);
    const [patient, setPatient] = useState<Identity>();
    const [error, setError] = useState("");
    useEffect(() => { careAPI<Identity>("me").then(setUser).catch(() => {}).finally(() => setChecking(false)); }, []);
    useEffect(() => {
        if (!user) return;
        const abort = new AbortController();
        careAPI<Identity[]>("patients", "GET", undefined, abort.signal).then(list => {
            if (abort.signal.aborted) return;
            setPatients(list);
            if (user.role === "patient") setPatient(user);
            else {
                const match = window.location.pathname.match(/patients\/([^/]+)/);
                if (match) {
                    const authorized = list.find(p => p.id === decodeURIComponent(match[1]));
                    if (authorized) setPatient(authorized);
                    else setError("The linked patient is not in your authorized roster.");
                }
            }
        }).catch(e => { if (e.name !== "AbortError") setError(e.message); });
        return () => abort.abort();
    }, [user]);
    async function logout() {
        try { await careAPI("auth/logout", "POST"); setPatient(undefined); setPatients([]); setUser(undefined); }
        catch(e) { setError((e as Error).message); }
    }
    if (checking) return <main className="care-app"><p role="status">Verifying session…</p></main>;
    if (!user) return <CareLogin onLogin={setUser} />;
    return <div className="care-app">
        <header className="care-top"><a href="/" className="care-brand">ThyroCare</a><span>{user.name} · {user.role}</span><button onClick={logout}>Sign out</button></header>
        {error && <p role="alert">{error}</p>}
        {user.role === "clinician" && <CareRoster patients={patients} onSelect={setPatient} />}
        {patient ? <CarePatientWorkspace key={`${user.id}:${patient.id}`} user={user} patient={patient} /> : <section className="care-card"><h1>Your practice</h1><p>Select an authorized patient or invite a patient to connect. No example patients are inserted.</p></section>}
        <CareSharing key={user.id} user={user} />
        <footer>Development build. Account recovery, deletion, notification delivery, camera capture and clinical-release review remain incomplete. Forecasts are unavailable.</footer>
    </div>;
}

function CareLogin({ onLogin }: { onLogin: (user: Identity) => void }) {
    const [register, setRegister] = useState(false);
    const [error, setError] = useState("");
    const [busy, setBusy] = useState(false);
    async function submit(e: FormEvent<HTMLFormElement>) {
        e.preventDefault(); setBusy(true); setError("");
        const data = new FormData(e.currentTarget);
        try { const session = await careAPI<{ user: Identity }>(register ? "auth/register" : "auth/login", "POST", Object.fromEntries(data)); onLogin(session.user); }
        catch (e) { setError((e as Error).message); }
        finally { setBusy(false); }
    }
    return <main className="care-app care-login"><section className="care-card"><span className="care-brand">ThyroCare</span><h1>Your care, in one place.</h1><p>Keep records. Understand measured patterns. Communicate with your care team.</p>
        <form onSubmit={submit}><h2>{register ? "Create patient account" : "Sign in"}</h2>{register && <label>Name<input name="name" autoComplete="name" required maxLength={120} /></label>}
            <label>Email<input name="email" type="email" autoComplete="username" required /></label><label>Password<input name="password" type="password" autoComplete={register ? "new-password" : "current-password"} minLength={register ? 12 : undefined} required /></label>
            {error && <p role="alert">{error}</p>}<button disabled={busy} className="care-primary">{busy ? "Connecting…" : register ? "Create account" : "Sign in"}</button>
        </form><button onClick={() => setRegister(!register)}>{register ? "I have an account" : "Create patient account"}</button><p>Clinician accounts are provisioned by the practice operator. A visual role selector cannot grant clinical access.</p></section></main>;
}

function CarePatientWorkspace({ user, patient }: { user: Identity; patient: Identity }) {
    const [records, setRecords] = useState<CareRecord[]>([]);
    const [kind, setKind] = useState<Kind>("labs");
    const [navigationOpen, setNavigationOpen] = useState(false);
    const [status, setStatus] = useState("Loading records…");
    const [error, setError] = useState("");
    const [editing, setEditing] = useState<{ original?: CareRecord }>();
    const [detail, setDetail] = useState<CareRecord>();
    const [history, setHistory] = useState<CareRecord[]>([]);
    const generation = useRef(0);
    useEffect(() => {
        const section = window.location.pathname.split("/").filter(Boolean).at(-1);
        const aliases: Record<string, Kind> = { labs: "labs", trends: "labs", symptoms: "symptoms", medications: "medications", nutrition: "meals", "food-analysis": "meals", notes: "notes", appointments: "appointments" };
        if (section && aliases[section]) setKind(aliases[section]);
    }, []);

    const refresh = useCallback(async (signal?: AbortSignal) => {
        const current = ++generation.current;
        try {
            const result = await Promise.all(kinds.map(k => careAPI<CareRecord[]>(`patients/${patient.id}/${k}`, "GET", undefined, signal)));
            if (current !== generation.current || signal?.aborted) return;
            setRecords(result.flat()); setStatus(`Synced at ${new Date().toLocaleTimeString()}`); setError("");
        } catch(e) { if (!signal?.aborted && current === generation.current) { setStatus("Sync failed — last loaded records retained"); setError((e as Error).message); } }
    }, [patient.id]);
    useEffect(() => {
        const abort = new AbortController(); void refresh(abort.signal);
        const timer = setInterval(() => void refresh(abort.signal), 15000);
        return () => { generation.current++; abort.abort(); clearInterval(timer); };
    }, [refresh]);
    const selected = records.filter(r => r.kind === kind).sort((a,b) => kind === "messages" ? a.recordedAt.localeCompare(b.recordedAt) : observationDate(b).localeCompare(observationDate(a)));
    async function showHistory(record: CareRecord) {
        setDetail(record); setHistory([]);
        try { const versions = await careAPI<CareRecord[]>(`patients/${patient.id}/${record.kind}?history=true`); setHistory(versions.filter(r => r.id === record.id)); }
        catch(e) { setError((e as Error).message); }
    }
    async function generateSummary() {
        try {
            await careAPI(`patients/${patient.id}/notes`, "POST", { id: crypto.randomUUID(), expectedVersion: 0, fields: { body: symptomSummary(records), state: "draft", visibility: "patient", generator: "descriptive-diary-v1", sourceVersions: records.filter(r => r.kind === "symptoms").map(r => `${r.id}:${r.version}`).join(",") } });
            setKind("notes"); await refresh();
        } catch(e) { setError((e as Error).message); }
    }
    return <main>
        <section className="care-patient-header"><div><p>Patient workspace</p><h1>{patient.name}</h1><p>ID {patient.id}</p></div><div><span role="status">{status}</span><button onClick={() => refresh()}>Refresh</button></div></section>
        <button className="care-mobile-navigation" aria-expanded={navigationOpen} aria-controls="patient-record-navigation" onClick={() => setNavigationOpen(open => !open)}>{kindNames[kind]} · {navigationOpen ? "Close navigation" : "Change section"}</button>
        <nav id="patient-record-navigation" className={`care-nav${navigationOpen ? " is-open" : ""}`} aria-label="Patient records">{kinds.map(k => <button key={k} aria-current={kind === k ? "page" : undefined} onClick={() => { setKind(k); setNavigationOpen(false); setEditing(undefined); setDetail(undefined); }}>{kindNames[k]}</button>)}</nav>
        {error && <p role="alert">{error}</p>}
        {kind === "labs" && <CareChart records={records.filter(r => r.kind === "labs")} />}
        {kind === "symptoms" && <section className="care-card"><h2>Symptoms over time</h2><p>{new Set(selected.map(r => r.fields.observedDate).filter(d => d && Date.parse(d) >= Date.now() - 7 * 86400000)).size} distinct logged dates in the last seven days. Unlogged days are missing.</p><p>Custom 0–4 scale: None, Mild, Moderate, Severe, Very severe. Weekly recollections are separate records.</p><p>Individualized symptom-to-hormone forecasting is not validated. No effect size is calculated.</p>{user.role === "clinician" && <button onClick={generateSummary} disabled={!selected.length}>Generate clinical symptom summary</button>}<p>Generated summaries use a descriptive template with source IDs and versions; they are patient-visible unsigned drafts, not AI treatment advice.</p></section>}
        {kind === "symptoms" && <CareSymptomChart records={records} />}
        {kind === "meals" && <section className="care-card"><h2>Meal context</h2><p>Manual logging is available. Confirmed photos are stored with the meal. Nutrient estimation and detailed AI summaries are not yet connected. Unknown nutrient quantities are not zero.</p></section>}
        {kind === "messages" && <section className="care-card"><h2>Care thread</h2><p>Shared with this patient’s authorized care team. Confirm response times with your practice. This is not an emergency service.</p></section>}
        {editing ? <CareRecordForm key={`${patient.id}:${kind}:${editing.original?.id ?? "new"}`} patientID={patient.id} kind={kind} original={editing.original} onSaved={() => { setEditing(undefined); void refresh(); }} onCancel={() => setEditing(undefined)} /> : <section className="care-card">
            <div className="care-heading"><h2>{kindNames[kind]}</h2>{(!["care-plans", "administrations", "questionnaire"].includes(kind) && (!["notes", "appointments"].includes(kind) || user.role === "clinician")) && <button className="care-primary" onClick={() => setEditing({})}>Add record</button>}</div>
            {!selected.length && <p>No saved records. Nothing has been filled with example values.</p>}
            {selected.map(record => <article className="care-record" key={record.id}>
                <h3>{recordTitle(record)}</h3>{record.kind === "meals" && record.fields.hasPhoto === "true" && <CareMealPhoto record={record} />}{record.fields.result && <p className="care-metric">{record.fields.result} <span>{record.fields.unit}</span></p>}
                {record.fields.body && <p className="care-prose">{record.fields.body}</p>}
                {record.fields.sourceVersions && record.fields.sourceVersions.split(",").some(pair => { const [id,version] = pair.split(":"); return records.find(r => r.id === id)?.version !== Number(version); }) && <p role="status">Source entries changed. This saved summary is outdated and needs review.</p>}
                <p>{observationDate(record)} · {record.fields.source || "Entered record"} · Version {record.version}{record.fields.state ? ` · ${record.fields.state}` : ""}</p>
                <button onClick={() => showHistory(record)}>Details and history</button>
                {(record.authorID === user.id || (kind === "requests" && user.role === "clinician")) && !["messages", "care-plans", "administrations"].includes(kind) && record.fields.state !== "signed" && <button onClick={() => setEditing({ original: record })}>Correct record</button>}
            </article>)}
        </section>}
        {detail && <section className="care-card"><div className="care-heading"><h2>Record details</h2><button onClick={() => setDetail(undefined)}>Close details</button></div><dl>{Object.entries(detail.fields).filter(([,v]) => v !== "").map(([key,value]) => <div key={key}><dt>{key}</dt><dd>{value}</dd></div>)}</dl><p>Entered {detail.recordedAt} · Author {detail.authorID}</p><h3>Revision history</h3>{history.map(r => <details key={r.version}><summary>Version {r.version} · {r.recordedAt}</summary><dl>{Object.entries(r.fields).map(([k,v]) => <div key={k}><dt>{k}</dt><dd>{v || "Not recorded"}</dd></div>)}</dl></details>)}</section>}
    </main>;
}

function CareRoster({ patients, onSelect }: { patients: Identity[]; onSelect: (p: Identity) => void }) {
    const [sort, setSort] = useState("appointment");
    const [query, setQuery] = useState("");
    const [dates, setDates] = useState<Record<string, { appointment?: string; lab?: string }>>({});
    useEffect(() => { const saved = localStorage.getItem("care-roster-sort"); if (saved) setSort(saved); }, []);
    useEffect(() => {
        const abort = new AbortController();
        Promise.all(patients.map(async p => {
            const [appointments, labs] = await Promise.all([careAPI<CareRecord[]>(`patients/${p.id}/appointments`, "GET", undefined, abort.signal), careAPI<CareRecord[]>(`patients/${p.id}/labs`, "GET", undefined, abort.signal)]);
            // Only absolute UTC instants can be sorted reliably; local times without offsets remain unknown.
            const upcoming = nextAppointment(appointments, Date.now());
            const lab = labs.map(r => r.fields.collectedDate).filter(Boolean).sort().reverse()[0];
            return [p.id, { appointment: upcoming, lab }] as const;
        })).then(rows => { if (!abort.signal.aborted) setDates(Object.fromEntries(rows)); }).catch(() => {});
        return () => abort.abort();
    }, [patients]);
    const ordered = [...patients].filter(p => p.name.toLowerCase().includes(query.toLowerCase())).sort((a,b) => compareRoster(a, b, dates, sort));
    return <section className="care-card"><h2>Your patients</h2><div className="care-controls"><label>Search<input value={query} onChange={e => setQuery(e.target.value)} /></label><label>Sort<select value={sort} onChange={e => { setSort(e.target.value); localStorage.setItem("care-roster-sort", e.target.value); }}><option value="appointment">Upcoming appointment</option><option value="lab">Latest blood collection</option><option value="oldest">Oldest blood collection</option><option value="name">Patient name</option></select></label></div><div className="care-table-wrap"><table><thead><tr><th>Patient</th><th>Next confirmed appointment</th><th>Latest blood collection</th></tr></thead><tbody>{ordered.map(p => <tr key={p.id}><td><button onClick={() => onSelect(p)}>{p.name}</button><small>{p.id}</small></td><td>{dates[p.id]?.appointment || "No upcoming appointment"}</td><td>{dates[p.id]?.lab || "Not recorded"}</td></tr>)}</tbody></table></div></section>;
}

function CareSharing({ user }: { user: Identity }) {
    const [code, setCode] = useState("");
    const [preview, setPreview] = useState<Identity>();
    const [team, setTeam] = useState<Identity[]>([]);
    const [status, setStatus] = useState("");
    const reload = useCallback(() => { if (user.role === "patient") careAPI<Identity[]>("care-team").then(setTeam).catch(e => setStatus(e.message)); }, [user.role]);
    useEffect(reload, [reload]);
    async function action(work: () => Promise<void>) { try { await work(); } catch(e) { setStatus((e as Error).message); } }
    return <section className="care-card"><h2>Care-team connection</h2>{user.role === "clinician" ? <><button onClick={() => action(async () => { const result = await careAPI<{ code: string }>("invitations", "POST"); setCode(result.code); })}>Create 15-minute invitation</button>{code && <p>Share this one-use code with the intended patient through a trusted channel: <code>{code}</code></p>}</> : <><label>Invitation code<input value={code} onChange={e => { setCode(e.target.value); setPreview(undefined); }} /></label><button onClick={() => action(async () => setPreview(await careAPI<Identity>("invitations/preview", "POST", { code })))}>Review invitation</button>{preview && <div><p>Connect to {preview.name}? This grants access to all your care-record categories. Revoke access below at any time.</p><button onClick={() => action(async () => { await careAPI("invitations/accept", "POST", { code }); setPreview(undefined); setCode(""); setStatus("Care team connected."); reload(); })}>Confirm connection</button></div>}{team.map(person => <p key={person.id}>{person.name} <button onClick={() => action(async () => { await careAPI(`care-team/${person.id}`, "DELETE"); reload(); })}>Revoke access</button></p>)}</>}<p role="status">{status}</p></section>;
}
