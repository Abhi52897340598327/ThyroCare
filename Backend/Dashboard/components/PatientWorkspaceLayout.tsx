"use client";

import { getPatientById } from "@/lib/demoData";
import ClinicalAppShell from "./ClinicalAppShell";
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
    <ClinicalAppShell>
      <div className="flex flex-col min-h-screen bg-slate-100 font-sans text-slate-900">
        <PatientHeader patient={patient} />
        <div className="flex flex-col lg:flex-row flex-1 max-w-[1920px] w-full mx-auto min-w-0">
          <PatientSidebar patientId={patient.id} />
          <div className="flex-1 p-3 sm:p-6 overflow-x-auto min-w-0">
            {children}
          </div>
        </div>
      </div>
    </ClinicalAppShell>
  );
}
