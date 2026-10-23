"use client";
import { useState } from "react";
import Link from "next/link";
import { ArrowUpRight, CalendarDays, Clock, Stethoscope } from "lucide-react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { PageHeading } from "@/components/DashboardUI";
import { MOCK_PATIENTS } from "@/lib/demoData";
export default function FamilyAppointmentsPage() {
  const [memberId, setMemberId] = useState("all");
  const appointments = MOCK_PATIENTS.filter(
    (p) => memberId === "all" || p.id === memberId,
  )
    .flatMap((p) =>
      p.appointments
        .filter((a) => a.status !== "Completed")
        .map((a) => ({ ...a, member: p })),
    )
    .sort((a, b) => Date.parse(a.date) - Date.parse(b.date));
  return (
    <FamilyAppShell>
      <div className="tc-page">
        <PageHeading
          eyebrow="MAKE TIME FOR YOU"
          title="Your next step in care."
          description="Keep upcoming visits and follow-ups close at hand."
          action={
            <Link className="tc-button primary" href="/providers">
              <Stethoscope size={17} />
              Find a doctor
            </Link>
          }
        />
        <div className="tc-toolbar">
          <label htmlFor="appointment-member" className="tc-field-label">
            Family member
          </label>
          <select
            id="appointment-member"
            className="tc-input"
            value={memberId}
            onChange={(e) => setMemberId(e.target.value)}
          >
            <option value="all">All family members</option>
            {MOCK_PATIENTS.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
          <span className="tc-muted">
            {appointments.length} upcoming or recommended visits
          </span>
        </div>
        <div className="tc-appointment-grid">
          {appointments.map((a) => {
            const date = new Date(a.date);
            return (
              <article
                className="tc-appointment"
                key={`${a.member.id}-${a.id}`}
              >
                <div className="tc-appointment-top">
                  <span className="tc-date-tile">
                    <small>
                      {date.toLocaleDateString("en-US", {
                        month: "short",
                        timeZone: "UTC",
                      })}
                    </small>
                    <strong>{date.getUTCDate()}</strong>
                  </span>
                  <div>
                    <h2>{a.type}</h2>
                    <p>{a.member.name}</p>
                  </div>
                  <span
                    className="tc-status neutral"
                    style={{ marginLeft: "auto" }}
                  >
                    {a.status}
                  </span>
                </div>
                <p className="tc-appointment-meta">
                  <Clock size={16} />
                  {a.date} · {a.time}
                </p>
                <p className="tc-appointment-meta">
                  <Stethoscope size={16} />
                  {a.provider}
                </p>
                {a.recommendedReason && <p>{a.recommendedReason}</p>}
                <div className="tc-toolbar">
                  <Link
                    className="tc-button secondary"
                    href={`/family/members/${a.member.id}`}
                  >
                    <CalendarDays size={16} />
                    Review record
                  </Link>
                  <Link className="tc-text-link" href="/family/reports">
                    Prepare a report
                    <ArrowUpRight size={15} />
                  </Link>
                </div>
              </article>
            );
          })}
        </div>
        {!appointments.length && (
          <div className="tc-panel tc-empty">
            <CalendarDays size={28} />
            <h3>No upcoming visits in this record.</h3>
            <p>
              Find a specialist when you are ready to plan your next
              appointment.
            </p>
            <Link className="tc-text-link" href="/providers">
              Find a doctor
              <ArrowUpRight size={15} />
            </Link>
          </div>
        )}
      </div>
    </FamilyAppShell>
  );
}
