import UnavailableWorkspace from "@/components/UnavailableWorkspace";
export function generateStaticParams() { return [{ memberId: "record" }]; }
export default function Page() { return <UnavailableWorkspace />; }
