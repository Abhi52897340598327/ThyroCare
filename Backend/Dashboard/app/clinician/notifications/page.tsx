"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { MOCK_PATIENTS } from "@/lib/demoData";
import Link from "next/link";
import { Bell, ArrowRight, FlaskConical, AlertTriangle, FileText, Calendar } from "lucide-react";

export default function NotificationsPage() {
  const alertsList = MOCK_PATIENTS.flatMap(p => 
    p.alerts.map(a => ({ ...a, patientName: p.name, patientId: p.id }))
  );

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <Bell className="w-5 h-5 text-teal-600" />
            <span>GLOBAL CLINICAL NOTIFICATIONS SURVEILLANCE</span>
          </h1>
          <p className="text-xs text-slate-500">New lab results, TSH trend alerts, patient-generated reports, and follow-up requests across population.</p>

          <div className="space-y-3 pt-2">
            {alertsList.map((item, idx) => (
              <div key={idx} className="p-4 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between">
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-bold text-slate-900 text-xs uppercase">{item.patientName}</span>
                    <span className="bg-amber-100 text-amber-900 font-extrabold px-2 py-0.5 rounded text-[9px]">
                      {item.category}
                    </span>
                  </div>
                  <h4 className="font-bold text-slate-800 text-xs mt-1">{item.title}</h4>
                  <p className="text-xs text-slate-600 mt-0.5">{item.detail}</p>
                </div>

                <Link
                  href={`/clinician/patients/${item.patientId}/alerts`}
                  className="bg-slate-900 hover:bg-teal-700 text-white text-xs font-bold px-3 py-1.5 rounded flex items-center space-x-1 transition-colors shrink-0"
                >
                  <span>Inspect</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
