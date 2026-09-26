import SharingClient from "./SharingClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function SharingPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <SharingClient patientId={params.patient_id} />;
}
