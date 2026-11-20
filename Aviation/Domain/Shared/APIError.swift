nonisolated struct APIError: Error, Equatable, Sendable, Decodable {
    let code: String
    let message: String
}
