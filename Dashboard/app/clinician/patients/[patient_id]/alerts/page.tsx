"use client";

import { use, useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, ReviewAlert } from "@/lib/demoData";
import { AlertTriangle, CheckCircle2, MessageSquare, PlusCircle, Calendar, FlaskConical } from "lucide-react";

export default function AlertsPage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);
  const [alerts, setAlerts] = useState<ReviewAlert[]>(patient.alerts);
  const [activeAlert, setActiveAlert] = useState<ReviewAlert | null>(patient.alerts[0] || null);

  const toggleReview = (id: string) => {
    setAlerts(alerts.map(a => a.id === id ? { ...a, reviewed: !a.reviewed } : a));
  };

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">CLINICAL ALERTS & REVIEW PANEL</h1>
            <p className="text-xs text-slate-500">Targeted surveillance review flags, laboratory shifts, and decision support for {patient.name}.</p>
          </div>
        </div>

        {/* Alerts List */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          <div className="space-y-3">
            <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Active Clinical Review Flags ({alerts.length})</h2>

            {alerts.map((alert) => (
              <div 
                key={alert.id}
                onClick={() => setActiveAlert(alert)}
                className={`p-4 rounded-lg border text-xs cursor-pointer transition-colors space-y-2 ${
                  activeAlert?.id === alert.id ? "bg-amber-50 border-amber-300 shadow-sm" : "bg-white border-slate-200 hover:bg-slate-50"
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="bg-amber-200 text-amber-900 font-extrabold px-2 py-0.5 rounded text-[9px] uppercase">
                    {alert.category}
                  </span>
                  <span className="text-[10px] text-slate-400 font-mono">{alert.date}</span>
                </div>

                <h3 className="font-bold text-slate-900">{alert.title}</h3>

                <div className="flex items-center justify-between border-t border-slate-200/60 pt-2">
                  <span className={`text-[10px] font-bold ${alert.reviewed ? "text-emerald-700" : "text-amber-700"}`}>
                    {alert.reviewed ? "✓ REVIEWED" : "● PENDING REVIEW"}
                  </span>
                  <button 
                    onClick={(e) => { e.stopPropagation(); toggleReview(alert.id); }}
                    className="text-[11px] font-semibold text-teal-700 hover:underline"
                  >
                    {alert.reviewed ? "Mark Unreviewed" : "Mark Reviewed"}
                  </button>
                </div>
              </div>
            ))}
          </div>

          {/* Active Review Drawer Panel */}
          {activeAlert && (
            <div className="lg:col-span-2 bg-white rounded-lg border border-amber-200 p-6 shadow-md space-y-5">
              <div className="border-b border-amber-200 pb-3 flex items-center justify-between">
                <div>
                  <span className="text-[10px] uppercase font-bold text-amber-800 bg-amber-100 px-2 py-0.5 rounded">
                    CLINICAL REVIEW EVENT — {activeAlert.category}
                  </span>
                  <h2 className="text-base font-bold text-slate-900 mt-1">{activeAlert.title}</h2>
                </div>
                <button
                  onClick={() => toggleReview(activeAlert.id)}
                  className={`text-xs font-bold px-3 py-1.5 rounded transition-colors ${
                    activeAlert.reviewed ? "bg-emerald-100 text-emerald-800" : "bg-teal-700 text-white hover:bg-teal-800"
                  }`}
                >
                  {activeAlert.reviewed ? "✓ MARKED REVIEWED" : "MARK REVIEWED"}
                </button>
              </div>

              <div className="bg-slate-50 p-4 rounded border border-slate-200 text-xs space-y-2">
                <h4 className="font-bold text-slate-800 uppercase text-[11px]">Event Details & Context</h4>
                <p className="text-slate-700 leading-relaxed">{activeAlert.detail}</p>
              </div>

              <div className="space-y-3">
                <h4 className="font-bold text-slate-800 text-xs uppercase">Clinician Action Controls</h4>
                <div className="grid grid-cols-2 gap-3">
                  <button 
                    onClick={() => alert(`Clinical note modal launched for ${patient.name}`)}
                    className="p-3 bg-slate-900 hover:bg-slate-800 text-white rounded text-xs font-semibold flex items-center justify-center space-x-2 transition-colors"
                  >
                    <PlusCircle className="w-4 h-4 text-teal-400" />
                    <span>Add Clinical Note</span>
                  </button>

                  <button 
                    onClick={() => alert(`Follow-up scheduled for ${patient.name}`)}
                    className="p-3 bg-teal-700 hover:bg-teal-800 text-white rounded text-xs font-semibold flex items-center justify-center space-x-2 transition-colors"
                  >
                    <Calendar className="w-4 h-4" />
                    <span>Recommend Follow-Up</span>
                  </button>

                  <button 
                    onClick={() => alert(`New lab order interface opened for ${patient.name}`)}
                    className="p-3 bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-300 rounded text-xs font-semibold flex items-center justify-center space-x-2 transition-colors"
                  >
                    <FlaskConical className="w-4 h-4 text-slate-600" />
                    <span>Request New Lab Order</span>
                  </button>

                  <button 
                    onClick={() => alert(`Secure patient message dialog opened`)}
                    className="p-3 bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-300 rounded text-xs font-semibold flex items-center justify-center space-x-2 transition-colors"
                  >
                    <MessageSquare className="w-4 h-4 text-slate-600" />
                    <span>Message Patient</span>
                  </button>
                </div>
              </div>
            </div>
          )}

        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
