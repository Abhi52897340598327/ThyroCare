"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { History, ShieldCheck } from "lucide-react";

export default function AuditHistoryPage({
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
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Immutable HIPAA Audit & Access History Log</h1>
            <p className="text-xs text-slate-500">Cryptographically signed access audit trail recording reads, edits, exports, and access timestamps for {patient.name}.</p>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Audit Trail Entries ({patient.auditHistory.length + 1} events)</span>
            <span className="text-[11px] text-slate-500 font-normal">Tamper-evident audit storage</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Timestamp</th>
                <th className="py-2.5 px-4">Actor</th>
                <th className="py-2.5 px-4">Action Performed</th>
                <th className="py-2.5 px-4 text-right">IP Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium font-mono text-[11px]">
              <tr className="hover:bg-slate-50">
                <td className="py-3 px-4 font-bold text-slate-900">{new Date().toLocaleString()}</td>
                <td className="py-3 px-4 text-teal-800 font-bold">Dr. Jane Smith</td>
                <td className="py-3 px-4 text-slate-800">Opened Patient Workspace Audit Trail</td>
                <td className="py-3 px-4 text-right text-slate-500">192.168.1.42</td>
              </tr>
              {patient.auditHistory.map((audit) => (
                <tr key={audit.id} className="hover:bg-slate-50">
                  <td className="py-3 px-4 text-slate-700">{audit.timestamp}</td>
                  <td className="py-3 px-4 text-slate-900 font-bold">{audit.actor}</td>
                  <td className="py-3 px-4 text-slate-800">{audit.action}</td>
                  <td className="py-3 px-4 text-right text-slate-500">{audit.ip}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
