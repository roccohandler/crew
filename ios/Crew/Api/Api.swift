// SPEC: 5.2 Api/Api.swift — one func per endpoint (docs/api.md), URLSession only (Part IV zero dependencies),
// C3 (Api.shared), C13 (AppError from the standard error shape). The transport is one private `send`; the auth
// endpoints live here, feature endpoints in ApiPlans/ApiPosts/ApiCrews/ApiSync.swift (C9 file cap).
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

final class Api {
    static let shared = Api()

    // The server this build talks to comes from Info.plist (project.yml sets CREW_API_SCHEME / CREW_API_HOST per
    // configuration: http + localhost:3000 in Debug, https + the deployed host in Release, overridable on the xcodebuild
    // command line). A TestFlight build must reach a real server, and a device on your desk must reach your machine —
    // neither can be a hard-coded string. Two plain keys, no parsing (C6).
    var baseURL = Api.configuredBaseURL()
    private let session = URLSession(configuration: .default)

    static func configuredBaseURL() -> URL {
        let info = Bundle.main.infoDictionary
        let scheme = info?["CrewApiScheme"] as? String ?? "http"
        let host = info?["CrewApiHost"] as? String ?? "localhost:3000"
        guard let url = URL(string: "\(scheme)://\(host)/api/v1") else { fatalError("CrewApiScheme/CrewApiHost do not form a URL: \(scheme)://\(host)") }
        return url
    }

    // MARK: Auth (docs/api.md auth/*)

    func register(_ body: RegisterRequestDTO) async throws -> AuthSessionDTO {
        try await send("POST", "auth/register", body: body, authenticated: false)
    }

    func login(_ body: LoginRequestDTO) async throws -> AuthSessionDTO {
        try await send("POST", "auth/login", body: body, authenticated: false)
    }

    func signInWithApple(_ body: AppleSignInRequestDTO) async throws -> AuthSessionDTO {
        try await send("POST", "auth/apple", body: body, authenticated: false)
    }

    func refresh(refreshToken: String) async throws -> AuthSessionDTO {
        try await send("POST", "auth/refresh", body: RefreshRequestDTO(refreshToken: refreshToken), authenticated: false)
    }

    func logout(refreshToken: String) async throws -> OkDTO {
        try await send("POST", "auth/logout", body: RefreshRequestDTO(refreshToken: refreshToken))
    }

    func requestPasswordReset(email: String) async throws -> OkDTO {
        try await send("POST", "auth/reset", body: ResetRequestDTO(email: email), authenticated: false)
    }

    // MARK: Transport

    struct Empty: Codable {}

    func send<Body: Encodable, Reply: Decodable>(_ method: String, _ path: String, body: Body? = nil as Empty?, query: [URLQueryItem] = [], authenticated: Bool = true) async throws -> Reply {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("ios", forHTTPHeaderField: "X-Crew-Client")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.crew.encode(body)
        }
        if authenticated {
            let token = try await AuthStore.shared.validAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await perform(request)
        return try decode(Reply.self, from: data, response: response)
    }

    // SPEC: E6 — no network is not a failed attempt: the three URLError codes become .offline (ApiPhotos sends through here too)
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AppError.invalidResponse }
            return (data, http)
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost || error.code == .cannotConnectToHost {
            throw AppError.offline
        }
    }

    // SPEC: C13 — the standard error shape becomes AppError.server; 401 becomes .unauthorized
    private func decode<Reply: Decodable>(_ type: Reply.Type, from data: Data, response: HTTPURLResponse) throws -> Reply {
        if HttpStatus.successRange.contains(response.statusCode) {
            if data.isEmpty, let empty = Empty() as? Reply { return empty }
            return try JSONDecoder.crew.decode(Reply.self, from: data)
        }
        if response.statusCode == HttpStatus.unauthorized { throw AppError.unauthorized }
        if let body = try? JSONDecoder.crew.decode(ApiErrorBodyDTO.self, from: data) {
            throw AppError.server(code: body.error.code, message: body.error.message, status: response.statusCode)
        }
        throw AppError.invalidResponse
    }
}
