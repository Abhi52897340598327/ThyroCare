"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Activity,
  Bug,
  MapPin,
  ShieldAlert,
  Stethoscope,
  Users
} from "lucide-react";

export function Navbar() {
  const pathname = usePathname();

  const navItems = [
    {
      href: "/clinician",
      label: "Clinician Portal",
      icon: Stethoscope
    },
    {
      href: "/family",
      label: "Family Portal",
      icon: Users
    },
    {
      href: "/patient",
      label: "Patient Timeline & Reports",
      icon: Activity
    },
    {
      href: "/providers",
      label: "Find Endocrinologist",
      icon: MapPin
    },
    {
      href: "/debug",
      label: "Debug & Telemetry",
      icon: Bug,
      highlight: true
    }
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-4 md:flex-row md:items-center md:justify-between">
        <Link href="/clinician" className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-teal-700 text-white shadow-sm">
            <Stethoscope className="h-5 w-5" />
          </div>
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-teal-700">
              ThyroCare V3
            </span>
            <h1 className="text-lg font-semibold tracking-tight text-slate-900">
              Clinical Platform
            </h1>
          </div>
        </Link>

        <nav className="flex flex-wrap items-center gap-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive =
              pathname === item.href ||
              (item.href === "/clinician" && pathname === "/");

            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-teal-50 text-teal-800 font-semibold border border-teal-200/80 shadow-xs"
                    : item.highlight
                    ? "text-amber-700 hover:bg-amber-50 font-semibold"
                    : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                }`}
              >
                <Icon
                  className={`h-4 w-4 ${
                    isActive
                      ? "text-teal-700"
                      : item.highlight
                      ? "text-amber-600"
                      : "text-slate-400"
                  }`}
                />
                <span>{item.label}</span>
                {item.highlight && (
                  <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold text-amber-800">
                    Separate Link
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>
    </header>
  );
}
