"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { MOCK_PATIENTS } from "@/lib/demoData";
import Link from "next/link";
import { Eye, ArrowRight } from "lucide-react";

export default function MonitoringPage() {
  const activeMonitored = MOCK_PATIENTS.filter(p => p.status !== "STABLE");

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <Eye className="w-5 h-5 text-teal-600" />
            <span>ACTIVE POPULATION SURVEILLANCE & MONITORING QUEUE</span>
          </h1>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-xs">
            {activeMonitored.map((patient) => (
              <div key={patient.id} className="p-4 bg-amber-50/40 border border-amber-200 rounded-lg space-y-3 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-slate-900 text-sm uppercase">{patient.name}</h3>
                    <span className="bg-amber-200 text-amber-900 font-extrabold px-2 py-0.5 rounded text-[9px]">{patient.status}</span>
                  </div>
                  <p className="text-slate-600 mt-1">{patient.condition}</p>
                  <p className="text-slate-900 font-bold mt-2">Latest TSH: {patient.latestTSH} mIU/L ({patient.trend})</p>
                </div>

                <Link
                  href={`/clinician/patients/${patient.id}`}
                  className="w-full bg-slate-900 hover:bg-teal-700 text-white font-bold py-1.5 px-3 rounded text-center block transition-colors"
                >
                  Open Patient Workspace
                </Link>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
