import FamilyMemberClient from "./FamilyMemberClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    memberId: p.id,
  }));
}

export default function FamilyMemberPage({
  params,
}: {
  params: { memberId: string };
}) {
  return <FamilyMemberClient memberId={params.memberId} />;
}
