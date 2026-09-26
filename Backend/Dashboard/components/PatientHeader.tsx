"use client";

import { PatientProfile } from "@/lib/demoData";
import { 
  FileCheck, 
  Calendar, 
  TrendingUp, 
  TrendingDown, 
  Minus, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  PlusCircle, 
  FileText,
  ChevronDown
} from "lucide-react";
import { useState } from "react";

export default function PatientHeader({ patient }: { patient: PatientProfile }) {
  const [showActions, setShowActions] = useState(false);
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  const getStatusBadge = (status: PatientProfile["status"]) => {
    switch (status) {
      case "STABLE":
        return <span className="inline-flex items-center space-x-1 bg-emerald-50 text-emerald-700 border border-emerald-200 px-2.5 py-0.5 rounded-full text-xs font-semibold"><CheckCircle2 className="w-3.5 h-3.5" /><span>STABLE</span></span>;
      case "REVIEW SUGGESTED":
        return <span className="inline-flex items-center space-x-1 bg-amber-50 text-amber-700 border border-amber-200 px-2.5 py-0.5 rounded-full text-xs font-semibold"><AlertTriangle className="w-3.5 h-3.5 text-amber-600" /><span>REVIEW SUGGESTED</span></span>;
      case "NEW LAB RESULT":
        return <span className="inline-flex items-center space-x-1 bg-blue-50 text-blue-700 border border-blue-200 px-2.5 py-0.5 rounded-full text-xs font-semibold"><Clock className="w-3.5 h-3.5 text-blue-600" /><span>NEW LAB RESULT</span></span>;
      case "FOLLOW-UP REQUESTED":
        return <span className="inline-flex items-center space-x-1 bg-purple-50 text-purple-700 border border-purple-200 px-2.5 py-0.5 rounded-full text-xs font-semibold"><Calendar className="w-3.5 h-3.5 text-purple-600" /><span>FOLLOW-UP REQUESTED</span></span>;
      case "TREND CHANGE":
        return <span className="inline-flex items-center space-x-1 bg-orange-50 text-orange-700 border border-orange-200 px-2.5 py-0.5 rounded-full text-xs font-semibold"><TrendingUp className="w-3.5 h-3.5 text-orange-600" /><span>TREND CHANGE</span></span>;
      default:
        return <span className="inline-flex items-center space-x-1 bg-slate-100 text-slate-700 border border-slate-300 px-2.5 py-0.5 rounded-full text-xs font-semibold"><span>INSUFFICIENT DATA</span></span>;
    }
  };

  const getTrendIcon = (trend: PatientProfile["trend"]) => {
    if (trend === "Increasing") return <TrendingUp className="w-4 h-4 text-amber-600 inline ml-1" />;
    if (trend === "Decreasing") return <TrendingDown className="w-4 h-4 text-emerald-600 inline ml-1" />;
    return <Minus className="w-4 h-4 text-slate-500 inline ml-1" />;
  };

  const handleAction = (msg: string) => {
    setActionMessage(msg);
    setShowActions(false);
    setTimeout(() => setActionMessage(null), 4000);
  };

  return (
    <div className="bg-white border-b border-slate-200 px-6 py-3 shadow-xs sticky top-14 z-40">
      <div className="max-w-[1920px] mx-auto flex flex-wrap items-center justify-between gap-4">
        
        {/* Patient Identity */}
        <div className="flex items-center space-x-4">
          <div className="w-10 h-10 rounded-full bg-slate-900 text-teal-400 font-bold flex items-center justify-center text-sm shadow-xs border border-slate-700">
            {patient.name.split(" ").map(n => n[0]).join("")}
          </div>
          <div>
            <div className="flex items-center space-x-3">
              <h1 className="text-base font-bold text-slate-900 uppercase tracking-tight">{patient.name}</h1>
              <span className="text-xs text-slate-500 font-medium">{patient.age} yrs | {patient.sex}</span>
              {getStatusBadge(patient.status)}
            </div>
            <p className="text-xs text-slate-600 font-medium mt-0.5">
              Condition: <strong className="text-slate-800">{patient.condition}</strong>
            </p>
          </div>
        </div>

        {/* Clinical Metrics Bar */}
        <div className="flex items-center space-x-6 text-xs border-x border-slate-200 px-6 py-1">
          <div>
            <span className="text-slate-500 block uppercase font-medium text-[10px]">Latest TSH</span>
            <span className="font-extrabold text-sm text-slate-900">
              {patient.latestTSH} <span className="text-[10px] font-medium text-slate-500">mIU/L</span>
              {getTrendIcon(patient.trend)}
            </span>
          </div>

          <div>
            <span className="text-slate-500 block uppercase font-medium text-[10px]">Free T4</span>
            <span className="font-bold text-slate-800 text-xs">
              {patient.latestFT4} <span className="text-[10px] font-normal text-slate-500">ng/dL</span>
            </span>
          </div>

          <div>
            <span className="text-slate-500 block uppercase font-medium text-[10px]">Free T3</span>
            <span className="font-bold text-slate-800 text-xs">
              {patient.latestFT3} <span className="text-[10px] font-normal text-slate-500">pg/mL</span>
            </span>
          </div>

          <div>
            <span className="text-slate-500 block uppercase font-medium text-[10px]">Last Lab</span>
            <span className="font-semibold text-slate-700">{patient.lastLabDate}</span>
          </div>

          <div>
            <span className="text-slate-500 block uppercase font-medium text-[10px]">Next Visit</span>
            <span className="font-semibold text-teal-700">{patient.nextVisit}</span>
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex items-center space-x-2 relative">
          <button 
            onClick={() => handleAction(`Report generation initiated for ${patient.name}`)}
            className="inline-flex items-center space-x-1.5 bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold px-3 py-1.5 rounded shadow-xs transition-colors"
          >
            <FileText className="w-3.5 h-3.5" />
            <span>Generate Report</span>
          </button>

          <button 
            onClick={() => handleAction(`Follow-up recommendation logged for ${patient.name}`)}
            className="inline-flex items-center space-x-1.5 bg-slate-800 hover:bg-slate-900 text-white text-xs font-semibold px-3 py-1.5 rounded shadow-xs transition-colors"
          >
            <Calendar className="w-3.5 h-3.5 text-teal-400" />
            <span>Recommend Follow-Up</span>
          </button>

          <div className="relative">
            <button 
              onClick={() => setShowActions(!showActions)}
              className="inline-flex items-center space-x-1 bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold px-2.5 py-1.5 rounded border border-slate-300 transition-colors"
            >
              <span>Actions</span>
              <ChevronDown className="w-3.5 h-3.5" />
            </button>

            {showActions && (
              <div className="absolute right-0 mt-1 w-48 bg-white border border-slate-200 rounded-md shadow-lg py-1 z-50 text-xs">
                <button onClick={() => handleAction("New Lab Requested")} className="w-full text-left px-3 py-1.5 hover:bg-slate-100 text-slate-700 font-medium">Request New Lab Order</button>
                <button onClick={() => handleAction("Clinical Note Added")} className="w-full text-left px-3 py-1.5 hover:bg-slate-100 text-slate-700 font-medium">Add Quick Note</button>
                <button onClick={() => handleAction("Patient Messaged")} className="w-full text-left px-3 py-1.5 hover:bg-slate-100 text-slate-700 font-medium">Message Patient</button>
                <button onClick={() => handleAction("Marked Reviewed")} className="w-full text-left px-3 py-1.5 hover:bg-slate-100 text-emerald-700 font-semibold border-t border-slate-100">Mark Reviewed</button>
              </div>
            )}
          </div>
        </div>

      </div>

      {actionMessage && (
        <div className="max-w-[1920px] mx-auto mt-2 text-xs bg-teal-50 border border-teal-200 text-teal-800 px-3 py-1 rounded flex items-center space-x-2">
          <CheckCircle2 className="w-4 h-4 text-teal-600" />
          <span>{actionMessage}</span>
        </div>
      )}
    </div>
  );
}
