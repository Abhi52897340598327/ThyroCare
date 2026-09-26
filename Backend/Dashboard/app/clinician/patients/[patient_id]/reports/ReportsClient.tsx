"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, PatientReport } from "@/lib/demoData";
import { FileText, PlusCircle, Download, Share2 } from "lucide-react";

export default function ReportsClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);
  const [reports, setReports] = useState<PatientReport[]>(patient.reports);
  const [generating, setGenerating] = useState(false);

  const handleGenerateReport = () => {
    setGenerating(true);
    setTimeout(() => {
      const newRep: PatientReport = {
        id: `r_${Date.now()}`,
        title: `Comprehensive Thyroid Report — ${new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`,
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        type: "Comprehensive Thyroid Report"
      };
      setReports([newRep, ...reports]);
      setGenerating(false);
    }, 1500);
  };

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Clinical & Patient Report Archive</h1>
            <p className="text-xs text-slate-500">Generated thyroid clinical summaries, trend exports, and patient progress documents for {patient.name}.</p>
          </div>

          <button 
            onClick={handleGenerateReport}
            disabled={generating}
            className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-bold px-4 py-2 rounded shadow-xs flex items-center space-x-2 transition-colors disabled:opacity-50"
          >
            <PlusCircle className="w-4 h-4" />
            <span>{generating ? "GENERATING CLINICAL REPORT..." : "GENERATE NEW THYROID REPORT"}</span>
          </button>
        </div>

        {/* Reports Archive Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Authorized Report Documents ({reports.length} files)</span>
            <span className="text-[11px] text-slate-500 font-normal">HIPAA-compliant document archive</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Report Title</th>
                <th className="py-2.5 px-4">Document Type</th>
                <th className="py-2.5 px-4">Generated Date</th>
                <th className="py-2.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {reports.map((report) => (
                <tr key={report.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-bold text-slate-900 flex items-center space-x-2">
                    <FileText className="w-4 h-4 text-teal-700 shrink-0" />
                    <span>{report.title}</span>
                  </td>
                  <td className="py-3 px-4 text-slate-600 font-semibold">{report.type}</td>
                  <td className="py-3 px-4 text-slate-600">{report.date}</td>
                  <td className="py-3 px-4 text-right space-x-2">
                    <button 
                      onClick={() => alert(`Opening ${report.title}`)}
                      className="bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold px-2.5 py-1 rounded border border-slate-300 inline-flex items-center space-x-1"
                    >
                      <Download className="w-3 h-3" />
                      <span>View</span>
                    </button>
                    <button 
                      onClick={() => alert(`Secure share link generated for ${report.title}`)}
                      className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-2.5 py-1 rounded inline-flex items-center space-x-1"
                    >
                      <Share2 className="w-3 h-3" />
                      <span>Secure Share</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
