"use client";

import { useState } from "react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { MOCK_PATIENTS, PatientProfile } from "@/lib/demoData";
import { downloadThyroidReportPDF } from "@/lib/pdfGenerator";
import { 
  FileText, 
  Download, 
  Share2, 
  Filter, 
  ShieldCheck 
} from "lucide-react";

export default function FamilyReportsPage() {
  const [selectedMemberId, setSelectedMemberId] = useState<string>("all");
  const [downloadingId, setDownloadingId] = useState<string | null>(null);

  const filteredMembers = selectedMemberId === "all" 
    ? MOCK_PATIENTS 
    : MOCK_PATIENTS.filter(m => m.id === selectedMemberId);

  const handleDownload = (member: PatientProfile) => {
    setDownloadingId(member.id);
    setTimeout(() => {
      downloadThyroidReportPDF(member);
      setDownloadingId(null);
    }, 400);
  };

  return (
    <FamilyAppShell>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-teal-100 text-teal-800 text-[11px] font-extrabold uppercase px-2.5 py-0.5 rounded border border-teal-200">
                Official Clinical Export
              </span>
              <span className="text-xs text-slate-500 font-mono">PDF Standard 2.0</span>
            </div>
            <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase tracking-tight flex items-center space-x-2">
              <FileText className="w-5 h-5 text-teal-700" />
              <span>FAMILY THYROID REPORTS & PDF EXPORTS</span>
            </h1>
            <p className="text-xs text-slate-600 mt-0.5">
              Download, preview, or securely share formatted clinical thyroid reports for authorized linked family members.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
              <Filter className="w-3.5 h-3.5 text-slate-500" />
              <span className="text-xs text-slate-600 font-semibold">Filter Member:</span>
              <select
                value={selectedMemberId}
                onChange={(e) => setSelectedMemberId(e.target.value)}
                className="bg-white border border-slate-300 text-slate-900 text-xs font-bold rounded px-2 py-1 focus:outline-none focus:border-teal-600"
              >
                <option value="all">All Family Members</option>
                {MOCK_PATIENTS.map(m => (
                  <option key={m.id} value={m.id}>{m.name} ({m.relationship || "Member"})</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Reports Table / List */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 bg-slate-900 text-white flex items-center justify-between">
            <h2 className="text-xs font-bold uppercase tracking-wider flex items-center space-x-2">
              <ShieldCheck className="w-4 h-4 text-teal-400" />
              <span>Authorized Family Clinical Reports</span>
            </h2>
            <span className="text-xs text-slate-400 font-mono">
              Showing {filteredMembers.length} Patient Files
            </span>
          </div>

          <div className="divide-y divide-slate-200">
            {filteredMembers.map((member) => (
              <div key={member.id} className="p-5 hover:bg-slate-50 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 rounded-lg bg-teal-50 border border-teal-200 flex items-center justify-center text-teal-800 shrink-0">
                    <FileText className="w-6 h-6" />
                  </div>

                  <div className="space-y-1">
                    <div className="flex items-center space-x-2">
                      <h3 className="text-sm font-extrabold text-slate-900">{member.name} — Comprehensive Thyroid Report</h3>
                      <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded border border-emerald-300">
                        VERIFIED
                      </span>
                    </div>

                    <p className="text-xs text-slate-500 font-mono">
                      MRN: #{member.mrn || "THY-84920"} • Date Range: June 2026 – September 2026 • Latest TSH: {member.latestTSH} mIU/L
                    </p>

                    <div className="flex items-center space-x-3 text-[11px] text-slate-600 pt-1">
                      <span>Condition: <strong>{member.condition}</strong></span>
                      <span>•</span>
                      <span>Assayed Labs: <strong>{member.labs.length} Entries</strong></span>
                      <span>•</span>
                      <span>Generated: <strong>{member.lastLabDate}</strong></span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-3 self-end md:self-auto">
                  <button
                    onClick={() => handleDownload(member)}
                    disabled={downloadingId === member.id}
                    className="bg-teal-700 hover:bg-teal-800 text-white font-semibold text-xs px-4 py-2 rounded-lg flex items-center space-x-1.5 transition-colors shadow-xs disabled:opacity-50"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>{downloadingId === member.id ? "Generating PDF..." : "Download PDF"}</span>
                  </button>

                  <button
                    onClick={() => alert(`Secure Sharing link copied for ${member.name}'s report.`)}
                    className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs px-3 py-2 rounded-lg flex items-center space-x-1.5 border border-slate-300 transition-colors"
                  >
                    <Share2 className="w-3.5 h-3.5 text-slate-500" />
                    <span>Secure Share</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </FamilyAppShell>
  );
}
