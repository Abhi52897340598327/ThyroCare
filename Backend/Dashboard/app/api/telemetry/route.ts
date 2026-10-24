import { NextResponse } from "next/server";

export async function GET() {
    return NextResponse.json({ status: "ok", telemetry: [] }, { status: 200, headers: { "Cache-Control": "no-store" } });
}
export async function POST() { return GET(); }
