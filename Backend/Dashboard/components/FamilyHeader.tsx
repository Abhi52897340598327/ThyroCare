"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Heart, Users, FileText, Calendar, Settings, ShieldCheck, MapPin } from "lucide-react";

export default function FamilyHeader() {
  const pathname = usePathname();

  const navItems = [
    { label: "Family", href: "/family", icon: Users },
    { label: "Reports", href: "/family/reports", icon: FileText },
    { label: "Appointments", href: "/family/appointments", icon: Calendar },
    { label: "Settings", href: "/family/settings", icon: Settings },
  ];

  return (
    <header className="bg-slate-900 border-b border-slate-800 text-white sticky top-0 z-50 font-sans shadow-md">
      <div className="max-w-[1600px] mx-auto px-4 sm:px-6 h-14 flex items-center justify-between">
        
        {/* Brand */}
        <Link href="/family" className="flex items-center space-x-3 group">
          <div className="w-8 h-8 rounded-md bg-teal-950 border border-teal-600/50 flex items-center justify-center p-1">
            <img src="/thyrocare-logo.png" alt="ThyroCare Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <span className="font-extrabold text-sm tracking-wider text-white block leading-tight">
              THYROCARE
            </span>
            <span className="text-[10px] font-mono text-teal-400 font-bold uppercase tracking-widest block leading-tight">
              FAMILY PORTAL
            </span>
          </div>
        </Link>

        {/* Primary Navigation Tabs */}
        <nav className="flex items-center space-x-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || (item.href !== "/family" && pathname.startsWith(item.href));

            return (
              <Link
                key={item.label}
                href={item.href}
                className={`relative flex items-center space-x-2 px-3.5 py-1.5 rounded-md text-xs font-semibold transition-all ${
                  isActive
                    ? "bg-teal-600 text-white shadow-xs font-bold border border-teal-500"
                    : "text-slate-300 hover:bg-slate-800 hover:text-white"
                }`}
              >
                {isActive && (
                  <span className="absolute -bottom-1 left-2 right-2 h-0.5 bg-teal-400 rounded-full" />
                )}
                <Icon className={`w-4 h-4 ${isActive ? "text-white" : "text-slate-400"}`} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        {/* Caregiver Account Info */}
        <div className="hidden md:flex items-center space-x-3 text-xs text-slate-300 pl-4 border-l border-slate-800">
          <div className="flex items-center space-x-1.5 bg-slate-800 px-2.5 py-1 rounded border border-slate-700">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
            <span className="text-slate-200">Authorized Caregiver: <strong className="text-white">Suresh Venigalla</strong></span>
          </div>
        </div>

      </div>
    </header>
  );
}
