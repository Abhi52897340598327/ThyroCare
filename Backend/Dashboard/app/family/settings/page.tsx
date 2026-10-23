"use client";
import { useEffect, useState } from "react";
import { Check, Save } from "lucide-react";
import FamilyAppShell from "@/components/FamilyAppShell";
import { PageHeading, Panel } from "@/components/DashboardUI";
const initial = {
  displayName: "Family caregiver",
  labAlerts: true,
  appointmentReminders: true,
};
const storageKey = "thyrocare.dashboard.preferences.v1";
export default function FamilySettingsPage() {
  const [preferences, setPreferences] = useState(initial);
  const [message, setMessage] = useState("");
  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem(storageKey) || "null");
      if (
        saved &&
        typeof saved.displayName === "string" &&
        typeof saved.labAlerts === "boolean" &&
        typeof saved.appointmentReminders === "boolean"
      )
        setPreferences(saved);
    } catch {
      /* Keep defaults when storage is unavailable. */
    }
  }, []);
  const save = (event: React.FormEvent) => {
    event.preventDefault();
    try {
      localStorage.setItem(storageKey, JSON.stringify(preferences));
      window.dispatchEvent(new Event("thyrocare-preferences-changed"));
      setMessage("Preferences saved on this browser.");
    } catch {
      setMessage(
        "Your browser couldn't save these preferences. Check your browser storage settings.",
      );
    }
  };
  return (
    <FamilyAppShell>
      <div className="tc-page" style={{ maxWidth: 980 }}>
        <PageHeading
          eyebrow="MAKE IT YOURS"
          title="A workspace that fits your family."
          description="Personalize this dashboard and review your notification preferences."
        />
        <form onSubmit={save} className="tc-page">
          <Panel
            title="Your profile"
            subtitle="A familiar name for your workspace"
          >
            <div className="tc-form">
              <div className="tc-field">
                <label htmlFor="display-name">Display name</label>
                <input
                  id="display-name"
                  required
                  maxLength={80}
                  className="tc-input"
                  value={preferences.displayName}
                  onChange={(e) => {
                    setMessage("");
                    setPreferences({
                      ...preferences,
                      displayName: e.target.value,
                    });
                  }}
                />
              </div>
              <p className="tc-muted">
                These preview preferences are saved only in this browser.
              </p>
            </div>
          </Panel>
          <Panel
            title="Stay in the loop"
            subtitle="Choose the updates you want to follow"
          >
            <div className="tc-form">
              <label className="tc-toggle-row">
                <div>
                  <strong>New lab results</strong>
                  <p>Include new thyroid results in your preferred updates.</p>
                </div>
                <input
                  type="checkbox"
                  checked={preferences.labAlerts}
                  onChange={(e) => {
                    setMessage("");
                    setPreferences({
                      ...preferences,
                      labAlerts: e.target.checked,
                    });
                  }}
                />
              </label>
              <label className="tc-toggle-row">
                <div>
                  <strong>Appointment reminders</strong>
                  <p>Keep upcoming visits in your preferred updates.</p>
                </div>
                <input
                  type="checkbox"
                  checked={preferences.appointmentReminders}
                  onChange={(e) => {
                    setMessage("");
                    setPreferences({
                      ...preferences,
                      appointmentReminders: e.target.checked,
                    });
                  }}
                />
              </label>
              <p className="tc-muted">
                Email and text delivery are not connected in this preview.
              </p>
            </div>
          </Panel>
          <div className="tc-form-actions">
            <span role="status" className="tc-form-status">
              {message}
            </span>
            <button className="tc-button primary" type="submit">
              {message.startsWith("Preferences saved") ? (
                <Check size={17} />
              ) : (
                <Save size={17} />
              )}
              Save preferences
            </button>
          </div>
        </form>
      </div>
    </FamilyAppShell>
  );
}
