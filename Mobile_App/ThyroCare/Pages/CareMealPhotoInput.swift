import SwiftUI
import PhotosUI

struct CareMealPhotoInput: View {
    @Binding var photo: Data?
    @State private var selection: PhotosPickerItem?
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label(photo == nil ? "Choose meal photo" : "Choose another photo", systemImage: "photo")
            }
            if loading { ProgressView("Preparing photo") }
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Selected meal photo for confirmation")
                Text("Review this photo. Save record confirms its upload to your account and sharing with your connected care team. No external AI analysis is performed.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Discard photo", role: .destructive) {
                    self.photo = nil
                    selection = nil
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .task(id: selection) {
            guard let selection else { return }
            loading = true
            error = nil
            defer { loading = false }
            do {
                guard let data = try await selection.loadTransferable(type: Data.self),
                      let source = UIImage(data: data), source.size.width > 0, source.size.height > 0 else {
                    throw CareClientError.message("This image could not be opened. Try another photo or log the meal manually.")
                }
                try Task.checkCancellation()
                let scale = min(1, 1600 / max(source.size.width, source.size.height))
                let size = CGSize(width: source.size.width * scale, height: source.size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = true
                // Rendering normalizes orientation and excludes location/EXIF metadata.
                let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    UIColor.white.setFill()
                    UIRectFill(CGRect(origin: .zero, size: size))
                    source.draw(in: CGRect(origin: .zero, size: size))
                }
                guard let jpeg = normalized.jpegData(compressionQuality: 0.82) else {
                    throw CareClientError.message("The photo could not be prepared.")
                }
                photo = jpeg
            } catch is CancellationError {
                return
            } catch { self.error = error.localizedDescription }
        }
    }
}

struct CareMealPhotoView: View {
    let store: CareStore
    let record: PatientRecord
    @State private var photo: Data?
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFit()
                    .accessibilityLabel("Confirmed meal photo")
            } else if let error {
                Text(error).font(.footnote).foregroundStyle(.secondary)
                Button("Retry photo") { Task { await load() } }
            } else { ProgressView("Loading authorized meal photo") }
        }
        .task(id: record.id) { photo = nil; await load() }
    }

    private func load() async {
        do { photo = try await store.mealPhoto(record); error = nil }
        catch { self.error = "Photo is not available yet. A device upload may still be waiting to sync." }
    }
}
