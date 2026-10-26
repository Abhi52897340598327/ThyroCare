"use client";

import { useEffect, useState, useCallback } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById } from "@/lib/demoData";
import { careAPI, CareRecord } from "@/lib/care-api";
import Link from "next/link";
import { 
  Activity, 
  TrendingUp, 
  AlertTriangle, 
  Clock, 
  Calendar, 
  ChevronRight,
  MessageSquare,
  Send,
  CheckCircle2,
  User,
  Stethoscope
} from "lucide-react";

export default function PatientHomeClient({
  patientId,
}: {
  patientId: string;
}) {
  const patient = getPatientById(patientId);

  const [messages, setMessages] = useState<CareRecord[]>([]);
  const [replyText, setReplyText] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [replySuccess, setReplySuccess] = useState(false);

  const fetchMessages = useCallback(async () => {
    try {
      const records = await careAPI<CareRecord[]>(`patients/${patientId}/messages`);
      if (Array.isArray(records)) {
        setMessages(records.sort((a, b) => (b.recordedAt || "").localeCompare(a.recordedAt || "")));
      }
    } catch {}
  }, [patientId]);

  useEffect(() => {
    void fetchMessages();
    const interval = setInterval(() => void fetchMessages(), 2500);
    return () => clearInterval(interval);
  }, [fetchMessages]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = replyText.trim();
    if (!trimmed) return;
    setIsSending(true);
    try {
      await careAPI(`patients/${patientId}/messages`, "POST", {
        id: crypto.randomUUID(),
        expectedVersion: 0,
        fields: {
          body: trimmed,
          subject: "Clinician Response",
          sender: "Dr. Jane Smith (Endocrinology)",
          authorRole: "clinician",
          recipient: patient.name,
          observedDate: new Date().toISOString(),
        },
      });
      setReplyText("");
      setReplySuccess(true);
      setTimeout(() => setReplySuccess(false), 3000);
      await fetchMessages();
    } catch (err) {
      console.error(err);
    } finally {
      setIsSending(false);
    }
  };

  return (
    <PatientWorkspaceLayout patientId={patientId}>
      <div className="space-y-6">
        
        {/* Page Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Patient Overview Home</h1>
            <p className="text-xs text-slate-500">Central thyroid summary and clinical review status for {patient.name}.</p>
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

            {/* SVG Longitudinal Graph */}
            <div className="h-44 w-full bg-slate-50 rounded border border-slate-200 p-4 flex flex-col justify-between">
              <div className="flex justify-between text-[10px] text-slate-400 border-b border-slate-200 pb-1">
                <span>7.0 mIU/L (High)</span>
                <span>Upper Reference Boundary: 4.5 mIU/L</span>
              </div>

              <div className="relative flex-1 flex items-end justify-between px-4 py-2">
                {patient.labs.slice().reverse().map((lab) => (
                  <div key={lab.id} className="flex flex-col items-center group relative">
                    <div 
                      className="w-3 bg-teal-600 rounded-t hover:bg-teal-700 transition-all cursor-pointer relative"
                      style={{ height: `${Math.min(100, (lab.tsh / 7.0) * 100)}%` }}
                    >
                      <div className="opacity-0 group-hover:opacity-100 absolute -top-8 left-1/2 transform -translate-x-1/2 bg-slate-900 text-white text-[9px] py-1 px-1.5 rounded whitespace-nowrap z-10 pointer-events-none transition-opacity">
                        {lab.tsh} mIU/L
                      </div>
                    </div>
                    <span className="text-[9px] text-slate-500 mt-2 font-medium">{lab.date.split(" ")[0]}</span>
                  </div>
                ))}
              </div>

              <div className="flex justify-between text-[10px] text-slate-400 border-t border-slate-200 pt-1">
                <span>Lower Reference: 0.4 mIU/L</span>
                <span>0.0 mIU/L</span>
              </div>
            </div>
          </div>

          {/* Active Review Events */}
          <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
            <div>
              <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-4 flex items-center space-x-2">
                <AlertTriangle className="w-4 h-4 text-amber-500" />
                <span>Active Review Triggers</span>
              </h2>

              <ul className="space-y-3">
                {patient.alerts.length > 0 ? (
                  patient.alerts.map((alert) => (
                    <li key={alert.id} className="p-3 bg-amber-50/70 border border-amber-200 rounded-lg">
                      <div className="flex justify-between items-start mb-1">
                        <span className="text-[10px] font-bold uppercase bg-amber-200 text-amber-900 px-1.5 py-0.5 rounded">
                          {alert.category}
                        </span>
                        <span className="text-[10px] text-slate-400 font-medium">{alert.date}</span>
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

        {/* Section 3: Live Patient Care Thread & Instant Mobile Reply */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4 border-b border-slate-100 pb-3">
            <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center space-x-2">
              <MessageSquare className="w-4 h-4 text-teal-600" />
              <span>Direct Patient Care Thread & Mobile Transmission</span>
            </h2>
            <span className="text-[11px] text-slate-500 flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-emerald-500"></span>
              Live connection to {patient.name}&apos;s mobile app
            </span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Conversation Log */}
            <div className="space-y-3 max-h-[340px] overflow-y-auto pr-1">
              {messages.length > 0 ? (
                messages.map((msg) => {
                  const isClinician = msg.fields.authorRole === "clinician" || msg.fields.sender?.includes("Dr.");
                  return (
                    <div
                      key={msg.id}
                      className={`p-3.5 rounded-lg border text-xs space-y-1.5 ${
                        isClinician
                          ? "bg-teal-50/80 border-teal-200 ml-4"
                          : "bg-slate-50 border-slate-200 mr-4"
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className={`font-semibold flex items-center gap-1.5 ${
                          isClinician ? "text-teal-900" : "text-slate-800"
                        }`}>
                          {isClinician ? <Stethoscope size={13} className="text-teal-700" /> : <User size={13} className="text-slate-600" />}
                          {msg.fields.sender || (isClinician ? "Dr. Jane Smith" : patient.name)}
                        </span>
                        <span className="text-[10px] text-slate-400">
                          {msg.recordedAt ? new Date(msg.recordedAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "Recent"}
                        </span>
                      </div>

                      <p className="text-slate-700 leading-relaxed">
                        {msg.fields.body}
                      </p>

                      <div className="flex items-center justify-between text-[10px] pt-1 border-t border-slate-200/50">
                        <span className="text-slate-400 font-medium">
                          {msg.fields.subject || (isClinician ? "Clinical Response" : "Patient Message")}
                        </span>
                        <span className={`font-medium ${isClinician ? "text-teal-700" : "text-slate-500"}`}>
                          {isClinician ? "Sent to Patient's Phone" : "Received from Mobile App"}
                        </span>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="p-8 text-center text-slate-400 text-xs border border-dashed border-slate-200 rounded-lg">
                  No messages exchanged yet with {patient.name}. Type below to send the first message to their phone.
                </div>
              )}
            </div>

            {/* Compose Response */}
            <div className="bg-slate-50/70 border border-slate-200 rounded-lg p-4 flex flex-col justify-between">
              <div>
                <h3 className="text-xs font-bold text-slate-800 uppercase tracking-wider mb-1">
                  Send Response to Patient&apos;s Phone
                </h3>
                <p className="text-xs text-slate-500 mb-3">
                  Transmits directly to {patient.name}&apos;s mobile app in real-time.
                </p>

                {replySuccess && (
                  <div className="mb-3 flex items-center gap-2 p-2.5 bg-emerald-100 border border-emerald-300 text-emerald-800 text-xs font-medium rounded-lg">
                    <CheckCircle2 size={15} className="shrink-0 text-emerald-600" />
                    <span>Response successfully delivered to {patient.name}&apos;s mobile app!</span>
                  </div>
                )}

                <form onSubmit={handleSend} className="space-y-3">
                  <textarea
                    rows={4}
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder={`Write clinical message to ${patient.name}... (e.g. adjust medication, symptom guidance, reassurance)`}
                    className="w-full text-xs p-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-teal-600 bg-white"
                  />

                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {[
                      "Please continue current dosage and retest in 4 weeks.",
                      "Take medication with water 30 minutes before breakfast.",
                      "I reviewed your symptom log. Let's schedule a call.",
                    ].map((template) => (
                      <button
                        key={template}
                        type="button"
                        onClick={() => setReplyText(template)}
                        className="text-[10px] bg-white hover:bg-slate-100 text-slate-600 border border-slate-200 px-2 py-1 rounded transition-colors"
                      >
                        {template}
                      </button>
                    ))}
                  </div>

                  <div className="flex justify-end">
                    <button
                      type="submit"
                      disabled={isSending || !replyText.trim()}
                      className="bg-teal-700 hover:bg-teal-800 disabled:opacity-50 text-white text-xs font-semibold py-2 px-4 rounded-lg flex items-center gap-1.5 transition-colors shadow-xs"
                    >
                      {isSending ? (
                        <span>Transmitting...</span>
                      ) : (
                        <>
                          <span>Transmit to Patient Phone</span>
                          <Send size={13} />
                        </>
                      )}
                    </button>
                  </div>
                </form>
              </div>

              <div className="text-[10px] text-slate-400 mt-4 border-t border-slate-200/80 pt-2 flex items-center justify-between">
                <span>Sender Identity: Dr. Jane Smith (Endocrinology)</span>
                <span>Patient Target: {patient.name} ({patient.id})</span>
              </div>
            </div>
          </div>
        </div>

        {/* Section 4: Recent Activity & Next Appointment */}
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
