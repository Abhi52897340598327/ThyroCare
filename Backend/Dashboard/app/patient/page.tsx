"use client";

import { useEffect, useState } from "react";
import {
  Activity,
  Calendar,
  CheckCircle2,
  Download,
  FileText,
  Lock,
  Plus,
  Share2,
  ShieldAlert
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from "@/components/ui/card";

type Lab = {
  id: string;
  testDate: string;
  tsh: number;
  freeT4?: number;
  freeT3?: number;
  labName: string;
};

type GeneratedReport = {
  reportId: string;
  patientName: string;
  dateRange: string;
  version: number;
  contentHash: string;
  shareToken: string;
  expiresAt: string;
  htmlReport: string;
};

export default function PatientPortalPage() {
  const [labs, setLabs] = useState<Lab[]>([]);
  const [showAddLab, setShowAddLab] = useState(false);
  const [tshInput, setTshInput] = useState("");
  const [ft4Input, setFt4Input] = useState("");
  const [labNameInput, setLabNameInput] = useState("Quest Diagnostics");
  const [report, setReport] = useState<GeneratedReport | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);

  useEffect(() => {
    fetch("http://localhost:8080/patients/P-1001/labs")
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setLabs(data);
      })
      .catch(() => {
        setLabs([
          { id: "1", testDate: "2026-05-10", tsh: 2.1, freeT4: 1.35, labName: "Quest Diagnostics" },
          { id: "2", testDate: "2026-07-15", tsh: 2.45, freeT4: 1.28, labName: "Quest Diagnostics" },
          { id: "3", testDate: "2026-09-12", tsh: 2.8, freeT4: 1.22, labName: "Quest Diagnostics" }
        ]);
      });
  }, []);

  const handleAddLab = async (e: React.FormEvent) => {
    e.preventDefault();
    const tshVal = parseFloat(tshInput);
    if (isNaN(tshVal)) return;

    const newLab: Lab = {
      id: `lab_${Date.now()}`,
      testDate: new Date().toISOString().substring(0, 10),
      tsh: tshVal,
      freeT4: ft4Input ? parseFloat(ft4Input) : undefined,
      labName: labNameInput
    };

    setLabs((prev) => [...prev, newLab]);
    setTshInput("");
    setFt4Input("");
    setShowAddLab(false);

    try {
      await fetch("http://localhost:8080/patients/P-1001/labs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          tsh: tshVal,
          freeT4: ft4Input ? parseFloat(ft4Input) : null,
          labName: labNameInput
        })
      });
    } catch {
      // client update fallback
    }
  };

  const handleGenerateReport = async () => {
    setIsGenerating(true);
    try {
      const res = await fetch("http://localhost:8080/patients/P-1001/reports", {
        method: "POST"
      });
      const data = await res.json();
      setReport(data);
    } catch {
      // Fallback preview
      setReport({
        reportId: "rep_889102",
        patientName: "Abhiraam Venigalla",
        dateRange: "2026-05-10 to 2026-09-12",
        version: 1,
        contentHash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        shareToken: "token_secure_990182",
        expiresAt: "2026-10-02T12:00:00Z",
        htmlReport: "<p>ThyroCare Immutable Report Preview</p>"
      });
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <main className="mx-auto max-w-7xl px-6 py-8">
      {/* Banner */}
      <div className="mb-8 rounded-xl border border-teal-100 bg-slate-900 p-6 text-white shadow-md">
        <div className="flex items-center gap-2 text-teal-400 font-semibold text-xs tracking-wider uppercase">
          <Activity className="h-4 w-4" />
          Patient Portal & Reports
        </div>
        <h1 className="mt-1 text-2xl font-bold tracking-tight md:text-3xl">
          Thyroid Longitudinal Timeline & Report Generator
        </h1>
        <p className="mt-1 text-sm text-slate-300">
          Track lab history, generate versioned Thyroid PDF/HTML Health Reports, and manage secure share tokens.
        </p>
      </div>

      <div className="grid gap-8 lg:grid-cols-[1.2fr_0.8fr]">
        {/* Lab History & Logger */}
        <Card className="border-slate-200 bg-white">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-lg font-bold text-slate-900">Longitudinal Laboratory History</CardTitle>
                <CardDescription className="text-xs">Recorded TSH & Free T4 lab results</CardDescription>
              </div>
              <Button
                size="sm"
                onClick={() => setShowAddLab(!showAddLab)}
                className="bg-teal-700 hover:bg-teal-800 text-white gap-1.5"
              >
                <Plus className="h-4 w-4" />
                {showAddLab ? "Cancel" : "Log Lab Result"}
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {showAddLab && (
              <form onSubmit={handleAddLab} className="rounded-lg border bg-teal-50/40 p-4 space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">TSH (mIU/L)</label>
                    <input
                      type="number"
                      step="0.01"
                      placeholder="e.g. 2.45"
                      value={tshInput}
                      onChange={(e) => setTshInput(e.target.value)}
                      className="w-full rounded border bg-white p-2 text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">Free T4 (ng/dL)</label>
                    <input
                      type="number"
                      step="0.01"
                      placeholder="e.g. 1.25"
                      value={ft4Input}
                      onChange={(e) => setFt4Input(e.target.value)}
                      className="w-full rounded border bg-white p-2 text-sm"
                    />
                  </div>
                </div>
                <Button type="submit" className="w-full bg-teal-700 text-white" size="sm">
                  Save Lab Entry
                </Button>
              </form>
            )}

            <div className="space-y-3">
              {labs.map((lab) => (
                <div key={lab.id} className="flex items-center justify-between rounded-lg border bg-slate-50 p-4">
                  <div>
                    <p className="font-bold text-slate-900 text-base">
                      TSH: {lab.tsh} <span className="text-xs text-slate-500 font-normal">mIU/L</span>
                    </p>
                    <p className="text-xs text-slate-500">
                      Free T4: {lab.freeT4 ?? "N/A"} ng/dL | Lab: {lab.labName}
                    </p>
                  </div>
                  <span className="flex items-center gap-1 text-xs text-slate-600 font-medium">
                    <Calendar className="h-3.5 w-3.5 text-teal-700" />
                    {lab.testDate}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Report Generator Panel */}
        <Card className="border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <FileText className="h-5 w-5 text-teal-700" />
              Automated Report Generator
            </CardTitle>
            <CardDescription className="text-xs">
              Generate versioned, immutable Thyroid Health Reports with cryptographic hashes
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <Button
              onClick={handleGenerateReport}
              disabled={isGenerating}
              className="w-full bg-teal-700 hover:bg-teal-800 text-white font-semibold py-3 gap-2"
            >
              <Download className="h-4 w-4" />
              {isGenerating ? "Compiling Report..." : "Generate Thyroid Report"}
            </Button>

            {report && (
              <div className="rounded-lg border border-teal-200 bg-teal-50/50 p-4 space-y-3 text-xs">
                <div className="flex items-center justify-between font-bold text-teal-900">
                  <span>Report ID: {report.reportId}</span>
                  <span className="rounded bg-teal-200 px-2 py-0.5 text-[10px]">v{report.version}.0</span>
                </div>
                <p className="text-slate-600">
                  <strong>Content Hash (SHA-256):</strong>
                  <span className="block truncate font-mono text-[10px] text-slate-500">{report.contentHash}</span>
                </p>
                <div className="rounded border bg-white p-3 space-y-1">
                  <p className="font-semibold text-slate-900">Secure Share Token Link</p>
                  <p className="text-[11px] text-teal-800 underline truncate">
                    http://localhost:8080/reports/{report.shareToken}
                  </p>
                  <p className="text-[10px] text-slate-400">Expires: {report.expiresAt}</p>
                </div>
                <a
                  href={`http://localhost:8080/reports/${report.reportId}`}
                  target="_blank"
                  rel="noreferrer"
                  className="block text-center rounded bg-slate-900 px-4 py-2 font-bold text-white hover:bg-slate-800"
                >
                  View Full HTML/PDF Report
                </a>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
