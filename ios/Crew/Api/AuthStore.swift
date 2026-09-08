// SPEC: 5.2 Api/AuthStore.swift (Keychain, refresh, Sign in with Apple) · Part IV (JWT in Keychain; zero dependencies) ·
// 1C (a Crew user authenticates ONCE per device, ever — sessions persist in Keychain indefinitely) · 8.7 (Keychain-only
// tokens, never UserDefaults) · C3 (well-known singleton AuthStore.shared) · C14 (@Observable, plain vars) · T012.
// WRITTEN — UNVERIFIED (needs Mac).

import AuthenticationServices
import Foundation
import Observation

@Observable
final class AuthStore {
    static let shared = AuthStore()

    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var accessExpiresAt: Date?
    private(set) var currentUser: UserDTO?

    var isSignedIn: Bool { refreshToken != nil }

    private let keychain = KeychainStore(service: "com.yourteam.crew.auth")

    init() {
        accessToken = keychain.read("accessToken")
        refreshToken = keychain.read("refreshToken")
        if let raw = keychain.read("accessExpiresAt"), let seconds = TimeInterval(raw) {
            accessExpiresAt = Date(timeIntervalSince1970: seconds)
        }
        if let data = keychain.readData("currentUser") {
            currentUser = try? JSONDecoder.crew.decode(UserDTO.self, from: data)
        }
    }

    // SPEC: docs/api.md — every signed-in response carries the same token shape
    func store(_ session: AuthSessionDTO) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        accessExpiresAt = session.accessExpiresAt
        currentUser = session.user
        keychain.write("accessToken", session.accessToken)
        keychain.write("refreshToken", session.refreshToken)
        keychain.write("accessExpiresAt", String(session.accessExpiresAt.timeIntervalSince1970))
        if let data = try? JSONEncoder.crew.encode(session.user) { keychain.writeData("currentUser", data) }
    }

    // PATCH users/me replies with the user; the Keychain copy follows so a cold launch reads the same facts
    func updateCurrentUser(_ user: UserDTO) {
        currentUser = user
        if let data = try? JSONEncoder.crew.encode(user) { keychain.writeData("currentUser", data) }
    }

    func signOutLocally() {
        accessToken = nil
        refreshToken = nil
        accessExpiresAt = nil
        currentUser = nil
        for key in ["accessToken", "refreshToken", "accessExpiresAt", "currentUser"] { keychain.delete(key) }
    }

    // The access token is refreshed one minute before it expires; a dead refresh token signs the user out (G11)
    func validAccessToken() async throws -> String {
        if let token = accessToken, let expiresAt = accessExpiresAt, expiresAt.timeIntervalSinceNow > SpecConstants.tokenRefreshLeadSeconds {
            return token
        }
        guard let refresh = refreshToken else { throw AppError.unauthorized }
        do {
            let session = try await Api.shared.refresh(refreshToken: refresh)
            store(session)
            return session.accessToken
        } catch AppError.unauthorized {
            signOutLocally()
            throw AppError.unauthorized
        }
    }

    // SPEC: 1C — the native Sign in with Apple; the identity token goes to POST /auth/apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, timezone: TimeZone, eulaAccepted: Bool, birthYear: Int?) async throws {
        guard let tokenData = credential.identityToken, let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw AppError.invalidResponse
        }
        let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        let request = AppleSignInRequestDTO(identityToken: identityToken, displayName: name.isEmpty ? nil : name, timezone: timezone.identifier, eulaAccepted: eulaAccepted, birthYear: birthYear)
        store(try await Api.shared.signInWithApple(request))
    }
}
