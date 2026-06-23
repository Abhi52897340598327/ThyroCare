"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Activity,
  BellRing,
  Radio,
  RefreshCw,
  ShieldCheck,
  Siren,
  Stethoscope
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
  created_at?: Timestamp;
  source?: string;
};

type ChartPoint = {
  day: string;
  severity: number;
  hrv: number;
};

function formatTime(timestamp?: Timestamp) {
  if (!timestamp) {
    return "Pending";
  }

  return new Intl.DateTimeFormat("en-US", {
    hour: "numeric",
    minute: "2-digit",
    month: "short",
    day: "numeric"
  }).format(timestamp.toDate());
}

function severityTone(score: number) {
  if (score >= 80) {
    return "text-red-600";
  }

  if (score >= 60) {
    return "text-amber-600";
  }

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
    const key = record.created_at?.toDate().toISOString().slice(0, 10);

    if (key && buckets.has(key)) {
      buckets.get(key)?.severity.push(record.severity_score);
      buckets.get(key)?.hrv.push(record.hr_variability);
    }
  });

  return Array.from(buckets.entries()).map(([key, values]) => {
    const date = new Date(`${key}T12:00:00`);
    const averageSeverity =
      values.severity.length > 0
        ? values.severity.reduce((sum, score) => sum + score, 0) /
          values.severity.length
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

export default function DashboardPage() {
  const [telemetry, setTelemetry] = useState<TelemetryRecord[]>([]);
  const [isFiring, setIsFiring] = useState(false);
  const [ingestStatus, setIngestStatus] = useState("Realtime listener armed");

  useEffect(() => {
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
        setIngestStatus("Live telemetry synchronized");
      },
      (error) => {
        setIngestStatus(error.message);
      }
    );
  }, []);

  const latest = telemetry[0];
  const liveSeverity = latest?.severity_score ?? 0;
  const trend = useMemo(() => buildSevenDayTrend(telemetry), [telemetry]);
  const criticalCount = telemetry.filter(
    (record) => record.severity_score >= 80
  ).length;

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
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const body = await response.json();
        throw new Error(body.error ?? "Mock payload rejected");
      }

      setIngestStatus(`Accepted telemetry for ${payload.patient_id}`);
    } catch (error) {
      setIngestStatus(
        error instanceof Error ? error.message : "Mock payload failed"
      );
    } finally {
      setIsFiring(false);
    }
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <section className="border-b bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-teal-700 text-white">
              <Stethoscope className="h-6 w-6" />
            </div>
            <div>
              <p className="text-sm font-medium uppercase tracking-[0.18em] text-teal-700">
                ThyroCare
              </p>
              <h1 className="text-2xl font-semibold tracking-normal text-slate-950">
                Clinical Mission Control
              </h1>
            </div>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="flex items-center gap-2 rounded-md border bg-slate-50 px-3 py-2 text-sm text-slate-600">
              <Radio className="h-4 w-4 text-teal-700" />
              <span>{ingestStatus}</span>
            </div>
            <Button onClick={fireMockPayload} disabled={isFiring}>
              <RefreshCw
                className={`h-4 w-4 ${isFiring ? "animate-spin" : ""}`}
              />
              Fire Mock Payload
            </Button>
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-6 px-6 py-6 lg:grid-cols-[1.1fr_0.9fr]">
        <Card className="border-slate-200 bg-white">
          <CardHeader className="pb-4">
            <div className="flex items-start justify-between gap-4">
              <div>
                <CardDescription>Live Severity Score</CardDescription>
                <CardTitle className="mt-2 text-5xl font-semibold tracking-normal text-slate-950 md:text-7xl">
                  <span className={severityTone(liveSeverity)}>
                    {liveSeverity}
                  </span>
                  <span className="text-2xl text-slate-400">/100</span>
                </CardTitle>
              </div>
              <div className="rounded-lg bg-red-50 p-3 text-red-600">
                <Siren className="h-6 w-6" />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-3">
              <div className="rounded-lg border bg-slate-50 p-4">
                <p className="text-sm text-slate-500">Patient</p>
                <p className="mt-2 text-xl font-semibold text-slate-950">
                  {latest?.patient_id ?? "No active feed"}
                </p>
              </div>
              <div className="rounded-lg border bg-slate-50 p-4">
                <p className="text-sm text-slate-500">HR Variability</p>
                <p className="mt-2 text-xl font-semibold text-slate-950">
                  {latest?.hr_variability ?? 0} ms
                </p>
              </div>
              <div className="rounded-lg border bg-slate-50 p-4">
                <p className="text-sm text-slate-500">Last Signal</p>
                <p className="mt-2 text-xl font-semibold text-slate-950">
                  {formatTime(latest?.created_at)}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-1">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-2">
                <BellRing className="h-5 w-5 text-red-600" />
                Critical Watch
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-4xl font-semibold text-slate-950">
                {criticalCount}
              </p>
              <p className="mt-2 text-sm text-slate-500">
                high-severity events in the current feed
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-2">
                <ShieldCheck className="h-5 w-5 text-teal-700" />
                Ingest Guard
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-4xl font-semibold text-slate-950">
                {telemetry.length}
              </p>
              <p className="mt-2 text-sm text-slate-500">
                records loaded from Firestore
              </p>
            </CardContent>
          </Card>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-6 px-6 pb-8 lg:grid-cols-[1.25fr_0.75fr]">
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-4">
              <div>
                <CardTitle>7-Day Metabolic Trend</CardTitle>
                <CardDescription>
                  Severity and HRV averages from live telemetry
                </CardDescription>
              </div>
              <Activity className="h-5 w-5 text-teal-700" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="h-[340px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={trend} margin={{ left: -16, right: 12 }}>
                  <defs>
                    <linearGradient id="severity" x1="0" x2="0" y1="0" y2="1">
                      <stop offset="5%" stopColor="#dc2626" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#dc2626" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="hrv" x1="0" x2="0" y1="0" y2="1">
                      <stop offset="5%" stopColor="#0f766e" stopOpacity={0.26} />
                      <stop offset="95%" stopColor="#0f766e" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke="#e2e8f0" strokeDasharray="4 4" />
                  <XAxis dataKey="day" stroke="#64748b" tickLine={false} />
                  <YAxis stroke="#64748b" tickLine={false} />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 8,
                      border: "1px solid #cbd5e1",
                      boxShadow: "0 12px 30px rgb(15 23 42 / 0.12)"
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="severity"
                    stroke="#dc2626"
                    strokeWidth={3}
                    fill="url(#severity)"
                    animationDuration={450}
                  />
                  <Area
                    type="monotone"
                    dataKey="hrv"
                    stroke="#0f766e"
                    strokeWidth={3}
                    fill="url(#hrv)"
                    animationDuration={450}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Telemetry Log</CardTitle>
            <CardDescription>Newest iOS payloads streamed first</CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Patient</TableHead>
                  <TableHead>Severity</TableHead>
                  <TableHead>HRV</TableHead>
                  <TableHead>Time</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {telemetry.slice(0, 10).map((record) => (
                  <TableRow key={record.id}>
                    <TableCell className="font-medium text-slate-950">
                      {record.patient_id}
                    </TableCell>
                    <TableCell
                      className={`font-semibold ${severityTone(
                        record.severity_score
                      )}`}
                    >
                      {record.severity_score}
                    </TableCell>
                    <TableCell>{record.hr_variability} ms</TableCell>
                    <TableCell className="text-slate-500">
                      {formatTime(record.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
                {telemetry.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={4}
                      className="h-24 text-center text-slate-500"
                    >
                      No telemetry yet. Fire a mock payload to seed Firestore.
                    </TableCell>
                  </TableRow>
                ) : null}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </section>
    </main>
  );
}
