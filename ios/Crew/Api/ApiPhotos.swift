// SPEC: docs/api.md POST photos (multipart file + purpose → photoKey). URLSession only. WRITTEN — UNVERIFIED (needs Mac). T027

import Foundation
import UIKit

struct PhotoUploadDTO: Codable {
    let photoKey: String
    let width: Int
    let height: Int
    let bytes: Int
}

extension Api {
    // GET photos/[key] — the auth-checked read (own or a crew-mate's); a redirect to blob storage is followed by URLSession
    func photo(key: String) async throws -> UIImage {
        var request = URLRequest(url: baseURL.appending(path: "photos/\(key)"))
        request.setValue("Bearer \(try await AuthStore.shared.validAccessToken())", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, HttpStatus.successRange.contains(http.statusCode), let image = UIImage(data: data) else { throw AppError.invalidResponse }
        return image
    }

    func uploadPhoto(fileURL: URL, purpose: String) async throws -> PhotoUploadDTO {
        let boundary = "crew-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "photos"))
        request.httpMethod = "POST"
        request.setValue("ios", forHTTPHeaderField: "X-Crew-Client")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try await AuthStore.shared.validAccessToken())", forHTTPHeaderField: "Authorization")
        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"purpose\"\r\n\r\n\(purpose)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: fileURL))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.invalidResponse }
        guard HttpStatus.successRange.contains(http.statusCode) else {
            if http.statusCode == HttpStatus.unauthorized { throw AppError.unauthorized }
            let body = try? JSONDecoder.crew.decode(ApiErrorBodyDTO.self, from: data)
            throw AppError.server(code: body?.error.code ?? "photo", message: body?.error.message ?? "Couldn't upload that photo.", status: http.statusCode)
        }
        return try JSONDecoder.crew.decode(PhotoUploadDTO.self, from: data)
    }
}
