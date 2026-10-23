import SymptomsClient from "./SymptomsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function SymptomsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <SymptomsClient patientId={params.patient_id} />;
}
