"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Pill, AlertTriangle, Info } from "lucide-react";

export default function MedicationsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  const patient = getPatientById(params.patient_id);

  return (
    <PatientWorkspaceLayout patientId={params.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Active Medications & Pharmacological Interactions</h1>
            <p className="text-xs text-slate-500">Thyroid hormone replacements, co-administered medications, dosing schedules, and timing compliance.</p>
          </div>
          <button 
            onClick={() => alert(`Medication entry interface opened for ${patient.name}`)}
            className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <Pill className="w-3.5 h-3.5" />
            <span>Update Prescription Record</span>
          </button>
        </div>

        {/* Current Medications Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase">
            <span>Current Prescribed & OTC Medications ({patient.medications.length} active)</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Medication</th>
                <th className="py-2.5 px-4">Dose</th>
                <th className="py-2.5 px-4">Frequency</th>
                <th className="py-2.5 px-4">Timing</th>
                <th className="py-2.5 px-4">Started Date</th>
                <th className="py-2.5 px-4">Potential Thyroid Relevance</th>
                <th className="py-2.5 px-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {patient.medications.map((med) => (
                <tr key={med.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-bold text-slate-900">{med.name}</td>
                  <td className="py-3 px-4 text-slate-800 font-semibold">{med.dose}</td>
                  <td className="py-3 px-4 text-slate-600">{med.frequency}</td>
                  <td className="py-3 px-4 text-slate-700">{med.timing}</td>
                  <td className="py-3 px-4 text-slate-600">{med.started}</td>
                  <td className="py-3 px-4 text-slate-700">
                    <span className="text-[11px] font-semibold text-slate-900">{med.relevance}</span>
                  </td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                      med.status === "Changed" ? "bg-amber-100 text-amber-800" : "bg-emerald-100 text-emerald-800"
                    }`}>
                      {med.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pharmacological & Timing Interaction Review */}
        <div className="bg-white rounded-lg border border-amber-200 p-5 shadow-xs space-y-4">
          <div className="flex items-center space-x-2 text-amber-900 font-bold text-xs uppercase">
            <AlertTriangle className="w-4 h-4 text-amber-600" />
            <span>IDENTIFIED PHARMACOLOGICAL TIMING & ABSORPTION CONSIDERATIONS</span>
          </div>

          <div className="space-y-3 text-xs">
            <div className="p-3 bg-amber-50 rounded border border-amber-200 space-y-1">
              <h4 className="font-bold text-amber-900">PPI Co-Administration: Omeprazole 20mg + Levothyroxine 75mcg</h4>
              <p className="text-amber-800">
                Omeprazole was initiated on Jul 03, 2026. Proton pump inhibitors reduce gastric acidity required for optimal levothyroxine tablet dissolution and absorption.
              </p>
            </div>

            <div className="p-3 bg-amber-50 rounded border border-amber-200 space-y-1">
              <h4 className="font-bold text-amber-900">Timing Proximity Overlap</h4>
              <p className="text-amber-800">
                Patient logs indicate Levothyroxine is taken at 7:00 AM, followed by Omeprazole and calcium-fortified beverages at 7:30 AM (30-minute window). Recommend enforcing a 60+ minute separation.
              </p>
            </div>
          </div>

          <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
            <Info className="w-4 h-4 text-blue-600 shrink-0" />
            <p><strong>Clinical Policy:</strong> Dose adjustments must be made exclusively by authorized clinicians based on full clinical context.</p>
          </div>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
