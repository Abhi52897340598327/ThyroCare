"use client";

import { use, useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Stethoscope, Activity, Info, TrendingUp } from "lucide-react";

export default function SymptomsPage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);
  const [filterPresentOnly, setFilterPresentOnly] = useState(false);

  const displayedSymptoms = filterPresentOnly 
    ? patient.symptoms.filter(s => s.present)
    : patient.symptoms;

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Patient-Reported Symptom Matrix</h1>
            <p className="text-xs text-slate-500">Structured thyroid symptom severity, frequency, and daily life interference matrix for {patient.name}.</p>
          </div>

          <div className="flex items-center space-x-2 bg-white border border-slate-300 rounded p-1 text-xs">
            <button
              onClick={() => setFilterPresentOnly(false)}
              className={`px-3 py-1 rounded font-semibold transition-colors ${
                !filterPresentOnly ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
              }`}
            >
              All 15 Symptoms
            </button>
            <button
              onClick={() => setFilterPresentOnly(true)}
              className={`px-3 py-1 rounded font-semibold transition-colors ${
                filterPresentOnly ? "bg-teal-700 text-white" : "text-slate-600 hover:bg-slate-100"
              }`}
            >
              Present Symptoms Only ({patient.symptoms.filter(s => s.present).length})
            </button>
          </div>
        </div>

        {/* Symptom Matrix Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Comprehensive Thyroid Symptom Matrix</span>
            <span className="text-[11px] text-slate-500 font-normal">Last Updated: {patient.lastLabDate}</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Symptom</th>
                <th className="py-2.5 px-4 text-center">Present?</th>
                <th className="py-2.5 px-4">Frequency</th>
                <th className="py-2.5 px-4">Severity</th>
                <th className="py-2.5 px-4">Interference</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {displayedSymptoms.map((symptom, idx) => (
                <tr key={idx} className={`hover:bg-slate-50 transition-colors ${symptom.present ? "bg-amber-50/20 font-bold" : "text-slate-500"}`}>
                  <td className="py-3 px-4 text-slate-900">{symptom.name}</td>
                  <td className="py-3 px-4 text-center">
                    {symptom.present ? (
                      <span className="bg-amber-100 text-amber-800 border border-amber-200 px-2 py-0.5 rounded text-[10px] font-bold">YES</span>
                    ) : (
                      <span className="bg-slate-100 text-slate-500 px-2 py-0.5 rounded text-[10px] font-normal">NO</span>
                    )}
                  </td>
                  <td className="py-3 px-4 text-slate-700">{symptom.frequency}</td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                      symptom.severity === "Severe" ? "bg-red-100 text-red-800" :
                      symptom.severity === "Moderate" ? "bg-amber-100 text-amber-800" :
                      symptom.severity === "Mild" ? "bg-blue-100 text-blue-800" : "bg-slate-100 text-slate-500"
                    }`}>
                      {symptom.severity}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-slate-700">{symptom.interference}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Longitudinal Symptom Severity Progression Chart */}
        {patient.symptomHistory.length > 0 && (
          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
              <TrendingUp className="w-4 h-4 text-teal-600" />
              <span>Longitudinal Fatigue & Symptom Severity Progression (5-Month Horizon)</span>
            </h3>

            <div className="h-40 bg-slate-50 rounded border border-slate-200 p-4 flex items-end justify-between">
              {patient.symptomHistory.map((hist, idx) => (
                <div key={idx} className="flex flex-col items-center">
                  <div className="w-3 h-3 rounded-full bg-amber-600 shadow-xs" style={{ marginBottom: `${hist.fatigue * 22}px` }} />
                  <span className="text-[10px] font-bold text-slate-900">Score {hist.fatigue}/5</span>
                  <span className="text-[9px] text-slate-500">{hist.date}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Clinical Disclaimer */}
        <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
          <Info className="w-4 h-4 text-blue-600 shrink-0" />
          <p><strong>Clinical Disclaimer:</strong> These entries represent patient-reported symptoms and do not constitute formal clinician diagnoses.</p>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
