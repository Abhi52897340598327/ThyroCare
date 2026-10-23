import { NextResponse } from "next/server";

// Retired globally scoped prototype ingestion. The shared source of truth is the authorized Vapor /v1 API.
export async function GET() {
    return NextResponse.json({ error: "Prototype telemetry is retired. Use authenticated /v1 patient records." }, { status: 410, headers: { "Cache-Control": "no-store" } });
}
export async function POST() { return GET(); }
