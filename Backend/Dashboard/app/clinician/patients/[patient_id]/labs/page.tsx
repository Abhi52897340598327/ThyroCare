import LabsClient from "./LabsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function LabsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <LabsClient patientId={params.patient_id} />;
}
