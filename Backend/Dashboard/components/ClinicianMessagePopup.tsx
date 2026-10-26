"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { MessageSquare, X, ArrowUpRight, CheckCircle2, Send } from "lucide-react";
import { careAPI, CareRecord } from "@/lib/care-api";

interface PopupMessage {
  id: string;
  sender: string;
  subject: string;
  body: string;
  timestamp: string;
  patientId: string;
}

const STORAGE_KEY = "thyrocare_dismissed_message_ids";

export default function ClinicianMessagePopup() {
  const [activeMessage, setActiveMessage] = useState<PopupMessage | null>(null);
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(new Set());
  const [replyText, setReplyText] = useState("");
  const [isSendingReply, setIsSendingReply] = useState(false);

  // Initialize dismissed message IDs from localStorage
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setDismissedIds(new Set(JSON.parse(stored)));
      }
    } catch {
      // Local storage fallback
    }
  }, []);

  const dismissMessage = (id: string) => {
    setDismissedIds((prev) => {
      const updated = new Set(prev);
      updated.add(id);
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(Array.from(updated)));
      } catch {}
      return updated;
    });
    setActiveMessage(null);
    setReplyText("");
  };

  const handleSendReply = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const trimmed = replyText.trim();
    if (!trimmed || !activeMessage) return;

    const messageIdToDismiss = activeMessage.id;
    setIsSendingReply(true);
    try {
      const patientId = activeMessage.patientId || "p1";
      await careAPI(`patients/${patientId}/messages`, "POST", {
        id: crypto.randomUUID(),
        expectedVersion: 0,
        fields: {
          body: trimmed,
          subject: "Clinician Response",
          sender: "Dr. Jane Smith (Endocrinology)",
          authorRole: "clinician",
          recipient: activeMessage.sender,
          observedDate: new Date().toISOString(),
          replyToId: messageIdToDismiss,
        },
      });

      // Immediately dismiss this message so it never pops up again
      dismissMessage(messageIdToDismiss);
    } catch (err) {
      console.error("Failed to send clinician reply:", err);
    } finally {
      setIsSendingReply(false);
    }
  };

  useEffect(() => {
    let isCancelled = false;

    async function checkMessages() {
      try {
        // Query backend for recent incoming patient messages
        const records = await careAPI<CareRecord[]>("clinician/messages").catch(
          () => []
        );

        if (isCancelled || !Array.isArray(records) || records.length === 0) {
          return;
        }

        // Find the latest patient message that hasn't been dismissed or answered
        for (const r of records) {
          // Strictly ignore any responses from clinician / dashboard
          const isClinician =
            r.fields.authorRole === "clinician" ||
            r.authorID === "c1" ||
            r.fields.sender?.includes("Dr.") ||
            r.fields.subject === "Clinician Response";
          if (isClinician) {
            continue;
          }

          if (!dismissedIds.has(r.id)) {
            const rawSender = r.fields.sender?.trim();
            const sender = rawSender && rawSender !== "Patient" ? rawSender : "Eleanor Vance (Demo Patient)";
            const subject = r.fields.subject || "Care Update";
            const body = r.fields.body || "";
            const timestamp = r.recordedAt || new Date().toISOString();
            const patientId = r.patientID || "p1";

            setActiveMessage({
              id: r.id,
              sender,
              subject,
              body,
              timestamp,
              patientId,
            });
            break;
          }
        }
      } catch {
        // Graceful handling when offline or between poll cycles
      }
    }

    // Check immediately and poll every 2 seconds
    void checkMessages();
    const interval = setInterval(() => {
      void checkMessages();
    }, 2000);

    return () => {
      isCancelled = true;
      clearInterval(interval);
    };
  }, [dismissedIds]);

  if (!activeMessage) return null;

  const formattedTime = (() => {
    try {
      const d = new Date(activeMessage.timestamp);
      return isNaN(d.getTime()) ? "Just now" : d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    } catch {
      return "Just now";
    }
  })();

  const patientUrl = `/clinician/patients/${activeMessage.patientId || "p1"}`;

  return (
    <div
      role="alert"
      aria-live="assertive"
      style={{ zIndex: 99999 }}
      className="fixed bottom-6 right-6 z-[99999] max-w-md w-[92vw] sm:w-[420px] bg-slate-900 border-2 border-teal-500 rounded-xl p-4 shadow-2xl text-white animate-in fade-in slide-in-from-bottom-5 duration-300"
    >
      <div className="flex items-center justify-between gap-2 border-b border-slate-800 pb-2 mb-2.5">
        <div className="flex items-center space-x-2">
          <span className="relative flex h-3 w-3">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-3 w-3 bg-teal-500"></span>
          </span>
          <span className="text-[11px] font-bold text-teal-300 tracking-wider uppercase flex items-center gap-1.5">
            <MessageSquare size={13} />
            Patient Message Received
          </span>
        </div>
        <button
          onClick={() => dismissMessage(activeMessage.id)}
          aria-label="Dismiss message alert"
          className="text-slate-400 hover:text-white p-1 rounded-md transition-colors"
        >
          <X size={16} />
        </button>
      </div>

      <div className="space-y-1.5">
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold text-white truncate">
            {activeMessage.sender}
          </p>
          <span className="text-[10px] font-medium bg-teal-950/80 text-teal-300 border border-teal-600/30 px-2 py-0.5 rounded-full shrink-0">
            {activeMessage.subject}
          </span>
        </div>

        <p className="text-xs text-slate-300 leading-relaxed bg-slate-800/80 p-2.5 rounded-lg border border-slate-700/60 line-clamp-3">
          &ldquo;{activeMessage.body}&rdquo;
        </p>

        <div className="flex items-center justify-between text-[10px] text-slate-400 pt-1">
          <span>Received {formattedTime}</span>
          <span className="text-teal-400 flex items-center gap-1">
            <CheckCircle2 size={11} /> Ready for reply
          </span>
        </div>
      </div>

      {/* Clinician Quick Response Box */}
      <div className="mt-3 pt-2.5 border-t border-slate-800">
        <form onSubmit={handleSendReply} className="space-y-2">
          <div className="flex items-center gap-1.5">
            <input
              type="text"
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              placeholder="Type response back to phone..."
              className="flex-1 bg-slate-800/90 text-xs text-white placeholder-slate-400 px-3 py-2 rounded-lg border border-slate-700 focus:outline-none focus:border-teal-400 transition-colors"
            />
            <button
              type="submit"
              disabled={isSendingReply || !replyText.trim()}
              className="bg-teal-600 hover:bg-teal-500 disabled:opacity-50 text-white text-xs font-semibold px-3 py-2 rounded-lg flex items-center gap-1.5 transition-colors shrink-0 shadow-sm"
            >
              {isSendingReply ? (
                <span>Sending...</span>
              ) : (
                <>
                  <span>Reply</span>
                  <Send size={12} />
                </>
              )}
            </button>
          </div>
          {/* Quick response suggestions */}
          <div className="flex flex-wrap gap-1">
            {[
              "Take meds 30m before food",
              "I reviewed your note; continue current dose",
              "Let's order repeat TSH labs",
            ].map((suggestion) => (
              <button
                key={suggestion}
                type="button"
                onClick={() => setReplyText(suggestion)}
                className="text-[10px] bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white px-2 py-0.5 rounded border border-slate-700 transition-colors"
              >
                {suggestion}
              </button>
            ))}
          </div>
        </form>
      </div>

      <div className="mt-3 flex items-center gap-2">
        <Link
          href={patientUrl}
          onClick={() => dismissMessage(activeMessage.id)}
          className="flex-1 bg-slate-800 hover:bg-slate-700 text-teal-300 text-xs font-semibold py-2 px-3 rounded-lg text-center flex items-center justify-center gap-1.5 transition-colors border border-slate-700"
        >
          <span>Open Full Chart</span>
          <ArrowUpRight size={13} />
        </Link>
        <button
          onClick={() => dismissMessage(activeMessage.id)}
          className="bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 text-xs font-medium py-2 px-3 rounded-lg transition-colors border border-slate-700"
        >
          Dismiss
        </button>
      </div>
    </div>
  );
}
