"use client";

import { useState } from "react";
import Link from "next/link";
import { MOCK_PATIENTS, PatientProfile } from "@/lib/demoData";
import { 
  Users, 
  Home, 
  FileText, 
  Calendar, 
  Settings, 
  TrendingUp, 
  FlaskConical, 
  Pill, 
  Utensils, 
  Stethoscope, 
  ShieldCheck,
  ChevronRight,
  Heart
} from "lucide-react";

export default function FamilyPortal() {
  const [selectedPatient, setSelectedPatient] = useState<PatientProfile>(MOCK_PATIENTS[0]);
  const [activeTab, setActiveTab] = useState<"home" | "trends" | "labs" | "meds" | "diet" | "symptoms" | "reports" | "appointments">("home");

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      
      {/* Family Top Nav */}
      <header className="bg-slate-900 border-b border-slate-800 text-white sticky top-0 z-50">
        <div className="max-w-[1920px] mx-auto px-6 h-14 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Heart className="w-5 h-5 text-rose-400" />
            <span className="font-bold text-base tracking-wide text-white">
              THYROCARE <span className="text-xs px-2 py-0.5 rounded bg-rose-950 text-rose-300 border border-rose-800 font-semibold uppercase">Family Portal</span>
            </span>
          </div>

          <nav className="flex items-center space-x-2 text-xs font-semibold">
            <button className="px-3 py-1.5 rounded bg-teal-600 text-white">HOME</button>
            <button className="px-3 py-1.5 rounded text-slate-300 hover:bg-slate-800">FAMILY</button>
            <button className="px-3 py-1.5 rounded text-slate-300 hover:bg-slate-800">REPORTS</button>
            <button className="px-3 py-1.5 rounded text-slate-300 hover:bg-slate-800">APPOINTMENTS</button>
            <button className="px-3 py-1.5 rounded text-slate-300 hover:bg-slate-800">SETTINGS</button>
          </nav>

          <div className="text-xs text-slate-400">
            Caregiver: <strong className="text-white">Suresh Venigalla</strong>
          </div>
        </div>
      </header>

      {/* Main Family Workspace */}
      <div className="flex flex-1 max-w-[1920px] w-full mx-auto">
        
        {/* Left Family Navigation */}
        <aside className="w-64 bg-slate-900 border-r border-slate-800 p-4 space-y-4 text-slate-300 shrink-0">
          <div>
            <span className="text-[10px] uppercase font-bold text-slate-500 block">FAMILY MEMBER</span>
            <select
              value={selectedPatient.id}
              onChange={(e) => setSelectedPatient(MOCK_PATIENTS.find(p => p.id === e.target.value) || MOCK_PATIENTS[0])}
              className="w-full bg-slate-800 border border-slate-700 text-white rounded p-2 text-xs font-bold mt-1 focus:outline-none focus:ring-2 focus:ring-teal-500"
            >
              {MOCK_PATIENTS.map(p => (
                <option key={p.id} value={p.id}>{p.name} ({p.relationship || "Family Member"})</option>
              ))}
            </select>
          </div>

          <nav className="space-y-1 text-xs font-semibold pt-2">
            {[
              { id: "home", label: "Home Overview", icon: Home },
              { id: "trends", label: "Thyroid Trends", icon: TrendingUp },
              { id: "labs", label: "Lab Results", icon: FlaskConical },
              { id: "meds", label: "Medications", icon: Pill },
              { id: "diet", label: "Diet & Nutrition", icon: Utensils },
              { id: "symptoms", label: "Symptoms Log", icon: Stethoscope },
              { id: "reports", label: "Family Reports", icon: FileText },
              { id: "appointments", label: "Appointments", icon: Calendar },
            ].map(item => {
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id as any)}
                  className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded text-left transition-colors ${
                    activeTab === item.id ? "bg-teal-600 text-white font-bold" : "hover:bg-slate-800 text-slate-300"
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>

          <div className="p-3 bg-slate-950/60 rounded border border-slate-800 text-[11px] text-slate-400 space-y-1">
            <span className="font-bold text-slate-300 block flex items-center space-x-1">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
              <span>Permission Protected</span>
            </span>
            <span>Displaying authorized records under family consent.</span>
          </div>
        </aside>

        {/* Right Family Workspace Content */}
        <main className="flex-1 p-6 space-y-6 overflow-y-auto">
          
          {/* Family Member Header */}
          <div className="bg-white p-5 rounded-lg border border-slate-200 shadow-xs flex flex-wrap items-center justify-between gap-4">
            <div>
              <h1 className="text-lg font-bold text-slate-900 uppercase">{selectedPatient.name}</h1>
              <p className="text-xs text-slate-500">{selectedPatient.age} yrs | {selectedPatient.sex} | {selectedPatient.condition}</p>
            </div>

            <div className="flex items-center space-x-6 text-xs border-l border-slate-200 pl-6">
              <div>
                <span className="text-slate-500 block uppercase font-semibold text-[10px]">Latest TSH</span>
                <span className="text-lg font-black text-teal-900">{selectedPatient.latestTSH} mIU/L</span>
              </div>
              <div>
                <span className="text-slate-500 block uppercase font-semibold text-[10px]">Last Lab</span>
                <span className="text-xs font-bold text-slate-800">{selectedPatient.lastLabDate}</span>
              </div>
              <div>
                <span className="text-slate-500 block uppercase font-semibold text-[10px]">Next Visit</span>
                <span className="text-xs font-bold text-teal-700">{selectedPatient.nextVisit}</span>
              </div>
            </div>
          </div>

          {/* Module Content */}
          {activeTab === "home" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Family Member Health Summary</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                <div className="p-4 bg-teal-50 rounded border border-teal-200">
                  <span className="text-teal-800 font-bold block uppercase text-[10px]">Thyroid Status</span>
                  <span className="text-2xl font-black text-teal-900">{selectedPatient.latestTSH} mIU/L</span>
                  <span className="text-xs text-teal-700 block mt-1">Trend: {selectedPatient.trend}</span>
                </div>

                <div className="p-4 bg-slate-50 rounded border border-slate-200">
                  <span className="text-slate-600 font-bold block uppercase text-[10px]">Current Medication</span>
                  <span className="text-base font-extrabold text-slate-900 mt-1 block">{selectedPatient.medications[0]?.name || "None"}</span>
                  <span className="text-xs text-slate-500 block">{selectedPatient.medications[0]?.dose || ""} daily</span>
                </div>

                <div className="p-4 bg-slate-50 rounded border border-slate-200">
                  <span className="text-slate-600 font-bold block uppercase text-[10px]">Next Scheduled Appointment</span>
                  <span className="text-base font-extrabold text-slate-900 mt-1 block">{selectedPatient.nextVisit}</span>
                  <span className="text-xs text-slate-500 block">Endocrinology Clinic</span>
                </div>
              </div>
            </div>
          )}

          {activeTab === "trends" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">TSH Trend Graph</h2>
              <div className="h-44 bg-slate-50 rounded border border-slate-200 p-4 flex items-end justify-between">
                {selectedPatient.labs.slice().reverse().map(lab => (
                  <div key={lab.id} className="flex flex-col items-center">
                    <div className="w-3 h-3 rounded-full bg-teal-700" style={{ marginBottom: `${(lab.tsh / 7) * 90}px` }} />
                    <span className="text-[10px] font-bold">{lab.tsh}</span>
                    <span className="text-[9px] text-slate-400">{lab.date.split(",")[0]}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === "labs" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Authorized Lab History</h2>
              <table className="w-full text-left text-xs border-collapse">
                <thead className="bg-slate-100 uppercase text-[10px] font-semibold text-slate-600">
                  <tr>
                    <th className="py-2.5 px-4">Date</th>
                    <th className="py-2.5 px-4 text-right">TSH</th>
                    <th className="py-2.5 px-4 text-right">Free T4</th>
                    <th className="py-2.5 px-4 text-right">Free T3</th>
                    <th className="py-2.5 px-4">Laboratory</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 font-medium">
                  {selectedPatient.labs.map(lab => (
                    <tr key={lab.id}>
                      <td className="py-3 px-4 font-bold">{lab.date}</td>
                      <td className="py-3 px-4 text-right font-black">{lab.tsh}</td>
                      <td className="py-3 px-4 text-right">{lab.ft4}</td>
                      <td className="py-3 px-4 text-right">{lab.ft3}</td>
                      <td className="py-3 px-4 text-slate-600">{lab.labName}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {activeTab === "meds" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Active Medications</h2>
              <ul className="space-y-2 text-xs">
                {selectedPatient.medications.map(med => (
                  <li key={med.id} className="p-3 bg-slate-50 rounded border border-slate-200 flex justify-between">
                    <div>
                      <span className="font-bold text-slate-900 block">{med.name} — {med.dose}</span>
                      <span className="text-slate-500">{med.frequency} at {med.timing}</span>
                    </div>
                    <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px] self-center">ACTIVE</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {activeTab === "diet" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Nutrition & Intake Summary</h2>
              <div className="space-y-2 text-xs">
                {selectedPatient.nutritionSummary.patterns.map((pat, i) => (
                  <p key={i} className="p-3 bg-slate-50 rounded border border-slate-200">{pat}</p>
                ))}
              </div>
            </div>
          )}

          {activeTab === "symptoms" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Tracked Symptoms</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3 text-xs">
                {selectedPatient.symptoms.filter(s => s.present).map((sym, i) => (
                  <div key={i} className="p-3 bg-amber-50 rounded border border-amber-200 font-bold text-amber-900">
                    <span>{sym.name}</span>
                    <span className="block text-[10px] font-normal text-amber-800">Severity: {sym.severity} ({sym.frequency})</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === "reports" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Family Reports</h2>
              <div className="space-y-2 text-xs">
                {selectedPatient.reports.map(rep => (
                  <div key={rep.id} className="p-3 bg-slate-50 rounded border border-slate-200 flex justify-between items-center">
                    <span className="font-bold text-slate-900">{rep.title}</span>
                    <button onClick={() => alert(`Downloading ${rep.title}`)} className="text-teal-700 font-bold hover:underline">Download PDF</button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === "appointments" && (
            <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Appointments</h2>
              <div className="p-4 bg-teal-50 rounded border border-teal-200 text-xs">
                <span className="font-bold text-teal-900 block text-sm">Next Visit: {selectedPatient.nextVisit}</span>
                <span className="text-teal-700 block mt-1">Endocrinology Specialist Consult</span>
              </div>
            </div>
          )}

        </main>
      </div>

    </div>
  );
}
