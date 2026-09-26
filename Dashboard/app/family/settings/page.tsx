"use client";

import { useState } from "react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { 
  Settings, 
  User, 
  Users, 
  Bell, 
  ShieldCheck, 
  Sun, 
  Key, 
  Check, 
  Save 
} from "lucide-react";

export default function FamilySettingsPage() {
  const [caregiverName, setCaregiverName] = useState("Suresh Venigalla");
  const [email, setEmail] = useState("suresh.v@thyrocare.org");
  const [phone, setPhone] = useState("(617) 555-0192");
  const [labAlerts, setLabAlerts] = useState(true);
  const [appointmentReminders, setAppointmentReminders] = useState(true);
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <FamilyAppShell>
      <div className="space-y-6 max-w-5xl mx-auto">
        
        {/* Header */}
        <div className="bg-white rounded-lg border border-slate-200 p-5 shadow-xs flex items-center justify-between">
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-teal-100 text-teal-800 text-[11px] font-extrabold uppercase px-2.5 py-0.5 rounded border border-teal-200">
                Caregiver Preferences
              </span>
            </div>
            <h1 className="text-xl font-extrabold text-slate-900 mt-1 uppercase tracking-tight flex items-center space-x-2">
              <Settings className="w-5 h-5 text-teal-700" />
              <span>FAMILY PORTAL SETTINGS & ACCESS CONTROL</span>
            </h1>
            <p className="text-xs text-slate-600 mt-0.5">
              Manage caregiver profile details, family linking consent, notification alerts, and security preferences.
            </p>
          </div>
        </div>

        {/* Form Container */}
        <form onSubmit={handleSave} className="space-y-6">
          
          {/* Section 1: Caregiver Profile */}
          <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-xs space-y-4">
            <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2 border-b border-slate-200 pb-3">
              <User className="w-4 h-4 text-teal-700" />
              <span>Primary Caregiver Account Information</span>
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div>
                <label className="block text-slate-700 font-bold mb-1">Full Legal Name</label>
                <input
                  type="text"
                  value={caregiverName}
                  onChange={(e) => setCaregiverName(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded px-3 py-2 text-slate-900 font-medium focus:outline-none focus:border-teal-600"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">Email Address</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded px-3 py-2 text-slate-900 font-medium focus:outline-none focus:border-teal-600"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">Mobile Phone for SMS Notifications</label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded px-3 py-2 text-slate-900 font-medium focus:outline-none focus:border-teal-600"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-bold mb-1">Account Role</label>
                <input
                  type="text"
                  disabled
                  value="Authorized Family Caregiver (Full Proxy)"
                  className="w-full bg-slate-100 border border-slate-200 text-slate-500 rounded px-3 py-2 font-semibold"
                />
              </div>
            </div>
          </div>

          {/* Section 2: Family Access & Consent */}
          <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-xs space-y-4">
            <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2 border-b border-slate-200 pb-3">
              <Users className="w-4 h-4 text-teal-700" />
              <span>Family Access & Linking Consent</span>
            </h2>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 border border-slate-200 rounded flex justify-between items-center">
                <div>
                  <span className="font-bold text-slate-900 block">Abhiraam Venigalla</span>
                  <span className="text-slate-500">Full Record Consent • Valid through Sep 2027</span>
                </div>
                <span className="bg-emerald-100 text-emerald-800 font-bold text-[10px] px-2 py-0.5 rounded border border-emerald-300">
                  ACTIVE PROXY
                </span>
              </div>

              <div className="p-3 bg-slate-50 border border-slate-200 rounded flex justify-between items-center">
                <div>
                  <span className="font-bold text-slate-900 block">Mother (Family Record)</span>
                  <span className="text-slate-500">Labs & Trends Consent • Valid through Dec 2026</span>
                </div>
                <span className="bg-emerald-100 text-emerald-800 font-bold text-[10px] px-2 py-0.5 rounded border border-emerald-300">
                  ACTIVE PROXY
                </span>
              </div>
            </div>
          </div>

          {/* Section 3: Notification Preferences */}
          <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-xs space-y-4">
            <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-2 border-b border-slate-200 pb-3">
              <Bell className="w-4 h-4 text-teal-700" />
              <span>Notification & Alert Preferences</span>
            </h2>

            <div className="space-y-3 text-xs">
              <label className="flex items-center justify-between p-3 bg-slate-50 rounded border border-slate-200 cursor-pointer">
                <div>
                  <span className="font-bold text-slate-900 block">Immediate Lab Result Alerts</span>
                  <span className="text-slate-500">Receive SMS and email notifications when new TSH/T4 lab results are published.</span>
                </div>
                <input
                  type="checkbox"
                  checked={labAlerts}
                  onChange={(e) => setLabAlerts(e.target.checked)}
                  className="w-4 h-4 text-teal-600 rounded focus:ring-teal-500"
                />
              </label>

              <label className="flex items-center justify-between p-3 bg-slate-50 rounded border border-slate-200 cursor-pointer">
                <div>
                  <span className="font-bold text-slate-900 block">Appointment Reminders</span>
                  <span className="text-slate-500">Send reminder notifications 48 hours and 2 hours prior to scheduled clinic visits.</span>
                </div>
                <input
                  type="checkbox"
                  checked={appointmentReminders}
                  onChange={(e) => setAppointmentReminders(e.target.checked)}
                  className="w-4 h-4 text-teal-600 rounded focus:ring-teal-500"
                />
              </label>
            </div>
          </div>

          {/* Submit Action */}
          <div className="flex items-center justify-end space-x-3 pt-2">
            <button
              type="submit"
              className="bg-teal-700 hover:bg-teal-800 text-white text-xs font-bold px-6 py-2.5 rounded-lg flex items-center space-x-2 shadow-xs transition-colors"
            >
              {saved ? <Check className="w-4 h-4 text-emerald-300" /> : <Save className="w-4 h-4" />}
              <span>{saved ? "Settings Saved!" : "Save Settings"}</span>
            </button>
          </div>

        </form>
      </div>
    </FamilyAppShell>
  );
}
