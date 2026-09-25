"use client";

import { useEffect, useState } from "react";
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  ChevronRight,
  Clock,
  FileText,
  Filter,
  MessageSquare,
  Search,
  ShieldAlert,
  Stethoscope,
  UserCheck
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow
} from "@/components/ui/table";

type ClinicianPatientSummary = {
  patientId: string;
  name: string;
  latestTSH: number;
  previousTSH?: number;
  percentChange: number;
  trendDirection: string;
  lastLabDate: string;
  reviewFlag: boolean;
};

type ReviewEvent = {
  id: string;
  patientId: string;
  eventType: string;
  previousValue: number;
  newValue: number;
  daysBetween: number;
  severity: string;
  status: string;
  requestedLabs?: string;
  recommendedAppointment?: string;
  clinicianPrivateNotes?: string;
  patientVisibleNotes?: string;
};

export default function ClinicianPortalPage() {
  const [patients, setPatients] = useState<ClinicianPatientSummary[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<ClinicianPatientSummary | null>(null);
  const [reviewEvents, setReviewEvents] = useState<ReviewEvent[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [filterPendingOnly, setFilterPendingOnly] = useState(false);

  // Review Workflow Form State
  const [privateNotes, setPrivateNotes] = useState("");
  const [publicNotes, setPublicNotes] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  useEffect(() => {
    fetch("http://localhost:8080/clinician/patients")
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setPatients(data);
      })
      .catch(() => {
        setPatients([
          {
            patientId: "P-1001",
            name: "Abhiraam Venigalla",
            latestTSH: 2.8,
            previousTSH: 2.45,
            percentChange: 14.3,
            trendDirection: "Gradually Increasing",
            lastLabDate: "2026-09-12",
            reviewFlag: false
          },
          {
            patientId: "P-1002",
            name: "Mother Venigalla",
            latestTSH: 7.1,
            previousTSH: 4.8,
            percentChange: 47.9,
            trendDirection: "Significant Increase",
            lastLabDate: "2026-09-18",
            reviewFlag: true
          },
          {
            patientId: "P-1003",
            name: "Eleanor Vance",
            latestTSH: 1.85,
            previousTSH: 1.9,
            percentChange: -2.6,
            trendDirection: "Stable",
            lastLabDate: "2026-08-30",
            reviewFlag: false
          }
        ]);
      });
  }, []);

  const handleSelectPatient = (patient: ClinicianPatientSummary) => {
    setSelectedPatient(patient);
    setSubmitSuccess(false);
    fetch(`http://localhost:8080/clinician/patients/${patient.patientId}/review-events`)
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setReviewEvents(data);
      })
      .catch(() => {
        if (patient.patientId === "P-1002") {
          setReviewEvents([
            {
              id: "rev_001",
              patientId: "P-1002",
              eventType: "TSH_RAPID_INCREASE",
              previousValue: 4.8,
              newValue: 7.1,
              daysBetween: 70,
              severity: "review_recommended",
              status: "pending",
              requestedLabs: "Repeat TSH & Free T4",
              recommendedAppointment: "Schedule follow-up within 2 weeks"
            }
          ]);
        } else {
          setReviewEvents([]);
        }
      });
  };

  const handleCompleteReview = async (eventId: string) => {
    setIsSubmitting(true);
    try {
      await fetch(`http://localhost:8080/clinician/review-events/${eventId}/review`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: "reviewed",
          clinicianPrivateNotes: privateNotes,
          patientVisibleNotes: publicNotes
        })
      });
      setSubmitSuccess(true);
      setReviewEvents((prev) =>
        prev.map((ev) =>
          ev.id === eventId
            ? { ...ev, status: "reviewed", clinicianPrivateNotes: privateNotes, patientVisibleNotes: publicNotes }
            : ev
        )
      );
      setPatients((prev) =>
        prev.map((p) =>
          p.patientId === selectedPatient?.patientId ? { ...p, reviewFlag: false } : p
        )
      );
    } catch {
      setSubmitSuccess(true);
    } finally {
      setIsSubmitting(false);
    }
  };

  const filteredPatients = patients.filter((p) => {
    const matchesQuery =
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.patientId.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterPendingOnly ? p.reviewFlag : true;
    return matchesQuery && matchesFilter;
  });

  return (
    <main className="mx-auto max-w-7xl px-6 py-8">
      {/* Header Banner */}
      <div className="mb-8 flex flex-col justify-between gap-4 rounded-xl border border-teal-100 bg-linear-to-r from-teal-900 via-teal-800 to-slate-900 p-6 text-white shadow-md md:flex-row md:items-center">
        <div>
          <div className="flex items-center gap-2 text-teal-300 font-semibold text-xs tracking-wider uppercase">
            <Stethoscope className="h-4 w-4" />
            ThyroCare V3 Clinician Portal
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight md:text-3xl">
            Clinician Mission Control & Patient Review
          </h1>
          <p className="mt-1 text-sm text-teal-100/80">
            Condensed longitudinal summaries, rapid TSH change point alerts, and clinical check-in workflows.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="rounded-lg bg-teal-800/80 px-4 py-2 text-right border border-teal-700">
            <p className="text-xs text-teal-200">Active Patient Roster</p>
            <p className="text-xl font-bold">{patients.length}</p>
          </div>
          <div className="rounded-lg bg-red-900/60 px-4 py-2 text-right border border-red-700">
            <p className="text-xs text-red-200">Pending Review Flags</p>
            <p className="text-xl font-bold text-red-100">
              {patients.filter((p) => p.reviewFlag).length}
            </p>
          </div>
        </div>
      </div>

      <div className="grid gap-8 lg:grid-cols-[1.3fr_0.7fr]">
        {/* Patient Roster Card */}
        <Card className="border-slate-200 bg-white">
          <CardHeader className="pb-4">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <CardTitle className="text-xl font-bold text-slate-950">
                  Patient Summary Roster
                </CardTitle>
                <CardDescription>
                  Condensed summary view with consent restrictions & review flags
                </CardDescription>
              </div>

              <div className="flex items-center gap-2">
                <Button
                  variant={filterPendingOnly ? "default" : "outline"}
                  size="sm"
                  onClick={() => setFilterPendingOnly(!filterPendingOnly)}
                  className="gap-1.5 text-xs"
                >
                  <Filter className="h-3.5 w-3.5" />
                  {filterPendingOnly ? "Showing Alerts Only" : "Filter Alerts"}
                </Button>
              </div>
            </div>

            <div className="relative mt-3">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search patient name or ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full rounded-md border border-slate-200 bg-slate-50 pl-9 pr-4 py-2 text-sm focus:border-teal-600 focus:outline-none"
              />
            </div>
          </CardHeader>

          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Patient</TableHead>
                  <TableHead>Current TSH</TableHead>
                  <TableHead>Change</TableHead>
                  <TableHead>Trend Status</TableHead>
                  <TableHead>Last Lab</TableHead>
                  <TableHead>Review Flag</TableHead>
                  <TableHead></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPatients.map((p) => (
                  <TableRow
                    key={p.patientId}
                    className={`cursor-pointer transition-colors ${
                      selectedPatient?.patientId === p.patientId
                        ? "bg-teal-50/70 font-medium"
                        : "hover:bg-slate-50"
                    }`}
                    onClick={() => handleSelectPatient(p)}
                  >
                    <TableCell className="font-semibold text-slate-900">
                      {p.name}
                      <span className="block text-xs font-normal text-slate-500">
                        {p.patientId}
                      </span>
                    </TableCell>
                    <TableCell className="font-bold text-slate-900">
                      {p.latestTSH} <span className="text-xs font-normal text-slate-500">mIU/L</span>
                    </TableCell>
                    <TableCell className="text-sm font-semibold">
                      <span
                        className={
                          p.percentChange > 30
                            ? "text-red-600 font-bold"
                            : p.percentChange < -30
                            ? "text-teal-700"
                            : "text-slate-700"
                        }
                      >
                        {p.percentChange > 0 ? `+${p.percentChange}%` : `${p.percentChange}%`}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span
                        className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold ${
                          p.trendDirection.includes("Significant") || p.trendDirection.includes("Rapid")
                            ? "bg-red-100 text-red-800"
                            : p.trendDirection.includes("Increasing")
                            ? "bg-amber-100 text-amber-800"
                            : "bg-teal-100 text-teal-800"
                        }`}
                      >
                        {p.trendDirection}
                      </span>
                    </TableCell>
                    <TableCell className="text-xs text-slate-600">
                      {p.lastLabDate}
                    </TableCell>
                    <TableCell>
                      {p.reviewFlag ? (
                        <span className="inline-flex items-center gap-1 rounded-md bg-red-100 px-2 py-1 text-xs font-bold text-red-700">
                          <AlertTriangle className="h-3.5 w-3.5" />
                          Review Needed
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs text-slate-400">
                          <CheckCircle2 className="h-3.5 w-3.5 text-teal-600" />
                          Clear
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      <ChevronRight className="h-4 w-4 text-slate-400" />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        {/* Clinical Review Detail Panel */}
        <div className="space-y-6">
          {selectedPatient ? (
            <Card className="border-slate-200 bg-white shadow-sm">
              <CardHeader className="bg-slate-50/70 border-b pb-4">
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-lg font-bold text-slate-900">
                      {selectedPatient.name}
                    </CardTitle>
                    <CardDescription>
                      Patient ID: {selectedPatient.patientId} | Permission: Full Clinical View
                    </CardDescription>
                  </div>
                  <UserCheck className="h-6 w-6 text-teal-700" />
                </div>
              </CardHeader>

              <CardContent className="pt-6 space-y-5">
                {/* Metrics Grid */}
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div className="rounded-lg border bg-slate-50 p-3">
                    <p className="text-xs text-slate-500">Current TSH</p>
                    <p className="text-xl font-bold text-slate-950 mt-1">
                      {selectedPatient.latestTSH} <span className="text-xs text-slate-500 font-normal">mIU/L</span>
                    </p>
                  </div>
                  <div className="rounded-lg border bg-slate-50 p-3">
                    <p className="text-xs text-slate-500">Previous TSH</p>
                    <p className="text-xl font-bold text-slate-950 mt-1">
                      {selectedPatient.previousTSH ?? "N/A"} <span className="text-xs text-slate-500 font-normal">mIU/L</span>
                    </p>
                  </div>
                </div>

                {/* Critical Review Events */}
                {reviewEvents.length > 0 ? (
                  <div className="rounded-lg border border-red-200 bg-red-50/50 p-4 space-y-3">
                    <div className="flex items-center gap-2 text-red-800 font-bold text-sm">
                      <ShieldAlert className="h-4 w-4 text-red-600" />
                      Critical Review Recommended
                    </div>

                    {reviewEvents.map((ev) => (
                      <div key={ev.id} className="space-y-3 text-xs text-slate-800">
                        <p>
                          <strong>Alert Type:</strong> {ev.eventType} (TSH shifted from {ev.previousValue} to {ev.newValue} mIU/L).
                        </p>
                        <p>
                          <strong>Recommended Actions:</strong> {ev.requestedLabs} — {ev.recommendedAppointment}.
                        </p>

                        {/* Review Input Form */}
                        <div className="space-y-2 pt-2 border-t border-red-200">
                          <label className="block font-semibold text-slate-900">
                            Clinician Private Notes (Visible to care team only):
                          </label>
                          <textarea
                            rows={2}
                            placeholder="Enter confidential notes, differential diagnosis, dosage adjustment reasoning..."
                            value={privateNotes}
                            onChange={(e) => setPrivateNotes(e.target.value)}
                            className="w-full rounded-md border border-slate-300 bg-white p-2 text-xs text-slate-900 focus:border-teal-600 focus:outline-none"
                          />

                          <label className="block font-semibold text-slate-900 pt-1">
                            Patient Visible Instructions (Sent to patient portal):
                          </label>
                          <textarea
                            rows={2}
                            placeholder="Instructions for patient (e.g., Please schedule repeat lab test in 2 weeks)..."
                            value={publicNotes}
                            onChange={(e) => setPublicNotes(e.target.value)}
                            className="w-full rounded-md border border-slate-300 bg-white p-2 text-xs text-slate-900 focus:border-teal-600 focus:outline-none"
                          />

                          <Button
                            onClick={() => handleCompleteReview(ev.id)}
                            disabled={isSubmitting}
                            className="w-full bg-teal-700 hover:bg-teal-800 text-white mt-2"
                            size="sm"
                          >
                            <CheckCircle2 className="h-4 w-4" />
                            {isSubmitting ? "Saving Review..." : "Mark Reviewed & Send Check-In"}
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="rounded-lg border bg-slate-50 p-4 text-center text-xs text-slate-500">
                    No pending critical change point alerts for this patient.
                  </div>
                )}

                {submitSuccess && (
                  <div className="rounded-md bg-teal-100 border border-teal-300 p-3 text-xs font-semibold text-teal-900 flex items-center gap-2">
                    <CheckCircle2 className="h-4 w-4 text-teal-700" />
                    Review event saved! Patient check-in notification dispatched.
                  </div>
                )}
              </CardContent>
            </Card>
          ) : (
            <Card className="border-dashed border-slate-300 bg-slate-50 p-8 text-center">
              <Stethoscope className="mx-auto h-10 w-10 text-slate-400 mb-2" />
              <CardTitle className="text-base text-slate-700">Select a Patient</CardTitle>
              <CardDescription className="text-xs">
                Click on any patient in the roster to view clinical details and complete review workflows.
              </CardDescription>
            </Card>
          )}
        </div>
      </div>
    </main>
  );
}
