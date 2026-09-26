"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Bell, ChevronDown, UserCheck, Stethoscope } from "lucide-react";

export default function ClinicalHeader() {
  const pathname = usePathname();

  const getPageTitle = () => {
    if (pathname.includes("/clinician/food-analysis")) return "FOOD ANALYSIS & USDA TSH/T3/T4 DISTRIBUTION";
    if (pathname.includes("/clinician/search")) return "PATIENT DIRECTORY & SEARCH";
    if (pathname.includes("/clinician/monitoring")) return "PATIENT MONITORING & ALERT SURVEILLANCE";
    if (pathname.includes("/clinician/notifications")) return "CLINICAL NOTIFICATIONS";
    if (pathname.includes("/clinician/reports")) return "CLINICAL REPORTS & PDF GENERATOR";
    if (pathname.includes("/clinician/data")) return "ANALYTICS & POPULATION DATA";
    if (pathname.includes("/clinician/users")) return "PRACTICE USER MANAGEMENT";
    if (pathname.includes("/clinician/settings")) return "CLINICAL SETTINGS";
    if (pathname.includes("/clinician/patients/")) return "PATIENT CLINICAL RECORD";
    return "THYROCARE DASHBOARD";
  };

  return (
    <header className="bg-slate-900 border-b border-slate-800 text-white h-14 sticky top-0 z-40 shadow-xs flex items-center justify-between px-6 font-sans">
      
      {/* Left: Page Context Title */}
      <div className="flex items-center space-x-3">
        <span className="text-xs font-mono font-bold text-teal-400 uppercase tracking-wider bg-teal-950 px-2 py-0.5 rounded border border-teal-800">
          Clinical Portal
        </span>
        <h1 className="text-sm font-extrabold text-white tracking-wide uppercase">
          {getPageTitle()}
        </h1>
      </div>

      {/* Right: Practice & User Credentials */}
      <div className="flex items-center space-x-4">
        
        {/* Practice Selector */}
        <div className="hidden sm:flex items-center space-x-2 text-xs font-semibold text-slate-300 bg-slate-800 hover:bg-slate-700/80 px-3 py-1.5 rounded-md border border-slate-700 cursor-pointer transition-colors">
          <UserCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span>Endocrinology Practice</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>

        {/* Notifications Shortcut */}
        <Link 
          href="/clinician/notifications" 
          className="relative text-slate-300 hover:text-white p-1.5 rounded-md hover:bg-slate-800 transition-colors"
          title="View Notifications"
        >
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-teal-400 animate-pulse" />
        </Link>

        {/* Clinician Profile Dropdown */}
        <div className="flex items-center space-x-2.5 pl-3 border-l border-slate-800 cursor-pointer">
          <div className="w-7 h-7 rounded-full bg-teal-700 text-white font-bold text-xs flex items-center justify-center border border-teal-500/40">
            JS
          </div>
          <div className="text-xs font-semibold text-slate-200 hidden md:block">
            Dr. Jane Smith
          </div>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>

      </div>
    </header>
  );
}
