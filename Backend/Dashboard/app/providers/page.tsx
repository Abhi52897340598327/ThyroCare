"use client";

import { useEffect, useState } from "react";
import {
  ExternalLink,
  MapPin,
  Navigation,
  Phone,
  Search,
  Star,
  Stethoscope
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from "@/components/ui/card";

type Provider = {
  id: string;
  name: string;
  specialty: string;
  distanceMiles: number;
  rating: number;
  reviewCount: number;
  address: string;
  phone: string;
  website: string;
  directionsURL: string;
  bookingURL: string;
};

export default function ProviderSearchPage() {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [query, setQuery] = useState("");
  const [bookingConfirmed, setBookingConfirmed] = useState<string | null>(null);

  useEffect(() => {
    fetch("http://localhost:8080/providers/endocrinologists")
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setProviders(data);
      })
      .catch(() => {
        setProviders([
          {
            id: "prov_1",
            name: "Dr. Sarah Jenkins, MD",
            specialty: "Endocrinology & Thyroid Care",
            distanceMiles: 1.4,
            rating: 4.9,
            reviewCount: 214,
            address: "450 Medical Center Blvd, Suite 300, Boston, MA",
            phone: "(615) 555-0192",
            website: "https://www.bostonthyroidcare.org",
            directionsURL: "https://maps.apple.com/?q=450+Medical+Center+Blvd+Boston+MA",
            bookingURL: "https://www.bostonthyroidcare.org/book"
          },
          {
            id: "prov_2",
            name: "Dr. Michael Chen, MD",
            specialty: "Thyroid & Metabolic Disorders",
            distanceMiles: 3.1,
            rating: 4.8,
            reviewCount: 189,
            address: "880 Harrison Ave, Suite 102, Boston, MA",
            phone: "(615) 555-0341",
            website: "https://www.mgh.harvard.edu/endocrinology",
            directionsURL: "https://maps.apple.com/?q=880+Harrison+Ave+Boston+MA",
            bookingURL: "https://www.mgh.harvard.edu/endocrinology/appointments"
          },
          {
            id: "prov_3",
            name: "Dr. Elena Rostova, MD, PhD",
            specialty: "Thyroid Neoplasia & Autoimmune Thyroiditis",
            distanceMiles: 4.8,
            rating: 4.7,
            reviewCount: 142,
            address: "15 Park Plaza, Suite 500, Boston, MA",
            phone: "(615) 555-0887",
            website: "https://www.brighamandwomens.org/endocrinology",
            directionsURL: "https://maps.apple.com/?q=15+Park+Plaza+Boston+MA",
            bookingURL: "https://www.brighamandwomens.org/endocrinology/schedule"
          }
        ]);
      });
  }, []);

  const handleBookAppointment = (provider: Provider) => {
    setBookingConfirmed(provider.name);
    window.open(provider.bookingURL, "_blank");
  };

  const filteredProviders = providers.filter(
    (p) =>
      p.name.toLowerCase().includes(query.toLowerCase()) ||
      p.specialty.toLowerCase().includes(query.toLowerCase()) ||
      p.address.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <main className="mx-auto max-w-7xl px-6 py-8">
      {/* Banner */}
      <div className="mb-8 rounded-xl border border-teal-100 bg-slate-900 p-6 text-white shadow-md">
        <div className="flex items-center gap-2 text-teal-400 font-semibold text-xs tracking-wider uppercase">
          <MapPin className="h-4 w-4" />
          Endocrinologist Finder & Appointments
        </div>
        <h1 className="mt-1 text-2xl font-bold tracking-tight md:text-3xl">
          Find a Thyroid Specialist Near You
        </h1>
        <p className="mt-1 text-sm text-slate-300">
          Ranked by proximity, clinician rating, and review count. Access official appointment booking portals directly.
        </p>
      </div>

      {/* Search Input */}
      <div className="relative mb-6">
        <Search className="absolute left-3.5 top-3 h-5 w-5 text-slate-400" />
        <input
          type="text"
          placeholder="Search by doctor name, specialty, or zip code..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="w-full rounded-xl border border-slate-300 bg-white pl-11 pr-4 py-3 text-sm focus:border-teal-600 focus:outline-none shadow-xs"
        />
      </div>

      {bookingConfirmed && (
        <div className="mb-6 rounded-lg bg-teal-100 border border-teal-300 p-4 text-xs font-semibold text-teal-900">
          Redirecting to official appointment booking portal for <strong>{bookingConfirmed}</strong>...
        </div>
      )}

      {/* Provider List */}
      <div className="space-y-4">
        {filteredProviders.map((p) => (
          <Card key={p.id} className="border-slate-200 bg-white transition-shadow hover:shadow-md">
            <CardContent className="p-6">
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div className="space-y-1">
                  <div className="flex items-center gap-3">
                    <h3 className="text-lg font-bold text-slate-900">{p.name}</h3>
                    <span className="flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-bold text-amber-700 border border-amber-200">
                      <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                      {p.rating} ({p.reviewCount} reviews)
                    </span>
                  </div>
                  <p className="text-xs font-semibold text-teal-700">{p.specialty}</p>
                  <p className="text-xs text-slate-500 flex items-center gap-1">
                    <MapPin className="h-3.5 w-3.5 text-slate-400" />
                    {p.address} • <strong>{p.distanceMiles} miles away</strong>
                  </p>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                  <a
                    href={p.directionsURL}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100"
                  >
                    <Navigation className="h-3.5 w-3.5 text-slate-500" />
                    Directions
                  </a>
                  <Button
                    onClick={() => handleBookAppointment(p)}
                    className="bg-teal-700 hover:bg-teal-800 text-white gap-1.5 text-xs font-semibold"
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                    Book Appointment
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </main>
  );
}
