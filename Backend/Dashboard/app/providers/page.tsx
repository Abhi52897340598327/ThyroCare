"use client";

import ClinicalAppShell from "@/components/ClinicalAppShell";
import EndocrinologistSearch from "@/components/EndocrinologistSearch";

export default function ProviderSearchPage() {
  return (
    <ClinicalAppShell>
      <div className="max-w-[1600px] mx-auto p-4 sm:p-6 space-y-6">
        <EndocrinologistSearch />
      </div>
    </ClinicalAppShell>
  );
}
