import AuditClient from "./AuditClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function AuditPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <AuditClient patientId={params.patient_id} />;
}
