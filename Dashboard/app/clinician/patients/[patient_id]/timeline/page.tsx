"use client";

import { use, useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, TimelineEvent } from "@/lib/demoData";
import { Clock, Filter, FlaskConical, Pill, Utensils, Stethoscope, FileText, Calendar } from "lucide-react";

export default function TimelinePage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);
  const [filterType, setFilterType] = useState<string>("ALL");

  const filteredTimeline = filterType === "ALL" 
    ? patient.timeline 
    : patient.timeline.filter(t => t.type === filterType);

  const getEventBadge = (type: TimelineEvent["type"]) => {
    switch (type) {
      case "LAB":
        return <span className="bg-teal-100 text-teal-800 border border-teal-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><FlaskConical className="w-3 h-3" /><span>LAB RESULT</span></span>;
      case "MEDICATION":
        return <span className="bg-amber-100 text-amber-800 border border-amber-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><Pill className="w-3 h-3" /><span>MEDICATION</span></span>;
      case "NUTRITION":
        return <span className="bg-purple-100 text-purple-800 border border-purple-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><Utensils className="w-3 h-3" /><span>NUTRITION</span></span>;
      case "SYMPTOM":
        return <span className="bg-rose-100 text-rose-800 border border-rose-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><Stethoscope className="w-3 h-3" /><span>SYMPTOM</span></span>;
      case "REPORT":
        return <span className="bg-blue-100 text-blue-800 border border-blue-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><FileText className="w-3 h-3" /><span>REPORT</span></span>;
      default:
        return <span className="bg-slate-100 text-slate-800 border border-slate-200 px-2 py-0.5 rounded text-[10px] font-bold flex items-center space-x-1"><Calendar className="w-3 h-3" /><span>APPOINTMENT</span></span>;
    }
  };

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">EHR Chronological Patient Timeline</h1>
            <p className="text-xs text-slate-500">Unified audit timeline combining laboratory, medication, symptom, nutrition, and clinical events for {patient.name}.</p>
          </div>

          {/* Filters */}
          <div className="flex items-center space-x-1 bg-white border border-slate-300 rounded p-1 text-xs">
            {["ALL", "LAB", "MEDICATION", "NUTRITION", "SYMPTOM", "REPORT", "APPOINTMENT"].map((cat) => (
              <button
                key={cat}
                onClick={() => setFilterType(cat)}
                className={`px-2.5 py-1 rounded text-xs font-semibold transition-colors ${
                  filterType === cat ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Timeline Stream */}
        <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-xs relative">
          <div className="absolute left-10 top-8 bottom-8 w-0.5 bg-slate-200" />

          <div className="space-y-6 relative z-10">
            {filteredTimeline.length > 0 ? (
              filteredTimeline.map((item) => (
                <div key={item.id} className="flex items-start space-x-6">
                  <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center text-xs font-bold shrink-0 border-2 border-white shadow-xs">
                    <Clock className="w-4 h-4 text-teal-400" />
                  </div>

                  <div className="flex-1 bg-slate-50 border border-slate-200 rounded-lg p-4 space-y-2 text-xs">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <span className="font-bold text-slate-900 text-sm">{item.title}</span>
                        {getEventBadge(item.type)}
                      </div>
                      <span className="text-slate-500 font-semibold font-mono text-[11px]">{item.date}</span>
                    </div>

                    <p className="text-slate-700 leading-relaxed">{item.detail}</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-8 text-center text-slate-500 text-xs">
                No timeline events matching the selected category.
              </div>
            )}
          </div>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
