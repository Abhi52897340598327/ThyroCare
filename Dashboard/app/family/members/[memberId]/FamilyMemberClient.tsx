"use client";

import { useState } from "react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { getPatientById } from "@/lib/demoData";
import { downloadThyroidReportPDF } from "@/lib/pdfGenerator";
import { 
  Activity, 
  FlaskConical, 
  Pill, 
  TrendingUp, 
  Download, 
  ChevronLeft 
} from "lucide-react";
import Link from "next/link";

export default function FamilyMemberClient({ memberId }: { memberId: string }) {
  const patient = getPatientById(memberId);
  const [activeTab, setActiveTab] = useState<"overview" | "labs" | "trends" | "meds">("overview");

  return (
    <FamilyAppShell>
      <div className="space-y-6">
        
        {/* Back Link & Header */}
        <div className="space-y-3">
          <Link href="/family" className="inline-flex items-center space-x-1 text-xs font-bold text-teal-700 hover:underline">
            <ChevronLeft className="w-4 h-4" />
            <span>Back to Family Portal Dashboard</span>
          </Link>

          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-wrap items-center justify-between gap-4">
            <div>
              <span className="text-[10px] font-bold uppercase text-teal-700 bg-teal-50 px-2 py-0.5 rounded border border-teal-200">
                {patient.relationship || "Family Member"} Profile
              </span>
              <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase">{patient.name}</h1>
              <p className="text-xs text-slate-500 font-mono">
                MRN: #{patient.mrn || "THY-84920"} • Age {patient.age} • {patient.sex} • {patient.condition}
              </p>
            </div>

            <div className="flex items-center space-x-3">
              <button
                onClick={() => downloadThyroidReportPDF(patient)}
                className="bg-teal-700 hover:bg-teal-800 text-white font-semibold text-xs px-4 py-2.5 rounded-lg flex items-center space-x-2 shadow-xs transition-colors"
              >
                <Download className="w-4 h-4" />
                <span>Download Report PDF</span>
              </button>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="flex border-b border-slate-200 bg-slate-50">
            <button
              onClick={() => setActiveTab("overview")}
              className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                activeTab === "overview"
                  ? "border-teal-600 text-teal-700 bg-white"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              <Activity className="w-3.5 h-3.5" />
              <span>Overview</span>
            </button>

            <button
              onClick={() => setActiveTab("labs")}
              className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                activeTab === "labs"
                  ? "border-teal-600 text-teal-700 bg-white"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              <FlaskConical className="w-3.5 h-3.5" />
              <span>Lab Results</span>
            </button>

            <button
              onClick={() => setActiveTab("trends")}
              className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                activeTab === "trends"
                  ? "border-teal-600 text-teal-700 bg-white"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              <TrendingUp className="w-3.5 h-3.5" />
              <span>Trends</span>
            </button>

            <button
              onClick={() => setActiveTab("meds")}
              className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                activeTab === "meds"
                  ? "border-teal-600 text-teal-700 bg-white"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              <Pill className="w-3.5 h-3.5" />
              <span>Medications</span>
            </button>
          </div>

          <div className="p-6">
            {activeTab === "overview" && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                <div className="p-4 bg-teal-50 rounded border border-teal-200">
                  <span className="text-[10px] font-bold text-teal-800 uppercase block">Latest TSH Level</span>
                  <span className="text-2xl font-black text-slate-900 mt-1 block">{patient.latestTSH} mIU/L</span>
                  <span className="text-xs text-teal-700 block mt-1">Trend: {patient.trend}</span>
                </div>

                <div className="p-4 bg-slate-50 rounded border border-slate-200">
                  <span className="text-[10px] font-bold text-slate-500 uppercase block">Active Regimen</span>
                  <span className="text-base font-extrabold text-slate-900 mt-1 block">{patient.medications[0]?.name || "None"}</span>
                  <span className="text-xs text-slate-500 block">{patient.medications[0]?.dose} {patient.medications[0]?.frequency}</span>
                </div>

                <div className="p-4 bg-slate-50 rounded border border-slate-200">
                  <span className="text-[10px] font-bold text-slate-500 uppercase block">Next Appointment</span>
                  <span className="text-base font-extrabold text-slate-900 mt-1 block">{patient.nextVisit}</span>
                  <span className="text-xs text-slate-500 block">Endocrinology Specialist Consult</span>
                </div>
              </div>
            )}

            {activeTab === "labs" && (
              <div className="space-y-4">
                <table className="w-full text-left text-xs border-collapse">
                  <thead className="bg-slate-100 uppercase text-[10px] font-semibold text-slate-600">
                    <tr>
                      <th className="py-2.5 px-4">Date</th>
                      <th className="py-2.5 px-4 text-right">TSH (mIU/L)</th>
                      <th className="py-2.5 px-4 text-right">Free T4 (ng/dL)</th>
                      <th className="py-2.5 px-4 text-right">Free T3 (pg/mL)</th>
                      <th className="py-2.5 px-4">Laboratory</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 font-medium">
                    {patient.labs.map(lab => (
                      <tr key={lab.id}>
                        <td className="py-3 px-4 font-bold text-slate-900">{lab.date}</td>
                        <td className="py-3 px-4 text-right font-black text-teal-800">{lab.tsh}</td>
                        <td className="py-3 px-4 text-right">{lab.ft4}</td>
                        <td className="py-3 px-4 text-right">{lab.ft3}</td>
                        <td className="py-3 px-4 text-slate-600">{lab.labName}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {activeTab === "trends" && (
              <div className="space-y-4">
                <h3 className="text-xs font-bold text-slate-800 uppercase">TSH Assay Longitudinal Graph</h3>
                <div className="h-48 bg-slate-50 rounded border border-slate-200 p-4 flex items-end justify-around">
                  {patient.labs.slice().reverse().map(lab => (
                    <div key={lab.id} className="flex flex-col items-center">
                      <div className="w-4 h-4 rounded-full bg-teal-700 text-white text-[9px] flex items-center justify-center font-bold" style={{ marginBottom: `${(lab.tsh / 7) * 100}px` }}>
                        {lab.tsh}
                      </div>
                      <span className="text-[10px] font-bold text-slate-700">{lab.tsh}</span>
                      <span className="text-[9px] text-slate-400 font-mono">{lab.date.split(",")[0]}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === "meds" && (
              <div className="space-y-3 text-xs">
                {patient.medications.map(med => (
                  <div key={med.id} className="p-4 bg-slate-50 rounded border border-slate-200 flex justify-between items-center">
                    <div>
                      <span className="font-extrabold text-slate-900 text-sm block">{med.name} — {med.dose}</span>
                      <span className="text-slate-500 font-mono">{med.frequency} • {med.timing}</span>
                    </div>
                    <span className="bg-emerald-100 text-emerald-800 font-bold text-[10px] px-2.5 py-1 rounded border border-emerald-300">
                      ACTIVE REGIMEN
                    </span>
                  </div>
                ))}
              </div>
            )}

          </div>
        </div>

      </div>
    </FamilyAppShell>
  );
}
