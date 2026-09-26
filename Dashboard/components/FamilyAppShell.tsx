"use client";

import FamilyHeader from "./FamilyHeader";

export default function FamilyAppShell({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 font-sans flex flex-col">
      <FamilyHeader />
      <main className="flex-1 max-w-[1600px] w-full mx-auto p-4 sm:p-6 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}
