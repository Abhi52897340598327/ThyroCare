"use client";
import { useState } from "react";
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
import { MOCK_PATIENTS } from "@/lib/demoData";
export default function GlobalClinicianDashboard() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [sort, setSort] = useState<"name" | "tsh">("name");
  const [ascending, setAscending] = useState(true);
  const review = MOCK_PATIENTS.filter((p) =>
    ["REVIEW SUGGESTED", "TREND CHANGE", "NEW LAB RESULT"].includes(p.status),
  );
  const patients = MOCK_PATIENTS.filter(
    (p) =>
      `${p.name} ${p.condition} ${p.id}`
        .toLowerCase()
        .includes(search.toLowerCase()) &&
      (status === "all" ||
        (status === "review" ? review.includes(p) : p.status === status)),
  ).sort(
    (a, b) =>
      (sort === "name"
        ? a.name.localeCompare(b.name)
        : a.latestTSH - b.latestTSH) * (ascending ? 1 : -1),
  );
  const toggle = (field: "name" | "tsh") => {
    if (sort === field) setAscending(!ascending);
    else {
      setSort(field);
      setAscending(true);
    }
  };
  return (
    <ClinicalAppShell>
      <div className="tc-page">
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
            value={MOCK_PATIENTS.length}
            detail="Sample patient population"
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
              MOCK_PATIENTS.filter((p) => p.status === "NEW LAB RESULT").length
            }
            detail="Patients with a new-result flag"
            icon={FileText}
            tone="violet"
          />
          <MetricCard
            label="Follow-up requested"
            value={
              MOCK_PATIENTS.filter((p) => p.status === "FOLLOW-UP REQUESTED")
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
          subtitle={`${patients.length} of ${MOCK_PATIENTS.length} records`}
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
                            {p.age} years · {p.sex}
                          </small>
                        </span>
                      </Link>
                    </td>
                    <td>{p.condition}</td>
                    <td>
                      <strong>{p.latestTSH}</strong>{" "}
                      <span className="tc-muted">mIU/L</span>
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
