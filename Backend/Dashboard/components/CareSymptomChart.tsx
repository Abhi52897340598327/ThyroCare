"use client";
import { useEffect, useRef, useState } from "react";
import { CareRecord, symptomNames } from "@/lib/care-api";

export default function CareSymptomChart({ records }: { records: CareRecord[] }) {
    const [symptom, setSymptom] = useState("fatigue");
    const node = useRef<HTMLDivElement>(null);
    const daily = records.filter(r => r.kind === "symptoms" && r.fields[symptom] !== undefined && r.fields[symptom] !== "").sort((a,b) => a.fields.observedDate.localeCompare(b.fields.observedDate));
    const weekly = records.filter(r => r.kind === "weekly-checkins");
    const signature = JSON.stringify(daily.map(r => [r.id,r.version]));
    useEffect(() => {
        let cancelled = false;
        let chart: import("echarts").ECharts | undefined;
        let observer: ResizeObserver | undefined;
        import("echarts").then(e => {
            if (cancelled || !node.current) return;
            chart = e.init(node.current, undefined, { renderer: "canvas" });
            chart.setOption({ useUTC: true, animation: !matchMedia("(prefers-reduced-motion: reduce)").matches, animationDuration: 300,
                grid:{left:55,right:24,top:25,bottom:55}, tooltip:{trigger:"item",renderMode:"richText"},
                xAxis:{type:"time",name:"Reported local date",nameLocation:"middle",nameGap:32},
                yAxis:{type:"value",min:0,max:4,interval:1,name:"Rating (0–4)"},
                series:[{name:symptomNames[symptom],type:"scatter",symbolSize:10,itemStyle:{color:"#087F82"},data:daily.map(r=>[Date.parse(r.fields.observedDate+"T00:00:00Z"),Number(r.fields[symptom])])}]
            });
            observer = new ResizeObserver(()=>chart?.resize()); observer.observe(node.current);
        });
        return ()=>{cancelled=true;observer?.disconnect();chart?.dispose();};
        // Unchanged server refreshes do not rebuild the chart.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [signature,symptom]);
    return <section className="care-card"><h2>Daily observations</h2><label>Symptom<select value={symptom} onChange={e=>setSymptom(e.target.value)}>{Object.entries(symptomNames).map(([key,name])=><option key={key} value={key}>{name}</option>)}</select></label><div ref={node} style={{height:280}} aria-hidden="true" /><p>Each point is one reported observation. No line fills missing days. 0 None · 1 Mild · 2 Moderate · 3 Severe · 4 Very severe.</p><div className="care-table-wrap"><table><caption>{symptomNames[symptom]} — equivalent chart data</caption><thead><tr><th>Observed date</th><th>Timezone</th><th>Rating</th><th>Interference / context</th></tr></thead><tbody>{daily.map(r=><tr key={r.id}><td>{r.fields.observedDate}</td><td>{r.fields.timezone}</td><td>{r.fields[symptom]} / 4</td><td>{r.fields.interference || "Not recorded"} · {r.fields.context || "No context recorded"}</td></tr>)}</tbody></table></div><h3>Separate weekly recollections</h3>{weekly.length ? weekly.map(r=><p key={r.id}>{r.fields.recallStart} to {r.fields.recallEnd}: {r.fields.body}</p>) : <p>No weekly check-ins recorded.</p>}</section>;
}
