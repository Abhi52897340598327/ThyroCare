"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { CareRecord, analyteUnits, observationDate } from "@/lib/care-api";
import type { ECharts } from "echarts";

export default function CareChart({ records }: { records: CareRecord[] }) {
    const container = useRef<HTMLDivElement>(null);
    const instance = useRef<ECharts>();
    const resize = useRef<ResizeObserver>();
    const [analyte, setAnalyte] = useState("TSH");
    const [unit, setUnit] = useState("mIU/L");
    const [selected, setSelected] = useState<string>();
    const [period, setPeriod] = useState("all");
    const series = useMemo(() => records.filter(r => r.fields.analyte === analyte && r.fields.unit === unit &&
        (period === "all" || (r.fields.collectedDate && Date.parse(r.fields.collectedDate) >= Date.now() - Number(period) * 86400000)))
        .sort((a, b) => (a.fields.collectedDate || "9999").localeCompare(b.fields.collectedDate || "9999")), [records, analyte, unit, period]);
    const signature = JSON.stringify(series.map(r => [r.id, r.version]));
    useEffect(() => {
        let disposed = false;
        import("echarts").then(echarts => {
            if (disposed || !container.current) return;
            const first = !instance.current;
            const chart = instance.current ?? echarts.init(container.current, undefined, { renderer: "canvas" });
            instance.current = chart;
            chart.resize();
            chart.setOption({ useUTC: true, animationDurationUpdate: 0, animation: first && !matchMedia("(prefers-reduced-motion: reduce)").matches, animationDuration: 300,
                animationEasing: "cubicOut", grid: { left: 60, right: 24, top: 24, bottom: 55 },
                tooltip: { trigger: "item", renderMode: "richText" },
                xAxis: { type: "time", name: "Blood collection date", nameLocation: "middle", nameGap: 32 },
                yAxis: { type: "value", name: unit, scale: true },
                series: [{ type: "scatter", symbolSize: 10, itemStyle: { color: "#087F82" }, data: series.filter(r => r.fields.collectedDate && /^\d+(\.\d+)?$/.test(r.fields.result)).map(r => ({ value: [Date.parse(r.fields.collectedDate + "T00:00:00Z"), Number(r.fields.result)], id: r.id })) }]
            });
            if (first) {
                chart.on("click", params => { const data = params.data as { id?: string }; setSelected(data.id); });
                resize.current = new ResizeObserver(() => chart.resize()); resize.current.observe(container.current);
            }
        });
        return () => { disposed = true; };
        // Record versions define chart inputs; unchanged polling results do not replay chart entry.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [signature, unit]);
    useEffect(() => () => { resize.current?.disconnect(); instance.current?.dispose(); instance.current = undefined; }, []);
    const detail = series.find(r => r.id === selected);
    return <section className="care-card" aria-label="Measured laboratory trends">
        <h2>Measured laboratory results</h2>
        <div className="care-controls">
            <label>Analyte<select value={analyte} onChange={e => { setAnalyte(e.target.value); setUnit(analyteUnits[e.target.value][0]); setSelected(undefined); }}>{Object.keys(analyteUnits).map(a => <option key={a}>{a}</option>)}</select></label>
            <label>Report unit<select value={unit} onChange={e => setUnit(e.target.value)}>{analyteUnits[analyte].map(u => <option key={u}>{u}</option>)}</select></label>
            <label>Period<select value={period} onChange={e => setPeriod(e.target.value)}>{[["30", "30 days"], ["90", "90 days"], ["180", "6 months"], ["365", "1 year"], ["all", "All"]].map(([v,l]) => <option key={v} value={v}>{l}</option>)}</select></label>
        </div>
        <div ref={container} style={{ height: 300, width: "100%", display: series.length ? "block" : "none" }} aria-hidden="true" />{!series.length && <p>No results in this period. Add a measured result to begin.</p>}
        <p>Discrete measured points only. Censored results and unknown collection dates remain in the table; they are not plotted as exact measurements. Units and assays are not silently converted.</p>
        <div aria-live="polite">{detail && <p><strong>{detail.fields.result} {unit}</strong> · {observationDate(detail)} · {detail.fields.source}. Report interval: {detail.fields.referenceLower || "Not supplied"} – {detail.fields.referenceUpper || "Not supplied"}.</p>}</div>
        <div className="care-table-wrap"><table><caption>{analyte} source observations</caption><thead><tr><th>Collection date</th><th>Result</th><th>Report interval</th><th>Source</th></tr></thead><tbody>{series.map(r => <tr key={r.id}><td><button onClick={() => setSelected(r.id)}>{observationDate(r)}</button></td><td>{r.fields.result} {unit}</td><td>{r.fields.referenceLower || "Not supplied"} – {r.fields.referenceUpper || "Not supplied"}</td><td>{r.fields.source}</td></tr>)}</tbody></table></div>
    </section>;
}
