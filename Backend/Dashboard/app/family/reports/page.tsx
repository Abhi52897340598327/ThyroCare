"use client";
import { useState } from "react";
import Link from "next/link";
import { ArrowRight, Download, FileText } from "lucide-react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { PageHeading, Panel } from "@/components/DashboardUI";
import { MOCK_PATIENTS, PatientProfile } from "@/lib/demoData";
import { downloadThyroidReportPDF } from "@/lib/pdfGenerator";
export default function FamilyReportsPage() {
  const [selected, setSelected] = useState("all");
  const [downloading, setDownloading] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  const members =
    selected === "all"
      ? MOCK_PATIENTS
      : MOCK_PATIENTS.filter((p) => p.id === selected);
  const download = async (member: PatientProfile) => {
    setDownloading(member.id);
    setMessage("");
    try {
      await new Promise((resolve) => setTimeout(resolve, 50));
      downloadThyroidReportPDF(member);
      setMessage(`Report downloaded for ${member.name}.`);
    } catch {
      setMessage("We couldn't create that report. Please try again.");
    } finally {
      setDownloading(null);
    }
  };
  return (
    <FamilyAppShell>
      <div className="tc-page">
        <PageHeading
          eyebrow="THE BIG PICTURE"
          title="Your health, ready to share."
          description="Bring a clear summary of your results and records to your next appointment."
        />
        <Panel
          title="Family reports"
          subtitle="Sample health summaries · PDF format"
          action={
            <label className="tc-toolbar">
              <span className="tc-field-label">Family member</span>
              <select
                className="tc-input"
                value={selected}
                onChange={(e) => setSelected(e.target.value)}
                aria-label="Filter reports by family member"
              >
                <option value="all">All family members</option>
                {MOCK_PATIENTS.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
          }
        >
          {members.map((member) => (
            <article className="tc-report-row" key={member.id}>
              <span className="tc-report-icon">
                <FileText size={23} />
              </span>
              <div>
                <h3>{member.name}</h3>
                <p>Thyroid health summary · {member.labs.length} lab results</p>
                <p>
                  Latest result: {member.lastLabDate} · {member.condition}
                </p>
                <Link
                  className="tc-text-link"
                  href={`/family/members/${member.id}`}
                >
                  Review health record
                  <ArrowRight size={14} />
                </Link>
              </div>
              <button
                className="tc-button secondary"
                disabled={downloading !== null}
                onClick={() => download(member)}
              >
                <Download size={16} />
                {downloading === member.id ? "Creating PDF…" : "Download PDF"}
              </button>
            </article>
          ))}
        </Panel>
        <p className="tc-form-status" role="status">
          {message}
        </p>
        <div className="tc-gentle-note">
          <FileText size={18} />
          <span>
            Downloads contain the sample records shown in this preview. Choose
            which information to share with your care team.
          </span>
        </div>
      </div>
    </FamilyAppShell>
  );
}
