"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  Activity, 
  Search, 
  Bell, 
  FileText, 
  BarChart3, 
  Settings, 
  Users, 
  Eye, 
  UserCheck, 
  ChevronDown,
  Stethoscope,
  Utensils
} from "lucide-react";

export default function ClinicalTopNav() {
  const pathname = usePathname();

  const navItems = [
    { label: "Dashboard", href: "/clinician", icon: Activity },
    { label: "Food Analysis", href: "/clinician/food-analysis", icon: Utensils },
    { label: "Patient Search", href: "/clinician/search", icon: Search },
    { label: "Notifications", href: "/clinician/notifications", icon: Bell },
    { label: "Reports", href: "/clinician/reports", icon: FileText },
    { label: "Data", href: "/clinician/data", icon: BarChart3 },
    { label: "Settings", href: "/clinician/settings", icon: Settings },
    { label: "Users", href: "/clinician/users", icon: Users },
    { label: "Monitoring", href: "/clinician/monitoring", icon: Eye },
  ];

  return (
    <header className="bg-slate-900 border-b border-slate-800 text-white sticky top-0 z-50 shadow-md">
      <div className="max-w-[1920px] mx-auto px-4 h-14 flex items-center justify-between">
        
        {/* Brand */}
        <div className="flex items-center space-x-6">
          <Link href="/clinician" className="flex items-center space-x-2 text-teal-400 font-bold text-lg tracking-wide hover:opacity-90">
            <Stethoscope className="w-5 h-5" />
            <span>THYROCARE <span className="text-xs px-2 py-0.5 rounded bg-teal-950 text-teal-300 border border-teal-800 font-semibold uppercase">Clinical</span></span>
          </Link>

          {/* Navigation Links */}
          <nav className="hidden xl:flex items-center space-x-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href || (item.href !== "/clinician" && pathname.startsWith(item.href));
              return (
                <Link
                  key={item.label}
                  href={item.href}
                  className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
                    isActive
                      ? "bg-teal-600 text-white shadow-xs"
                      : "text-slate-300 hover:bg-slate-800 hover:text-white"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        {/* Right User Bar */}
        <div className="flex items-center space-x-4">
          <div className="hidden md:flex items-center space-x-2 text-xs text-slate-300 bg-slate-800 px-3 py-1 rounded-full border border-slate-700">
            <UserCheck className="w-3.5 h-3.5 text-emerald-400" />
            <span>Active Session: <strong className="text-slate-100">Endocrinology Practice</strong></span>
          </div>

          <div className="flex items-center space-x-2 pl-3 border-l border-slate-800">
            <div className="w-7 h-7 rounded-full bg-teal-700 flex items-center justify-center font-bold text-xs text-white">
              JS
            </div>
            <div className="text-xs font-medium text-slate-200 hidden sm:block">
              Dr. Jane Smith
            </div>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </div>
        </div>

      </div>
    </header>
  );
}
