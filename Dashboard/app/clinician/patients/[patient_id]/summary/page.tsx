"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Activity, Calendar, ArrowUpRight, ArrowDownRight, Minus } from "lucide-react";

export default function ThyroidSummaryPage({
  params,
}: {
  params: { patient_id: string };
}) {
  const patient = getPatientById(params.patient_id);
  const [timeframe, setTimeframe] = useState("All Data");

  const latest = patient.labs[0];
  const previous = patient.labs[1] || latest;

  const tshChangePercent = Math.round(((latest.tsh - previous.tsh) / previous.tsh) * 100);
  const ft4ChangePercent = Math.round(((latest.ft4 - previous.ft4) / previous.ft4) * 100);
  const ft3ChangePercent = Math.round(((latest.ft3 - previous.ft3) / previous.ft3) * 100);

  return (
    <PatientWorkspaceLayout patientId={params.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Thyroid Summary Assessment</h1>
            <p className="text-xs text-slate-500">Structured longitudinal thyroid hormone measurement comparison and graph trajectory.</p>
          </div>

          {/* Timeframe Selector */}
          <div className="flex items-center space-x-1 bg-white border border-slate-300 rounded p-1 text-xs">
            {["1 month", "3 months", "6 months", "1 year", "All Data"].map((tf) => (
              <button
                key={tf}
                onClick={() => setTimeframe(tf)}
                className={`px-2.5 py-1 rounded text-xs font-semibold transition-colors ${
                  timeframe === tf ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {tf}
              </button>
            ))}
          </div>
        </div>

        {/* Clinical Comparison Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex items-center justify-between">
            <span>Thyroid Hormone Delta Table</span>
            <span className="text-[11px] text-slate-500 font-normal">Latest Lab Date: {latest.date}</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Measurement</th>
                <th className="py-2.5 px-4 text-right">Current Value</th>
                <th className="py-2.5 px-4 text-right">Previous Value</th>
                <th className="py-2.5 px-4 text-right">Change</th>
                <th className="py-2.5 px-4">Reference Range</th>
                <th className="py-2.5 px-4">Last Lab Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              <tr>
                <td className="py-3 px-4 font-bold text-slate-900">TSH (Thyroid Stimulating Hormone)</td>
                <td className="py-3 px-4 text-right font-black text-teal-800 text-sm">{latest.tsh} mIU/L</td>
                <td className="py-3 px-4 text-right text-slate-600">{previous.tsh} mIU/L</td>
                <td className="py-3 px-4 text-right">
                  <span className={`inline-flex items-center font-bold ${tshChangePercent > 0 ? "text-amber-700" : "text-emerald-700"}`}>
                    {tshChangePercent > 0 ? `↑ +${tshChangePercent}%` : `↓ ${tshChangePercent}%`}
                  </span>
                </td>
                <td className="py-3 px-4 text-slate-500">{latest.referenceRanges.tsh}</td>
                <td className="py-3 px-4 text-slate-600">{latest.date}</td>
              </tr>
              <tr>
                <td className="py-3 px-4 font-bold text-slate-900">Free T4 (Thyroxine)</td>
                <td className="py-3 px-4 text-right font-bold text-slate-900">{latest.ft4} ng/dL</td>
                <td className="py-3 px-4 text-right text-slate-600">{previous.ft4} ng/dL</td>
                <td className="py-3 px-4 text-right">
                  <span className="text-slate-600 font-medium">{ft4ChangePercent}%</span>
                </td>
                <td className="py-3 px-4 text-slate-500">{latest.referenceRanges.ft4}</td>
                <td className="py-3 px-4 text-slate-600">{latest.date}</td>
              </tr>
              <tr>
                <td className="py-3 px-4 font-bold text-slate-900">Free T3 (Triiodothyronine)</td>
                <td className="py-3 px-4 text-right font-bold text-slate-900">{latest.ft3} pg/mL</td>
                <td className="py-3 px-4 text-right text-slate-600">{previous.ft3} pg/mL</td>
                <td className="py-3 px-4 text-right">
                  <span className="text-slate-600 font-medium">{ft3ChangePercent}%</span>
                </td>
                <td className="py-3 px-4 text-slate-500">{latest.referenceRanges.ft3}</td>
                <td className="py-3 px-4 text-slate-600">{latest.date}</td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* Triple Longitudinal Graphs */}
        <div className="space-y-4">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Thyroid Panel Longitudinal Graphs ({timeframe})</h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            
            {/* TSH Graph Card */}
            <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs">
              <h3 className="text-xs font-bold text-teal-800 uppercase mb-2">TSH Trajectory (mIU/L)</h3>
              <div className="h-36 bg-slate-50 rounded border border-slate-200 p-3 flex items-end justify-between">
                {patient.labs.slice().reverse().map((lab) => (
                  <div key={lab.id} className="flex flex-col items-center">
                    <div className="w-2.5 h-2.5 rounded-full bg-teal-700" style={{ marginBottom: `${(lab.tsh / 7) * 70}px` }} />
                    <span className="text-[9px] font-bold">{lab.tsh}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Free T4 Graph Card */}
            <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs">
              <h3 className="text-xs font-bold text-slate-800 uppercase mb-2">Free T4 Trajectory (ng/dL)</h3>
              <div className="h-36 bg-slate-50 rounded border border-slate-200 p-3 flex items-end justify-between">
                {patient.labs.slice().reverse().map((lab) => (
                  <div key={lab.id} className="flex flex-col items-center">
                    <div className="w-2.5 h-2.5 rounded-full bg-blue-600" style={{ marginBottom: `${(lab.ft4 / 2) * 70}px` }} />
                    <span className="text-[9px] font-bold">{lab.ft4}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Free T3 Graph Card */}
            <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs">
              <h3 className="text-xs font-bold text-slate-800 uppercase mb-2">Free T3 Trajectory (pg/mL)</h3>
              <div className="h-36 bg-slate-50 rounded border border-slate-200 p-3 flex items-end justify-between">
                {patient.labs.slice().reverse().map((lab) => (
                  <div key={lab.id} className="flex flex-col items-center">
                    <div className="w-2.5 h-2.5 rounded-full bg-purple-600" style={{ marginBottom: `${(lab.ft3 / 4) * 70}px` }} />
                    <span className="text-[9px] font-bold">{lab.ft3}</span>
                  </div>
                ))}
              </div>
            </div>

          </div>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
