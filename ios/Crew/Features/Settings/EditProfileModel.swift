// SPEC: E1 — name + one profile picture, changeable anytime in Settings, camera or library · A7 (owner-directed 2026-09-08):
// upload with purpose profile → PATCH profilePhotoKey (+ displayName ≤ displayNameMaxChars); Remove photo = an explicit null
// · E5 (camera denied → the library still works; Open Settings). WRITTEN — UNVERIFIED (needs Mac). T041

import AVFoundation
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class EditProfileModel {
    var displayName = AuthStore.shared.currentUser?.displayName ?? ""
    var photo: UIImage?            // a newly chosen picture, uploaded on Save
    var removesPhoto = false
    var isSaving = false
    var errorLine: String?
    var saved = false

    var existingPhotoKey: String? { removesPhoto ? nil : AuthStore.shared.currentUser?.profilePhotoKey }
    var hasPhoto: Bool { photo != nil || existingPhotoKey != nil }
    var cameraAvailable: Bool { CameraCapture.isAvailable }
    var cameraDenied: Bool { AVCaptureDevice.authorizationStatus(for: .video) == .denied }
    var trimmedName: String { displayName.trimmingCharacters(in: .whitespaces) }
    var canSave: Bool { !trimmedName.isEmpty && !isSaving }

    // SPEC: E1 — displayName ≤ displayNameMaxChars (lib/validate.ts displayNameSchema)
    func setName(_ value: String) {
        displayName = String(value.prefix(SpecConstants.displayNameMaxChars))
    }

    func choose(_ image: UIImage?) {
        guard let image else { return }
        photo = image
        removesPhoto = false
    }

    func removePhoto() {
        photo = nil
        removesPhoto = true
    }

    // E5: camera denied → the one honest path is the system Settings app
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // SPEC: A7 — Save: upload (purpose profile) then PATCH users/me { profilePhotoKey, displayName }; the Keychain copy follows
    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            var body = UpdateMeRequestDTO(displayName: trimmedName)
            if let photo {
                body.profilePhotoKey = try await Api.shared.uploadPhoto(fileURL: try Self.writeJPEG(photo), purpose: "profile").photoKey
            } else if removesPhoto {
                body.clearsProfilePhoto = true
            }
            AuthStore.shared.updateCurrentUser(try await Api.shared.updateMe(body))
            errorLine = nil
            saved = true
        } catch let error as AppError { errorLine = error.userLine } catch { errorLine = AppError.invalidResponse.userLine }
    }

    // No filters, no editing: the JPEG bytes go to a temporary file for the multipart upload (same quality as a post photo)
    private static func writeJPEG(_ image: UIImage) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "profile-photo.jpg")
        guard let data = image.jpegData(compressionQuality: Double(SpecConstants.photoJpegQuality) / Double(SpecConstants.percentScale)) else { throw AppError.storage("photo") }
        try data.write(to: url, options: .atomic)
        return url
    }
}
