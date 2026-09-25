"use client";

import { use, useState } from "react";
import PatientWorkspaceLayout from "@/components/PatientWorkspaceLayout";
import { getPatientById, ClinicalNote } from "@/lib/demoData";
import { FileCheck, Lock, Eye, PlusCircle, ShieldAlert } from "lucide-react";

export default function ClinicalNotesPage({
  params,
}: {
  params: Promise<{ patient_id: string }>;
}) {
  const resolvedParams = use(params);
  const patient = getPatientById(resolvedParams.patient_id);
  const [notes, setNotes] = useState<ClinicalNote[]>(patient.notes);
  const [noteType, setNoteType] = useState<"patient-visible" | "private">("private");
  const [noteText, setNoteText] = useState("");

  const handleAddNote = (e: React.FormEvent) => {
    e.preventDefault();
    if (!noteText.trim()) return;

    const newNote: ClinicalNote = {
      id: `n_${Date.now()}`,
      date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
      author: "Dr. Jane Smith",
      type: noteType,
      text: noteText
    };

    setNotes([newNote, ...notes]);
    setNoteText("");
  };

  return (
    <PatientWorkspaceLayout patientId={resolvedParams.patient_id}>
      <div className="space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div>
            <h1 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Clinical Documentation & Progress Notes</h1>
            <p className="text-xs text-slate-500">Secure clinical note entry with strict privacy boundary separation for {patient.name}.</p>
          </div>
        </div>

        {/* Note Entry Form */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center space-x-2">
              <PlusCircle className="w-4 h-4 text-teal-700" />
              <span>Create New Documentation Entry</span>
            </h2>

            {/* Note Privacy Toggle Tabs */}
            <div className="flex items-center space-x-1 bg-slate-100 p-1 rounded text-xs border border-slate-300">
              <button
                type="button"
                onClick={() => setNoteType("private")}
                className={`px-3 py-1 rounded font-bold transition-colors flex items-center space-x-1 ${
                  noteType === "private" ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-200"
                }`}
              >
                <Lock className="w-3 h-3 text-amber-400" />
                <span>PRIVATE CLINICAL NOTE</span>
              </button>
              <button
                type="button"
                onClick={() => setNoteType("patient-visible")}
                className={`px-3 py-1 rounded font-bold transition-colors flex items-center space-x-1 ${
                  noteType === "patient-visible" ? "bg-teal-700 text-white" : "text-slate-600 hover:bg-slate-200"
                }`}
              >
                <Eye className="w-3 h-3" />
                <span>PATIENT VISIBLE NOTE</span>
              </button>
            </div>
          </div>

          <form onSubmit={handleAddNote} className="space-y-3">
            <textarea
              rows={3}
              placeholder={noteType === "private" ? "Type private clinician notes (internal EHR only)..." : "Type notes visible to patient app..."}
              value={noteText}
              onChange={(e) => setNoteText(e.target.value)}
              className="w-full bg-slate-50 border border-slate-300 rounded p-3 text-xs focus:outline-none focus:ring-2 focus:ring-teal-500"
            />

            <div className="flex items-center justify-between">
              <div className="text-[11px] text-slate-500 font-medium">
                Author: <strong>Dr. Jane Smith</strong> | Access: <strong>{noteType === "private" ? "Internal Clinician Confidential" : "Patient Shared"}</strong>
              </div>

              <button
                type="submit"
                className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-bold px-4 py-2 rounded transition-colors"
              >
                Save Note Entry
              </button>
            </div>
          </form>
        </div>

        {/* Security Alert Banner */}
        <div className="p-3 bg-amber-50 border border-amber-200 rounded text-amber-900 text-xs flex items-center space-x-2">
          <ShieldAlert className="w-4 h-4 text-amber-600 shrink-0" />
          <p><strong>HIPAA Privacy Boundary:</strong> Private clinical notes are strictly isolated and NEVER exposed in patient mobile apps, family portals, or public export PDFs.</p>
        </div>

        {/* Notes Feed */}
        <div className="space-y-3">
          <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Historical Clinical Notes Archive ({notes.length})</h3>

          {notes.map((note) => (
            <div 
              key={note.id} 
              className={`p-4 rounded-lg border text-xs space-y-2 ${
                note.type === "private" ? "bg-slate-900 text-white border-slate-800" : "bg-white text-slate-900 border-slate-200"
              }`}
            >
              <div className="flex items-center justify-between border-b border-slate-700/40 pb-2">
                <div className="flex items-center space-x-2">
                  <span className="font-bold">{note.author}</span>
                  <span className={`px-2 py-0.5 rounded text-[10px] font-extrabold ${
                    note.type === "private" ? "bg-amber-400 text-slate-950" : "bg-teal-100 text-teal-800"
                  }`}>
                    {note.type === "private" ? "PRIVATE CLINICAL NOTE" : "PATIENT VISIBLE"}
                  </span>
                </div>
                <span className="text-[10px] text-slate-400 font-mono">{note.date}</span>
              </div>

              <p className="leading-relaxed">{note.text}</p>
            </div>
          ))}
        </div>

      </div>
    </PatientWorkspaceLayout>
  );
}
