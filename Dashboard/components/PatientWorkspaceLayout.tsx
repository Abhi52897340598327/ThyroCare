"use client";

import { getPatientById } from "@/lib/demoData";
import ClinicalTopNav from "./ClinicalTopNav";
import PatientHeader from "./PatientHeader";
import PatientSidebar from "./PatientSidebar";

export default function PatientWorkspaceLayout({
  patientId,
  children,
}: {
  patientId: string;
  children: React.ReactNode;
}) {
  const patient = getPatientById(patientId);

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />
      <PatientHeader patient={patient} />

      <div className="flex flex-1 max-w-[1920px] w-full mx-auto">
        <PatientSidebar patientId={patient.id} />
        <main className="flex-1 p-6 overflow-y-auto min-w-0">
          {children}
        </main>
      </div>
    </div>
  );
}
