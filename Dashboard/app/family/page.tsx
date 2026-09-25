"use client";

import { useEffect, useState } from "react";
import {
  Heart,
  Plus,
  Shield,
  ShieldCheck,
  Trash2,
  UserCheck,
  Users
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from "@/components/ui/card";

type FamilyLink = {
  id: string;
  ownerUserId: string;
  linkedUserId: string;
  linkedUserName: string;
  relationship: string;
  permissionLevel: string;
  grantedAt: string;
};

export default function FamilyPortalPage() {
  const [links, setLinks] = useState<FamilyLink[]>([]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [name, setName] = useState("");
  const [relationship, setRelationship] = useState("Mother");
  const [permission, setPermission] = useState("VIEW_SUMMARY");

  useEffect(() => {
    fetch("http://localhost:8080/family-links")
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setLinks(data);
      })
      .catch(() => {
        setLinks([
          {
            id: "fam_1",
            ownerUserId: "P-1001",
            linkedUserId: "P-1002",
            linkedUserName: "Mother Venigalla",
            relationship: "Mother",
            permissionLevel: "VIEW_SUMMARY",
            grantedAt: "2026-05-10"
          },
          {
            id: "fam_2",
            ownerUserId: "P-1001",
            linkedUserId: "P-1003",
            linkedUserName: "Leo Venigalla (Child)",
            relationship: "Child",
            permissionLevel: "GUARDIAN_FULL_ACCESS",
            grantedAt: "2026-06-15"
          }
        ]);
      });
  }, []);

  const handleAddLink = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    const newLink: FamilyLink = {
      id: `fam_${Date.now()}`,
      ownerUserId: "P-1001",
      linkedUserId: `P-${Math.floor(1000 + Math.random() * 9000)}`,
      linkedUserName: name,
      relationship,
      permissionLevel: permission,
      grantedAt: new Date().toISOString().substring(0, 10)
    };

    try {
      await fetch("http://localhost:8080/family-links", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          linkedUserId: newLink.linkedUserId,
          linkedUserName: name,
          relationship,
          permissionLevel: permission
        })
      });
    } catch {
      // client update
    }

    setLinks((prev) => [newLink, ...prev]);
    setName("");
    setShowAddForm(false);
  };

  const handleDelete = async (id: string) => {
    setLinks((prev) => prev.filter((l) => l.id !== id));
    try {
      await fetch(`http://localhost:8080/family-links/${id}`, { method: "DELETE" });
    } catch {
      // offline fallback
    }
  };

  return (
    <main className="mx-auto max-w-7xl px-6 py-8">
      {/* Banner */}
      <div className="mb-8 rounded-xl border border-teal-100 bg-slate-900 p-6 text-white shadow-md">
        <div className="flex items-center gap-2 text-teal-400 font-semibold text-xs tracking-wider uppercase">
          <Users className="h-4 w-4" />
          Family & Parent Portal
        </div>
        <h1 className="mt-1 text-2xl font-bold tracking-tight md:text-3xl">
          Multi-Profile Family Care & Permissions
        </h1>
        <p className="mt-1 text-sm text-slate-300">
          Manage linked family profiles, view child/parent health summaries, and configure explicit access controls.
        </p>
      </div>

      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Linked Family Members</h2>
          <p className="text-xs text-slate-500">Profiles linked under your primary account</p>
        </div>
        <Button
          onClick={() => setShowAddForm(!showAddForm)}
          className="bg-teal-700 hover:bg-teal-800 text-white gap-2"
        >
          <Plus className="h-4 w-4" />
          {showAddForm ? "Cancel" : "Link Family Member"}
        </Button>
      </div>

      {showAddForm && (
        <Card className="mb-8 border-teal-200 bg-teal-50/40">
          <CardHeader>
            <CardTitle className="text-base text-slate-900">Link New Family Member</CardTitle>
            <CardDescription className="text-xs">
              Configure explicit consent permission level for this family link.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleAddLink} className="grid gap-4 sm:grid-cols-3">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Full Name</label>
                <input
                  type="text"
                  placeholder="e.g. Sarah Venigalla"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full rounded-md border bg-white p-2 text-sm focus:border-teal-600 focus:outline-none"
                  required
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Relationship</label>
                <select
                  value={relationship}
                  onChange={(e) => setRelationship(e.target.value)}
                  className="w-full rounded-md border bg-white p-2 text-sm focus:border-teal-600 focus:outline-none"
                >
                  <option value="Mother">Mother</option>
                  <option value="Father">Father</option>
                  <option value="Child">Child</option>
                  <option value="Spouse">Spouse</option>
                  <option value="Sibling">Sibling</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Permission Level</label>
                <select
                  value={permission}
                  onChange={(e) => setPermission(e.target.value)}
                  className="w-full rounded-md border bg-white p-2 text-sm focus:border-teal-600 focus:outline-none"
                >
                  <option value="VIEW_SUMMARY">View Summary Only</option>
                  <option value="VIEW_LABS">View Lab History</option>
                  <option value="VIEW_REPORTS">View Reports</option>
                  <option value="GUARDIAN_FULL_ACCESS">Guardian Full Access</option>
                </select>
              </div>
              <div className="sm:col-span-3">
                <Button type="submit" className="bg-teal-700 text-white w-full sm:w-auto">
                  Save Family Link
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Cards Grid */}
      <div className="grid gap-6 md:grid-cols-2">
        {links.map((link) => (
          <Card key={link.id} className="border-slate-200 bg-white">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-teal-100 text-teal-800 font-bold">
                    {link.linkedUserName.charAt(0)}
                  </div>
                  <div>
                    <CardTitle className="text-base font-bold text-slate-900">
                      {link.linkedUserName}
                    </CardTitle>
                    <CardDescription className="text-xs">
                      Relationship: {link.relationship} | ID: {link.linkedUserId}
                    </CardDescription>
                  </div>
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => handleDelete(link.id)}
                  className="text-slate-400 hover:text-red-600"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-3 pt-2 text-xs">
              <div className="flex items-center justify-between rounded-md bg-slate-50 p-2.5">
                <span className="flex items-center gap-1.5 text-slate-600 font-medium">
                  <ShieldCheck className="h-4 w-4 text-teal-700" />
                  Granted Access Level
                </span>
                <span className="rounded-full bg-teal-100 px-2.5 py-0.5 font-bold text-teal-800">
                  {link.permissionLevel}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-2 text-slate-600">
                <div className="rounded-md border p-2">
                  <p className="text-[10px] text-slate-400">Latest TSH Status</p>
                  <p className="font-bold text-slate-900 text-sm mt-0.5">2.45 mIU/L (Normal)</p>
                </div>
                <div className="rounded-md border p-2">
                  <p className="text-[10px] text-slate-400">Active Medication</p>
                  <p className="font-bold text-slate-900 text-sm mt-0.5">Levothyroxine 50 mcg</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </main>
  );
}
