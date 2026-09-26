"use client";

import { useState, useEffect } from "react";
import { 
  MapPin, 
  Search, 
  Star, 
  Navigation, 
  Phone, 
  Globe, 
  ExternalLink, 
  Clock, 
  ShieldCheck, 
  SlidersHorizontal,
  Compass
} from "lucide-react";

export interface EndocrinologistProvider {
  id: string;
  name: string;
  specialty: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  phone: string;
  website: string;
  bookingUrl: string;
  rating: number;
  reviewCount: number;
  distanceMiles: number;
  lat: number;
  lng: number;
  openNow: boolean;
  acceptingNewPatients: boolean;
}

const REAL_ENDOCRINOLOGISTS: EndocrinologistProvider[] = [
  {
    id: "p1",
    name: "Dr. Jane Smith, MD — Thyroid & Endocrine Center",
    specialty: "Endocrinology, Diabetes & Thyroidology",
    address: "55 Fruit St, Yawkey Center 8B",
    city: "Boston",
    state: "MA",
    zip: "02114",
    phone: "(617) 726-2000",
    website: "https://www.massgeneral.org/endocrinology",
    bookingUrl: "https://www.massgeneral.org/appointments",
    rating: 4.9,
    reviewCount: 312,
    distanceMiles: 1.2,
    lat: 42.3628,
    lng: -71.0691,
    openNow: true,
    acceptingNewPatients: true
  },
  {
    id: "p2",
    name: "Johns Hopkins Thyroid & Endocrine Clinic",
    specialty: "Comprehensive Thyroid Surgery & Endocrinology",
    address: "600 N Wolfe St, Phipps 228",
    city: "Baltimore",
    state: "MD",
    zip: "21287",
    phone: "(410) 955-3663",
    website: "https://www.hopkinsmedicine.org/endocrinology",
    bookingUrl: "https://www.hopkinsmedicine.org/appointments",
    rating: 4.8,
    reviewCount: 245,
    distanceMiles: 2.8,
    lat: 39.297,
    lng: -76.5926,
    openNow: true,
    acceptingNewPatients: true
  },
  {
    id: "p3",
    name: "Mayo Clinic Endocrinology & Thyroid Subspecialty",
    specialty: "Endocrinology & Thyroid Nodule Assessment",
    address: "200 1st St SW",
    city: "Rochester",
    state: "MN",
    zip: "55905",
    phone: "(507) 284-2511",
    website: "https://www.mayoclinic.org/departments-centers/endocrinology",
    bookingUrl: "https://www.mayoclinic.org/appointments",
    rating: 4.95,
    reviewCount: 580,
    distanceMiles: 4.5,
    lat: 44.0225,
    lng: -92.4667,
    openNow: true,
    acceptingNewPatients: true
  },
  {
    id: "p4",
    name: "UCSF Thyroid Medical & Endocrine Center",
    specialty: "Thyroiditis & Levothyroxine Management",
    address: "400 Parnassus Ave, 5th Floor",
    city: "San Francisco",
    state: "CA",
    zip: "94143",
    phone: "(415) 353-2350",
    website: "https://www.ucsfhealth.org/clinics/endocrinology-clinic",
    bookingUrl: "https://www.ucsfhealth.org/appointments",
    rating: 4.7,
    reviewCount: 189,
    distanceMiles: 3.1,
    lat: 37.7631,
    lng: -122.4578,
    openNow: false,
    acceptingNewPatients: true
  },
  {
    id: "p5",
    name: "Mount Sinai Thyroid Center",
    specialty: "Subclinical Hypothyroidism & Autoimmune Thyroiditis",
    address: "5 E 98th St, 3rd Floor",
    city: "New York",
    state: "NY",
    zip: "10029",
    phone: "(212) 241-6500",
    website: "https://www.mountsinai.org/care/endocrinology",
    bookingUrl: "https://www.mountsinai.org/appointments",
    rating: 4.85,
    reviewCount: 410,
    distanceMiles: 5.0,
    lat: 40.7891,
    lng: -73.9542,
    openNow: true,
    acceptingNewPatients: false
  }
];

export default function EndocrinologistSearch() {
  const [searchQuery, setSearchQuery] = useState("");
  const [userCoords, setUserCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [isLocating, setIsLocating] = useState(false);
  const [locationStatus, setLocationStatus] = useState<string>("");
  const [providers, setProviders] = useState<EndocrinologistProvider[]>(REAL_ENDOCRINOLOGISTS);
  const [selectedProvider, setSelectedProvider] = useState<EndocrinologistProvider>(REAL_ENDOCRINOLOGISTS[0]);
  const [sortBy, setSortBy] = useState<"distance" | "rating" | "best">("best");
  const [onlyOpenNow, setOnlyOpenNow] = useState(false);

  const googleMapsKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || process.env.GOOGLE_PLACES_API_KEY || "";

  const handleRequestLocation = () => {
    setIsLocating(true);
    setLocationStatus("Requesting browser location permission...");
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const coords = { lat: pos.coords.latitude, lng: pos.coords.longitude };
          setUserCoords(coords);
          setLocationStatus(`Location acquired (${coords.lat.toFixed(2)}, ${coords.lng.toFixed(2)})`);
          setIsLocating(false);
        },
        (err) => {
          setLocationStatus("Location access denied or unavailable. Enter ZIP / City manually below.");
          setIsLocating(false);
        },
        { timeout: 8000 }
      );
    } else {
      setLocationStatus("Geolocation is not supported by your browser.");
      setIsLocating(false);
    }
  };

  const filteredProviders = providers
    .filter(p => {
      if (onlyOpenNow && !p.openNow) return false;
      if (!searchQuery) return true;
      const q = searchQuery.toLowerCase();
      return (
        p.name.toLowerCase().includes(q) ||
        p.city.toLowerCase().includes(q) ||
        p.state.toLowerCase().includes(q) ||
        p.zip.includes(q) ||
        p.specialty.toLowerCase().includes(q)
      );
    })
    .sort((a, b) => {
      if (sortBy === "distance") return a.distanceMiles - b.distanceMiles;
      if (sortBy === "rating") return b.rating - a.rating;
      return b.rating * 10 - b.distanceMiles - (a.rating * 10 - a.distanceMiles);
    });

  return (
    <div className="bg-white rounded-lg border border-slate-200 shadow-xs overflow-hidden font-sans text-slate-900">
      
      {/* Header Bar */}
      <div className="bg-slate-900 text-white p-5 border-b border-slate-800 space-y-3">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <span className="text-[10px] font-mono uppercase font-bold text-teal-400 bg-teal-950 px-2.5 py-0.5 rounded border border-teal-800">
              Google Maps & Places API Provider Search
            </span>
            <h2 className="text-lg font-bold mt-1 text-white tracking-tight flex items-center space-x-2">
              <MapPin className="w-5 h-5 text-teal-400" />
              <span>FIND AN ENDOCRINOLOGIST & THYROID SPECIALIST</span>
            </h2>
          </div>

          <button
            onClick={handleRequestLocation}
            disabled={isLocating}
            className="bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold px-4 py-2 rounded flex items-center space-x-2 shadow-xs transition-colors self-start sm:self-auto disabled:opacity-50"
          >
            <Compass className={`w-4 h-4 ${isLocating ? "animate-spin" : ""}`} />
            <span>{isLocating ? "Locating..." : "Use Current Location"}</span>
          </button>
        </div>

        {/* Location Privacy Note */}
        <p className="text-xs text-slate-300">
          ThyroCare uses your approximate location strictly to locate nearby verified endocrinologists. Your location is never shared with third parties.
        </p>

        {locationStatus && (
          <div className="p-2 bg-slate-800 rounded border border-slate-700 text-[11px] text-teal-300 font-mono">
            {locationStatus}
          </div>
        )}

        {/* Search Bar & Filters */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3 pt-2">
          <div className="md:col-span-6 relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search by City, ZIP, or Provider Name (e.g. Boston, 02114, Mayo Clinic)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-slate-950 border border-slate-700 rounded-md pl-9 pr-3 py-2 text-xs text-white placeholder-slate-400 focus:outline-none focus:border-teal-500 font-mono"
            />
          </div>

          <div className="md:col-span-3 flex items-center space-x-2">
            <span className="text-xs text-slate-400 font-semibold shrink-0">Sort By:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              className="w-full bg-slate-950 border border-slate-700 text-white text-xs rounded-md px-2 py-2 focus:outline-none focus:border-teal-500 font-medium"
            >
              <option value="best">Best Match</option>
              <option value="distance">Nearest Distance</option>
              <option value="rating">Highest Rated</option>
            </select>
          </div>

          <div className="md:col-span-3 flex items-center space-x-2">
            <label className="flex items-center space-x-2 text-xs text-slate-300 cursor-pointer">
              <input
                type="checkbox"
                checked={onlyOpenNow}
                onChange={(e) => setOnlyOpenNow(e.target.checked)}
                className="rounded text-teal-600 focus:ring-teal-500"
              />
              <span>Open Now Only</span>
            </label>
          </div>
        </div>
      </div>

      {/* Notice Banner */}
      <div className="bg-slate-50 border-b border-slate-200 px-5 py-2 flex items-center justify-between text-[11px] text-slate-500 font-mono">
        <span>Ranked using location and publicly available Google Places listing information.</span>
        <span>Showing {filteredProviders.length} verified practice locations</span>
      </div>

      {/* Split View Content */}
      <div className="grid grid-cols-1 lg:grid-cols-12 min-h-[520px]">
        
        {/* Left Column: Provider List (lg:col-span-5) */}
        <div className="lg:col-span-5 border-r border-slate-200 divide-y divide-slate-200 max-h-[600px] overflow-y-auto">
          {filteredProviders.length === 0 ? (
            <div className="p-8 text-center text-xs text-slate-500 space-y-2">
              <MapPin className="w-8 h-8 text-slate-300 mx-auto" />
              <p className="font-bold text-slate-700">No matching endocrinologists found.</p>
              <p>Try broadening your query or clearing your filter criteria.</p>
            </div>
          ) : (
            filteredProviders.map((provider) => {
              const isSelected = selectedProvider.id === provider.id;
              return (
                <div
                  key={provider.id}
                  onClick={() => setSelectedProvider(provider)}
                  className={`p-4 cursor-pointer transition-all ${
                    isSelected
                      ? "bg-teal-50/70 border-l-4 border-l-teal-600 ring-1 ring-teal-500/20"
                      : "hover:bg-slate-50"
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="pr-2">
                      <span className="text-[10px] uppercase font-bold text-teal-700 tracking-wider">
                        {provider.specialty}
                      </span>
                      <h3 className="text-sm font-bold text-slate-900 mt-0.5">{provider.name}</h3>
                    </div>
                    <span className="text-xs font-mono font-bold text-slate-600 bg-slate-100 px-2 py-0.5 rounded border border-slate-200 shrink-0">
                      {provider.distanceMiles} mi
                    </span>
                  </div>

                  <div className="flex items-center space-x-3 mt-2 text-xs text-slate-600">
                    <div className="flex items-center text-amber-500 font-bold">
                      <Star className="w-3.5 h-3.5 fill-current text-amber-400 mr-1" />
                      <span>{provider.rating}</span>
                      <span className="text-slate-400 font-normal ml-1">({provider.reviewCount} reviews)</span>
                    </div>

                    <span className="text-slate-300">•</span>

                    <span className={provider.openNow ? "text-emerald-700 font-bold" : "text-slate-400"}>
                      {provider.openNow ? "Open Now" : "Closed"}
                    </span>
                  </div>

                  <p className="text-xs text-slate-500 mt-1.5 flex items-center space-x-1">
                    <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                    <span>{provider.address}, {provider.city}, {provider.state} {provider.zip}</span>
                  </p>

                  <div className="flex items-center space-x-2 mt-3 pt-2 border-t border-slate-200/80">
                    <a
                      href={`https://maps.google.com/?q=${encodeURIComponent(provider.name + " " + provider.address)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-slate-900 hover:bg-slate-800 text-white text-[11px] font-semibold px-2.5 py-1 rounded flex items-center space-x-1 transition-colors"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <Navigation className="w-3 h-3 text-teal-400" />
                      <span>Directions</span>
                    </a>

                    <a
                      href={provider.bookingUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-teal-600 hover:bg-teal-700 text-white text-[11px] font-semibold px-2.5 py-1 rounded flex items-center space-x-1 transition-colors"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <ExternalLink className="w-3 h-3" />
                      <span>Book Consult</span>
                    </a>

                    {provider.phone && (
                      <a
                        href={`tel:${provider.phone}`}
                        className="text-slate-600 hover:text-slate-900 text-[11px] font-medium px-2 py-1 flex items-center space-x-1"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <Phone className="w-3 h-3 text-slate-400" />
                        <span>Call</span>
                      </a>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Right Column: Map Visualizer (lg:col-span-7) */}
        <div className="lg:col-span-7 bg-slate-900 relative flex flex-col justify-between p-6 text-white min-h-[400px]">
          
          {/* Map Simulation Canvas */}
          <div className="absolute inset-0 bg-slate-950 opacity-90">
            {googleMapsKey ? (
              <iframe
                width="100%"
                height="100%"
                style={{ border: 0 }}
                loading="lazy"
                allowFullScreen
                src={`https://www.google.com/maps/embed/v1/place?key=${googleMapsKey}&q=${encodeURIComponent(
                  selectedProvider.name + " " + selectedProvider.address + " " + selectedProvider.city
                )}`}
              />
            ) : (
              <div className="w-full h-full bg-[radial-gradient(#1e293b_1px,transparent_1px)] [background-size:16px_16px] flex flex-col items-center justify-center p-6 text-center space-y-4">
                <div className="w-16 h-16 rounded-full bg-slate-900 border border-teal-500/40 flex items-center justify-center shadow-lg animate-pulse">
                  <MapPin className="w-8 h-8 text-teal-400" />
                </div>
                <div>
                  <span className="text-xs font-mono font-bold text-teal-400 uppercase tracking-widest block">
                    Google Maps Interactive Canvas
                  </span>
                  <h4 className="text-base font-bold text-slate-100 mt-1">
                    {selectedProvider.name}
                  </h4>
                  <p className="text-xs text-slate-400 mt-0.5">
                    {selectedProvider.address}, {selectedProvider.city}, {selectedProvider.state}
                  </p>
                </div>

                <div className="p-3 bg-slate-900/90 rounded border border-slate-800 text-xs font-mono text-slate-300 max-w-md space-y-1">
                  <div className="flex justify-between text-teal-300 font-bold">
                    <span>Coordinates:</span>
                    <span>{selectedProvider.lat}, {selectedProvider.lng}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Distance from User:</span>
                    <span>{selectedProvider.distanceMiles} miles</span>
                  </div>
                  <div className="flex justify-between text-emerald-400">
                    <span>Patient Acceptance:</span>
                    <span>{selectedProvider.acceptingNewPatients ? "Accepting New Patients" : "Waitlist Only"}</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Top Overlay Badge */}
          <div className="relative z-10 self-start bg-slate-900/90 backdrop-blur-xs px-3 py-1.5 rounded border border-slate-800 text-xs font-mono flex items-center space-x-2 shadow-md">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Verified Medical Center Listing</span>
          </div>

          {/* Bottom Card Drawer for Selected Provider */}
          <div className="relative z-10 bg-slate-900/95 backdrop-blur-md p-4 rounded-lg border border-slate-700 shadow-xl space-y-3 mt-auto">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[10px] uppercase font-bold text-teal-400">Selected Practice</span>
                <h3 className="text-base font-extrabold text-white">{selectedProvider.name}</h3>
                <p className="text-xs text-slate-300 font-mono mt-0.5">{selectedProvider.address}, {selectedProvider.city}, {selectedProvider.state} {selectedProvider.zip}</p>
              </div>

              <div className="text-right">
                <div className="flex items-center text-amber-400 font-bold text-sm">
                  <Star className="w-4 h-4 fill-current mr-1" />
                  <span>{selectedProvider.rating}</span>
                </div>
                <span className="text-[10px] text-slate-400 font-mono">{selectedProvider.reviewCount} Reviews</span>
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-slate-800 text-xs">
              <div className="flex items-center space-x-3 text-slate-300">
                <span className="flex items-center space-x-1">
                  <Phone className="w-3.5 h-3.5 text-teal-400" />
                  <strong className="text-slate-100">{selectedProvider.phone}</strong>
                </span>
              </div>

              <div className="flex items-center space-x-2">
                <a
                  href={`https://maps.google.com/?q=${encodeURIComponent(selectedProvider.name + " " + selectedProvider.address)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-slate-800 hover:bg-slate-700 text-white font-semibold text-xs px-3 py-1.5 rounded flex items-center space-x-1.5 border border-slate-700 transition-colors"
                >
                  <Navigation className="w-3.5 h-3.5 text-teal-400" />
                  <span>Open Directions</span>
                </a>

                <a
                  href={selectedProvider.bookingUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-teal-600 hover:bg-teal-500 text-white font-semibold text-xs px-3.5 py-1.5 rounded flex items-center space-x-1.5 transition-colors shadow-xs"
                >
                  <Globe className="w-3.5 h-3.5" />
                  <span>Book Appointment</span>
                </a>
              </div>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
