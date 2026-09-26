"use client";

import ClinicalSidebar from "./ClinicalSidebar";
import ClinicalHeader from "./ClinicalHeader";

export default function ClinicalAppShell({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 font-sans flex flex-col">
      <ClinicalHeader />
      <div className="flex flex-1 min-w-0">
        <ClinicalSidebar />
        <main className="flex-1 min-w-0 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
