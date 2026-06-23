import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { NextRequest, NextResponse } from "next/server";
import { getAdminDb } from "@/lib/firebase-admin";

export const runtime = "nodejs";

type TelemetryPayload = {
  patient_id: string;
  severity_score: number;
  hr_variability: number;
};

function validateTelemetryPayload(input: unknown): TelemetryPayload {
  if (!input || typeof input !== "object") {
    throw new Error("Request body must be a JSON object.");
  }

  const payload = input as Partial<TelemetryPayload>;
  const patientId = payload.patient_id?.trim();

  if (!patientId) {
    throw new Error("patient_id is required.");
  }

  if (
    typeof payload.severity_score !== "number" ||
    payload.severity_score < 0 ||
    payload.severity_score > 100
  ) {
    throw new Error("severity_score must be a number from 0 to 100.");
  }

  if (
    typeof payload.hr_variability !== "number" ||
    payload.hr_variability < 0
  ) {
    throw new Error("hr_variability must be a non-negative number.");
  }

  return {
    patient_id: patientId,
    severity_score: Math.round(payload.severity_score),
    hr_variability: Math.round(payload.hr_variability)
  };
}

function isAuthorized(request: NextRequest) {
  const expectedToken = process.env.TELEMETRY_INGEST_TOKEN;

  if (!expectedToken) {
    return true;
  }

  const authHeader = request.headers.get("authorization");
  return authHeader === `Bearer ${expectedToken}`;
}

export async function POST(request: NextRequest) {
  if (!isAuthorized(request)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const payload = validateTelemetryPayload(await request.json());
    const db = getAdminDb();
    const timestamp = Timestamp.now();

    const telemetryRef = await db.collection("telemetry").add({
      ...payload,
      created_at: timestamp,
      source: "ios"
    });

    await db.collection("patients").doc(payload.patient_id).set(
      {
        patient_id: payload.patient_id,
        latest_severity_score: payload.severity_score,
        latest_hr_variability: payload.hr_variability,
        latest_telemetry_id: telemetryRef.id,
        updated_at: FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    return NextResponse.json(
      {
        id: telemetryRef.id,
        accepted: true,
        created_at: timestamp.toDate().toISOString()
      },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error ? error.message : "Unable to ingest telemetry."
      },
      { status: 400 }
    );
  }
}
