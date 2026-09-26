"use client";

import { useState } from "react";
import FamilyAppShell from "@/components/FamilyAppShell";
import EndocrinologistSearch from "@/components/EndocrinologistSearch";
import { MOCK_PATIENTS } from "@/lib/demoData";
import { 
  Calendar, 
  Clock, 
  MapPin, 
  ExternalLink, 
  CheckCircle2, 
  AlertCircle,
  Search,
  UserCheck
} from "lucide-react";

export default function FamilyAppointmentsPage() {
  const [showSearchModal, setShowSearchModal] = useState(false);

  return (
    <FamilyAppShell>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-teal-100 text-teal-800 text-[11px] font-extrabold uppercase px-2.5 py-0.5 rounded border border-teal-200">
                Schedule & Provider Directory
              </span>
              <span className="text-xs text-slate-500 font-mono">Google Maps Places Integration</span>
            </div>
            <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase tracking-tight flex items-center space-x-2">
              <Calendar className="w-5 h-5 text-teal-700" />
              <span>FAMILY APPOINTMENTS & ENDOCRINOLOGIST FINDER</span>
            </h1>
            <p className="text-xs text-slate-600 mt-0.5">
              Review upcoming consults, manage past clinic visits, or locate top-rated endocrinologists in your area.
            </p>
          </div>

          <button
            onClick={() => setShowSearchModal(!showSearchModal)}
            className="bg-teal-700 hover:bg-teal-800 text-white font-semibold text-xs px-4 py-2.5 rounded-lg flex items-center space-x-2 shadow-xs transition-colors"
          >
            <Search className="w-4 h-4" />
            <span>{showSearchModal ? "Hide Provider Search" : "FIND AN ENDOCRINOLOGIST"}</span>
          </button>
        </div>

        {/* Embedded Provider Search Component */}
        {showSearchModal && (
          <div className="space-y-4">
            <div className="bg-teal-900 text-white p-3 rounded-t-lg flex items-center justify-between text-xs">
              <span className="font-bold uppercase tracking-wider flex items-center space-x-2">
                <MapPin className="w-4 h-4 text-teal-400" />
                <span>Live Google Maps Endocrinologist & Specialist Locator</span>
              </span>
              <button onClick={() => setShowSearchModal(false)} className="text-slate-300 hover:text-white font-bold">✕ Close</button>
            </div>
            <EndocrinologistSearch />
          </div>
        )}

        {/* Upcoming Appointments Cards */}
        <div className="space-y-4">
          <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2">
            <Clock className="w-4 h-4 text-teal-700" />
            <span>UPCOMING SCHEDULED APPOINTMENTS</span>
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {MOCK_PATIENTS.map((member) => (
              <div key={member.id} className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-3">
                <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                  <div>
                    <span className="text-[10px] font-bold uppercase text-teal-700">{member.relationship || "Patient"}</span>
                    <h3 className="text-sm font-bold text-slate-900">{member.name}</h3>
                  </div>
                  <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded border border-emerald-300">
                    CONFIRMED
                  </span>
                </div>

                <div className="space-y-2 text-xs">
                  <div className="flex items-center space-x-2 text-slate-800 font-bold">
                    <Calendar className="w-4 h-4 text-teal-700" />
                    <span>{member.nextVisit} at 10:30 AM</span>
                  </div>

                  <div className="flex items-center space-x-2 text-slate-600">
                    <UserCheck className="w-4 h-4 text-slate-400" />
                    <span>Dr. Jane Smith, MD — Endocrinology Specialist</span>
                  </div>

                  <div className="flex items-center space-x-2 text-slate-500">
                    <MapPin className="w-4 h-4 text-slate-400" />
                    <span>Mass General Yawkey Center 8B, Boston MA</span>
                  </div>
                </div>

                <div className="pt-2 flex items-center space-x-2">
                  <a
                    href="https://maps.google.com/?q=Mass+General+Yawkey+Center+Boston+MA"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-slate-900 hover:bg-slate-800 text-white text-[11px] font-semibold px-3 py-1.5 rounded flex items-center space-x-1 transition-colors"
                  >
                    <MapPin className="w-3 h-3 text-teal-400" />
                    <span>Get Directions</span>
                  </a>

                  <a
                    href="https://www.massgeneral.org/endocrinology"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-teal-700 hover:bg-teal-800 text-white text-[11px] font-semibold px-3 py-1.5 rounded flex items-center space-x-1 transition-colors"
                  >
                    <ExternalLink className="w-3 h-3" />
                    <span>Open Patient Portal</span>
                  </a>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Main Provider Search Banner if not open */}
        {!showSearchModal && (
          <div className="bg-gradient-to-r from-slate-900 to-slate-800 text-white rounded-lg p-6 border border-slate-700 shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <span className="text-[10px] font-mono text-teal-400 font-bold uppercase tracking-widest block">
                Thyroid Provider Network
              </span>
              <h3 className="text-base font-bold text-white mt-1">Need a Second Opinion or Local Endocrinologist?</h3>
              <p className="text-xs text-slate-300 mt-0.5">
                Search verified thyroid specialists and endocrinology clinics near you using Google Maps & Places API.
              </p>
            </div>

            <button
              onClick={() => setShowSearchModal(true)}
              className="bg-teal-600 hover:bg-teal-500 text-white font-semibold text-xs px-5 py-3 rounded-lg flex items-center space-x-2 shrink-0 shadow-md transition-colors"
            >
              <Search className="w-4 h-4" />
              <span>FIND AN ENDOCRINOLOGIST</span>
            </button>
          </div>
        )}

      </div>
    </FamilyAppShell>
  );
}
