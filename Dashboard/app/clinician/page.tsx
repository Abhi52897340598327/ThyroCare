"use client";

import { useState } from "react";
import Link from "next/link";
import ClinicalTopNav from "@/components/ClinicalTopNav";
import { MOCK_PATIENTS, PatientProfile } from "@/lib/demoData";
import { 
  Users, 
  AlertTriangle, 
  Clock, 
  Calendar, 
  Search, 
  TrendingUp, 
  TrendingDown, 
  Minus, 
  ArrowRight,
  Stethoscope,
  Filter,
  ArrowUpDown
} from "lucide-react";

export default function GlobalClinicianDashboard() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [sortField, setSortField] = useState<keyof PatientProfile>("name");
  const [sortAsc, setSortAsc] = useState(true);

  // Filter patients
  const filteredPatients = MOCK_PATIENTS.filter(p => {
    const matchesSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          p.condition.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          p.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === "ALL" || p.status === statusFilter;
    return matchesSearch && matchesStatus;
  }).sort((a, b) => {
    let valA = a[sortField];
    let valB = b[sortField];
    if (typeof valA === "string") {
      return sortAsc ? valA.localeCompare(valB as string) : (valB as string).localeCompare(valA);
    }
    if (typeof valA === "number") {
      return sortAsc ? (valA as number) - (valB as number) : (valB as number) - (valA as number);
    }
    return 0;
  });

  const patientsRequiringReview = MOCK_PATIENTS.filter(p => p.status === "REVIEW SUGGESTED" || p.status === "TREND CHANGE" || p.status === "NEW LAB RESULT");

  const getStatusBadge = (status: PatientProfile["status"]) => {
    switch (status) {
      case "STABLE":
        return <span className="bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded text-[11px] font-semibold">STABLE</span>;
      case "REVIEW SUGGESTED":
        return <span className="bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded text-[11px] font-semibold">REVIEW SUGGESTED</span>;
      case "NEW LAB RESULT":
        return <span className="bg-blue-50 text-blue-700 border border-blue-200 px-2 py-0.5 rounded text-[11px] font-semibold">NEW LAB RESULT</span>;
      case "FOLLOW-UP REQUESTED":
        return <span className="bg-purple-50 text-purple-700 border border-purple-200 px-2 py-0.5 rounded text-[11px] font-semibold">FOLLOW-UP REQUESTED</span>;
      case "TREND CHANGE":
        return <span className="bg-orange-50 text-orange-700 border border-orange-200 px-2 py-0.5 rounded text-[11px] font-semibold">TREND CHANGE</span>;
      default:
        return <span className="bg-slate-100 text-slate-700 border border-slate-300 px-2 py-0.5 rounded text-[11px] font-semibold">INSUFFICIENT DATA</span>;
    }
  };

  const getTrendIcon = (trend: PatientProfile["trend"]) => {
    if (trend === "Increasing") return <TrendingUp className="w-3.5 h-3.5 text-amber-600 inline ml-1" />;
    if (trend === "Decreasing") return <TrendingDown className="w-3.5 h-3.5 text-emerald-600 inline ml-1" />;
    return <Minus className="w-3.5 h-3.5 text-slate-400 inline ml-1" />;
  };

  const toggleSort = (field: keyof PatientProfile) => {
    if (sortField === field) {
      setSortAsc(!sortAsc);
    } else {
      setSortField(field);
      setSortAsc(true);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col font-sans text-slate-900">
      <ClinicalTopNav />

      <main className="flex-1 max-w-[1920px] w-full mx-auto p-6 space-y-6">
        
        {/* Clinician Welcome Banner */}
        <div className="bg-slate-900 text-white rounded-lg p-6 shadow-md border border-slate-800 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white flex items-center space-x-2">
              <Stethoscope className="w-5 h-5 text-teal-400" />
              <span>GOOD EVENING, DR. SMITH</span>
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Endocrinology Clinical Patient Dashboard — Active Population Surveillance
            </p>
          </div>

          <div className="flex items-center space-x-4">
            <Link
              href="/clinician/search"
              className="bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold px-4 py-2 rounded shadow-xs transition-colors flex items-center space-x-1.5"
            >
              <Search className="w-3.5 h-3.5" />
              <span>Patient Quick Search</span>
            </Link>
          </div>
        </div>

        {/* Population Summary Metrics */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs flex items-center space-x-4">
            <div className="p-3 bg-teal-50 rounded-lg border border-teal-100 text-teal-700">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <span className="text-xs font-medium text-slate-500 block uppercase">Active Patients</span>
              <span className="text-2xl font-black text-slate-900">10 <span className="text-xs font-normal text-slate-500">(Demographic Pool)</span></span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs flex items-center space-x-4">
            <div className="p-3 bg-amber-50 rounded-lg border border-amber-100 text-amber-700">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <span className="text-xs font-medium text-slate-500 block uppercase">Review Suggested</span>
              <span className="text-2xl font-black text-amber-700">4</span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs flex items-center space-x-4">
            <div className="p-3 bg-blue-50 rounded-lg border border-blue-100 text-blue-700">
              <Clock className="w-6 h-6" />
            </div>
            <div>
              <span className="text-xs font-medium text-slate-500 block uppercase">New Lab Results</span>
              <span className="text-2xl font-black text-blue-700">3</span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-xs flex items-center space-x-4">
            <div className="p-3 bg-purple-50 rounded-lg border border-purple-100 text-purple-700">
              <Calendar className="w-6 h-6" />
            </div>
            <div>
              <span className="text-xs font-medium text-slate-500 block uppercase">Follow-Ups Pending</span>
              <span className="text-2xl font-black text-purple-700">2</span>
            </div>
          </div>
        </div>

        {/* High-Priority Review Queue */}
        <div className="bg-white rounded-lg border border-amber-200 shadow-xs overflow-hidden">
          <div className="bg-amber-50/80 px-6 py-3 border-b border-amber-200 flex items-center justify-between">
            <div className="flex items-center space-x-2 text-amber-900 font-bold text-sm">
              <AlertTriangle className="w-4 h-4 text-amber-600" />
              <span>PATIENTS REQUIRING IMMEDIATE CLINICAL REVIEW ({patientsRequiringReview.length})</span>
            </div>
            <span className="text-xs text-amber-800 font-medium">Surveillance queue updated live</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
            {patientsRequiringReview.map((patient) => (
              <div key={patient.id} className="border border-amber-200 rounded-md p-3.5 bg-amber-50/30 hover:bg-amber-50/70 transition-colors flex flex-col justify-between space-y-3">
                <div>
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-xs text-slate-900 uppercase">{patient.name}</h3>
                    {getStatusBadge(patient.status)}
                  </div>
                  <p className="text-[11px] text-slate-600 mt-1">{patient.condition}</p>
                  
                  <div className="mt-2 text-xs font-semibold text-slate-800 flex items-center justify-between bg-white p-2 rounded border border-amber-100">
                    <span>TSH: <strong>{patient.latestTSH} mIU/L</strong> {getTrendIcon(patient.trend)}</span>
                    <span className="text-[10px] text-slate-500 font-normal">{patient.lastLabDate}</span>
                  </div>
                </div>

                <Link
                  href={`/clinician/patients/${patient.id}`}
                  className="w-full bg-slate-900 hover:bg-teal-700 text-white text-xs font-semibold py-1.5 px-3 rounded flex items-center justify-center space-x-1 transition-colors"
                >
                  <span>Open Patient Workspace</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            ))}
          </div>
        </div>

        {/* Main Population Patient Table */}
        <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-200 flex flex-wrap items-center justify-between gap-4 bg-slate-50">
            <div>
              <h2 className="font-bold text-sm text-slate-900 uppercase">Assigned Patient Population</h2>
              <p className="text-xs text-slate-500">Select any patient to transition into their dedicated clinical workspace.</p>
            </div>

            <div className="flex items-center space-x-3">
              {/* Search Bar */}
              <div className="relative">
                <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5" />
                <input
                  type="text"
                  placeholder="Search by name or condition..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-9 pr-3 py-1.5 bg-white border border-slate-300 rounded text-xs focus:outline-none focus:ring-2 focus:ring-teal-500 w-64"
                />
              </div>

              {/* Filter Dropdown */}
              <div className="flex items-center space-x-1 text-xs">
                <Filter className="w-3.5 h-3.5 text-slate-500" />
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="bg-white border border-slate-300 rounded px-2 py-1.5 text-xs focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
                >
                  <option value="ALL">All Review Statuses</option>
                  <option value="REVIEW SUGGESTED">Review Suggested</option>
                  <option value="STABLE">Stable</option>
                  <option value="NEW LAB RESULT">New Lab Result</option>
                  <option value="TREND CHANGE">Trend Change</option>
                  <option value="FOLLOW-UP REQUESTED">Follow-up Requested</option>
                  <option value="INSUFFICIENT DATA">Insufficient Data</option>
                </select>
              </div>
            </div>
          </div>

          {/* Table */}
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead className="bg-slate-100 text-slate-700 uppercase font-semibold text-[11px] border-b border-slate-200">
                <tr>
                  <th className="py-3 px-4 cursor-pointer hover:bg-slate-200" onClick={() => toggleSort("name")}>
                    <div className="flex items-center space-x-1">
                      <span>Patient Name</span>
                      <ArrowUpDown className="w-3 h-3 text-slate-400" />
                    </div>
                  </th>
                  <th className="py-3 px-4">Condition</th>
                  <th className="py-3 px-4 cursor-pointer hover:bg-slate-200" onClick={() => toggleSort("latestTSH")}>
                    <div className="flex items-center space-x-1">
                      <span>Latest TSH</span>
                      <ArrowUpDown className="w-3 h-3 text-slate-400" />
                    </div>
                  </th>
                  <th className="py-3 px-4">Trend</th>
                  <th className="py-3 px-4">Last Lab</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Next Visit</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 font-medium">
                {filteredPatients.map((patient) => (
                  <tr key={patient.id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3 px-4 font-bold text-slate-900">
                      <Link href={`/clinician/patients/${patient.id}`} className="hover:text-teal-600 hover:underline">
                        {patient.name}
                      </Link>
                      <span className="block text-[10px] text-slate-400 font-normal">{patient.age} yrs | {patient.sex}</span>
                    </td>
                    <td className="py-3 px-4 text-slate-600">{patient.condition}</td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {patient.latestTSH} <span className="text-[10px] font-normal text-slate-500">mIU/L</span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center text-xs font-semibold">
                        {patient.trend} {getTrendIcon(patient.trend)}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-600">{patient.lastLabDate}</td>
                    <td className="py-3 px-4">{getStatusBadge(patient.status)}</td>
                    <td className="py-3 px-4 text-teal-700 font-semibold">{patient.nextVisit}</td>
                    <td className="py-3 px-4 text-right">
                      <Link
                        href={`/clinician/patients/${patient.id}`}
                        className="inline-flex items-center space-x-1 bg-teal-700 hover:bg-teal-800 text-white text-[11px] font-semibold px-3 py-1.5 rounded transition-colors"
                      >
                        <span>Open Record</span>
                        <ArrowRight className="w-3 h-3" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </main>
    </div>
  );
}
