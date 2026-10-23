import TrendsClient from "./TrendsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function TrendsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <TrendsClient patientId={params.patient_id} />;
}
