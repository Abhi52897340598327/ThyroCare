"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Share2, Lock, ShieldCheck } from "lucide-react";

export default function SharingClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Inter-Provider Data Sharing Controls</h1>
            <p className="text-xs text-slate-500">Manage external health system data sharing permissions, consent tokens, and export policies for {patient.name}.</p>
          </div>
        </div>

        {/* Sharing Policy Matrix */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
          <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center space-x-2">
            <Share2 className="w-4 h-4 text-teal-700" />
            <span>EXTERNAL HEALTH SYSTEM SHARING CONSENT</span>
          </h2>

          <div className="space-y-3 text-xs">
            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">LabCorp / Quest EHR Auto-Sync</span>
                <span className="text-slate-500 text-[11px]">Allows automated retrieval of external laboratory panel assays.</span>
              </div>
              <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px]">AUTHORIZED</span>
            </div>

            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">Endocrinology Specialist Network Share</span>
                <span className="text-slate-500 text-[11px]">Enables encrypted clinical summary transfers between network practices.</span>
              </div>
              <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px]">AUTHORIZED</span>
            </div>

            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">De-Identified Research Registry Export</span>
                <span className="text-slate-500 text-[11px]">Anonymized longitudinal thyroid research dataset contribution.</span>
              </div>
              <span className="bg-slate-200 text-slate-700 font-bold px-2 py-0.5 rounded text-[10px]">OPTED OUT</span>
            </div>
          </div>
        </div>

        {/* Security Assurance */}
        <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
          <ShieldCheck className="w-4 h-4 text-blue-600 shrink-0" />
          <p><strong>Security Standard:</strong> All inter-provider transfers utilize TLS 1.3 encryption and OAuth2 scoped consent verification.</p>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
