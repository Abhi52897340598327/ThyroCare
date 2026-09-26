"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { FlaskConical, PlusCircle, ArrowUpRight, ArrowDownRight, Minus } from "lucide-react";

export default function LabsClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);

  const getDeltaBadge = (current: number, previous?: number) => {
    if (!previous) return <span className="text-slate-400 text-[11px] font-mono"><Minus className="w-3 h-3 inline" /> Baseline</span>;
    const diff = current - previous;
    const percent = Math.round((diff / previous) * 100);
    if (diff > 0) {
      return (
        <span className="bg-amber-100 text-amber-800 border border-amber-200 px-2 py-0.5 rounded text-[10px] font-bold inline-flex items-center space-x-1">
          <ArrowUpRight className="w-3 h-3" />
          <span>+{percent}% (+{diff.toFixed(2)})</span>
        </span>
      );
    } else if (diff < 0) {
      return (
        <span className="bg-blue-100 text-blue-800 border border-blue-200 px-2 py-0.5 rounded text-[10px] font-bold inline-flex items-center space-x-1">
          <ArrowDownRight className="w-3 h-3" />
          <span>{percent}% ({diff.toFixed(2)})</span>
        </span>
      );
    }
    return <span className="bg-slate-100 text-slate-700 border border-slate-200 px-2 py-0.5 rounded text-[10px] font-bold inline-flex items-center space-x-1"><Minus className="w-3 h-3" /><span>Stable</span></span>;
  };

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Thyroid Function Assays & Laboratory Matrix</h1>
            <p className="text-xs text-slate-500">Longitudinal lab history, reference ranges, and lab source tracking for {patient.name}.</p>
          </div>
          <button 
            onClick={() => alert(`Lab order interface launched for ${patient.name}`)}
            className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <PlusCircle className="w-3.5 h-3.5" />
            <span>Order New Lab Panel</span>
          </button>
        </div>

        {/* Lab Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Historical Thyroid Assays ({patient.labs.length} records)</span>
            <span className="text-[11px] text-slate-500 font-normal">Reference: TSH (0.45 - 4.5 mIU/L), FT4 (0.8 - 1.8 ng/dL)</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Date</th>
                <th className="py-2.5 px-4">TSH (mIU/L)</th>
                <th className="py-2.5 px-4">TSH Change</th>
                <th className="py-2.5 px-4">Free T4 (ng/dL)</th>
                <th className="py-2.5 px-4">Free T3 (pg/mL)</th>
                <th className="py-2.5 px-4">Laboratory</th>
                <th className="py-2.5 px-4">Review Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {patient.labs.map((lab, index) => {
                const prevLab = patient.labs[index + 1];
                return (
                  <tr key={lab.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4 font-bold text-slate-900">{lab.date}</td>
                    <td className="py-3 px-4 text-teal-800 font-black text-sm">{lab.tsh}</td>
                    <td className="py-3 px-4">{getDeltaBadge(lab.tsh, prevLab?.tsh)}</td>
                    <td className="py-3 px-4 text-slate-800 font-bold">{lab.ft4}</td>
                    <td className="py-3 px-4 text-slate-800 font-bold">{lab.ft3}</td>
                    <td className="py-3 px-4 text-slate-600">{lab.labName}</td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        lab.status === "Review" || lab.status === "Elevated" ? "bg-amber-100 text-amber-800" : "bg-slate-100 text-slate-700"
                      }`}>
                        {lab.status}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
