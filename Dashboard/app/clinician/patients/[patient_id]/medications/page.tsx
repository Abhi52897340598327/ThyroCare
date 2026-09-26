import MedicationsClient from "./MedicationsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function MedicationsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <MedicationsClient patientId={params.patient_id} />;
}
