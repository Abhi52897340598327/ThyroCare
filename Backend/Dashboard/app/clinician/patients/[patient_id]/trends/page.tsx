"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { TrendingUp, AlertCircle, Info } from "lucide-react";

export default function TSHTrendsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  const patient = getPatientById(params.patient_id);

  const [showTSH, setShowTSH] = useState(true);
  const [showFT4, setShowFT4] = useState(true);
  const [showFT3, setShowFT3] = useState(false);
  const [showEventMarkers, setShowEventMarkers] = useState(true);

  const labsReversed = patient.labs.slice().reverse();
  const firstLab = labsReversed[0];
  const lastLab = labsReversed[labsReversed.length - 1];

  const overallDeltaPercent = Math.round(((lastLab.tsh - firstLab.tsh) / firstLab.tsh) * 100);

  return (
    <PatientWorkspaceLayout patientId={params.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">THYROID TREND ASSESSMENT & CHANGE-POINT ANALYTICS</h1>
            <p className="text-xs text-slate-500">Longitudinal TSH/T4/T3 trajectory with multi-modal medication, diet, and symptom event markers.</p>
          </div>

          {/* Series Toggles */}
          <div className="flex items-center space-x-2 bg-white border border-slate-300 rounded p-1.5 text-xs">
            <span className="text-slate-500 font-medium px-1 text-[11px]">Series:</span>
            <button
              onClick={() => setShowTSH(!showTSH)}
              className={`px-2.5 py-1 rounded font-bold transition-colors ${
                showTSH ? "bg-teal-700 text-white" : "bg-slate-100 text-slate-500"
              }`}
            >
              TSH
            </button>
            <button
              onClick={() => setShowFT4(!showFT4)}
              className={`px-2.5 py-1 rounded font-bold transition-colors ${
                showFT4 ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-500"
              }`}
            >
              Free T4
            </button>
            <button
              onClick={() => setShowFT3(!showFT3)}
              className={`px-2.5 py-1 rounded font-bold transition-colors ${
                showFT3 ? "bg-purple-600 text-white" : "bg-slate-100 text-slate-500"
              }`}
            >
              Free T3
            </button>
            <button
              onClick={() => setShowEventMarkers(!showEventMarkers)}
              className={`px-2.5 py-1 rounded font-bold border transition-colors ${
                showEventMarkers ? "bg-amber-100 border-amber-300 text-amber-900" : "bg-slate-100 text-slate-500 border-slate-300"
              }`}
            >
              Event Markers (M, L, F, S)
            </button>
          </div>
        </div>

        {/* Change-Point Visualizer Card */}
        <div className="bg-white rounded-lg border border-amber-200 p-5 shadow-xs">
          <div className="flex items-center space-x-2 text-amber-900 font-bold text-xs uppercase mb-3">
            <AlertCircle className="w-4 h-4 text-amber-600" />
            <span>CHANGE-POINT TREND ANALYSIS — SIGNIFICANT TSH INCREASE Flagged</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 bg-amber-50/50 p-4 rounded border border-amber-100 text-xs">
            <div>
              <span className="text-[10px] text-amber-800 uppercase font-semibold block">Interval Shift</span>
              <span className="text-xl font-black text-amber-900">{firstLab.tsh} → {lastLab.tsh} mIU/L</span>
            </div>
            <div>
              <span className="text-[10px] text-amber-800 uppercase font-semibold block">Percentage Change</span>
              <span className="text-xl font-black text-amber-900">+{overallDeltaPercent}% Change</span>
            </div>
            <div>
              <span className="text-[10px] text-amber-800 uppercase font-semibold block">Time Horizon</span>
              <span className="text-xl font-black text-amber-900">~11 Months</span>
            </div>
            <div>
              <span className="text-[10px] text-amber-800 uppercase font-semibold block">Clinical Assessment</span>
              <span className="text-xs font-bold text-amber-900 block mt-1">Under-replacement pattern / Absorption interference</span>
            </div>
          </div>
        </div>

        {/* Main Longitudinal Trajectory Graph */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center justify-between">
            <span>Longitudinal Assays & Co-Occurring Events</span>
            <span className="text-[11px] font-normal text-slate-400">Hover over datapoints for details</span>
          </h2>

          <div className="h-64 w-full bg-slate-50 rounded border border-slate-200 p-4 flex flex-col justify-between relative">
            <div className="flex justify-between text-[10px] text-slate-400 border-b border-slate-200 pb-1">
              <span>7.0 mIU/L</span>
              <span>Upper Normal Bound (4.5 mIU/L)</span>
              <span>Lower Normal Bound (0.45 mIU/L)</span>
            </div>

            {/* SVG Plot Line */}
            <div className="relative flex-1 flex items-end justify-between px-6 py-4">
              {labsReversed.map((lab, i) => (
                <div key={lab.id} className="flex flex-col items-center group relative z-10">
                  
                  {/* Event Marker Badge if enabled */}
                  {showEventMarkers && i === labsReversed.length - 1 && (
                    <span className="absolute -top-7 bg-amber-400 text-slate-900 font-extrabold text-[9px] px-1.5 py-0.5 rounded shadow-xs border border-amber-500">
                      M, F
                    </span>
                  )}

                  {/* TSH Node */}
                  {showTSH && (
                    <div 
                      className="w-3.5 h-3.5 rounded-full bg-teal-700 border-2 border-white shadow-xs group-hover:scale-150 transition-transform cursor-pointer"
                      style={{ marginBottom: `${(lab.tsh / 7) * 140}px` }}
                    />
                  )}

                  {/* FT4 Node */}
                  {showFT4 && (
                    <div 
                      className="w-2.5 h-2.5 rounded-full bg-blue-600 border-2 border-white shadow-xs group-hover:scale-150 transition-transform cursor-pointer absolute"
                      style={{ marginBottom: `${(lab.ft4 / 2) * 140}px` }}
                    />
                  )}

                  <span className="text-[10px] font-bold text-slate-800">{lab.tsh}</span>
                  <span className="text-[9px] text-slate-500 font-medium">{lab.date.split(",")[0]}</span>

                  {/* Tooltip */}
                  <div className="absolute bottom-16 hidden group-hover:block bg-slate-900 text-white text-[11px] p-3 rounded-md shadow-xl z-30 w-36 pointer-events-none">
                    <p className="font-bold border-b border-slate-700 pb-1 mb-1">{lab.date}</p>
                    <p className="text-teal-400">TSH: {lab.tsh} mIU/L</p>
                    <p className="text-blue-300">Free T4: {lab.ft4} ng/dL</p>
                    <p className="text-purple-300">Free T3: {lab.ft3} pg/mL</p>
                    <p className="text-[9px] text-slate-400 mt-1">Lab: {lab.labName}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-between text-[10px] text-slate-400 border-t border-slate-200 pt-1">
              <span>Oct 2025</span>
              <span>Sep 2026</span>
            </div>
          </div>

          <div className="flex items-center space-x-6 text-xs text-slate-600 mt-4 border-t border-slate-100 pt-3">
            <span className="font-semibold text-slate-800">Marker Legend:</span>
            <span className="inline-flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-teal-700" /><span>TSH Assay</span></span>
            <span className="inline-flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-blue-600" /><span>Free T4 Assay</span></span>
            <span className="inline-flex items-center space-x-1"><span className="w-2.5 h-2 bg-amber-400 rounded-xs" /><span>M = Medication Change</span></span>
            <span className="inline-flex items-center space-x-1"><span className="w-2.5 h-2 bg-purple-400 rounded-xs" /><span>F = Diet / Calcium Event</span></span>
          </div>
        </div>

        {/* Potentially Relevant Co-Occurring Events */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-3">
          <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Potentially Relevant Co-Occurring Events</h3>

          <ul className="space-y-2 text-xs">
            <li className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <span className="font-semibold text-slate-800">• Omeprazole 20mg initiated (Jul 03) — 30 mins after Levothyroxine dosing</span>
              <span className="text-[10px] text-slate-500 font-mono">MEDICATION</span>
            </li>
            <li className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <span className="font-semibold text-slate-800">• 8 Calcium-rich breakfast meals logged near Levothyroxine window</span>
              <span className="text-[10px] text-slate-500 font-mono">DIET</span>
            </li>
            <li className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center justify-between">
              <span className="font-semibold text-slate-800">• Patient-reported Fatigue severity escalated from Mild → Moderate</span>
              <span className="text-[10px] text-slate-500 font-mono">SYMPTOM</span>
            </li>
          </ul>

          <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
            <Info className="w-4 h-4 text-blue-600 shrink-0" />
            <p><strong>Clinical Disclaimer:</strong> These events occurred during the same period and do not establish causation.</p>
          </div>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
