"use client";

import { useState } from "react";
import ClinicalTopNav from "@/components/ClinicalTopNav";
import { 
  Camera, 
  Utensils, 
  Database, 
  Activity, 
  CheckCircle2, 
  AlertTriangle, 
  Copy, 
  Check, 
  RefreshCw, 
  Sliders, 
  Info 
} from "lucide-react";

interface FoodSample {
  id: string;
  name: string;
  image: string;
  confidence: number;
  protein: number;
  carbs: number;
  vitamins: number;
  produce: number;
  usdaMatchName: string;
  usdaFdcId: string;
  usdaDataType: string;
  usdaQuery: string;
  usdaApiCallLatencyMs: number;
  iodineMicrograms: number;
  seleniumMicrograms: number;
  calciumMilligrams: number;
  sodiumMilligrams: number;
  ironMilligrams: number;
  tshPercentChange: number;
  t3PercentChange: number;
  t4PercentChange: number;
  tshImpact: string;
  t3Impact: string;
  t4Impact: string;
  levothyroxineAbsorptionRisk: string;
  rawUsdaJsonResponse: string;
}

const PRESET_MEALS: FoodSample[] = [
  {
    id: "m1",
    name: "Grilled Chicken & Brown Rice Bowl",
    image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80",
    confidence: 0.94,
    protein: 34,
    carbs: 36,
    vitamins: 14,
    produce: 16,
    usdaMatchName: "Chicken breast, grilled with seasoned brown rice & steamed broccoli",
    usdaFdcId: "171077",
    usdaDataType: "SR Legacy Foods",
    usdaQuery: "chicken breast rice broccoli",
    usdaApiCallLatencyMs: 142,
    iodineMicrograms: 14.2,
    seleniumMicrograms: 36.5,
    calciumMilligrams: 48.0,
    sodiumMilligrams: 410.0,
    ironMilligrams: 2.1,
    tshPercentChange: -1.8,
    t3PercentChange: 3.2,
    t4PercentChange: 2.4,
    tshImpact: "Likely Favorable",
    t3Impact: "+3.2% Support",
    t4Impact: "+2.4% Support",
    levothyroxineAbsorptionRisk: "Moderate — Enforce 4-hour window from dose",
    rawUsdaJsonResponse: JSON.stringify({
      foodSearchCriteria: { query: "grilled chicken bowl", pageNumber: 1 },
      totalHits: 42,
      foods: [{
        fdcId: 171077,
        description: "Chicken breast, grilled with seasoned brown rice & steamed broccoli",
        dataType: "SR Legacy",
        foodNutrients: [
          { nutrientName: "Protein", value: 33.8, unitName: "G" },
          { nutrientName: "Carbohydrate, by difference", value: 36.1, unitName: "G" },
          { nutrientName: "Selenium, Se", value: 36.5, unitName: "UG" },
          { nutrientName: "Iodine, I", value: 14.2, unitName: "UG" },
          { nutrientName: "Calcium, Ca", value: 48.0, unitName: "MG" }
        ]
      }]
    }, null, 2)
  },
  {
    id: "m2",
    name: "Wild Salmon & Quinoa Salad",
    image: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=600&q=80",
    confidence: 0.96,
    protein: 42,
    carbs: 22,
    vitamins: 18,
    produce: 18,
    usdaMatchName: "Salmon, wild, cooked, dry heat with organic quinoa & kale",
    usdaFdcId: "175168",
    usdaDataType: "Foundation Foods",
    usdaQuery: "wild salmon quinoa kale",
    usdaApiCallLatencyMs: 118,
    iodineMicrograms: 38.5,
    seleniumMicrograms: 52.4,
    calciumMilligrams: 22.0,
    sodiumMilligrams: 115.0,
    ironMilligrams: 1.8,
    tshPercentChange: -3.4,
    t3PercentChange: 5.8,
    t4PercentChange: 4.2,
    tshImpact: "Strong Support",
    t3Impact: "+5.8% Support",
    t4Impact: "+4.2% Support",
    levothyroxineAbsorptionRisk: "Low Risk — Minimal GI Binding",
    rawUsdaJsonResponse: JSON.stringify({
      foodSearchCriteria: { query: "wild salmon quinoa", pageNumber: 1 },
      totalHits: 18,
      foods: [{
        fdcId: 175168,
        description: "Salmon, wild, cooked, dry heat with organic quinoa & kale",
        dataType: "Foundation Foods",
        foodNutrients: [
          { nutrientName: "Protein", value: 41.5, unitName: "G" },
          { nutrientName: "Selenium, Se", value: 52.4, unitName: "UG" },
          { nutrientName: "Iodine, I", value: 38.5, unitName: "UG" }
        ]
      }]
    }, null, 2)
  },
  {
    id: "m3",
    name: "Steamed Broccoli & Tofu Stir-Fry",
    image: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80",
    confidence: 0.91,
    protein: 22,
    carbs: 28,
    vitamins: 26,
    produce: 24,
    usdaMatchName: "Tofu, firm, prepared with calcium sulfate & steamed cruciferous vegetables",
    usdaFdcId: "172448",
    usdaDataType: "Branded / SR Legacy",
    usdaQuery: "tofu broccoli stir fry",
    usdaApiCallLatencyMs: 164,
    iodineMicrograms: 2.1,
    seleniumMicrograms: 12.8,
    calciumMilligrams: 380.0,
    sodiumMilligrams: 490.0,
    ironMilligrams: 4.2,
    tshPercentChange: 2.3,
    t3PercentChange: -1.4,
    t4PercentChange: -2.8,
    tshImpact: "Glucosinolates Alert",
    t3Impact: "-1.4% Dip",
    t4Impact: "-2.8% Dip",
    levothyroxineAbsorptionRisk: "High Risk — High Calcium & Soy Isoflavones",
    rawUsdaJsonResponse: JSON.stringify({
      foodSearchCriteria: { query: "tofu broccoli stir fry", pageNumber: 1 },
      totalHits: 35,
      foods: [{
        fdcId: 172448,
        description: "Tofu, firm, prepared with calcium sulfate & steamed cruciferous vegetables",
        dataType: "SR Legacy",
        foodNutrients: [
          { nutrientName: "Calcium, Ca", value: 380.0, unitName: "MG" },
          { nutrientName: "Protein", value: 21.8, unitName: "G" }
        ]
      }]
    }, null, 2)
  }
];

export default function FoodAnalysisClient() {
  const [selectedMeal, setSelectedMeal] = useState<FoodSample>(PRESET_MEALS[0]);
  const [activeTab, setActiveTab] = useState<"overview" | "usda" | "hormones" | "json">("overview");
  const [copied, setCopied] = useState(false);
  const [isSimulatingScan, setIsSimulatingScan] = useState(false);

  const handleCopyJson = () => {
    navigator.clipboard.writeText(selectedMeal.rawUsdaJsonResponse);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleScanSimulation = () => {
    setIsSimulatingScan(true);
    setTimeout(() => {
      setIsSimulatingScan(false);
    }, 900);
  };

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 font-sans">
      <ClinicalTopNav />

      <main className="max-w-[1600px] mx-auto p-4 sm:p-6 space-y-6">
        
        {/* Header */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-teal-100 text-teal-800 text-[11px] font-extrabold uppercase px-2.5 py-0.5 rounded-full border border-teal-200">
                Clinical Module
              </span>
              <span className="text-xs text-slate-500 font-mono">USDA FDC REST API v2.4</span>
            </div>
            <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase tracking-tight flex items-center space-x-2">
              <Utensils className="w-5 h-5 text-teal-600" />
              <span>Food Photo Scan & USDA Thyroid Impact Distribution</span>
            </h1>
            <p className="text-xs text-slate-600 mt-0.5">
              Inspect Vision AI classifications, USDA FoodData Central REST API calls, assayed micronutrients, and percentage shifts in TSH, Free T3, and Free T4.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={handleScanSimulation}
              disabled={isSimulatingScan}
              className="bg-teal-600 hover:bg-teal-700 text-white font-semibold text-xs px-4 py-2.5 rounded-lg flex items-center space-x-2 shadow-xs transition-colors disabled:opacity-50"
            >
              {isSimulatingScan ? (
                <RefreshCw className="w-4 h-4 animate-spin text-white" />
              ) : (
                <Camera className="w-4 h-4 text-white" />
              )}
              <span>{isSimulatingScan ? "Querying USDA..." : "Simulate Meal Photo Scan"}</span>
            </button>
          </div>
        </div>

        {/* Meal Preset Selection Strip */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {PRESET_MEALS.map((meal) => (
            <div
              key={meal.id}
              onClick={() => setSelectedMeal(meal)}
              className={`cursor-pointer bg-white rounded-lg border p-4 shadow-xs transition-all flex items-center space-x-3.5 ${
                selectedMeal.id === meal.id
                  ? "border-teal-600 ring-2 ring-teal-500/20 bg-teal-50/20"
                  : "border-slate-200 hover:border-slate-300"
              }`}
            >
              <div className="w-14 h-14 rounded-md overflow-hidden bg-slate-200 shrink-0 border border-slate-200">
                <img src={meal.image} alt={meal.name} className="w-full h-full object-cover" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold text-teal-700 uppercase tracking-wide">FDC #{meal.usdaFdcId}</span>
                  <span className="text-[10px] font-extrabold text-slate-500">{Math.round(meal.confidence * 100)}% AI Match</span>
                </div>
                <h3 className="text-xs font-bold text-slate-900 truncate">{meal.name}</h3>
                <p className="text-[11px] text-slate-500 truncate mt-0.5">{meal.usdaMatchName}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Main Inspector Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          
          {/* Left Column: Photo Preview & Macro Ratio */}
          <div className="lg:col-span-4 space-y-6">
            <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2">
                  <Camera className="w-4 h-4 text-teal-600" />
                  <span>Captured Meal Photo</span>
                </h2>
                <span className="text-[11px] font-mono font-bold text-teal-600 bg-teal-50 px-2 py-0.5 rounded border border-teal-200">
                  {Math.round(selectedMeal.confidence * 100)}% Vision Confidence
                </span>
              </div>

              <div className="relative rounded-lg overflow-hidden border border-slate-200 aspect-video bg-slate-950">
                <img src={selectedMeal.image} alt={selectedMeal.name} className="w-full h-full object-cover" />
                <div className="absolute bottom-2 left-2 right-2 bg-slate-900/85 backdrop-blur-xs p-2.5 rounded text-white text-xs flex items-center justify-between border border-slate-700">
                  <div className="truncate pr-2">
                    <p className="font-bold text-slate-100 truncate">{selectedMeal.name}</p>
                    <p className="text-[10px] text-slate-400 font-mono truncate">Query: &quot;{selectedMeal.usdaQuery}&quot;</p>
                  </div>
                  <CheckCircle2 className="w-4 h-4 text-teal-400 shrink-0" />
                </div>
              </div>

              <div className="space-y-3 pt-2">
                <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Macronutrient & Plant Balance</h3>
                
                <div className="space-y-2 text-xs">
                  <div>
                    <div className="flex justify-between font-semibold text-slate-700 mb-1">
                      <span>Protein</span>
                      <span className="font-mono text-teal-700">{selectedMeal.protein}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2">
                      <div className="bg-teal-600 h-2 rounded-full" style={{ width: `${selectedMeal.protein}%` }} />
                    </div>
                  </div>

                  <div>
                    <div className="flex justify-between font-semibold text-slate-700 mb-1">
                      <span>Carbohydrates</span>
                      <span className="font-mono text-amber-700">{selectedMeal.carbs}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2">
                      <div className="bg-amber-500 h-2 rounded-full" style={{ width: `${selectedMeal.carbs}%` }} />
                    </div>
                  </div>

                  <div>
                    <div className="flex justify-between font-semibold text-slate-700 mb-1">
                      <span>Vitamins & Co-factors</span>
                      <span className="font-mono text-purple-700">{selectedMeal.vitamins}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2">
                      <div className="bg-purple-600 h-2 rounded-full" style={{ width: `${selectedMeal.vitamins}%` }} />
                    </div>
                  </div>

                  <div>
                    <div className="flex justify-between font-semibold text-slate-700 mb-1">
                      <span>Fruits & Vegetables</span>
                      <span className="font-mono text-rose-700">{selectedMeal.produce}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2">
                      <div className="bg-rose-500 h-2 rounded-full" style={{ width: `${selectedMeal.produce}%` }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Tabbed Inspector */}
          <div className="lg:col-span-8 space-y-6">
            <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
              
              {/* Tab Bar Navigation */}
              <div className="flex border-b border-slate-200 bg-slate-50 overflow-x-auto">
                <button
                  onClick={() => setActiveTab("overview")}
                  className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                    activeTab === "overview"
                      ? "border-teal-600 text-teal-700 bg-white"
                      : "border-transparent text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <Utensils className="w-3.5 h-3.5" />
                  <span>Meal Overview</span>
                </button>

                <button
                  onClick={() => setActiveTab("usda")}
                  className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                    activeTab === "usda"
                      ? "border-teal-600 text-teal-700 bg-white"
                      : "border-transparent text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <Database className="w-3.5 h-3.5" />
                  <span>USDA FDC API Results</span>
                </button>

                <button
                  onClick={() => setActiveTab("hormones")}
                  className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                    activeTab === "hormones"
                      ? "border-teal-600 text-teal-700 bg-white"
                      : "border-transparent text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <Activity className="w-3.5 h-3.5" />
                  <span>TSH / T3 / T4 Distribution</span>
                </button>

                <button
                  onClick={() => setActiveTab("json")}
                  className={`px-4 py-3 text-xs font-bold uppercase tracking-wider flex items-center space-x-2 border-b-2 transition-colors ${
                    activeTab === "json"
                      ? "border-teal-600 text-teal-700 bg-white"
                      : "border-transparent text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <Sliders className="w-3.5 h-3.5" />
                  <span>Raw JSON Payload</span>
                </button>
              </div>

              {/* Tab Content Panes */}
              <div className="p-6 space-y-6">
                
                {/* TAB 0: OVERVIEW */}
                {activeTab === "overview" && (
                  <div className="space-y-6">
                    <div className="bg-slate-50 border border-slate-200 p-4 rounded-lg flex items-center justify-between">
                      <div>
                        <span className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Matched USDA Item</span>
                        <h3 className="text-sm font-extrabold text-slate-900">{selectedMeal.usdaMatchName}</h3>
                        <p className="text-xs text-slate-500 font-mono mt-0.5">FDC ID: #{selectedMeal.usdaFdcId} | Category: {selectedMeal.usdaDataType}</p>
                      </div>
                      <div className="text-right">
                        <span className="bg-emerald-100 text-emerald-800 text-[11px] font-bold px-2.5 py-1 rounded border border-emerald-300">
                          200 OK ({selectedMeal.usdaApiCallLatencyMs}ms)
                        </span>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                      <div className="p-3 bg-teal-50 border border-teal-200 rounded-lg text-center">
                        <span className="text-[10px] font-bold text-teal-700 uppercase">Iodine (I)</span>
                        <p className="text-lg font-extrabold text-teal-950 mt-1">{selectedMeal.iodineMicrograms} µg</p>
                      </div>

                      <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-center">
                        <span className="text-[10px] font-bold text-amber-700 uppercase">Selenium (Se)</span>
                        <p className="text-lg font-extrabold text-amber-950 mt-1">{selectedMeal.seleniumMicrograms} µg</p>
                      </div>

                      <div className="p-3 bg-purple-50 border border-purple-200 rounded-lg text-center">
                        <span className="text-[10px] font-bold text-purple-700 uppercase">Calcium (Ca)</span>
                        <p className="text-lg font-extrabold text-purple-950 mt-1">{selectedMeal.calciumMilligrams} mg</p>
                      </div>

                      <div className="p-3 bg-rose-50 border border-rose-200 rounded-lg text-center">
                        <span className="text-[10px] font-bold text-rose-700 uppercase">Sodium (Na)</span>
                        <p className="text-lg font-extrabold text-rose-950 mt-1">{selectedMeal.sodiumMilligrams} mg</p>
                      </div>
                    </div>

                    <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg space-y-1.5 text-xs text-amber-950">
                      <div className="flex items-center space-x-2 font-bold text-amber-900">
                        <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0" />
                        <span>Levothyroxine & Synthroid GI Absorption Warning</span>
                      </div>
                      <p className="text-slate-700">{selectedMeal.levothyroxineAbsorptionRisk}</p>
                    </div>
                  </div>
                )}

                {/* TAB 1: USDA API RESULTS */}
                {activeTab === "usda" && (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                      <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">USDA FoodData Central REST Response</h3>
                      <span className="text-xs text-slate-500 font-mono">Endpoint: /fdc/v1/foods/search</span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                      <div className="p-3 bg-slate-50 rounded border border-slate-200 space-y-1">
                        <span className="text-slate-500 font-bold uppercase text-[10px]">FDC Item Description</span>
                        <p className="font-bold text-slate-900">{selectedMeal.usdaMatchName}</p>
                      </div>

                      <div className="p-3 bg-slate-50 rounded border border-slate-200 space-y-1">
                        <span className="text-slate-500 font-bold uppercase text-[10px]">Query Input Parameters</span>
                        <p className="font-mono text-teal-700 font-semibold">&quot;{selectedMeal.usdaQuery}&quot;</p>
                      </div>

                      <div className="p-3 bg-slate-50 rounded border border-slate-200 space-y-1">
                        <span className="text-slate-500 font-bold uppercase text-[10px]">Database Data Type</span>
                        <p className="font-semibold text-slate-800">{selectedMeal.usdaDataType}</p>
                      </div>

                      <div className="p-3 bg-slate-50 rounded border border-slate-200 space-y-1">
                        <span className="text-slate-500 font-bold uppercase text-[10px]">API Latency & Status</span>
                        <p className="font-bold text-emerald-700">{selectedMeal.usdaApiCallLatencyMs} ms — HTTP 200 OK</p>
                      </div>
                    </div>

                    <div className="pt-3 space-y-2">
                      <h4 className="text-xs font-bold text-slate-700 uppercase">Assayed USDA Micronutrients</h4>
                      <table className="w-full text-left text-xs border-collapse">
                        <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px]">
                          <tr>
                            <th className="py-2 px-3">Nutrient</th>
                            <th className="py-2 px-3">Assayed Value</th>
                            <th className="py-2 px-3">Thyroid Co-Factor Status</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 font-medium">
                          <tr>
                            <td className="py-2.5 px-3 font-bold text-slate-900">Iodine (I)</td>
                            <td className="py-2.5 px-3 text-teal-700 font-bold font-mono">{selectedMeal.iodineMicrograms} µg</td>
                            <td className="py-2.5 px-3 text-slate-600">Essential substrate for T4/T3 synthesis</td>
                          </tr>
                          <tr>
                            <td className="py-2.5 px-3 font-bold text-slate-900">Selenium (Se)</td>
                            <td className="py-2.5 px-3 text-amber-700 font-bold font-mono">{selectedMeal.seleniumMicrograms} µg</td>
                            <td className="py-2.5 px-3 text-slate-600">Deiodinase enzyme cofactor (T4 to T3 conversion)</td>
                          </tr>
                          <tr>
                            <td className="py-2.5 px-3 font-bold text-slate-900">Calcium (Ca)</td>
                            <td className="py-2.5 px-3 text-purple-700 font-bold font-mono">{selectedMeal.calciumMilligrams} mg</td>
                            <td className="py-2.5 px-3 text-slate-600">Binds levothyroxine in GI tract if taken within 4 hrs</td>
                          </tr>
                          <tr>
                            <td className="py-2.5 px-3 font-bold text-slate-900">Sodium (Na)</td>
                            <td className="py-2.5 px-3 text-rose-700 font-bold font-mono">{selectedMeal.sodiumMilligrams} mg</td>
                            <td className="py-2.5 px-3 text-slate-600">General metabolic fluid balance indicator</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}

                {/* TAB 2: HORMONAL DISTRIBUTION */}
                {activeTab === "hormones" && (
                  <div className="space-y-6">
                    <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                      <div>
                        <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Estimated TSH, Free T3, & Free T4 Distribution Shift</h3>
                        <p className="text-[11px] text-slate-500">Predicted longitudinal hormonal shifts derived from the analyzed food composition.</p>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      
                      {/* TSH Gauge */}
                      <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg text-center space-y-2">
                        <span className="text-xs font-extrabold text-slate-700 uppercase tracking-wider">TSH Level Impact</span>
                        <div className="text-2xl font-black font-mono text-teal-700">
                          {selectedMeal.tshPercentChange >= 0 ? `+${selectedMeal.tshPercentChange}%` : `${selectedMeal.tshPercentChange}%`}
                        </div>
                        <span className="text-[11px] font-bold text-teal-800 bg-teal-100 px-2 py-0.5 rounded border border-teal-200 block">
                          {selectedMeal.tshImpact}
                        </span>
                      </div>

                      {/* Free T3 Gauge */}
                      <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg text-center space-y-2">
                        <span className="text-xs font-extrabold text-slate-700 uppercase tracking-wider">Free T3 Shift</span>
                        <div className="text-2xl font-black font-mono text-amber-700">
                          {selectedMeal.t3PercentChange >= 0 ? `+${selectedMeal.t3PercentChange}%` : `${selectedMeal.t3PercentChange}%`}
                        </div>
                        <span className="text-[11px] font-bold text-amber-800 bg-amber-100 px-2 py-0.5 rounded border border-amber-200 block">
                          {selectedMeal.t3Impact}
                        </span>
                      </div>

                      {/* Free T4 Gauge */}
                      <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg text-center space-y-2">
                        <span className="text-xs font-extrabold text-slate-700 uppercase tracking-wider">Free T4 Shift</span>
                        <div className="text-2xl font-black font-mono text-purple-700">
                          {selectedMeal.t4PercentChange >= 0 ? `+${selectedMeal.t4PercentChange}%` : `${selectedMeal.t4PercentChange}%`}
                        </div>
                        <span className="text-[11px] font-bold text-purple-800 bg-purple-100 px-2 py-0.5 rounded border border-purple-200 block">
                          {selectedMeal.t4Impact}
                        </span>
                      </div>

                    </div>

                    <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg space-y-2 text-xs text-blue-900">
                      <div className="flex items-center space-x-2 font-bold">
                        <Info className="w-4 h-4 text-blue-600 shrink-0" />
                        <span>Hormone Shift Distribution Mechanics</span>
                      </div>
                      <p>
                        High protein and selenium (e.g. wild salmon or chicken) support deiodinase enzyme activity, facilitating peripheral conversion of Free T4 into active Free T3 (+3% to +5% support). High calcium (&gt;300mg) or raw goitrogens (uncooked cruciferous veggies) may modestly elevate TSH (+2%).
                      </p>
                    </div>
                  </div>
                )}

                {/* TAB 3: RAW JSON */}
                {activeTab === "json" && (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Raw USDA FDC JSON Response Payload</h3>
                      <button
                        onClick={handleCopyJson}
                        className="bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold px-3 py-1.5 rounded flex items-center space-x-1.5 transition-colors"
                      >
                        {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                        <span>{copied ? "Copied JSON!" : "Copy JSON Payload"}</span>
                      </button>
                    </div>

                    <pre className="p-4 bg-slate-950 text-slate-100 text-xs font-mono rounded-lg overflow-x-auto border border-slate-800 max-h-96">
                      {selectedMeal.rawUsdaJsonResponse}
                    </pre>
                  </div>
                )}

              </div>
            </div>
          </div>

        </div>

      </main>
    </div>
  );
}
