"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { Utensils, Info, ChevronDown, ChevronUp } from "lucide-react";

export default function NutritionClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);
  const [showDetailed, setShowDetailed] = useState(false);

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Dietary & Nutrition Surveillance Summary</h1>
            <p className="text-xs text-slate-500">Aggregated dietary patterns relevant to thyroid hormone absorption and metabolism for {patient.name}.</p>
          </div>
          <button 
            onClick={() => setShowDetailed(!showDetailed)}
            className="bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <Utensils className="w-3.5 h-3.5 text-teal-400" />
            <span>{showDetailed ? "Hide Detailed Logs" : "View Detailed Logs"}</span>
            {showDetailed ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
          </button>
        </div>

        {/* 30-Day High-Level Nutrition Summary */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
            <Utensils className="w-4 h-4 text-teal-600" />
            <span>NUTRITION SUMMARY (Last {patient.nutritionSummary.periodDays} Days)</span>
          </h2>

          <div className="space-y-2 text-xs">
            {patient.nutritionSummary.patterns.map((pattern, idx) => (
              <div key={idx} className="p-3 bg-slate-50 rounded border border-slate-200 flex items-center space-x-3 text-slate-800 font-medium">
                <span className="w-2 h-2 rounded-full bg-teal-600 shrink-0" />
                <span>{pattern}</span>
              </div>
            ))}
          </div>

          <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
            <Info className="w-4 h-4 text-blue-600 shrink-0" />
            <p><strong>Clinical Disclaimer:</strong> Dietary associations represent potential absorption considerations and do not establish direct causality for TSH shifts.</p>
          </div>
        </div>

        {/* Expandable Detailed Logs */}
        {showDetailed && (
          <div className="bg-white rounded-lg border border-teal-200 shadow-md p-5 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <h3 className="font-bold text-xs text-teal-900 uppercase">AI-Analyzed Patient Food Intake Logs</h3>
              <span className="text-[11px] text-slate-500 font-mono">Patient Permitted View</span>
            </div>

            <table className="w-full text-left text-xs border-collapse">
              <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
                <tr>
                  <th className="py-2.5 px-4">Date</th>
                  <th className="py-2.5 px-4">Logged Food</th>
                  <th className="py-2.5 px-4">AI Confidence</th>
                  <th className="py-2.5 px-4">Identified Constituent</th>
                  <th className="py-2.5 px-4">Potential Thyroid Relevance</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 font-medium">
                {patient.nutritionSummary.detailedLogs.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4 font-bold text-slate-900">{item.date}</td>
                    <td className="py-3 px-4 text-slate-800 font-semibold">{item.food}</td>
                    <td className="py-3 px-4 text-teal-700 font-bold">{Math.round(item.confidence * 100)}%</td>
                    <td className="py-3 px-4 text-slate-600 font-mono">{item.constituent}</td>
                    <td className="py-3 px-4 text-slate-700">{item.relevance}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

      </div>
    </PatientWorkspaceLayout>
  );
}
