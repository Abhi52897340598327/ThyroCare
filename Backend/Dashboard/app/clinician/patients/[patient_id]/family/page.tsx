import FamilyClient from "./FamilyClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function FamilyPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <FamilyClient patientId={params.patient_id} />;
}
