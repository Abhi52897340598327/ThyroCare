import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
export function PageHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="tc-page-heading">
      <div>
        <p className="tc-eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="tc-description">{description}</p>
      </div>
      {action && <div className="tc-heading-action">{action}</div>}
    </div>
  );
}
export function MetricCard({
  label,
  value,
  unit,
  detail,
  icon: Icon,
  tone = "teal",
}: {
  label: string;
  value: string | number;
  unit?: string;
  detail: string;
  icon: LucideIcon;
  tone?: "teal" | "amber" | "violet" | "navy";
}) {
  return (
    <div className="tc-metric">
      <div className="tc-metric-top">
        <span>{label}</span>
        <span className={`tc-icon-tile ${tone}`}>
          <Icon size={19} />
        </span>
      </div>
      <div className="tc-metric-value">
        {value}
        <span>{unit}</span>
      </div>
      <p>{detail}</p>
    </div>
  );
}
export function Panel({
  title,
  subtitle,
  action,
  children,
  className = "",
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`tc-panel ${className}`}>
      <div className="tc-panel-heading">
        <div>
          <h2>{title}</h2>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
export function StatusBadge({ status }: { status: string }) {
  const tone =
    status === "STABLE"
      ? "teal"
      : status.includes("REVIEW") || status.includes("TREND")
        ? "amber"
        : "neutral";
  return (
    <span className={`tc-status ${tone}`}>
      <span />
      {status.toLowerCase().replace(/(^|\s)\S/g, (c) => c.toUpperCase())}
    </span>
  );
}
