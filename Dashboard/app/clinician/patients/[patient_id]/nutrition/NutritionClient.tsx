"use client";

import { useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { 
  Utensils, 
  Info, 
  ChevronDown, 
  ChevronUp, 
  Database, 
  Activity, 
  AlertTriangle, 
  Camera, 
  Check, 
  Copy, 
  Sliders 
} from "lucide-react";

export default function NutritionClient({ patientId }: { patientId: string }) {
  const patient = getPatientById(patientId);
  const [showDetailed, setShowDetailed] = useState(true);
  const [selectedScanIdx, setSelectedScanIdx] = useState(0);
  const [copiedJson, setCopiedJson] = useState(false);

  const scannedMeals = [
    {
      food: "Grilled Chicken & Brown Rice Bowl",
      date: "2026-09-24 12:45",
      confidence: 0.94,
      usdaMatchName: "Chicken breast, grilled with brown rice & steamed broccoli",
      usdaFdcId: "171077",
      usdaDataType: "SR Legacy",
      usdaQuery: "chicken breast rice broccoli",
      latencyMs: 142,
      iodine: "14.2 µg",
      selenium: "36.5 µg",
      calcium: "48 mg",
      sodium: "410 mg",
      tshShift: "-1.8%",
      t3Shift: "+3.2%",
      t4Shift: "+2.4%",
      tshStatus: "Favorable Support",
      t3Status: "+3.2% Support",
      t4Status: "+2.4% Support",
      levoRisk: "Moderate — Enforce 4-hour window from dose",
      jsonPayload: JSON.stringify({
        foodSearchCriteria: { query: "grilled chicken bowl", pageNumber: 1 },
        totalHits: 42,
        foods: [{
          fdcId: 171077,
          description: "Chicken breast, grilled with brown rice & steamed broccoli",
          dataType: "SR Legacy",
          foodNutrients: [
            { nutrientName: "Protein", value: 33.8, unitName: "G" },
            { nutrientName: "Selenium, Se", value: 36.5, unitName: "UG" },
            { nutrientName: "Iodine, I", value: 14.2, unitName: "UG" }
          ]
        }]
      }, null, 2)
    },
    {
      food: "Wild Alaskan Salmon & Quinoa",
      date: "2026-09-22 18:30",
      confidence: 0.96,
      usdaMatchName: "Salmon, wild, cooked, dry heat with quinoa",
      usdaFdcId: "175168",
      usdaDataType: "Foundation Foods",
      usdaQuery: "wild salmon quinoa",
      latencyMs: 118,
      iodine: "38.5 µg",
      selenium: "52.4 µg",
      calcium: "22 mg",
      sodium: "115 mg",
      tshShift: "-3.4%",
      t3Shift: "+5.8%",
      t4Shift: "+4.2%",
      tshStatus: "Strong Support",
      t3Status: "+5.8% Support",
      t4Status: "+4.2% Support",
      levoRisk: "Low Risk — Minimal GI Binding",
      jsonPayload: JSON.stringify({
        foodSearchCriteria: { query: "wild salmon quinoa", pageNumber: 1 },
        totalHits: 18,
        foods: [{
          fdcId: 175168,
          description: "Salmon, wild, cooked, dry heat with quinoa",
          dataType: "Foundation Foods",
          foodNutrients: [
            { nutrientName: "Protein", value: 41.5, unitName: "G" },
            { nutrientName: "Selenium, Se", value: 52.4, unitName: "UG" }
          ]
        }]
      }, null, 2)
    }
  ];

  const currentScan = scannedMeals[selectedScanIdx];

  const handleCopyJson = () => {
    navigator.clipboard.writeText(currentScan.jsonPayload);
    setCopiedJson(true);
    setTimeout(() => setCopiedJson(false), 2000);
  };

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Dietary & USDA Food Analysis Surveillance</h1>
            <p className="text-xs text-slate-500">Aggregated USDA FoodData Central API results and hormonal shift distributions for {patient.name}.</p>
          </div>
          <button 
            onClick={() => setShowDetailed(!showDetailed)}
            className="bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
          >
            <Utensils className="w-3.5 h-3.5 text-teal-400" />
            <span>{showDetailed ? "Hide USDA Inspector" : "View USDA Inspector"}</span>
            {showDetailed ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
          </button>
        </div>

        {/* 30-Day High-Level Nutrition Summary */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
            <Utensils className="w-4 h-4 text-teal-600" />
            <span>NUTRITION & ABSORPTION SURVEILLANCE ({patient.name})</span>
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
            <p><strong>Clinical Disclaimer:</strong> Dietary associations and USDA micronutrient assays represent potential GI absorption considerations and deiodinase co-factor availability. They do not replace lab TSH monitoring.</p>
          </div>
        </div>

        {/* USDA Food Bank API & Hormonal Shift Distribution Inspector */}
        {showDetailed && (
          <div className="bg-white rounded-lg border border-teal-200 shadow-md p-5 space-y-6">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <div>
                <h3 className="font-bold text-xs text-teal-900 uppercase flex items-center space-x-2">
                  <Database className="w-4 h-4 text-teal-600" />
                  <span>USDA FoodData Central API & Percent TSH / T3 / T4 Level Distribution</span>
                </h3>
                <p className="text-[11px] text-slate-500">Inspected Vision AI photo classification & raw USDA FDC REST API response.</p>
              </div>
              <span className="text-[11px] font-mono font-bold text-teal-700 bg-teal-50 px-2 py-0.5 rounded border border-teal-200">
                Patient EHR Permitted View
              </span>
            </div>

            {/* Selector strip */}
            <div className="flex space-x-3">
              {scannedMeals.map((scan, idx) => (
                <button
                  key={idx}
                  onClick={() => setSelectedScanIdx(idx)}
                  className={`px-3 py-2 text-xs font-bold rounded border transition-colors ${
                    selectedScanIdx === idx
                      ? "bg-teal-600 text-white border-teal-700 shadow-xs"
                      : "bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100"
                  }`}
                >
                  {scan.food} ({scan.date})
                </button>
              ))}
            </div>

            {/* Main Inspection Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
              
              {/* Left Box: USDA FDC API Results */}
              <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg space-y-3">
                <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                  <span className="font-bold text-slate-800 uppercase tracking-wide">USDA API Match Details</span>
                  <span className="text-[11px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded border border-emerald-300">
                    200 OK ({currentScan.latencyMs}ms)
                  </span>
                </div>

                <div className="space-y-1.5">
                  <p><strong className="text-slate-600">FDC Description:</strong> <span className="text-slate-900 font-semibold">{currentScan.usdaMatchName}</span></p>
                  <p><strong className="text-slate-600">FDC ID:</strong> <span className="font-mono text-teal-700 font-bold">#{currentScan.usdaFdcId}</span> | <strong>Type:</strong> {currentScan.usdaDataType}</p>
                  <p><strong className="text-slate-600">Submitted Query:</strong> <span className="font-mono text-slate-800">&quot;{currentScan.usdaQuery}&quot;</span></p>
                </div>

                <div className="pt-2 border-t border-slate-200">
                  <span className="font-bold text-slate-700 uppercase text-[10px] block mb-2">Assayed USDA Micronutrients</span>
                  <div className="grid grid-cols-2 gap-2 text-center">
                    <div className="p-2 bg-white rounded border border-slate-200">
                      <span className="text-[10px] text-slate-500 font-bold block">Iodine (I)</span>
                      <span className="font-mono font-extrabold text-teal-700">{currentScan.iodine}</span>
                    </div>
                    <div className="p-2 bg-white rounded border border-slate-200">
                      <span className="text-[10px] text-slate-500 font-bold block">Selenium (Se)</span>
                      <span className="font-mono font-extrabold text-amber-700">{currentScan.selenium}</span>
                    </div>
                    <div className="p-2 bg-white rounded border border-slate-200">
                      <span className="text-[10px] text-slate-500 font-bold block">Calcium (Ca)</span>
                      <span className="font-mono font-extrabold text-purple-700">{currentScan.calcium}</span>
                    </div>
                    <div className="p-2 bg-white rounded border border-slate-200">
                      <span className="text-[10px] text-slate-500 font-bold block">Sodium (Na)</span>
                      <span className="font-mono font-extrabold text-rose-700">{currentScan.sodium}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Box: % TSH, T3, & T4 Level Distribution */}
              <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg space-y-3">
                <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                  <span className="font-bold text-slate-800 uppercase tracking-wide flex items-center space-x-1.5">
                    <Activity className="w-4 h-4 text-teal-600" />
                    <span>Percent TSH, T3, & T4 Level Shift Distribution</span>
                  </span>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center pt-1">
                  <div className="p-3 bg-white rounded border border-slate-200">
                    <span className="text-[10px] font-bold text-slate-500 uppercase block">TSH Shift</span>
                    <span className="text-lg font-black font-mono text-teal-700 mt-1 block">{currentScan.tshShift}</span>
                    <span className="text-[9px] font-bold text-teal-800 bg-teal-50 px-1 py-0.5 rounded border border-teal-200 block mt-1">
                      {currentScan.tshStatus}
                    </span>
                  </div>

                  <div className="p-3 bg-white rounded border border-slate-200">
                    <span className="text-[10px] font-bold text-slate-500 uppercase block">Free T3 Shift</span>
                    <span className="text-lg font-black font-mono text-amber-700 mt-1 block">{currentScan.t3Shift}</span>
                    <span className="text-[9px] font-bold text-amber-800 bg-amber-50 px-1 py-0.5 rounded border border-amber-200 block mt-1">
                      {currentScan.t3Status}
                    </span>
                  </div>

                  <div className="p-3 bg-white rounded border border-slate-200">
                    <span className="text-[10px] font-bold text-slate-500 uppercase block">Free T4 Shift</span>
                    <span className="text-lg font-black font-mono text-purple-700 mt-1 block">{currentScan.t4Shift}</span>
                    <span className="text-[9px] font-bold text-purple-800 bg-purple-50 px-1 py-0.5 rounded border border-purple-200 block mt-1">
                      {currentScan.t4Status}
                    </span>
                  </div>
                </div>

                <div className="p-3 bg-amber-50 border border-amber-200 rounded text-amber-950 space-y-1 mt-2">
                  <div className="flex items-center space-x-1.5 font-bold text-amber-900">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                    <span>Absorption Advisory</span>
                  </div>
                  <p className="text-[11px]">{currentScan.levoRisk}</p>
                </div>
              </div>

            </div>

            {/* Raw JSON Payload Collapsible */}
            <div className="pt-2">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold text-slate-700 uppercase flex items-center space-x-1">
                  <Sliders className="w-3.5 h-3.5 text-slate-500" />
                  <span>Raw USDA FDC REST API JSON Payload</span>
                </span>
                <button
                  onClick={handleCopyJson}
                  className="bg-slate-900 hover:bg-slate-800 text-white text-[11px] font-semibold px-2.5 py-1 rounded flex items-center space-x-1 transition-colors"
                >
                  {copiedJson ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                  <span>{copiedJson ? "Copied!" : "Copy JSON"}</span>
                </button>
              </div>
              <pre className="p-3 bg-slate-950 text-slate-100 text-[11px] font-mono rounded border border-slate-800 max-h-48 overflow-x-auto">
                {currentScan.jsonPayload}
              </pre>
            </div>

          </div>
        )}

      </div>
    </PatientWorkspaceLayout>
  );
}
