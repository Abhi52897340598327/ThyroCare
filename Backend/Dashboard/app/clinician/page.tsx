"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import {
  AlertCircle,
  ArrowRight,
  ArrowUpDown,
  CalendarDays,
  FileText,
  Search,
  Users,
} from "lucide-react";
import ClinicalAppShell from "@/components/ClinicalAppShell";
import {
  MetricCard,
  PageHeading,
  Panel,
  StatusBadge,
} from "@/components/DashboardUI";
import { careAPI, CareRecord, Identity } from "@/lib/care-api";
import { compareRoster, nextAppointment, RosterDates } from "@/lib/care-roster";
type RosterRow = { id: string; name: string; age: string; sex: string; condition: string; latestTSH: string; unit: string; status: string; nextVisit: string; trend: string };

export default function GlobalClinicianDashboard() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [sort, setSort] = useState("appointment");
  const [ascending, setAscending] = useState(true);
  const [rows, setRows] = useState<RosterRow[]>([]);
  const [dates, setDates] = useState<Record<string, RosterDates>>({});
  const [error, setError] = useState("");
  const [workspace, setWorkspace] = useState("");
  useEffect(() => {
    const abort = new AbortController();
    async function load() {
      try {
        const me = await careAPI<Identity>("me", "GET", undefined, abort.signal);
        if (me.role !== "clinician") throw new Error("Sign in with your clinician account to view the authorized roster.");
        const people = await careAPI<Identity[]>("patients", "GET", undefined, abort.signal);
        const output = await Promise.all(people.map(async p => {
          const [labs, appointments, questionnaires] = await Promise.all(["labs", "appointments", "questionnaire"].map(kind => careAPI<CareRecord[]>(`patients/${p.id}/${kind}`, "GET", undefined, abort.signal)));
          const dated = labs.filter(r => r.fields.collectedDate).sort((a,b) => b.fields.collectedDate.localeCompare(a.fields.collectedDate));
          const latest = dated.find(r => r.fields.analyte === "TSH");
          const appointment = nextAppointment(appointments, Date.now());
          const q = questionnaires.at(-1)?.fields ?? {};
          const row: RosterRow = { ...p, age:q.age || "Age not recorded", sex:q.sex || "Not recorded", condition:q.condition || "Not recorded", latestTSH:latest?.fields.result ?? "Not recorded", unit:latest?.fields.unit ?? "", status:labs.length ? "NEW LAB RESULT" : "INSUFFICIENT DATA", nextVisit:appointment ? new Date(appointment).toISOString() + " (UTC)" : "No upcoming appointment", trend:latest?.fields.collectedDate ?? "Collection date unknown" };
          return {row, date:{appointment, lab:dated[0]?.fields.collectedDate}};
        }));
        if (abort.signal.aborted) return;
        setWorkspace(me.id); setRows(output.map(o=>o.row)); setDates(Object.fromEntries(output.map(o=>[o.row.id,o.date]))); setError("");
        const saved = localStorage.getItem(`thyrocare-roster-sort:${me.id}`); if (saved) setSort(saved);
      } catch(e) { if (!abort.signal.aborted) setError((e as Error).message); }
    }
    void load(); const timer=setInterval(()=>void load(),15000);
    return ()=>{abort.abort();clearInterval(timer);};
  }, []);
  const review = rows.filter(p=>p.status === "NEW LAB RESULT");
  const patients = rows.filter(p => `${p.name} ${p.condition} ${p.id}`.toLowerCase().includes(search.toLowerCase()) && (status === "all" || (status === "review" ? review.includes(p) : p.status === status))).sort((a,b) => compareRoster(a,b,dates,sort));
  const chooseSort = (value: string) => { setSort(value); setAscending(true); if(workspace) localStorage.setItem(`thyrocare-roster-sort:${workspace}`,value); };
  const toggle = (field: "name" | "tsh") => chooseSort(field === "tsh" ? "lab" : "name");
  return (
    <ClinicalAppShell>
      <div className="tc-page">
        {error && <p role="alert">{error} <Link href="/records">Sign in / connect care team</Link></p>}
        <PageHeading
          eyebrow="YOUR PRACTICE, AT A GLANCE"
          title="A clearer picture of patient care."
          description="Review changes, connect the details, and plan the next conversation."
          action={
            <Link className="tc-button primary" href="/clinician/search">
              <Search size={17} />
              Find a patient
            </Link>
          }
        />
        <div className="tc-metrics">
          <MetricCard
            label="Patients in your record"
            value={rows.length}
            detail="Authorized patient population"
            icon={Users}
          />
          <MetricCard
            label="Ready for review"
            value={review.length}
            detail="New results or changed trends"
            icon={AlertCircle}
            tone="amber"
          />
          <MetricCard
            label="New lab results"
            value={
              rows.filter((p) => p.status === "NEW LAB RESULT").length
            }
            detail="Patients with a new-result flag"
            icon={FileText}
            tone="violet"
          />
          <MetricCard
            label="Follow-up requested"
            value={
              rows.filter((p) => p.status === "FOLLOW-UP REQUESTED")
                .length
            }
            detail="Requests in the current record"
            icon={CalendarDays}
            tone="navy"
          />
        </div>
        <div className="tc-review-strip">
          <AlertCircle size={22} />
          <div>
            <strong>
              {review.length} patient records are ready for a closer look.
            </strong>
            <p>
              Review recent results alongside food logs, medication records, and
              patient notes.
            </p>
          </div>
          <button
            className="tc-text-link"
            onClick={() => setStatus(status === "review" ? "all" : "review")}
          >
            {status === "review" ? "Show everyone" : "View review queue"}
            <ArrowRight size={16} />
          </button>
        </div>
        <Panel
          title="Your patients"
          subtitle={`${patients.length} of ${rows.length} records`}
          action={
            <div className="tc-toolbar">
              <label className="tc-search">
                <Search size={16} />
                <input
                  className="tc-input"
                  aria-label="Search patients"
                  placeholder="Search name or condition"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </label>
              <select className="tc-input" aria-label="Sort patients" value={sort} onChange={e=>chooseSort(e.target.value)}>
                <option value="appointment">Upcoming appointment</option><option value="lab">Latest blood test</option><option value="oldest">Oldest blood test / no result</option><option value="name">Patient name</option>
              </select>
              <select
                className="tc-input"
                aria-label="Filter patients by status"
                value={status}
                onChange={(e) => setStatus(e.target.value)}
              >
                <option value="all">All statuses</option>
                <option value="review">Ready for review</option>
                <option value="STABLE">Stable</option>
                <option value="FOLLOW-UP REQUESTED">Follow-up requested</option>
              </select>
            </div>
          }
        >
          <div className="tc-table-wrap">
            <table className="tc-table">
              <thead>
                <tr>
                  <th
                    aria-sort={
                      sort === "name"
                        ? ascending
                          ? "ascending"
                          : "descending"
                        : "none"
                    }
                  >
                    <button
                      className="tc-table-sort"
                      onClick={() => toggle("name")}
                    >
                      Patient
                      <ArrowUpDown size={13} />
                    </button>
                  </th>
                  <th>Condition</th>
                  <th
                    aria-sort={
                      sort === "tsh"
                        ? ascending
                          ? "ascending"
                          : "descending"
                        : "none"
                    }
                  >
                    <button
                      className="tc-table-sort"
                      onClick={() => toggle("tsh")}
                    >
                      TSH
                      <ArrowUpDown size={13} />
                    </button>
                  </th>
                  <th>Status</th>
                  <th>Next visit</th>
                  <th>
                    <span className="sr-only">Open record</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {patients.map((p) => (
                  <tr key={p.id}>
                    <td>
                      <Link
                        className="tc-table-person"
                        href={`/clinician/patients/${p.id}`}
                      >
                        <span className="tc-avatar">
                          {p.name
                            .split(" ")
                            .map((n) => n[0])
                            .join("")}
                        </span>
                        <span>
                          <strong>{p.name}</strong>
                          <small>
                            {p.age} · {p.sex}
                          </small>
                        </span>
                      </Link>
                    </td>
                    <td>{p.condition}</td>
                    <td>
                      <strong>{p.latestTSH}</strong>{" "}
                      <span className="tc-muted">{p.unit}</span>
                      <small>{p.trend}</small>
                    </td>
                    <td>
                      <StatusBadge status={p.status} />
                    </td>
                    <td>{p.nextVisit}</td>
                    <td>
                      <Link
                        className="tc-icon-button"
                        href={`/clinician/patients/${p.id}`}
                        aria-label={`Open ${p.name}'s record`}
                      >
                        <ArrowRight size={17} />
                      </Link>
                    </td>
                  </tr>
                ))}
                {!patients.length && (
                  <tr>
                    <td colSpan={6} className="tc-table-empty">
                      No matching patients. Try another name or change the
                      status filter.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Panel>
      </div>
    </ClinicalAppShell>
  );
}
