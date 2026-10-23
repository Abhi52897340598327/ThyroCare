"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { BarChart3, Activity, Users, TrendingUp } from "lucide-react";

export default function GlobalDataPage() {
  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <BarChart3 className="w-5 h-5 text-teal-600" />
            <span>POPULATION THYROID DATA ANALYTICS</span>
          </h1>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg">
              <span className="text-slate-500 uppercase font-semibold block">Mean Population TSH</span>
              <span className="text-2xl font-black text-teal-900">3.49 mIU/L</span>
            </div>
            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg">
              <span className="text-slate-500 uppercase font-semibold block">Levothyroxine Compliance Rate</span>
              <span className="text-2xl font-black text-slate-900">91.4%</span>
            </div>
            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg">
              <span className="text-slate-500 uppercase font-semibold block">Review Flag Resolution Time</span>
              <span className="text-2xl font-black text-purple-900">1.8 Days</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
