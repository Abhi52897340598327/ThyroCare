"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Users, ShieldCheck, Mail } from "lucide-react";

export default function PatientFamilyAccessPage({
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
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Family & Caregiver Delegate Access Permissions</h1>
            <p className="text-xs text-slate-500">Authorized family member delegates permitted to access thyroid records for {patient.name}.</p>
          </div>
        </div>

        {/* Delegates Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Authorized Caregiver Delegates ({patient.familyAccess.length})</span>
            <span className="text-[11px] text-slate-500 font-normal">Patient Consent Verified</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Delegate Name</th>
                <th className="py-2.5 px-4">Relationship</th>
                <th className="py-2.5 px-4">Email</th>
                <th className="py-2.5 px-4">Permission Level</th>
                <th className="py-2.5 px-4">Authorization Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {patient.familyAccess.length > 0 ? (
                patient.familyAccess.map((fam) => (
                  <tr key={fam.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4 font-bold text-slate-900">{fam.name}</td>
                    <td className="py-3 px-4 text-slate-700">{fam.relation}</td>
                    <td className="py-3 px-4 text-slate-600 font-mono text-[11px]">{fam.email}</td>
                    <td className="py-3 px-4 text-teal-800 font-bold">{fam.accessLevel}</td>
                    <td className="py-3 px-4">
                      <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-[10px] font-bold">
                        ACTIVE CONSENT
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-500 text-xs">
                    No family delegates authorized by patient.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
