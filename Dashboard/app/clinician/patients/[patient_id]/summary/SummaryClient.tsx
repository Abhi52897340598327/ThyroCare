"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { ShieldAlert, AlertTriangle, TrendingUp, Info } from "lucide-react";

export default function SummaryClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Thyroid Clinical Assessment Summary</h1>
            <p className="text-xs text-slate-500">Comprehensive diagnostic summary, physiological trajectory, and clinical action flags for {patient.name}.</p>
          </div>
          <div className="text-xs text-slate-400 font-mono">
            MRN: {(patient as any).mrn || "••••9231"} | DOB: {(patient as any).dob || "1959-04-12"}
          </div>
        </div>

        {/* Section 1: Executive Summary */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-3">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
            <ShieldAlert className="w-4 h-4 text-teal-600" />
            <span>Executive Assessment & Primary Findings</span>
          </h2>
          <p className="text-xs text-slate-800 leading-relaxed bg-slate-50 p-4 rounded border border-slate-200">
            {(patient as any).clinicalSummaryText || `${patient.name} shows a TSH shift from 3.7 mIU/L to ${patient.latestTSH} mIU/L over recent months. Active monitoring recommended for medication timing compliance.`}
          </p>
        </div>

        {/* Section 2: Physiological Trajectory Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-3">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
              <TrendingUp className="w-4 h-4 text-teal-600" />
              <span>Hormone Dynamics</span>
            </h3>
            <div className="space-y-2 text-xs">
              <div className="flex justify-between p-2.5 bg-slate-50 rounded border border-slate-200">
                <span className="text-slate-600">Latest TSH:</span>
                <span className="font-bold text-teal-800">{patient.latestTSH} mIU/L</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded border border-slate-200">
                <span className="text-slate-600">Latest Free T4:</span>
                <span className="font-bold text-slate-800">{patient.latestFT4} ng/dL</span>
              </div>
              <div className="flex justify-between p-2.5 bg-slate-50 rounded border border-slate-200">
                <span className="text-slate-600">Latest Free T3:</span>
                <span className="font-bold text-slate-800">{patient.latestFT3} pg/mL</span>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-3">
            <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
              <AlertTriangle className="w-4 h-4 text-amber-600" />
              <span>Surveillance Flags</span>
            </h3>
            <div className="space-y-2 text-xs">
              <div className="p-2.5 bg-amber-50 rounded border border-amber-200 text-amber-900">
                <span className="font-bold block">Absorption & Timing Warning</span>
                <span className="text-[11px] text-amber-800">PPI co-administration near morning levothyroxine window.</span>
              </div>
              <div className="p-2.5 bg-slate-50 rounded border border-slate-200 text-slate-800">
                <span className="font-bold block">Symptom Trend</span>
                <span className="text-[11px] text-slate-600">Fatigue score escalated from 2 → 4 over last 30 days.</span>
              </div>
            </div>
          </div>
        </div>

        {/* Disclaimer */}
        <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
          <Info className="w-4 h-4 text-blue-600 shrink-0" />
          <p><strong>Clinical Note:</strong> AI summary suggestions sit alongside raw laboratory data and require clinician validation before action.</p>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
