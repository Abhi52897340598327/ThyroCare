"use client";

import { useState } from "react";
import Link from "next/link";
import FamilyAppShell from "@/components/FamilyAppShell";
import { MOCK_PATIENTS } from "@/lib/demoData";
import { 
  Users, 
  ChevronRight, 
  Activity, 
  Calendar, 
  ShieldCheck, 
  TrendingUp, 
  AlertCircle,
  FileText,
  Clock
} from "lucide-react";

export default function FamilyDashboard() {
  const familyMembers = MOCK_PATIENTS;

  return (
    <FamilyAppShell>
      <div className="space-y-6">
        
        {/* Header Summary */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-teal-100 text-teal-800 text-[11px] font-extrabold uppercase px-2.5 py-0.5 rounded border border-teal-200">
                Caregiver Access Level 1
              </span>
              <span className="text-xs text-slate-500 font-mono">HIPAA Compliant Sharing</span>
            </div>
            <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase tracking-tight flex items-center space-x-2">
              <Users className="w-5 h-5 text-teal-700" />
              <span>LINKED FAMILY HEALTH PORTAL</span>
            </h1>
            <p className="text-xs text-slate-600 mt-0.5">
              Authorized real-time summary of linked family members, latest thyroid assays, trends, and upcoming clinical consults.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <Link
              href="/family/reports"
              className="bg-slate-900 hover:bg-slate-800 text-white font-semibold text-xs px-4 py-2.5 rounded-lg flex items-center space-x-2 shadow-xs transition-colors"
            >
              <FileText className="w-4 h-4 text-teal-400" />
              <span>View Family Reports</span>
            </Link>
          </div>
        </div>

        {/* Linked Family Members Cards Grid */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2">
              <ShieldCheck className="w-4 h-4 text-emerald-600" />
              <span>Authorized Linked Family Members ({familyMembers.length})</span>
            </h2>
            <span className="text-xs text-slate-500">Updated today at 08:30 AM</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {familyMembers.map((member) => (
              <div
                key={member.id}
                className="bg-white rounded-lg border border-slate-200 shadow-xs hover:shadow-md transition-shadow p-5 flex flex-col justify-between space-y-4"
              >
                <div>
                  <div className="flex items-start justify-between">
                    <div>
                      <span className="text-[10px] font-bold uppercase text-teal-700 bg-teal-50 px-2 py-0.5 rounded border border-teal-200">
                        {member.relationship || "Family Member"}
                      </span>
                      <h3 className="text-base font-extrabold text-slate-900 mt-1">{member.name}</h3>
                      <p className="text-xs text-slate-500 font-mono">
                        Age {member.age} • {member.sex} • {member.condition}
                      </p>
                    </div>

                    <div className="w-10 h-10 rounded-full bg-slate-900 text-teal-400 font-extrabold text-xs flex items-center justify-center border border-slate-800 shrink-0">
                      {member.name.split(" ").map(n => n[0]).join("")}
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3 mt-4 pt-4 border-t border-slate-200">
                    <div className="p-3 bg-slate-50 rounded border border-slate-200">
                      <span className="text-[10px] font-bold text-slate-500 uppercase block">Latest TSH</span>
                      <div className="flex items-baseline space-x-1 mt-0.5">
                        <span className="text-lg font-black text-slate-900">{member.latestTSH}</span>
                        <span className="text-[10px] text-slate-500 font-mono">mIU/L</span>
                      </div>
                      <span className="text-[10px] font-semibold text-teal-700 block mt-0.5">
                        {member.trend}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-50 rounded border border-slate-200">
                      <span className="text-[10px] font-bold text-slate-500 uppercase block">Last Test</span>
                      <span className="text-xs font-bold text-slate-800 mt-1 block">{member.lastLabDate}</span>
                      <span className="text-[10px] text-slate-400 block mt-0.5">Quest Diagnostics</span>
                    </div>
                  </div>

                  <div className="mt-3 p-3 bg-teal-50/60 rounded border border-teal-200/80 text-xs space-y-1">
                    <div className="flex justify-between items-center text-teal-900 font-bold">
                      <span className="flex items-center space-x-1">
                        <Clock className="w-3.5 h-3.5 text-teal-700" />
                        <span>Next Appointment</span>
                      </span>
                      <span>{member.nextVisit}</span>
                    </div>
                    <p className="text-[11px] text-slate-600 truncate">Endocrinology Specialist Follow-up</p>
                  </div>
                </div>

                <Link
                  href={`/family/members/${member.id}`}
                  className="w-full bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold py-2.5 rounded-lg flex items-center justify-center space-x-1.5 transition-colors"
                >
                  <span>View Member Health Profile</span>
                  <ChevronRight className="w-4 h-4 text-teal-400" />
                </Link>
              </div>
            ))}
          </div>
        </div>

      </div>
    </FamilyAppShell>
  );
}
