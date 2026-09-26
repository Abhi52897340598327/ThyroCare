"use client";

import { useState, useRef } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  Activity, 
  Eye, 
  Bell, 
  Search, 
  Utensils, 
  FileText, 
  BarChart3, 
  Users, 
  Settings, 
  Pin, 
  PinOff,
  ChevronRight
} from "lucide-react";

export default function ClinicalSidebar() {
  const pathname = usePathname();
  const [isHovered, setIsHovered] = useState(false);
  const [isFocused, setIsFocused] = useState(false);
  const [isPinned, setIsPinned] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const isExpanded = isPinned || isHovered || isFocused;

  const handleMouseEnter = () => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    setIsHovered(true);
  };

  const handleMouseLeave = () => {
    timeoutRef.current = setTimeout(() => {
      setIsHovered(false);
    }, 180);
  };

  const navGroups = [
    {
      title: "OVERVIEW",
      items: [
        { label: "Dashboard", href: "/clinician", icon: Activity },
        { label: "Monitoring", href: "/clinician/monitoring", icon: Eye },
        { label: "Notifications", href: "/clinician/notifications", icon: Bell },
      ]
    },
    {
      title: "PATIENT CARE",
      items: [
        { label: "Patient Search", href: "/clinician/search", icon: Search },
        { label: "Food Analysis", href: "/clinician/food-analysis", icon: Utensils },
        { label: "Reports", href: "/clinician/reports", icon: FileText },
      ]
    },
    {
      title: "SYSTEM",
      items: [
        { label: "Data", href: "/clinician/data", icon: BarChart3 },
        { label: "Users", href: "/clinician/users", icon: Users },
        { label: "Settings", href: "/clinician/settings", icon: Settings },
      ]
    }
  ];

  return (
    <>
      {/* Slim Rail Spacer for Document Flow */}
      <div className={`shrink-0 transition-all duration-200 ${isPinned ? "w-[252px]" : "w-[68px]"}`} />

      {/* Floating Expanding Left Rail */}
      <aside
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleMouseLeave}
        onFocus={() => setIsFocused(true)}
        onBlur={() => setIsFocused(false)}
        className={`fixed top-0 left-0 bottom-0 z-50 bg-[#08111F] text-slate-200 border-r border-[#203049] shadow-2xl flex flex-col justify-between transition-all duration-200 ease-[cubic-bezier(0.4,0,0.2,1)] backdrop-blur-md overflow-hidden ${
          isExpanded ? "w-[252px]" : "w-[68px]"
        }`}
      >
        {/* Top Branding Section */}
        <div className="p-4 border-b border-[#203049] flex items-center justify-between h-14 shrink-0">
          <Link href="/clinician" className="flex items-center space-x-3 overflow-hidden">
            <div className="w-9 h-9 rounded-md bg-teal-950 border border-teal-600/50 flex items-center justify-center shrink-0 p-1">
              <img src="/thyrocare-logo.png" alt="ThyroCare Logo" className="w-full h-full object-contain" />
            </div>

            <div className={`transition-opacity duration-150 whitespace-nowrap ${isExpanded ? "opacity-100" : "opacity-0 pointer-events-none"}`}>
              <span className="font-extrabold text-sm tracking-wider text-white block">
                THYROCARE
              </span>
              <span className="text-[10px] font-mono text-teal-400 font-bold uppercase tracking-widest block">
                DASHBOARD
              </span>
            </div>
          </Link>

          {isExpanded && (
            <button
              onClick={() => setIsPinned(!isPinned)}
              title={isPinned ? "Unpin sidebar" : "Pin sidebar expanded"}
              className="text-slate-400 hover:text-teal-400 p-1 rounded transition-colors"
            >
              {isPinned ? <PinOff className="w-4 h-4 text-teal-400" /> : <Pin className="w-4 h-4" />}
            </button>
          )}
        </div>

        {/* Navigation Sections */}
        <div className="flex-1 py-4 px-2 space-y-6 overflow-y-auto scrollbar-none">
          {navGroups.map((group) => (
            <div key={group.title} className="space-y-1">
              {isExpanded && (
                <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-widest px-3 block mb-1">
                  {group.title}
                </span>
              )}

              {group.items.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href || (item.href !== "/clinician" && pathname.startsWith(item.href));

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`relative flex items-center h-10 px-3 rounded-lg text-xs font-medium transition-all group ${
                      isActive
                        ? "bg-[#111D30] text-white font-bold border border-teal-500/30 shadow-xs"
                        : "text-slate-300 hover:bg-[#0D1728] hover:text-white"
                    }`}
                  >
                    {/* Active Left Indicator Strip */}
                    {isActive && (
                      <span className="absolute left-0 top-1.5 bottom-1.5 w-1 bg-[#18B6A4] rounded-r-md shadow-[0_0_8px_#18B6A4]" />
                    )}

                    <Icon
                      className={`w-4 h-4 shrink-0 transition-colors ${
                        isActive ? "text-[#18B6A4]" : "text-slate-400 group-hover:text-slate-200"
                      }`}
                    />

                    <span
                      className={`ml-3 whitespace-nowrap transition-all duration-150 ${
                        isExpanded ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-2 pointer-events-none"
                      }`}
                    >
                      {item.label}
                    </span>

                    {/* Tooltip in collapsed mode */}
                    {!isExpanded && (
                      <div className="absolute left-16 bg-[#0D1728] text-white text-[11px] font-semibold px-2.5 py-1 rounded border border-[#203049] shadow-lg opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
                        {item.label}
                      </div>
                    )}
                  </Link>
                );
              })}
            </div>
          ))}
        </div>

        {/* Bottom User Indicator */}
        <div className="p-3 border-t border-[#203049] bg-[#060D18] flex items-center space-x-3 shrink-0">
          <div className="w-8 h-8 rounded-full bg-teal-700 text-white font-bold text-xs flex items-center justify-center shrink-0 border border-teal-500/40">
            JS
          </div>
          <div className={`transition-opacity duration-150 whitespace-nowrap text-xs ${isExpanded ? "opacity-100" : "opacity-0 pointer-events-none"}`}>
            <span className="font-bold text-white block">Dr. Jane Smith</span>
            <span className="text-[10px] text-slate-400 block font-mono">Endocrinology Practice</span>
          </div>
        </div>
      </aside>
    </>
  );
}
