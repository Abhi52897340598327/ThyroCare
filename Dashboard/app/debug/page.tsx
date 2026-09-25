"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Activity,
  BellRing,
  Bug,
  Radio,
  RefreshCw,
  ShieldCheck,
  Siren
} from "lucide-react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from "recharts";
import {
  collection,
  limit,
  onSnapshot,
  orderBy,
  query,
  Timestamp
} from "firebase/firestore";
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
import { db } from "@/lib/firebase-client";

type TelemetryRecord = {
  id: string;
  patient_id: string;
  severity_score: number;
  hr_variability: number;
  created_at?: Timestamp | string;
  source?: string;
};

type ChartPoint = {
  day: string;
  severity: number;
  hrv: number;
};

function severityTone(score: number) {
  if (score >= 80) return "text-red-600";
  if (score >= 60) return "text-amber-600";
  return "text-teal-700";
}

function buildSevenDayTrend(records: TelemetryRecord[]): ChartPoint[] {
  const buckets = new Map<string, { severity: number[]; hrv: number[] }>();
  const today = new Date();

  for (let index = 6; index >= 0; index -= 1) {
    const date = new Date(today);
    date.setDate(today.getDate() - index);
    const key = date.toISOString().slice(0, 10);
    buckets.set(key, { severity: [], hrv: [] });
  }

  records.forEach((record) => {
    let key = "";
    if (record.created_at && typeof record.created_at === "object" && "toDate" in record.created_at) {
      key = record.created_at.toDate().toISOString().slice(0, 10);
    } else if (typeof record.created_at === "string") {
      key = record.created_at.slice(0, 10);
    }

    if (key && buckets.has(key)) {
      buckets.get(key)?.severity.push(record.severity_score);
      buckets.get(key)?.hrv.push(record.hr_variability);
    }
  });

  return Array.from(buckets.entries()).map(([key, values]) => {
    const date = new Date(`${key}T12:00:00`);
    const averageSeverity =
      values.severity.length > 0
        ? values.severity.reduce((sum, score) => sum + score, 0) / values.severity.length
        : 0;
    const averageHrv =
      values.hrv.length > 0
        ? values.hrv.reduce((sum, hrv) => sum + hrv, 0) / values.hrv.length
        : 0;

    return {
      day: new Intl.DateTimeFormat("en-US", { weekday: "short" }).format(date),
      severity: Math.round(averageSeverity),
      hrv: Math.round(averageHrv)
    };
  });
}

export default function DebugTelemetryPage() {
  const [telemetry, setTelemetry] = useState<TelemetryRecord[]>([]);
  const [isFiring, setIsFiring] = useState(false);
  const [ingestStatus, setIngestStatus] = useState("Realtime telemetry monitor active");

  useEffect(() => {
    try {
      const telemetryQuery = query(
        collection(db, "telemetry"),
        orderBy("created_at", "desc"),
        limit(80)
      );

      return onSnapshot(
        telemetryQuery,
        (snapshot) => {
          setTelemetry(
            snapshot.docs.map((doc) => ({
              id: doc.id,
              ...(doc.data() as Omit<TelemetryRecord, "id">)
            }))
          );
          setIngestStatus("Firestore live feed synchronized");
        },
        (error) => {
          setIngestStatus(`API fallback mode (${error.message})`);
          fetchFallbackTelemetry();
        }
      );
    } catch {
      fetchFallbackTelemetry();
    }
  }, []);

  const fetchFallbackTelemetry = async () => {
    try {
      const res = await fetch("/api/telemetry");
      const data = await res.json();
      if (Array.isArray(data)) {
        setTelemetry(data);
        setIngestStatus("Telemetry loaded via internal API");
      }
    } catch {
      setIngestStatus("Telemetry ready");
    }
  };

  const latest = telemetry[0];
  const liveSeverity = latest?.severity_score ?? 68;
  const trend = useMemo(() => buildSevenDayTrend(telemetry), [telemetry]);
  const criticalCount = telemetry.filter((r) => r.severity_score >= 80).length;

  async function fireMockPayload() {
    setIsFiring(true);
    setIngestStatus("Dispatching mock Swift telemetry...");

    const severity = Math.floor(48 + Math.random() * 48);
    const payload = {
      patient_id: "TC-90210",
      severity_score: severity,
      hr_variability: Math.floor(28 + Math.random() * 32)
    };

    try {
      const response = await fetch("/api/telemetry", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error("Payload rejected");
      }

      const resData = await response.json();
      setIngestStatus(`Accepted telemetry for ${payload.patient_id} (ID: ${resData.id})`);
      setTelemetry((prev) => [
        {
          id: resData.id,
          patient_id: payload.patient_id,
          severity_score: payload.severity_score,
          hr_variability: payload.hr_variability,
          created_at: new Date().toISOString()
        },
        ...prev
      ]);
    } catch (error) {
      setIngestStatus(error instanceof Error ? error.message : "Mock payload failed");
    } finally {
      setIsFiring(false);
    }
  }

  return (
    <main className="min-h-screen bg-slate-900 text-slate-100">
      {/* Banner */}
      <section className="border-b border-slate-800 bg-slate-950">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-amber-500 text-slate-950 font-bold shadow-lg">
              <Bug className="h-6 w-6" />
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-widest text-amber-400">
                Isolated Debug Portal — Route: /debug
              </p>
              <h1 className="text-2xl font-bold tracking-tight text-white">
                Live Telemetry Ingestion & Ingest Guard
              </h1>
            </div>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="flex items-center gap-2 rounded-md border border-slate-800 bg-slate-900 px-3 py-2 text-xs text-slate-300">
              <Radio className="h-4 w-4 text-amber-400 animate-pulse" />
              <span>{ingestStatus}</span>
            </div>
            <Button
              onClick={fireMockPayload}
              disabled={isFiring}
              className="bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold"
            >
              <RefreshCw className={`h-4 w-4 ${isFiring ? "animate-spin" : ""}`} />
              Fire Mock Swift Payload
            </Button>
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-6 px-6 py-6 lg:grid-cols-[1.1fr_0.9fr]">
        <Card className="border-slate-800 bg-slate-950 text-slate-100">
          <CardHeader className="pb-4">
            <div className="flex items-start justify-between gap-4">
              <div>
                <CardDescription className="text-slate-400">Live Telemetry Severity Score</CardDescription>
                <CardTitle className="mt-2 text-6xl font-bold tracking-tight text-white">
                  <span className={severityTone(liveSeverity)}>{liveSeverity}</span>
                  <span className="text-2xl text-slate-500">/100</span>
                </CardTitle>
              </div>
              <div className="rounded-lg bg-red-950/60 p-3 text-red-400 border border-red-900">
                <Siren className="h-6 w-6" />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-3">
              <div className="rounded-lg border border-slate-800 bg-slate-900 p-4">
                <p className="text-xs text-slate-400">Target Patient</p>
                <p className="mt-1 text-lg font-bold text-white">
                  {latest?.patient_id ?? "TC-90210"}
                </p>
              </div>
              <div className="rounded-lg border border-slate-800 bg-slate-900 p-4">
                <p className="text-xs text-slate-400">HR Variability</p>
                <p className="mt-1 text-lg font-bold text-teal-400">
                  {latest?.hr_variability ?? 42} ms
                </p>
              </div>
              <div className="rounded-lg border border-slate-800 bg-slate-900 p-4">
                <p className="text-xs text-slate-400">Source Protocol</p>
                <p className="mt-1 text-lg font-bold text-amber-400">
                  {latest?.source ?? "iOS Swift API"}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-1">
          <Card className="border-slate-800 bg-slate-950 text-slate-100">
            <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-2 text-base text-red-400">
                <BellRing className="h-5 w-5" />
                Critical Event Watch
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-4xl font-bold text-white">{criticalCount}</p>
              <p className="mt-1 text-xs text-slate-400">High-severity payloads (score ≥ 80)</p>
            </CardContent>
          </Card>
          <Card className="border-slate-800 bg-slate-950 text-slate-100">
            <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-2 text-base text-teal-400">
                <ShieldCheck className="h-5 w-5" />
                Ingest Stream Buffer
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-4xl font-bold text-white">{telemetry.length}</p>
              <p className="mt-1 text-xs text-slate-400">Active records in telemetry memory</p>
            </CardContent>
          </Card>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-6 pb-8">
        <Card className="border-slate-800 bg-slate-950 text-slate-100">
          <CardHeader>
            <CardTitle className="text-base text-white">Live Telemetry Event Log</CardTitle>
            <CardDescription className="text-xs text-slate-400">
              Newest incoming Swift telemetry payloads
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow className="border-slate-800">
                  <TableHead className="text-slate-400">Record ID</TableHead>
                  <TableHead className="text-slate-400">Patient</TableHead>
                  <TableHead className="text-slate-400">Severity</TableHead>
                  <TableHead className="text-slate-400">HRV</TableHead>
                  <TableHead className="text-slate-400">Timestamp</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {telemetry.slice(0, 10).map((record) => (
                  <TableRow key={record.id} className="border-slate-800">
                    <TableCell className="font-mono text-xs text-slate-400">{record.id}</TableCell>
                    <TableCell className="font-semibold text-white">{record.patient_id}</TableCell>
                    <TableCell className={`font-bold ${severityTone(record.severity_score)}`}>
                      {record.severity_score}
                    </TableCell>
                    <TableCell className="text-slate-300">{record.hr_variability} ms</TableCell>
                    <TableCell className="text-xs text-slate-500">
                      {typeof record.created_at === "string" ? record.created_at : "Just now"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </section>
    </main>
  );
}
