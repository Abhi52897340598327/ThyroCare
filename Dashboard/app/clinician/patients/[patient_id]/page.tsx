"use client";

import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import Link from "next/link";
import { 
  Activity, 
  TrendingUp, 
  AlertTriangle, 
  Clock, 
  Calendar, 
  ChevronRight
} from "lucide-react";

export default function PatientHomePage({
  params,
}: {
  params: { patient_id: string };
}) {
  const patient = getPatientById(params.patient_id);

  return (
    <PatientWorkspaceLayout patientId={params.patient_id}>
      <div className="space-y-6">
        
        {/* Page Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Patient Overview Home</h1>
            <p className="text-xs text-slate-500">Central thyroid summary and clinical review status for {patient.name}.</p>
          </div>
          <div className="text-xs text-slate-400 font-mono">
            URL Context: /clinician/patients/{patient.id}
          </div>
        </div>

        {/* Section 1: Latest Thyroid Status */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs">
          <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center space-x-2">
            <Activity className="w-4 h-4 text-teal-600" />
            <span>Latest Thyroid Status ({patient.lastLabDate})</span>
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-center">
            <div className="p-4 bg-teal-50/70 border border-teal-200 rounded-lg">
              <span className="text-[11px] font-semibold text-teal-800 uppercase block">TSH</span>
              <span className="text-3xl font-black text-teal-900">{patient.latestTSH}</span>
              <span className="text-xs text-teal-700 block font-medium mt-0.5">mIU/L</span>
              <span className="text-[10px] text-amber-700 font-semibold block mt-1">↑ from 3.7 mIU/L</span>
            </div>

            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg">
              <span className="text-[11px] font-semibold text-slate-600 uppercase block">Free T4</span>
              <span className="text-3xl font-black text-slate-800">{patient.latestFT4}</span>
              <span className="text-xs text-slate-500 block font-medium mt-0.5">ng/dL</span>
              <span className="text-[10px] text-slate-500 font-normal block mt-1">Normal Range (0.8 - 1.8)</span>
            </div>

            <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg">
              <span className="text-[11px] font-semibold text-slate-600 uppercase block">Free T3</span>
              <span className="text-3xl font-black text-slate-800">{patient.latestFT3}</span>
              <span className="text-xs text-slate-500 block font-medium mt-0.5">pg/mL</span>
              <span className="text-[10px] text-slate-500 font-normal block mt-1">Normal Range (2.3 - 4.2)</span>
            </div>

            <div className="p-4 bg-slate-900 text-white rounded-lg flex flex-col justify-center items-center">
              <span className="text-[11px] font-semibold text-teal-400 uppercase block">Longitudinal Trend</span>
              <span className="text-xl font-bold mt-1 text-white flex items-center space-x-1">
                <span>{patient.trend}</span>
                <TrendingUp className="w-5 h-5 text-amber-400" />
              </span>
              <span className="text-[10px] text-slate-400 mt-1">Based on {patient.labs.length} historical lab points</span>
            </div>
          </div>
        </div>

        {/* Section 2: Longitudinal TSH Mini-Chart & Review Events */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Recent Trend Chart */}
          <div className="lg:col-span-2 bg-white rounded-lg border border-slate-200 p-5 shadow-xs">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
                <TrendingUp className="w-4 h-4 text-teal-600" />
                <span>Recent TSH Longitudinal Trajectory</span>
              </h2>
              <Link href={`/clinician/patients/${patient.id}/trends`} className="text-xs text-teal-700 hover:underline font-semibold flex items-center space-x-1">
                <span>Full Trend Assessment</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            {/* Simple SVG Longitudinal Graph */}
            <div className="h-44 w-full bg-slate-50 rounded border border-slate-200 p-4 flex flex-col justify-between">
              <div className="flex justify-between text-[10px] text-slate-400 border-b border-slate-200 pb-1">
                <span>7.0 mIU/L (High)</span>
                <span>Upper Reference Boundary: 4.5 mIU/L</span>
              </div>

              <div className="relative flex-1 flex items-end justify-between px-4 py-2">
                {patient.labs.slice().reverse().map((lab) => (
                  <div key={lab.id} className="flex flex-col items-center group relative">
                    <div 
                      className="w-3 h-3 rounded-full bg-teal-600 border-2 border-white shadow-xs group-hover:scale-125 transition-transform"
                      style={{ marginBottom: `${(lab.tsh / 7) * 100}px` }}
                    />
                    <span className="text-[10px] font-bold text-slate-700">{lab.tsh}</span>
                    <span className="text-[9px] text-slate-400">{lab.date.split(",")[0]}</span>

                    {/* Tooltip */}
                    <div className="absolute bottom-12 hidden group-hover:block bg-slate-900 text-white text-[10px] p-2 rounded shadow-md z-10 w-28 pointer-events-none">
                      <p className="font-bold">{lab.date}</p>
                      <p>TSH: {lab.tsh} mIU/L</p>
                      <p>FT4: {lab.ft4} ng/dL</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex justify-between text-[10px] text-slate-400 border-t border-slate-200 pt-1">
                <span>Earliest Lab</span>
                <span>Latest Lab</span>
              </div>
            </div>
          </div>

          {/* Clinical Review Events */}
          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
            <div>
              <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center space-x-2">
                <AlertTriangle className="w-4 h-4 text-amber-600" />
                <span>Clinical Review Events</span>
              </h2>

              <ul className="space-y-3 text-xs">
                {patient.alerts.length > 0 ? (
                  patient.alerts.map((alert) => (
                    <li key={alert.id} className="p-2.5 bg-amber-50/60 border border-amber-200 rounded text-amber-900 space-y-1">
                      <div className="font-bold flex items-center justify-between">
                        <span>{alert.title}</span>
                        <span className="text-[9px] bg-amber-200 text-amber-900 px-1.5 py-0.5 rounded">{alert.date}</span>
                      </div>
                      <p className="text-[11px] text-amber-800 leading-tight">{alert.detail}</p>
                    </li>
                  ))
                ) : (
                  <li className="p-3 bg-slate-50 border border-slate-200 rounded text-slate-500 text-xs text-center">
                    No active review events flagged for this patient.
                  </li>
                )}
              </ul>
            </div>

            <Link
              href={`/clinician/patients/${patient.id}/alerts`}
              className="mt-4 w-full bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold py-2 rounded text-center block transition-colors"
            >
              Open Complete Review Panel
            </Link>
          </div>

        </div>

        {/* Section 3: Recent Activity & Next Appointment */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Recent Activity */}
          <div className="lg:col-span-2 bg-white rounded-lg border border-slate-200 p-5 shadow-xs">
            <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center space-x-2">
              <Clock className="w-4 h-4 text-teal-600" />
              <span>Recent Longitudinal Activity Feed</span>
            </h2>

            <div className="space-y-3">
              {patient.timeline.length > 0 ? (
                patient.timeline.map((item) => (
                  <div key={item.id} className="flex items-start space-x-3 p-3 rounded bg-slate-50 border border-slate-200 text-xs">
                    <span className="text-[10px] font-bold bg-slate-200 text-slate-700 px-2 py-0.5 rounded shrink-0">{item.date}</span>
                    <div>
                      <h3 className="font-bold text-slate-900">{item.title}</h3>
                      <p className="text-slate-600 mt-0.5">{item.detail}</p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="p-3 bg-slate-50 border border-slate-200 rounded text-slate-500 text-xs text-center">
                  No activity recorded recently.
                </div>
              )}
            </div>
          </div>

          {/* Next Appointment Card */}
          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
            <div>
              <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center space-x-2">
                <Calendar className="w-4 h-4 text-teal-600" />
                <span>Next Scheduled Appointment</span>
              </h2>

              <div className="bg-teal-50 border border-teal-200 rounded-lg p-4 text-center">
                <span className="text-xs text-teal-700 font-semibold block uppercase">Endocrinology Follow-Up</span>
                <span className="text-lg font-black text-teal-900 block mt-1">{patient.nextVisit}</span>
                <span className="text-xs text-slate-600 font-medium block">10:30 AM — Dr. Jane Smith</span>
              </div>
            </div>

            <div className="space-y-2 mt-4">
              <Link
                href={`/clinician/patients/${patient.id}/appointments`}
                className="w-full bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold py-2 rounded text-center block transition-colors"
              >
                View Appointment Details
              </Link>
              <button 
                onClick={() => alert(`Earlier follow-up recommendation sent for ${patient.name}`)}
                className="w-full bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold py-2 rounded text-center block border border-slate-300 transition-colors"
              >
                Recommend Earlier Follow-Up
              </button>
            </div>
          </div>

        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
