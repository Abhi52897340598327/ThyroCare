import DashboardShell from "./DashboardShell";
export default function ClinicalAppShell({
  children,
}: {
  children: React.ReactNode;
}) {
  return <DashboardShell mode="clinician">{children}</DashboardShell>;
}
