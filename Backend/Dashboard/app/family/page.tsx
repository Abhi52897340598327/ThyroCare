"use client";
import { useState } from "react";
import Link from "next/link";
import {
  Activity,
  ArrowRight,
  CalendarDays,
  ChevronRight,
  FileText,
  Heart,
  Stethoscope,
  Utensils,
} from "lucide-react";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import FamilyAppShell from "@/components/FamilyAppShell";
import {
  MetricCard,
  PageHeading,
  Panel,
  StatusBadge,
} from "@/components/DashboardUI";
import { MOCK_PATIENTS } from "@/lib/demoData";

export default function FamilyDashboard() {
  const [memberId, setMemberId] = useState(MOCK_PATIENTS[0].id);
  const [period, setPeriod] = useState<"recent" | "all">("recent");
  const member =
    MOCK_PATIENTS.find((p) => p.id === memberId) ?? MOCK_PATIENTS[0];
  const labs = [...member.labs].sort(
    (a, b) => Date.parse(a.date) - Date.parse(b.date),
  );
  const chart = (period === "recent" ? labs.slice(-4) : labs).map((lab) => ({
    ...lab,
    label: new Date(lab.date).toLocaleDateString("en-US", {
      month: "short",
      year: "2-digit",
      timeZone: "UTC",
    }),
  }));
  const notes = member.notes.filter((note) => note.type === "patient-visible");
  return (
    <FamilyAppShell>
      <div className="tc-page">
        <PageHeading
          eyebrow="YOUR FAMILY, IN FOCUS"
          title="A little clarity. A healthier everyday."
          description="Keep your diet, thyroid health, and care team in one place."
          action={
            <Link className="tc-button primary" href="/family/reports">
              <FileText size={17} />
              View reports
            </Link>
          }
        />
        <div className="tc-member-bar">
          <div className="tc-member-identity">
            <span className="tc-avatar large">
              {member.name
                .split(" ")
                .map((n) => n[0])
                .join("")}
            </span>
            <div>
              <label htmlFor="family-member">Viewing health for</label>
              <select
                id="family-member"
                value={memberId}
                onChange={(e) => setMemberId(e.target.value)}
              >
                {MOCK_PATIENTS.map((p) => (
                  <option value={p.id} key={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </div>
            <span className="tc-member-condition">
              {member.relationship ?? "Family member"} · {member.condition}
            </span>
          </div>
          <Link href={`/family/members/${member.id}`} className="tc-text-link">
            Full health profile
            <ArrowRight size={16} />
          </Link>
        </div>
        <div className="tc-metrics">
          <MetricCard
            label="Latest TSH"
            value={member.latestTSH}
            unit="mIU/L"
            detail={`Last lab · ${member.lastLabDate}`}
            icon={Activity}
            tone="teal"
          />
          <MetricCard
            label="Free T4"
            value={member.latestFT4}
            unit="ng/dL"
            detail="From your latest lab result"
            icon={Heart}
            tone="violet"
          />
          <MetricCard
            label="Meals in your record"
            value={member.nutritionSummary.detailedLogs.length}
            unit="logged"
            detail={`Over the last ${member.nutritionSummary.periodDays} days`}
            icon={Utensils}
            tone="amber"
          />
          <MetricCard
            label="Next appointment"
            value={member.nextVisit.replace(", 2026", "")}
            detail="See appointment details"
            icon={CalendarDays}
            tone="navy"
          />
        </div>
        <div className="tc-main-grid">
          <Panel
            title="Your thyroid, over time"
            subtitle="TSH lab results · mIU/L"
            action={
              <div className="tc-segment" aria-label="Chart period">
                <button
                  aria-pressed={period === "recent"}
                  onClick={() => setPeriod("recent")}
                >
                  Recent
                </button>
                <button
                  aria-pressed={period === "all"}
                  onClick={() => setPeriod("all")}
                >
                  All results
                </button>
              </div>
            }
          >
            <div className="tc-chart-summary">
              <strong>
                {member.latestTSH}
                <span>mIU/L</span>
              </strong>
              <StatusBadge status={member.status} />
            </div>
            <div
              className="tc-chart"
              role="img"
              aria-label={`TSH results for ${member.name}: ${chart.map((lab) => `${lab.date}: ${lab.tsh} mIU/L`).join("; ")}`}
            >
              <ResponsiveContainer width="100%" height="100%">
                <LineChart
                  data={chart}
                  margin={{ top: 16, right: 20, bottom: 0, left: -24 }}
                >
                  <CartesianGrid
                    vertical={false}
                    stroke="#E6EDEE"
                    strokeDasharray="4 4"
                  />
                  <XAxis
                    dataKey="label"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "#607580", fontSize: 12 }}
                    dy={12}
                  />
                  <YAxis
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "#607580", fontSize: 12 }}
                    domain={[0, "auto"]}
                  />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 12,
                      border: "1px solid #DCE6E7",
                      fontSize: 13,
                    }}
                    labelFormatter={(_, payload) =>
                      payload?.[0]?.payload?.date ?? "Lab result"
                    }
                    formatter={(value: number) => [`${value} mIU/L`, "TSH"]}
                  />
                  <Line
                    type="linear"
                    dataKey="tsh"
                    stroke="#0D9494"
                    strokeWidth={3}
                    dot={{ r: 4, fill: "#FFFFFF", strokeWidth: 2 }}
                    activeDot={{ r: 6 }}
                    isAnimationActive={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
            <p className="tc-panel-footnote">
              Each point is a recorded lab result. Your care team can help
              interpret changes.
            </p>
          </Panel>
          <section className="tc-care-card">
            <div className="tc-care-icon">
              <Stethoscope size={23} />
            </div>
            <p className="tc-eyebrow">BETTER, TOGETHER</p>
            <h2>Your next conversation starts here.</h2>
            <p>
              Bring your food log and recent results to your next visit. Make
              room for questions that matter to you.
            </p>
            <Link href="/family/appointments" className="tc-button light">
              Plan your next visit
              <ArrowRight size={17} />
            </Link>
            <div className="tc-care-divider" />
            <span className="tc-care-caption">LOOKING FOR A SPECIALIST?</span>
            <Link href="/providers" className="tc-care-link">
              Find an endocrinologist
              <ArrowRight size={17} />
            </Link>
          </section>
        </div>
        <div className="tc-main-grid">
          <Panel
            title="Food & everyday habits"
            subtitle={`Recent entries for ${member.name.split(" ")[0]}`}
            action={
              <Link
                className="tc-text-link"
                href={`/family/members/${member.id}`}
              >
                View record
                <ChevronRight size={15} />
              </Link>
            }
          >
            <div className="tc-food-list">
              {member.nutritionSummary.detailedLogs.length ? (
                member.nutritionSummary.detailedLogs
                  .slice(0, 3)
                  .map((food, i) => (
                    <div className="tc-food-row" key={food.id}>
                      <span className={`tc-food-number tone-${i}`}>
                        0{i + 1}
                      </span>
                      <div>
                        <h3>{food.food}</h3>
                        <p>{food.constituent}</p>
                      </div>
                      <time>{food.date}</time>
                    </div>
                  ))
              ) : (
                <p className="tc-empty">
                  No meals recorded yet. Add a meal in the ThyroCare mobile app.
                </p>
              )}
            </div>
            <div className="tc-gentle-note">
              <Utensils size={17} />
              <span>
                Record meals in the mobile app to prepare for a conversation
                about your diet.
              </span>
            </div>
          </Panel>
          <Panel title="From your care team" subtitle="Notes shared with you">
            <div className="tc-note-list">
              {notes.length ? (
                notes.slice(0, 2).map((note) => (
                  <article className="tc-clinical-note" key={note.id}>
                    <div>
                      <span className="tc-avatar small">
                        {note.author
                          .split(" ")
                          .filter((n) => n !== "Dr.")
                          .map((n) => n[0])
                          .slice(0, 2)
                          .join("")}
                      </span>
                      <div>
                        <strong>{note.author}</strong>
                        <time>{note.date}</time>
                      </div>
                    </div>
                    <p>{note.text}</p>
                  </article>
                ))
              ) : (
                <div className="tc-empty">
                  <Stethoscope size={26} />
                  <h3>A space for your care team.</h3>
                  <p>
                    Patient-visible notes will appear here when they are
                    available in your record.
                  </p>
                </div>
              )}
            </div>
          </Panel>
        </div>
      </div>
    </FamilyAppShell>
  );
}
