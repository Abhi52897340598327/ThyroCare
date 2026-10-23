import TimelineClient from "./TimelineClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function TimelinePage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <TimelineClient patientId={params.patient_id} />;
}
