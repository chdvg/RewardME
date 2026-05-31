import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var pendingAvatarData: Data? = nil   // new photo chosen this session
    @State private var clearAvatar      = false          // user tapped "Remove Photo"
    @State private var photoErrorMessage: String? = nil  // non-nil if photo load failed

    // The data to preview — pending if chosen, else existing
    private var previewData: Data? {
        if clearAvatar          { return nil }
        if let d = pendingAvatarData { return d }
        return settings.avatarImageData
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Name ─────────────────────────────────────────────────
                Section("Your Name") {
                    TextField("e.g. Tonya", text: $name)
                        .autocorrectionDisabled()
                }

                // ── Avatar / Photo ────────────────────────────────────────
                Section {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 16) {
                            AvatarView(imageData: previewData, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(previewData != nil ? "Change Photo" : "Choose Photo")
                                    .foregroundColor(.accentColor)
                                    .font(.body)
                                Text("Pick any image from your Photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            photoErrorMessage = nil
                            guard let item else { return }
                            do {
                                guard let data = try await item.loadTransferable(type: Data.self) else {
                                    photoErrorMessage = "Could not load image data."
                                    return
                                }
                                guard let ui = UIImage(data: data) else {
                                    photoErrorMessage = "Image format not supported. Try a JPEG or PNG."
                                    return
                                }
                                guard let compressed = Self.compress(ui) else {
                                    photoErrorMessage = "Failed to process image. Please try another photo."
                                    return
                                }
                                clearAvatar       = false
                                pendingAvatarData = compressed
                            } catch {
                                photoErrorMessage = "Error loading photo: \(error.localizedDescription)"
                            }
                        }
                    }

                    if let msg = photoErrorMessage {
                        Label(msg, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if previewData != nil {
                        Button(role: .destructive) {
                            clearAvatar       = true
                            pendingAvatarData  = nil
                            selectedPhoto      = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Profile Photo")
                } footer: {
                    // swiftlint:disable:next line_length
                    Text("To use your Memoji: open Messages on your iPhone, tap the Memoji icon in the keyboard, then press-hold a sticker and choose \"Save to Photos\". You can then select it here.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                name = settings.userName
            }
        }
    }

    // MARK: - Save

    private func save() {
        settings.userName = name.trimmingCharacters(in: .whitespaces)
        if clearAvatar {
            settings.avatarImageData = nil
        } else if let data = pendingAvatarData {
            settings.avatarImageData = data
        }
        dismiss()
    }

    // MARK: - Image helpers

    /// Resize + JPEG compress to keep avatar tiny in UserDefaults (~15–25 KB max).
    static func compress(_ image: UIImage, maxDimension: CGFloat = 200) -> Data? {
        let s = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * s, height: image.size.height * s)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.75)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AppSettings.shared)
}
