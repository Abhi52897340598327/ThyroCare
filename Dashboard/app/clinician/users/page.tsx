"use client";

import ClinicalTopNav from "@/components/ClinicalTopNav";
import { Users, ShieldCheck } from "lucide-react";

export default function UsersPage() {
  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-xs space-y-4 text-xs">
          <h1 className="text-lg font-bold text-slate-900 uppercase flex items-center space-x-2">
            <Users className="w-5 h-5 text-teal-600" />
            <span>CLINICAL USER ROLES & ACCESS CONTROL</span>
          </h1>

          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-100 text-slate-600 uppercase font-semibold text-[10px] border-b border-slate-200">
              <tr>
                <th className="py-2.5 px-4">User Name</th>
                <th className="py-2.5 px-4">Role</th>
                <th className="py-2.5 px-4">Access Level</th>
                <th className="py-2.5 px-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 font-medium">
              <tr>
                <td className="py-3 px-4 font-bold text-slate-900">Dr. Jane Smith, MD</td>
                <td className="py-3 px-4 text-teal-800 font-bold">Attending Endocrinologist</td>
                <td className="py-3 px-4 text-slate-700">Full Prescribing & Clinical Access</td>
                <td className="py-3 px-4"><span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px]">ACTIVE</span></td>
              </tr>
              <tr>
                <td className="py-3 px-4 font-bold text-slate-900">Nurse Sarah Connor, RN</td>
                <td className="py-3 px-4 text-slate-800 font-semibold">Clinical Nurse Coordinator</td>
                <td className="py-3 px-4 text-slate-700">Triage & Patient Communication</td>
                <td className="py-3 px-4"><span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded text-[10px]">ACTIVE</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
