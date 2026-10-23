import FamilyAppShell from "@/components/FamilyAppShell";
import EndocrinologistSearch from "@/components/EndocrinologistSearch";
import { PageHeading } from "@/components/DashboardUI";
export default function ProviderSearchPage() {
  return (
    <FamilyAppShell>
      <div className="tc-page">
        <PageHeading
          eyebrow="BUILD YOUR CARE TEAM"
          title="Find care, closer to you."
          description="Take the next step toward a conversation about your thyroid health and diet."
        />
        <EndocrinologistSearch />
      </div>
    </FamilyAppShell>
  );
}
