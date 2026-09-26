"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { ShieldCheck, Eye, FileText, Lock } from "lucide-react";

export default function AuditClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);

  const mockLogs = [
    { id: "au1", timestamp: "Sep 25, 2026 — 20:04", user: "Dr. Jane Smith (NPI: 1982347102)", action: "Viewed Patient Overview Dashboard", ip: "192.168.1.42" },
    { id: "au2", timestamp: "Sep 25, 2026 — 19:42", user: "Dr. Jane Smith (NPI: 1982347102)", action: "Generated Clinical PDF Report", ip: "192.168.1.42" },
    { id: "au3", timestamp: "Sep 18, 2026 — 14:15", user: "LabCorp Interface Service", action: "Ingested Lab Panel (TSH: 5.4 mIU/L)", ip: "10.0.4.12" },
    { id: "au4", timestamp: "Sep 15, 2026 — 09:30", user: "Patient App API (Lori Karp)", action: "Logged Medication Dosage (Levothyroxine)", ip: "172.56.21.90" },
    { id: "au5", timestamp: "Aug 29, 2026 — 11:20", user: "Dr. Mark Davis (NPI: 1478523690)", action: "Viewed Laboratory History Matrix", ip: "192.168.1.88" },
  ];

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">HIPAA Access & EHR Audit Log</h1>
            <p className="text-xs text-slate-500">Immutable audit log of all clinical chart accesses, report exports, and data modifications for {patient.name}.</p>
          </div>
        </div>

        {/* Audit Log Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Security Audit Records ({mockLogs.length} entries)</span>
            <span className="text-[11px] text-slate-500 font-normal">Tamper-evident audit trail</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Timestamp</th>
                <th className="py-2.5 px-4">Authorized User / System</th>
                <th className="py-2.5 px-4">Action Event</th>
                <th className="py-2.5 px-4 font-mono">IP Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {mockLogs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-bold text-slate-900 font-mono text-[11px]">{log.timestamp}</td>
                  <td className="py-3 px-4 text-teal-800 font-semibold">{log.user}</td>
                  <td className="py-3 px-4 text-slate-800">{log.action}</td>
                  <td className="py-3 px-4 text-slate-500 font-mono text-[11px]">{log.ip}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
