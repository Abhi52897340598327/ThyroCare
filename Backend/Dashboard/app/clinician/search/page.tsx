"use client";

import { useState } from "react";
import ClinicalTopNav from "@/components/ClinicalTopNav";
import { MOCK_PATIENTS } from "@/lib/demoData";
import Link from "next/link";
import { Search, ArrowRight, UserCheck } from "lucide-react";

export default function PatientSearchPage() {
  const [query, setQuery] = useState("");

  const results = MOCK_PATIENTS.filter(p => 
    p.name.toLowerCase().includes(query.toLowerCase()) ||
    p.id.toLowerCase().includes(query.toLowerCase()) ||
    p.condition.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4">
          <h1 className="text-lg font-bold text-slate-900 uppercase">GLOBAL PATIENT SEARCH</h1>

          <div className="relative">
            <Search className="w-5 h-5 text-slate-400 absolute left-4 top-3.5" />
            <input
              type="text"
              autoFocus
              placeholder="Search by patient name, identifier (e.g. p1), or condition..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-3 bg-slate-50 border border-slate-300 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </div>

          <div className="space-y-3 pt-2">
            <span className="text-xs font-bold text-slate-500 uppercase block">Search Results ({results.length})</span>

            {results.map((patient) => (
              <div key={patient.id} className="p-4 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between hover:bg-slate-100 transition-colors">
                <div>
                  <h3 className="font-bold text-slate-900 text-sm uppercase">{patient.name}</h3>
                  <p className="text-xs text-slate-500">{patient.age} yrs | {patient.sex} | {patient.condition}</p>
                  <p className="text-xs text-teal-800 font-bold mt-1">Latest TSH: {patient.latestTSH} mIU/L | Last Lab: {patient.lastLabDate}</p>
                </div>

                <Link
                  href={`/clinician/patients/${patient.id}`}
                  className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-bold px-4 py-2 rounded flex items-center space-x-1.5 transition-colors"
                >
                  <span>Open Patient Record</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
