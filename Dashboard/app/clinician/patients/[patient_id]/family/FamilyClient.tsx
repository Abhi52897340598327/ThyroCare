"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Users, ShieldCheck, ShieldAlert, PlusCircle } from "lucide-react";

export interface FamilyDelegate {
  id: string;
  name: string;
  relationship: string;
  contact: string;
  accessScope: string;
  status: "Active" | "Revoked" | "Pending";
  authorizedDate: string;
  signedConsent: boolean;
}

export default function FamilyClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);
  const initialDelegates: FamilyDelegate[] = (patient as any).familyDelegates || [
    {
      id: "fd1",
      name: "Michael Karp",
      relationship: "Spouse",
      contact: "mkarp@example.com",
      accessScope: "Full Medical Record + Lab Alerts",
      status: "Active",
      authorizedDate: "Jan 14, 2026",
      signedConsent: true
    }
  ];

  const [familyDelegates, setFamilyDelegates] = useState<FamilyDelegate[]>(initialDelegates);

  const toggleStatus = (id: string) => {
    setFamilyDelegates(familyDelegates.map(f => f.id === id ? {
      ...f,
      status: f.status === "Active" ? "Revoked" : "Active"
    } : f));
  };

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Family & Caregiver Access Governance</h1>
            <p className="text-xs text-slate-500">Authorized family proxies, proxy scopes, and HIPAA disclosure consent status for {patient.name}.</p>
          </div>

          <button 
            onClick={() => alert(`Invite family caregiver modal opened for ${patient.name}`)}
            className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <PlusCircle className="w-3.5 h-3.5" />
            <span>Authorize Family Delegate</span>
          </button>
        </div>

        {/* Family Caregivers Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase flex justify-between items-center">
            <span>Authorized Family Caregivers ({familyDelegates.length})</span>
            <span className="text-[11px] text-slate-500 font-normal">HIPAA Disclosure Authorized</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Delegate Name</th>
                <th className="py-2.5 px-4">Relationship</th>
                <th className="py-2.5 px-4">Contact</th>
                <th className="py-2.5 px-4">Access Scope</th>
                <th className="py-2.5 px-4">Authorized Date</th>
                <th className="py-2.5 px-4">Consent Document</th>
                <th className="py-2.5 px-4 text-right">Access Control</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {familyDelegates.map((delegate) => (
                <tr key={delegate.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-bold text-slate-900 flex items-center space-x-2">
                    <Users className="w-4 h-4 text-teal-700 shrink-0" />
                    <span>{delegate.name}</span>
                  </td>
                  <td className="py-3 px-4 text-slate-700 font-semibold">{delegate.relationship}</td>
                  <td className="py-3 px-4 text-slate-600 font-mono text-[11px]">{delegate.contact}</td>
                  <td className="py-3 px-4 text-slate-800">{delegate.accessScope}</td>
                  <td className="py-3 px-4 text-slate-600">{delegate.authorizedDate}</td>
                  <td className="py-3 px-4">
                    {delegate.signedConsent ? (
                      <span className="text-emerald-700 font-bold flex items-center space-x-1">
                        <ShieldCheck className="w-3.5 h-3.5" />
                        <span>Signed Consent</span>
                      </span>
                    ) : (
                      <span className="text-amber-700 font-bold flex items-center space-x-1">
                        <ShieldAlert className="w-3.5 h-3.5" />
                        <span>Pending Signature</span>
                      </span>
                    )}
                  </td>
                  <td className="py-3 px-4 text-right">
                    <button
                      onClick={() => toggleStatus(delegate.id)}
                      className={`text-xs font-semibold px-2.5 py-1 rounded transition-colors ${
                        delegate.status === "Active" 
                          ? "bg-red-100 hover:bg-red-200 text-red-800 border border-red-200" 
                          : "bg-emerald-100 hover:bg-emerald-200 text-emerald-800 border border-emerald-200"
                      }`}
                    >
                      {delegate.status === "Active" ? "Revoke Access" : "Re-Activate Access"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
