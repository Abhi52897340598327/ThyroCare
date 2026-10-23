import CarePortal from "@/components/CarePortal";
export function generateStaticParams() { return [{ patient_id: "record" }]; }
export default function Page() { return <CarePortal />; }
