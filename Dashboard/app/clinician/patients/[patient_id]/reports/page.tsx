import ReportsClient from "./ReportsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function ReportsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <ReportsClient patientId={params.patient_id} />;
}
