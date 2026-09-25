"use client";

import { use } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { ShieldCheck, CheckCircle2, XCircle } from "lucide-react";

export default function SharingPage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Data Sharing, Consent & HIPAA Compliance</h1>
            <p className="text-xs text-slate-500">Patient consent records, research data sharing opt-ins, and external EHR integration for {patient.name}.</p>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4 text-xs">
          <h2 className="font-bold text-slate-900 uppercase tracking-wider flex items-center space-x-2">
            <ShieldCheck className="w-4 h-4 text-teal-700" />
            <span>Active Consent & Interoperability Settings</span>
          </h2>

          <div className="space-y-3">
            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">HIPAA Authorization Form</span>
                <span className="text-[11px] text-slate-500">Patient signed digital medical release consent</span>
              </div>
              {patient.sharingSettings.hipaaConsentSigned ? (
                <span className="bg-emerald-100 text-emerald-800 px-2.5 py-1 rounded font-bold flex items-center space-x-1"><CheckCircle2 className="w-3.5 h-3.5" /><span>SIGNED</span></span>
              ) : (
                <span className="bg-red-100 text-red-800 px-2.5 py-1 rounded font-bold flex items-center space-x-1"><XCircle className="w-3.5 h-3.5" /><span>UNSIGNED</span></span>
              )}
            </div>

            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">De-Identified Research Sharing</span>
                <span className="text-[11px] text-slate-500">Patient opted in to contribute anonymous thyroid data</span>
              </div>
              {patient.sharingSettings.researchShareOptIn ? (
                <span className="bg-emerald-100 text-emerald-800 px-2.5 py-1 rounded font-bold flex items-center space-x-1"><CheckCircle2 className="w-3.5 h-3.5" /><span>OPTED IN</span></span>
              ) : (
                <span className="bg-slate-200 text-slate-700 px-2.5 py-1 rounded font-bold">OPTED OUT</span>
              )}
            </div>

            <div className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <div>
                <span className="font-bold text-slate-900 block">External EHR Interoperability (HL7 / FHIR)</span>
                <span className="text-[11px] text-slate-500">Real-time lab & medication sync with Quest/LabCorp EHR</span>
              </div>
              {patient.sharingSettings.externalEHRIntegration ? (
                <span className="bg-teal-100 text-teal-800 px-2.5 py-1 rounded font-bold flex items-center space-x-1"><CheckCircle2 className="w-3.5 h-3.5" /><span>ACTIVE SYNC</span></span>
              ) : (
                <span className="bg-slate-200 text-slate-700 px-2.5 py-1 rounded font-bold">DISABLED</span>
              )}
            </div>
          </div>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
