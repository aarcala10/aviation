/// Error body returned by a remote API (code + message).
struct APIError: Error, Equatable, Sendable, Decodable {
    let code: String
    let message: String
}
