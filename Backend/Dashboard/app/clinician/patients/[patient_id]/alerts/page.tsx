import AlertsClient from "./AlertsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function AlertsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <AlertsClient patientId={params.patient_id} />;
}
