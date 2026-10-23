import AppointmentsClient from "./AppointmentsClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function AppointmentsPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <AppointmentsClient patientId={params.patient_id} />;
}
