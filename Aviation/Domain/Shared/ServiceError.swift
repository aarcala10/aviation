nonisolated enum ServiceError: Error, Equatable, Sendable {
    case missingKey, invalidKey, quotaExceeded, offline, server, unknown
}
