"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { Settings, User, Bell, Shield } from "lucide-react";

export default function SettingsPage() {
  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4 text-xs">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <Settings className="w-5 h-5 text-teal-600" />
            <span>CLINICIAN PREFERENCES & PROFILE SETTINGS</span>
          </h1>

          <div className="space-y-4 max-w-xl">
            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg space-y-2">
              <h3 className="font-bold text-slate-900 text-sm">Clinician Profile</h3>
              <p className="text-slate-600">Name: <strong>Dr. Jane Smith, MD</strong></p>
              <p className="text-slate-600">Specialty: <strong>Endocrinology & Thyroid Specialist</strong></p>
              <p className="text-slate-600">NPI: <strong>1982736450</strong></p>
            </div>

            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg space-y-2">
              <h3 className="font-bold text-slate-900 text-sm">Notification Thresholds</h3>
              <p className="text-slate-600">Alert TSH Shift Trigger: <strong>&gt; 30% Delta</strong></p>
              <p className="text-slate-600">Lab Result Auto-Sync: <strong>Enabled (Quest / LabCorp API)</strong></p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
