"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { MOCK_PATIENTS } from "@/lib/demoData";
import Link from "next/link";
import { FileText, Download, Share2 } from "lucide-react";

export default function GlobalReportsPage() {
  const allReports = MOCK_PATIENTS.flatMap(p => 
    p.reports.map(r => ({ ...r, patientName: p.name, patientId: p.id }))
  );

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <FileText className="w-5 h-5 text-teal-600" />
            <span>CLINICIAN AUTHORIZED REPORTS ARCHIVE</span>
          </h1>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Patient</th>
                <th className="py-2.5 px-4">Report Title</th>
                <th className="py-2.5 px-4">Report Type</th>
                <th className="py-2.5 px-4">Date</th>
                <th className="py-2.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {allReports.map((rep, idx) => (
                <tr key={idx} className="hover:bg-slate-50">
                  <td className="py-3 px-4 font-bold text-slate-900">
                    <Link href={`/clinician/patients/${rep.patientId}`} className="hover:underline text-teal-700">
                      {rep.patientName}
                    </Link>
                  </td>
                  <td className="py-3 px-4 text-slate-800">{rep.title}</td>
                  <td className="py-3 px-4 text-slate-600">{rep.type}</td>
                  <td className="py-3 px-4 text-slate-500">{rep.date}</td>
                  <td className="py-3 px-4 text-right">
                    <button onClick={() => alert(`Downloading ${rep.title}`)} className="text-teal-700 font-bold hover:underline">Download PDF</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
