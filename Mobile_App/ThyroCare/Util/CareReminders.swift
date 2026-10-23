import Foundation
import Observation
import UserNotifications

struct CareReminderOccurrence: Identifiable {
    let id: String
    let date: Date
    let plan: PatientRecord
    let slot: String
    let localDay: String
}

@MainActor @Observable
final class CareReminders {
    var status = "Notification permission has not been checked."
    var next: [CareReminderOccurrence] = []
    private var generation = UUID()

    func cancelForLogout() {
        generation = UUID()
        next = []
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch { status = "Notifications could not be enabled. Your plan remains saved." }
    }

    func reconcile(patientID: String, records: [PatientRecord]) async {
        let currentGeneration = generation
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let pending = await center.pendingNotificationRequests()
        guard generation == currentGeneration else { return }
        let owned = pending.filter { $0.identifier.hasPrefix("care.") }
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
            next = []
            status = "Plans saved; notifications disabled. Enable them in system Settings."
            return
        }
        let now = Date()
        var occurrences: [CareReminderOccurrence] = []
        for plan in records where plan.kind == "care-plans" && plan.fields["status"] == "active" && plan.fields["acknowledged"] == "true" {
            let f = plan.fields
            guard let timezone = TimeZone(identifier: f["timezone"] ?? "") else { continue }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timezone
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timezone
            formatter.dateFormat = "yyyy-MM-dd"
            guard let start = f["startDate"], !start.isEmpty else { continue }
            let type = f["planType"] ?? ""
            if type == "medication" {
                guard let regimen = records.first(where: { $0.kind == "medications" && $0.id == f["regimenID"] }),
                      String(regimen.version) == f["regimenVersion"],
                      (regimen.fields["endDate"] ?? "").isEmpty || (regimen.fields["endDate"] ?? "") >= formatter.string(from: now) else { continue }
                let schedule = (regimen.fields["schedule"] ?? "").lowercased()
                if schedule.contains("prn") || schedule.contains("as needed") { continue }
            }
            let slots = type == "meal" ? ["breakfast", "lunch", "dinner"] : ["time"]
            let weekdays = Set((f["weekdays"] ?? "1,2,3,4,5,6,7").split(separator: ",").compactMap { Int($0) })
            for offset in 0..<28 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
                let localDay = formatter.string(from: day)
                guard localDay >= start, (f["endDate"] ?? "").isEmpty || localDay <= (f["endDate"] ?? "") else { continue }
                if type != "meal" && type != "daily-symptom" && !weekdays.contains(calendar.component(.weekday, from: day)) { continue }
                for slot in slots {
                    guard let time = f[slot] else { continue }
                    let parts = time.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]),
                          let date = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward),
                          date > now else { continue }
                    let completed = records.contains { record in
                        if type == "meal" { return record.kind == "meals" && record.fields["observedDate"] == localDay && record.fields["mealType"]?.lowercased() == slot }
                        if type == "daily-symptom" { return record.kind == "symptoms" && record.fields["observedDate"] == localDay }
                        if type == "weekly-checkin" { return record.kind == "weekly-checkins" && record.fields["recallEnd"] == localDay }
                        return record.kind == "administrations" && record.fields["regimenID"] == f["regimenID"] && record.fields["regimenVersion"] == f["regimenVersion"] && record.fields["observedDate"] == localDay && record.fields["time"] == time
                    }
                    if completed { continue }
                    let identifier = "care.\(patientID).\(plan.id).v\(plan.version).\(localDay).\(slot)"
                    occurrences.append(CareReminderOccurrence(id: identifier, date: date, plan: plan, slot: slot, localDay: localDay))
                }
            }
        }
        let otherCount = pending.count - owned.count
        next = Array(occurrences.sorted { $0.date < $1.date }.prefix(max(0, 60 - otherCount)))
        let wanted = Set(next.map(\.id))
        center.removePendingNotificationRequests(withIdentifiers: owned.filter { !wanted.contains($0.identifier) }.map(\.identifier))
        let existing = Set(owned.map(\.identifier))
        do {
            for occurrence in next where !existing.contains(occurrence.id) {
                let content = UNMutableNotificationContent()
                content.title = "ThyroCare reminder"
                content.body = "Open your care plan to review what is due."
                content.sound = .default
                content.userInfo = ["patientID": patientID, "planID": occurrence.plan.id, "version": String(occurrence.plan.version), "slot": occurrence.slot, "day": occurrence.localDay]
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: occurrence.plan.fields["timezone"] ?? "") ?? .current
                var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: occurrence.date)
                components.timeZone = calendar.timeZone
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                guard generation == currentGeneration else { return }
                try await center.add(UNNotificationRequest(identifier: occurrence.id, content: content, trigger: trigger))
                if generation != currentGeneration {
                    center.removePendingNotificationRequests(withIdentifiers: [occurrence.id])
                    return
                }
            }
            status = next.isEmpty ? "No upcoming reminders. Check active plans and current medication versions." : "\(next.count) reminders scheduled through \(next.last?.date.formatted(date: .abbreviated, time: .shortened) ?? ""). Reopen the app before then to extend the schedule."
        } catch { status = "Some reminders could not be scheduled. Reopen the reminder center to retry." }
    }
}
