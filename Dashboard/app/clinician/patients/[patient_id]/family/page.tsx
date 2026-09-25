"use client";

import { use } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Users, ShieldCheck, Mail } from "lucide-react";

export default function FamilyAccessPage({
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
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Authorized Family Member & Caregiver Access</h1>
            <p className="text-xs text-slate-500">Patient-permitted family delegate authorizations and access control levels for {patient.name}.</p>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase">
            <span>Authorized Caregiver Delegates ({patient.familyAccess.length})</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Delegate Name</th>
                <th className="py-2.5 px-4">Relationship</th>
                <th className="py-2.5 px-4">Access Level</th>
                <th className="py-2.5 px-4">Email</th>
                <th className="py-2.5 px-4 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {patient.familyAccess.length > 0 ? (
                patient.familyAccess.map((fam) => (
                  <tr key={fam.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4 font-bold text-slate-900">{fam.name}</td>
                    <td className="py-3 px-4 text-slate-700">{fam.relation}</td>
                    <td className="py-3 px-4 text-teal-800 font-semibold">{fam.accessLevel}</td>
                    <td className="py-3 px-4 text-slate-600 font-mono">{fam.email}</td>
                    <td className="py-3 px-4 text-right">
                      <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px]">
                        ACTIVE AUTHORIZATION
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-slate-500">
                    No family delegates authorized for this patient.
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
