import SwiftUI

struct LocalMessageRecord: Identifiable, Codable {
    let id: String
    let body: String
    let subject: String
    let sender: String
    var isFromClinician: Bool = false
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
        var results: [LocalMessageRecord] = []
        if let store {
            for record in store.entries("messages") {
                if !results.contains(where: { $0.id == record.id }) {
                    let sub = record.fields["subject"] ?? "Care Message"
                    let body = record.fields["body"] ?? ""
                    let isClinician = record.fields["authorRole"] == "clinician" || (record.fields["sender"]?.contains("Dr.") ?? false)
                    let defaultSender = isClinician ? "Dr. Jane Smith (Endocrinology)" : (store.session?.user.name ?? "Eleanor Vance")
                    let sender = record.fields["sender"] ?? defaultSender
                    let date = ISO8601DateFormatter().date(from: record.recordedAt) ?? Date()
                    results.append(LocalMessageRecord(
                        id: record.id,
                        body: body,
                        subject: sub,
                        sender: sender,
                        isFromClinician: isClinician,
                        timestamp: date
                    ))
                }
            }
        }
        if results.isEmpty {
            results = cachedMessages
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

                    VStack(alignment: .leading, spacing: 3) {
                        Text(clinicianName)
                            .font(.headline)
                            .foregroundStyle(ThyroUI.navy)
                        Text("Specialty: Thyroid Endocrinology & Metabolic Care")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Response Time: Typically within 24 hours")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ThyroUI.teal)
                    }
                }
                .padding(.vertical, 4)

                Divider()

                HStack {
                    Label("Status: Active Care Thread", systemImage: "circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.green)

                    Spacer()

                    Text("Patient: \(senderDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Card 2: Compose Message
            ThyroCard {
                ThyroSectionTitle("Compose Message", subtitle: "Send questions, symptom updates, or notes directly to your doctor.")

                // Subject Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Subject")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(subjectOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ThyroUI.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Message Text Field
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

            // Card 3: Care Conversation & Messages
            ThyroCard {
                ThyroSectionTitle("Care Conversation & Messages", subtitle: "Live exchange with your endocrinologist and care team.")

                let list = allMessages
                if list.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("No messages in care thread yet.")
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
                        if item.isFromClinician {
                            // CLINICIAN RESPONSE CARD
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(ThyroUI.teal)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "stethoscope")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.sender)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(ThyroUI.navy)
                                        Text("Endocrinologist · Clinical Team Response")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(ThyroUI.teal)
                                    }
                                    Spacer()
                                    Text(item.formattedDate)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.body)
                                    .font(.subheadline)
                                    .foregroundStyle(ThyroUI.ink)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.caption2)
                                        .foregroundStyle(ThyroUI.teal)
                                    Text("Verified Clinical Team Response")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(ThyroUI.teal)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ThyroUI.mint.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ThyroUI.teal.opacity(0.35), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            // PATIENT OUTGOING MESSAGE CARD
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundStyle(ThyroUI.navy.opacity(0.65))
                                        Text(item.sender)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(ThyroUI.navy)
                                    }
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
        .refreshable {
            await store?.synchronize()
        }
        .task {
            await store?.synchronize()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await store?.synchronize()
            }
        }
    }

    private func sendMessage() async {
        let trimmed = messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil
        showSuccessBanner = false

        let patientName = store?.session?.user.name ?? "Eleanor Vance"
        let fields: [String: String] = [
            "body": trimmed,
            "subject": selectedSubject,
            "sender": patientName,
            "source": "Mobile App Direct Message",
            "observedDate": ISO8601DateFormatter().string(from: Date())
        ]

        if let store {
            // Send exactly once through CareStore sync
            let success = await store.save(kind: "messages", fields: fields)
            if !success {
                errorMessage = store.errorMessage ?? "Could not send message."
            }
        } else {
            // Direct POST fallback only if CareStore is not provided
            #if targetEnvironment(simulator)
            let primaryBase = URL(string: "http://localhost:8080")!
            #else
            let primaryBase = URL(string: "http://10.0.0.7:8080")!
            #endif

            let endpoint = primaryBase.appendingPathComponent("v1/patients/p1/messages")
            var directReq = URLRequest(url: endpoint)
            directReq.httpMethod = "POST"
            directReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            directReq.timeoutInterval = 5.0
            let postBody: [String: Any] = [
                "id": UUID().uuidString,
                "expectedVersion": 0,
                "fields": fields
            ]
            directReq.httpBody = try? JSONSerialization.data(withJSONObject: postBody)
            _ = try? await URLSession.shared.data(for: directReq)
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
