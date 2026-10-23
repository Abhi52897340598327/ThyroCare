import SummaryClient from "./SummaryClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function SummaryPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <SummaryClient patientId={params.patient_id} />;
}
