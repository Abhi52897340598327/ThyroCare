import PatientHomeClient from "./PatientHomeClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function PatientHomePage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <PatientHomeClient patientId={params.patient_id} />;
}
