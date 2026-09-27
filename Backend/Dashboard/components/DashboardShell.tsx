"use client";
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  Activity,
  ArrowUpRight,
  Bell,
  CalendarDays,
  ChartNoAxesCombined,
  ChevronRight,
  FileText,
  Heart,
  LayoutDashboard,
  Menu,
  PanelLeftClose,
  Pin,
  Settings,
  Stethoscope,
  Users,
  Utensils,
  X,
} from "lucide-react";
const familyNavigation = [
  { href: "/family", label: "Overview", icon: LayoutDashboard },
  { href: "/family/reports", label: "Reports", icon: FileText },
  { href: "/family/appointments", label: "Appointments", icon: CalendarDays },
  { href: "/providers", label: "Find a doctor", icon: Stethoscope },
  { href: "/family/settings", label: "Settings", icon: Settings },
];
const clinicianNavigation = [
  { href: "/clinician", label: "Overview", icon: LayoutDashboard },
  { href: "/clinician/search", label: "Patients", icon: Users },
  { href: "/clinician/monitoring", label: "Monitoring", icon: Activity },
  { href: "/clinician/food-analysis", label: "Food analysis", icon: Utensils },
  { href: "/clinician/reports", label: "Reports", icon: FileText },
  { href: "/clinician/notifications", label: "Notifications", icon: Bell },
  { href: "/clinician/data", label: "Analytics", icon: ChartNoAxesCombined },
  { href: "/clinician/users", label: "Practice team", icon: Users },
  { href: "/clinician/settings", label: "Settings", icon: Settings },
];
export default function DashboardShell({
  children,
  mode = "family",
}: {
  children: React.ReactNode;
  mode?: "family" | "clinician";
}) {
  const pathname = usePathname();
  const [displayName, setDisplayName] = useState("Family caregiver");
  useEffect(() => {
    const refresh = () => {
      try {
        const saved = JSON.parse(
          localStorage.getItem("thyrocare.dashboard.preferences.v1") || "null",
        );
        if (typeof saved?.displayName === "string" && saved.displayName.trim())
          setDisplayName(saved.displayName.trim());
      } catch {
        /* Keep the default name when storage is unavailable. */
      }
    };
    refresh();
    window.addEventListener("thyrocare-preferences-changed", refresh);
    window.addEventListener("storage", refresh);
    return () => {
      window.removeEventListener("thyrocare-preferences-changed", refresh);
      window.removeEventListener("storage", refresh);
    };
  }, []);
  const [expanded, setExpanded] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [focused, setFocused] = useState(false);
  const menuButton = useRef<HTMLButtonElement>(null);
  const rail = useRef<HTMLElement>(null);
  const items = mode === "family" ? familyNavigation : clinicianNavigation;
  const current =
    items.find((item) => pathname === item.href)?.label ??
    (pathname.includes("/members/") ? "Family member" : "Patient record");
  const isExpanded = expanded || pinned || focused || mobileOpen;
  useEffect(() => {
    setMobileOpen(false);
  }, [pathname]);
  useEffect(() => {
    if (!mobileOpen) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    rail.current?.querySelector<HTMLButtonElement>("button")?.focus();
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setMobileOpen(false);
        menuButton.current?.focus();
      }
      if (event.key === "Tab") {
        const elements = Array.from(
          rail.current?.querySelectorAll<HTMLElement>(
            "a[href], button:not([disabled])",
          ) ?? [],
        ).filter((el) => el.getClientRects().length > 0);
        const first = elements[0],
          last = elements[elements.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last?.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first?.focus();
        }
      }
    };
    document.addEventListener("keydown", handleKey);
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", handleKey);
    };
  }, [mobileOpen]);
  return (
    <div className={`tc-shell ${pinned ? "tc-pinned" : ""}`}>
      <a className="tc-skip" href="#dashboard-content">
        Skip to content
      </a>
      {mobileOpen && (
        <button
          className="tc-backdrop"
          tabIndex={-1}
          aria-label="Close navigation"
          onClick={() => {
            setMobileOpen(false);
            menuButton.current?.focus();
          }}
        />
      )}
      <aside
        ref={rail}
        id="dashboard-navigation"
        aria-label={`${mode} navigation`}
        role={mobileOpen ? "dialog" : undefined}
        aria-modal={mobileOpen ? true : undefined}
        className={`tc-rail ${isExpanded ? "is-expanded" : ""} ${mobileOpen ? "is-open" : ""}`}
        onMouseEnter={() => setExpanded(true)}
        onMouseLeave={() => setExpanded(false)}
        onFocus={() => setFocused(true)}
        onBlur={(e) => {
          if (!e.currentTarget.contains(e.relatedTarget)) setFocused(false);
        }}
      >
        <div className="tc-rail-brand">
          <Link
            href={mode === "family" ? "/family" : "/clinician"}
            aria-label="ThyroCare overview"
          >
            <Image src="/thyrocare-logo.png" width="40" height="40" alt="" />
            <span className="tc-rail-label">
              ThyroCare<span>Connected care</span>
            </span>
          </Link>
          <button
            className="tc-mobile-close tc-icon-button"
            aria-label="Close navigation"
            onClick={() => {
              setMobileOpen(false);
              menuButton.current?.focus();
            }}
          >
            <X size={20} />
          </button>
        </div>
        <div className="tc-rail-section tc-rail-label">
          {mode === "family" ? "YOUR HEALTH" : "YOUR PRACTICE"}
        </div>
        <nav>
          {items.map((item) => {
            const Icon = item.icon;
            const active =
              pathname === item.href ||
              (item.href !== "/family" &&
                item.href !== "/clinician" &&
                pathname.startsWith(item.href));
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-label={item.label}
                aria-current={active ? "page" : undefined}
                title={item.label}
                className={`tc-nav-item ${active ? "is-active" : ""}`}
              >
                <Icon size={20} />
                <span className="tc-rail-label">{item.label}</span>
                {active && <ChevronRight className="tc-rail-label" size={16} />}
              </Link>
            );
          })}
        </nav>
        <div className="tc-rail-bottom">
          <div className="tc-rail-note tc-rail-label">
            <Heart size={20} />
            <strong>Small steps. Better care.</strong>
            <p>A clearer picture of your thyroid health, together.</p>
          </div>
          <button
            className="tc-nav-item tc-pin"
            aria-label={pinned ? "Unpin navigation" : "Pin navigation"}
            aria-pressed={pinned}
            onClick={() => setPinned(!pinned)}
          >
            {pinned ? <PanelLeftClose size={20} /> : <Pin size={20} />}
            <span className="tc-rail-label">
              {pinned ? "Collapse sidebar" : "Keep sidebar open"}
            </span>
          </button>
          <Link
            href={
              mode === "family" ? "/family/settings" : "/clinician/settings"
            }
            className="tc-account"
          >
            <span className="tc-avatar">{mode === "family" ? "FC" : "JS"}</span>
            <span className="tc-rail-label">
              <strong>
                {mode === "family" ? displayName : "Dr. Jane Smith"}
              </strong>
              <small>
                {mode === "family" ? "Family workspace" : "Clinical workspace"}
              </small>
            </span>
          </Link>
        </div>
      </aside>
      <div className="tc-workspace">
        <header className="tc-topbar">
          <div className="tc-breadcrumb">
            <button
              ref={menuButton}
              className="tc-mobile-menu tc-icon-button"
              aria-label="Open navigation"
              aria-expanded={mobileOpen}
              aria-controls="dashboard-navigation"
              onClick={() => setMobileOpen(true)}
            >
              <Menu size={22} />
            </button>
            <span>
              {mode === "family" ? "Family workspace" : "Clinical workspace"}
            </span>
            <ChevronRight size={14} />
            <strong>{current}</strong>
          </div>
          <div className="tc-topbar-actions">
            <span className="tc-demo-badge">
              <span />
              Demo data
            </span>
            <Link
              className="tc-workspace-switch"
              href={mode === "family" ? "/clinician" : "/family"}
            >
              {mode === "family" ? "Clinician view" : "Family view"}
              <ArrowUpRight size={15} />
            </Link>
          </div>
        </header>
        <main id="dashboard-content" tabIndex={-1} className="tc-content">
          {children}
        </main>
        <footer className="tc-footer">
          <span>ThyroCare · Care, connected.</span>
          <span>Sample records for this dashboard preview</span>
        </footer>
      </div>
    </div>
  );
}
