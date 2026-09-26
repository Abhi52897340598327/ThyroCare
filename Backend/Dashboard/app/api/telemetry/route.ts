import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

type TelemetryPayload = {
  patient_id: string;
  severity_score: number;
  hr_variability: number;
};

const mockTelemetryMemory: Array<TelemetryPayload & { id: string; created_at: string; source: string }> = [];

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

export async function POST(request: NextRequest) {
  try {
    const payload = validateTelemetryPayload(await request.json());
    const id = `telemetry_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const timestamp = new Date().toISOString();

    let firebaseSaved = false;

    // Attempt Firebase Admin if configured
    try {
      const { getAdminDb } = await import("@/lib/firebase-admin");
      const { Timestamp, FieldValue } = await import("firebase-admin/firestore");
      const db = getAdminDb();
      const adminTimestamp = Timestamp.now();

      const telemetryRef = await db.collection("telemetry").add({
        ...payload,
        created_at: adminTimestamp,
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
      firebaseSaved = true;
    } catch {
      // Fallback to in-memory telemetry array when Firebase credentials are not set
    }

    mockTelemetryMemory.unshift({
      id,
      ...payload,
      created_at: timestamp,
      source: "ios"
    });

    return NextResponse.json(
      {
        id,
        accepted: true,
        firebaseSaved,
        created_at: timestamp
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

export async function GET() {
  return NextResponse.json(mockTelemetryMemory.slice(0, 50));
}
