// The one Swift file that names HTTP status codes (docs/api.md conventions). Not spec numbers, so not in
// spec-constants.json; exempt from the doctrine literal scan by name (shared/scripts/doctrine-lint.mjs).
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum HttpStatus {
    static let ok = 200
    static let created = 201
    static let successRange = 200..<300
    static let badRequest = 400
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let conflict = 409
    static let tooManyRequests = 429
    static let serviceUnavailable = 503
}
