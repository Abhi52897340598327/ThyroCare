"use client";

import { use, useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, AppointmentRecord } from "@/lib/demoData";
import { Calendar, PlusCircle, CheckCircle2, Info } from "lucide-react";

export default function AppointmentsPage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);
  const [appointments, setAppointments] = useState<AppointmentRecord[]>(patient.appointments);
  const [reason, setReason] = useState("Recent thyroid laboratory trend warrants clinical discussion.");
  const [submitted, setSubmitted] = useState(false);

  const handleRecommendFollowUp = (e: React.FormEvent) => {
    e.preventDefault();
    const newApp: AppointmentRecord = {
      id: `ap_${Date.now()}`,
      date: "Oct 12, 2026",
      time: "10:30 AM",
      provider: "Dr. Jane Smith",
      type: "Clinician Recommended Follow-Up",
      status: "Recommended",
      recommendedReason: reason
    };
    setAppointments([newApp, ...appointments]);
    setSubmitted(true);
    setTimeout(() => setSubmitted(false), 4000);
  };

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Clinical Appointments & Follow-Up Recommendations</h1>
            <p className="text-xs text-slate-500">Upcoming, completed, and clinician-recommended thyroid follow-up visits for {patient.name}.</p>
          </div>
        </div>

        {/* Recommend Follow-Up Form */}
        <div className="bg-white rounded-lg border border-teal-200 p-5 shadow-xs space-y-3">
          <h2 className="text-xs font-bold text-teal-900 uppercase tracking-wider flex items-center space-x-2">
            <PlusCircle className="w-4 h-4 text-teal-700" />
            <span>RECOMMEND CLINICAL FOLLOW-UP VISIT</span>
          </h2>

          <form onSubmit={handleRecommendFollowUp} className="space-y-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Clinician Recommendation Reason</label>
              <textarea
                rows={2}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                className="w-full bg-slate-50 border border-slate-300 rounded p-2 text-xs focus:outline-none focus:ring-2 focus:ring-teal-500"
              />
            </div>

            <button
              type="submit"
              className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-bold px-4 py-2 rounded transition-colors"
            >
              Log Clinician Recommendation
            </button>

            {submitted && (
              <p className="text-xs text-emerald-700 font-semibold flex items-center space-x-1 mt-1">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>Follow-up recommendation logged successfully!</span>
              </p>
            )}
          </form>

          <div className="p-3 bg-blue-50 border border-blue-200 rounded text-blue-900 text-xs flex items-center space-x-2">
            <Info className="w-4 h-4 text-blue-600 shrink-0" />
            <p><strong>Clinical Governance:</strong> Appointment recommendations reflect clinician clinical judgment, not automatic AI diagnostic orders.</p>
          </div>
        </div>

        {/* Appointments Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 font-bold text-xs text-slate-700 uppercase">
            <span>Scheduled & Recommended Visits ({appointments.length})</span>
          </div>

          <table className="w-full text-left text-xs border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">Date & Time</th>
                <th className="py-2.5 px-4">Visit Type</th>
                <th className="py-2.5 px-4">Provider</th>
                <th className="py-2.5 px-4">Status</th>
                <th className="py-2.5 px-4">Recommendation Reason</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              {appointments.map((app) => (
                <tr key={app.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-bold text-slate-900">{app.date} at {app.time}</td>
                  <td className="py-3 px-4 text-slate-800 font-semibold">{app.type}</td>
                  <td className="py-3 px-4 text-slate-600">{app.provider}</td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                      app.status === "Upcoming" ? "bg-teal-100 text-teal-800" :
                      app.status === "Recommended" ? "bg-amber-100 text-amber-800" : "bg-slate-100 text-slate-700"
                    }`}>
                      {app.status}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-slate-600 italic">{app.recommendedReason || "Routine clinical protocol"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
