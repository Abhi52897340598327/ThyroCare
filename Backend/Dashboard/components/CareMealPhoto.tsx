"use client";
import { useEffect, useState } from "react";
import { CareRecord, careAPI } from "@/lib/care-api";

export default function CareMealPhoto({ record }: { record: CareRecord }) {
    const [photo, setPhoto] = useState<string>();
    const [error, setError] = useState("");
    const [attempt, setAttempt] = useState(0);
    useEffect(() => {
        const abort = new AbortController();
        setPhoto(undefined); setError("");
        careAPI<{ imageBase64: string }>(`patients/${record.patientID}/meals/${record.id}/photo`, "GET", undefined, abort.signal)
            .then(result => { if (!abort.signal.aborted) setPhoto("data:image/jpeg;base64," + result.imageBase64); })
            .catch(e => { if (!abort.signal.aborted) setError(e.message); });
        return () => abort.abort();
    }, [record.patientID, record.id, attempt]);
    return <div>{photo ? <img src={photo} alt="Confirmed meal photo" style={{ maxWidth: "100%", maxHeight: 420, objectFit: "contain", borderRadius: 12 }} /> : error ? <p>{error} <button onClick={() => setAttempt(n => n + 1)}>Retry photo</button></p> : <p role="status">Loading authorized photo…</p>}</div>;
}

export async function normalizeMealPhoto(file: File): Promise<string> {
    if (!file.type.startsWith("image/") || file.size > 20_000_000) throw new Error("Choose an image under 20 MB.");
    const bitmap = await createImageBitmap(file);
    try {
        const scale = Math.min(1, 1600 / Math.max(bitmap.width, bitmap.height));
        const canvas = document.createElement("canvas");
        canvas.width = Math.max(1, Math.round(bitmap.width * scale)); canvas.height = Math.max(1, Math.round(bitmap.height * scale));
        const context = canvas.getContext("2d");
        if (!context) throw new Error("Image preparation is unavailable. Use manual entry.");
        context.fillStyle = "white"; context.fillRect(0,0,canvas.width,canvas.height);
        context.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        return canvas.toDataURL("image/jpeg", .82).split(",")[1];
    } finally { bitmap.close(); }
}
