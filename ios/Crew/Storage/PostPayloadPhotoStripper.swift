// SPEC: E19 — "[Post without photo]": the held createPost op is re-sent with its photo removed. One concrete
// transformation on the JSON payload; nothing else in the op changes. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum PostPayloadPhotoStripper {
    static func strip(_ payload: Data) throws -> Data {
        guard var object = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else { return payload }
        object["photoKey"] = NSNull()
        object["localPhotoPath"] = NSNull()
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
