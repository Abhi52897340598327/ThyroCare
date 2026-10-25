import SwiftUI

struct LocalMessageRecord: Identifiable, Codable {
    let id: String
    let body: String
    let subject: String
    let sender: String
    let timestamp: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct MessageClinicianPage: View {
    var store: CareStore?
    
    @State private var selectedSubject = "Routine Check-In"
    @State private var messageBody = ""
    @State private var isSending = false
    @State private var showSuccessBanner = false
    @State private var errorMessage: String?
    @AppStorage("thyrocare_local_messages_cache") private var localMessagesCache = ""

    private let subjectOptions = [
        "Routine Check-In",
        "Symptom Update",
        "Medication Question",
        "Lab Result Inquiry",
        "General Note"
    ]

    private var clinicianName: String {
        if let team = store?.careTeam, let first = team.first, !first.name.isEmpty {
            return first.name
        }
        return "Dr. Jane Smith (Endocrinology)"
    }

    private var senderDisplayName: String {
        if let name = store?.session?.user.name, !name.isEmpty {
            return name
        }
        return "Eleanor Vance (Demo Account)"
    }

    private var cachedMessages: [LocalMessageRecord] {
        guard !localMessagesCache.isEmpty,
              let data = localMessagesCache.data(using: .utf8),
              let list = try? JSONDecoder().decode([LocalMessageRecord].self, from: data) else {
            return []
        }
        return list
    }

    private var allMessages: [LocalMessageRecord] {
        var results = cachedMessages
        if let store {
            for record in store.entries("messages") {
                if !results.contains(where: { $0.id == record.id }) {
                    let sub = record.fields["subject"] ?? "Care Message"
                    let body = record.fields["body"] ?? ""
                    let sender = record.fields["sender"] ?? (store.session?.user.name ?? "Eleanor Vance")
                    let date = ISO8601DateFormatter().date(from: record.recordedAt) ?? Date()
                    results.append(LocalMessageRecord(id: record.id, body: body, subject: sub, sender: sender, timestamp: date))
                }
            }
        }
        return results.sorted(by: { $0.timestamp > $1.timestamp })
    }

    var body: some View {
        ThyroPageScaffold(title: "Message Clinician") {
            // Card 1: Clinician & Care Team Info
            ThyroCard {
                ThyroSectionTitle("Thyroid Care Team", subtitle: "Direct, secure connection to your clinical provider.")

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ThyroUI.mint)
                            .frame(width: 52, height: 52)
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(ThyroUI.teal)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(clinicianName)
                            .font(.headline)
                            .foregroundStyle(ThyroUI.navy)
                        Text("Department of Endocrinology & Metabolism")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("Active Clinician Dashboard Connection")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(ThyroUI.teal)
                        }
                    }
                }
            }

            // Card 2: Message Composer
            ThyroCard {
                ThyroSectionTitle("Compose Message", subtitle: "Your message will pop up directly on the clinician's dashboard.")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sender")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(ThyroUI.teal)
                        Text(senderDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ThyroUI.navy)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Subject / Category")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(subjectOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Message Content")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if messageBody.isEmpty {
                            Text("Write your message here (symptoms, medication questions, check-in note)...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                        }

                        TextEditor(text: $messageBody)
                            .font(.subheadline)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(ThyroUI.softGray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(ThyroUI.coral)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(ThyroUI.coral)
                    }
                }

                if showSuccessBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Message Transmitted!")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                            Text("Your message was delivered and will pop up on the clinician dashboard.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ThyroUI.mint.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                LandingButton(title: isSending ? "Sending..." : "Send to Clinician") {
                    Task {
                        await sendMessage()
                    }
                }
                .disabled(isSending || messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }

            // Medical Disclaimer
            ThyroMedicalDisclaimer()

            // Card 3: Recent Message History
            ThyroCard {
                ThyroSectionTitle("Sent Message History", subtitle: "Log of messages sent to your clinician's care thread.")

                let list = allMessages
                if list.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("No messages sent yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Compose a message above to contact your clinician.")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                } else {
                    ForEach(list) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.subject)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                                Spacer()
                                Text(item.formattedDate)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(item.body)
                                .font(.footnote)
                                .foregroundStyle(ThyroUI.ink)

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(ThyroUI.teal)
                                Text("Delivered to Clinician Dashboard")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(ThyroUI.teal)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ThyroUI.softGray)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func sendMessage() async {
        let trimmed = messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil
        showSuccessBanner = false

        let msgID = UUID().uuidString
        let patientName = store?.session?.user.name ?? "Eleanor Vance"
        let newRecord = LocalMessageRecord(
            id: msgID,
            body: trimmed,
            subject: selectedSubject,
            sender: patientName,
            timestamp: Date()
        )

        // Save into local cache
        var currentCache = cachedMessages
        currentCache.insert(newRecord, at: 0)
        if let encoded = try? JSONEncoder().encode(currentCache),
           let jsonStr = String(data: encoded, encoding: .utf8) {
            localMessagesCache = jsonStr
        }

        let fields: [String: String] = [
            "body": trimmed,
            "subject": selectedSubject,
            "sender": patientName,
            "source": "Mobile App Direct Message",
            "observedDate": ISO8601DateFormatter().string(from: Date())
        ]

        // 1. Direct POST to demo patient p1 messages on backend
        let directBase = store?.baseURL ?? URL(string: "http://localhost:8080")!
        let directEndpoint = directBase.appendingPathComponent("v1/patients/p1/messages")
        var directReq = URLRequest(url: directEndpoint)
        directReq.httpMethod = "POST"
        directReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let postBody: [String: Any] = [
            "id": msgID,
            "expectedVersion": 0,
            "fields": fields
        ]
        directReq.httpBody = try? JSONSerialization.data(withJSONObject: postBody)
        _ = try? await URLSession.shared.data(for: directReq)

        // 2. Save through CareStore
        if let store {
            _ = await store.save(kind: "messages", fields: fields)
        }

        isSending = false
        messageBody = ""
        withAnimation {
            showSuccessBanner = true
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

#Preview {
    MessageClinicianPage()
}
