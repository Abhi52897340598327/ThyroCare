import NotesClient from "./NotesClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function NotesPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <NotesClient patientId={params.patient_id} />;
}
