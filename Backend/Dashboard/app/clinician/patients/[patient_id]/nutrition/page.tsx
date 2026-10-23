import NutritionClient from "./NutritionClient";
import { MOCK_PATIENTS } from "@/lib/demoData";

export function generateStaticParams() {
  return MOCK_PATIENTS.map((p) => ({
    patient_id: p.id,
  }));
}

export default function NutritionPage({
  params,
}: {
  params: { patient_id: string };
}) {
  return <NutritionClient patientId={params.patient_id} />;
}
