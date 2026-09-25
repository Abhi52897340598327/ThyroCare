"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, LabRecord } from "@/lib/demoData";
import { FlaskConical, FileText, Download, ChevronRight } from "lucide-react";

export default function LabsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  const patient = getPatientById(params.patient_id);
  const [selectedLab, setSelectedLab] = useState<LabRecord | null>(patient.labs[0]);

  return (
    <PatientWorkspaceLayout patientId={params.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Laboratory Results Archive</h1>
            <p className="text-xs text-slate-500">Certified laboratory reports, reference ranges, and raw hormone assays for {patient.name}.</p>
          </div>
          <button 
            onClick={() => alert(`Lab order interface launched for ${patient.name}`)}
            className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <FlaskConical className="w-3.5 h-3.5" />
            <span>Order New Laboratory Panel</span>
          </button>
        </div>

        {/* Labs Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Historical Lab Panels ({patient.labs.length} records)</span>
            <span className="text-[11px] text-slate-500 font-normal">Click any row to inspect complete diagnostic detail</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Date</th>
                <th className="py-2.5 px-4 text-right">TSH (mIU/L)</th>
                <th className="py-2.5 px-4 text-right">Free T4 (ng/dL)</th>
                <th className="py-2.5 px-4 text-right">Free T3 (pg/mL)</th>
                <th className="py-2.5 px-4 text-right">TPOAb (IU/mL)</th>
                <th className="py-2.5 px-4">Laboratory</th>
                <th className="py-2.5 px-4">Status</th>
                <th className="py-2.5 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {patient.labs.map((lab) => {
                const isSelected = selectedLab?.id === lab.id;
                return (
                  <tr 
                    key={lab.id} 
                    onClick={() => setSelectedLab(lab)}
                    className={`cursor-pointer transition-colors ${isSelected ? "bg-teal-50/80 font-bold" : "hover:bg-slate-50"}`}
                  >
                    <td className="py-3 px-4 text-slate-900 flex items-center space-x-2">
                      {isSelected ? <ChevronRight className="w-3.5 h-3.5 text-teal-700" /> : <span className="w-3.5" />}
                      <span>{lab.date}</span>
                    </td>
                    <td className="py-3 px-4 text-right font-black text-slate-900">{lab.tsh}</td>
                    <td className="py-3 px-4 text-right font-bold text-slate-800">{lab.ft4}</td>
                    <td className="py-3 px-4 text-right font-bold text-slate-800">{lab.ft3}</td>
                    <td className="py-3 px-4 text-right text-slate-600">{lab.tpoAb ? `${lab.tpoAb}` : "—"}</td>
                    <td className="py-3 px-4 text-slate-600">{lab.labName}</td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        lab.status === "Review" ? "bg-amber-100 text-amber-800" : "bg-slate-100 text-slate-700"
                      }`}>
                        {lab.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button className="text-teal-700 hover:text-teal-900 text-[11px] font-semibold underline">
                        Inspect
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Selected Lab Inspection Card */}
        {selectedLab && (
          <div className="bg-white rounded-lg border border-teal-200 shadow-md p-5 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <div className="flex items-center space-x-2 text-teal-900 font-bold text-sm">
                <FileText className="w-4 h-4 text-teal-700" />
                <span>LABORATORY REPORT DETAIL — {selectedLab.date} ({selectedLab.labName})</span>
              </div>
              <button 
                onClick={() => alert(`Downloading verified PDF report for ${selectedLab.date}`)}
                className="text-xs bg-slate-900 hover:bg-slate-800 text-white font-semibold px-3 py-1.5 rounded flex items-center space-x-1 transition-colors"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Export Verified PDF</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
              <div className="p-3 bg-slate-50 rounded border border-slate-200">
                <span className="text-[10px] text-slate-500 uppercase font-semibold block">TSH Assay Result</span>
                <span className="text-xl font-extrabold text-teal-900">{selectedLab.tsh} mIU/L</span>
                <span className="text-[10px] text-slate-500 block mt-1">Ref: {selectedLab.referenceRanges.tsh}</span>
              </div>

              <div className="p-3 bg-slate-50 rounded border border-slate-200">
                <span className="text-[10px] text-slate-500 uppercase font-semibold block">Free T4 Assay Result</span>
                <span className="text-xl font-extrabold text-slate-900">{selectedLab.ft4} ng/dL</span>
                <span className="text-[10px] text-slate-500 block mt-1">Ref: {selectedLab.referenceRanges.ft4}</span>
              </div>

              <div className="p-3 bg-slate-50 rounded border border-slate-200">
                <span className="text-[10px] text-slate-500 uppercase font-semibold block">Free T3 Assay Result</span>
                <span className="text-xl font-extrabold text-slate-900">{selectedLab.ft3} pg/mL</span>
                <span className="text-[10px] text-slate-500 block mt-1">Ref: {selectedLab.referenceRanges.ft3}</span>
              </div>
            </div>

            <div className="bg-slate-50 p-4 rounded border border-slate-200 text-xs space-y-1">
              <h4 className="font-bold text-slate-800">Laboratory Metadata</h4>
              <p className="text-slate-600">Performing Lab: <strong>{selectedLab.labName}</strong></p>
              <p className="text-slate-600">Collection Timestamp: <strong>{selectedLab.date} 07:45 AM</strong></p>
              <p className="text-slate-600">Verification Status: <strong>Clinician Authorized & Signed</strong></p>
            </div>
          </div>
        )}

      </div>
    </PatientWorkspaceLayout>
  );
}
