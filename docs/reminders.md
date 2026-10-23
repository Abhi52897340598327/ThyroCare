# Reminder behavior and validation limits

The native reminder center stores `care-plans` through the same patient API. Separate plan types: meal, medication, daily-symptom, weekly-checkin. The patient explicitly acknowledges times, fixed IANA timezone, start date, optional end date, and weekdays where applicable. Meal plans have breakfast/lunch/dinner times. Medication plans reference a specific regimen ID and version; no dose is placed in notifications. PRN/as-needed schedules are excluded rather than made daily.

Permission is requested only from reminder setup or the explicit permission button. Denial retains the saved plan and shows notifications disabled with a system Settings action. Pausing/resuming creates a plan revision. On synchronization, obsolete local requests are removed. Matching meal, symptom, weekly or explicit taken/skipped logs suppress future occurrences. No notification marks a task complete.

The scheduler chooses the next at most 60 occurrences in 28 days, reserving space for unrelated pending requests. It shows the actual scheduled horizon. This is bounded scheduling, not a promise that all future occurrences exist. The app must reopen before that horizon. Apple Focus, permissions, device state and OS scheduling may prevent timely delivery. APNs, snooze, quiet hours, cross-device deduplication and ongoing-background reconciliation are not implemented.

Calendar dates use the plan's fixed timezone. DST gaps use Calendar's next valid time; a repeated time uses its first occurrence. Travel does not silently change the selected zone. Device interactions must still validate these policies with real notification delivery.

A notification contains only generic lock-screen text and patient/plan/version/date/slot identifiers. Tapping requires the matching authenticated patient and fetches the current plan. A stale or unavailable plan cannot issue a current dose instruction. The medication version, current signed-in account, and plan start/end dates in its recorded timezone are rechecked before opening the action. Explicit taken/skipped actions save administration records. Logout clears pending/delivered notifications and cancels in-flight scheduling.

Implemented code has compiled; OS delivery, Focus behavior, denied-permission transitions, travel, reinstall, multiple devices, background/closed-device behavior and end-to-end notification routing are **not yet verified**. Do not count acceptance criteria 15–20 as fully passed.
