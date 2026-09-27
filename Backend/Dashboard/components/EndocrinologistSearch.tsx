"use client";
import { useState } from "react";
import { ArrowUpRight, Compass, MapPin, Search } from "lucide-react";
import { Panel } from "./DashboardUI";
export default function EndocrinologistSearch() {
  const [location, setLocation] = useState("");
  const [submitted, setSubmitted] = useState("");
  const [locating, setLocating] = useState(false);
  const [message, setMessage] = useState("");
  const query = `endocrinologists near ${submitted}`;
  const mapsURL = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
  const mapsKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  const locate = () => {
    if (!navigator.geolocation) {
      setMessage(
        "Location isn't available in this browser. Enter a city or ZIP code instead.",
      );
      return;
    }
    setLocating(true);
    setMessage("");
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const place = `${position.coords.latitude.toFixed(3)}, ${position.coords.longitude.toFixed(3)}`;
        setLocation(place);
        setSubmitted(place);
        setLocating(false);
      },
      () => {
        setMessage(
          "We couldn't get your location. Enter a city or ZIP code instead.",
        );
        setLocating(false);
      },
      { timeout: 10000 },
    );
  };
  return (
    <div className="tc-page">
      <Panel
        title="Find an endocrinologist"
        subtitle="Search by city, ZIP code, or your current location"
      >
        <form
          className="tc-form"
          onSubmit={(e) => {
            e.preventDefault();
            if (location.trim()) {
              setSubmitted(location.trim());
              setMessage("");
            }
          }}
        >
          <div className="tc-field">
            <label htmlFor="doctor-location">
              Where would you like to find care?
            </label>
            <div className="tc-toolbar">
              <input
                id="doctor-location"
                className="tc-input"
                style={{ flex: 1, minWidth: 160 }}
                required
                placeholder="City or ZIP code"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
              />
              <button type="submit" className="tc-button primary">
                <Search size={17} />
                Search doctors
              </button>
              <button
                type="button"
                className="tc-button secondary"
                disabled={locating}
                onClick={locate}
              >
                <Compass size={17} />
                {locating ? "Locating…" : "Use my location"}
              </button>
            </div>
          </div>
          <p className="tc-muted">
            Search opens in Google Maps. Your search location is shared with
            Google when you open results.
          </p>
          <p role="status" className="tc-form-status">
            {message}
          </p>
        </form>
      </Panel>
      <section className="tc-provider-result tc-panel">
        {submitted ? (
          <>
            <div>
              <span className="tc-icon-tile teal">
                <MapPin size={20} />
              </span>
              <h2>Care near {submitted}</h2>
              <p>
                Explore nearby practices, contact details, and directions on
                Google Maps. Confirm appointment availability with the practice.
              </p>
              <a
                className="tc-button primary"
                href={mapsURL}
                target="_blank"
                rel="noopener noreferrer"
              >
                View results on Google Maps
                <ArrowUpRight size={17} />
              </a>
            </div>
            {mapsKey && (
              <iframe
                title={`Endocrinologists near ${submitted}`}
                loading="lazy"
                allowFullScreen
                referrerPolicy="no-referrer-when-downgrade"
                src={`https://www.google.com/maps/embed/v1/search?key=${encodeURIComponent(mapsKey)}&q=${encodeURIComponent(query)}`}
              />
            )}
          </>
        ) : (
          <div>
            <span className="tc-icon-tile teal">
              <MapPin size={20} />
            </span>
            <h2>The right care starts with a conversation.</h2>
            <p>Enter a location above to find thyroid specialists near you.</p>
          </div>
        )}
      </section>
    </div>
  );
}
