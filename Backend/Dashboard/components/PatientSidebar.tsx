"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  AlertTriangle, 
  Home, 
  Activity, 
  FlaskConical, 
  TrendingUp, 
  Pill, 
  Utensils, 
  Stethoscope, 
  Clock, 
  FileText, 
  Calendar, 
  FileCheck, 
  Users, 
  ShieldCheck, 
  History 
} from "lucide-react";

export default function PatientSidebar({ patientId }: { patientId: string }) {
  const pathname = usePathname();
  const basePath = `/clinician/patients/${patientId}`;

  const navItems = [
    { label: "Alerts", href: `${basePath}/alerts`, icon: AlertTriangle, badge: true },
    { label: "Home", href: basePath, icon: Home, exact: true },
    { label: "Thyroid Summary", href: `${basePath}/summary`, icon: Activity },
    { label: "Laboratory Results", href: `${basePath}/labs`, icon: FlaskConical },
    { label: "TSH Trends", href: `${basePath}/trends`, icon: TrendingUp },
    { label: "Medications", href: `${basePath}/medications`, icon: Pill },
    { label: "Diet & Nutrition", href: `${basePath}/nutrition`, icon: Utensils },
    { label: "Symptoms", href: `${basePath}/symptoms`, icon: Stethoscope },
    { label: "Timeline", href: `${basePath}/timeline`, icon: Clock },
    { label: "Reports", href: `${basePath}/reports`, icon: FileText },
    { label: "Appointments", href: `${basePath}/appointments`, icon: Calendar },
    { label: "Clinical Notes", href: `${basePath}/notes`, icon: FileCheck },
    { label: "Family Access", href: `${basePath}/family`, icon: Users },
    { label: "Sharing & Consent", href: `${basePath}/sharing`, icon: ShieldCheck },
    { label: "Audit History", href: `${basePath}/audit`, icon: History },
  ];

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col flex-shrink-0 min-h-[calc(100vh-7rem)] text-slate-300">
      <div className="p-3 border-b border-slate-800/80">
        <span className="text-[10px] uppercase tracking-wider font-semibold text-slate-400 block px-2">Patient Navigation</span>
        <span className="text-xs font-bold text-teal-400 px-2 truncate block">ID: {patientId.toUpperCase()}</span>
      </div>

      <nav className="flex-1 py-2 px-2 space-y-0.5 overflow-y-auto">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = item.exact 
            ? pathname === item.href 
            : pathname === item.href || pathname.startsWith(item.href + "/");

          return (
            <Link
              key={item.label}
              href={item.href}
              className={`flex items-center justify-between px-3 py-2 rounded-md text-xs font-medium transition-colors ${
                isActive
                  ? "bg-teal-600 text-white font-semibold shadow-xs"
                  : "text-slate-300 hover:bg-slate-800 hover:text-white"
              }`}
            >
              <div className="flex items-center space-x-2.5">
                <Icon className={`w-4 h-4 ${item.badge && !isActive ? "text-amber-400" : ""}`} />
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
              )}
            </Link>
          );
        })}
      </nav>

      <div className="p-3 border-t border-slate-800 bg-slate-950/60 text-[11px] text-slate-400">
        <span className="block font-semibold text-slate-300">Clinician EHR Context</span>
        <span>Authorized Access Active</span>
      </div>
    </aside>
  );
}
