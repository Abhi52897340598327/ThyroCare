import DashboardShell from "./DashboardShell";
export default function FamilyAppShell({
  children,
}: {
  children: React.ReactNode;
}) {
  return <DashboardShell mode="family">{children}</DashboardShell>;
}
