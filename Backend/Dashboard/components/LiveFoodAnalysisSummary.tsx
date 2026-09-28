"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Activity, Database, Utensils } from "lucide-react";

interface LatestMealAnalysis {
  name: string;
  usdaMatchName?: string;
  usdaFdcId?: string;
  usdaDataType?: string;
  tshPercentChange: number;
  t3PercentChange: number;
  t4PercentChange: number;
  nutritionDetails?: Array<{
    usdaDescription: string;
    usdaFdcId?: string;
    usdaDataType?: string;
  }>;
}

interface StoredMealAnalysis {
  analysis: LatestMealAnalysis;
}

function signedPercent(value: number) {
  return `${value >= 0 ? "+" : ""}${value.toFixed(1)}%`;
}

export default function LiveFoodAnalysisSummary() {
  const [meal, setMeal] = useState<LatestMealAnalysis | null>(null);

  useEffect(() => {
    const loadLatestMeal = async () => {
      try {
        const response = await fetch("/analyses", { cache: "no-store" });
        if (!response.ok) return;

        const records = (await response.json()) as StoredMealAnalysis[];
        setMeal(records[0]?.analysis ?? null);
      } catch {
        setMeal(null);
      }
    };

    loadLatestMeal();
  }, []);

  if (!meal) return null;

  const firstMatch = meal.nutritionDetails?.[0];
  const matchName = meal.usdaMatchName ?? firstMatch?.usdaDescription ?? "USDA match pending";
  const fdcId = meal.usdaFdcId ?? firstMatch?.usdaFdcId ?? "Pending";
  const dataType = meal.usdaDataType ?? firstMatch?.usdaDataType ?? "Pending";

  return (
    <aside
      aria-label="Latest food analysis"
      className="border-b border-teal-800 bg-slate-950 px-4 py-2.5 text-white shadow-sm"
    >
      <div className="mx-auto flex max-w-[1600px] flex-wrap items-center gap-x-5 gap-y-2 text-xs">
        <div className="flex min-w-0 items-center gap-2">
          <Utensils className="h-4 w-4 shrink-0 text-teal-300" />
          <div className="min-w-0">
            <span className="font-bold text-teal-200">Latest food analysis: </span>
            <span className="font-semibold">{meal.name}</span>
          </div>
        </div>

        <div className="flex min-w-0 items-center gap-2 text-slate-300">
          <Database className="h-4 w-4 shrink-0 text-teal-300" />
          <span className="truncate">
            {matchName} · FDC {fdcId} · {dataType}
          </span>
        </div>

        <div className="flex items-center gap-3 font-mono font-semibold tabular-nums">
          <Activity className="h-4 w-4 text-teal-300" />
          <span>TSH {signedPercent(meal.tshPercentChange)}</span>
          <span>T3 {signedPercent(meal.t3PercentChange)}</span>
          <span>T4 {signedPercent(meal.t4PercentChange)}</span>
        </div>

        <Link
          href="/clinician/food-analysis"
          className="ml-auto rounded border border-teal-600 px-2.5 py-1 font-bold text-teal-200 transition-colors hover:bg-teal-900 hover:text-white"
        >
          View full analysis
        </Link>
      </div>
    </aside>
  );
}
