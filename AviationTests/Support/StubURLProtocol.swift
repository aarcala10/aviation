import Foundation
import Synchronization
import Testing

private final class BundleToken {}

enum Fixture {
    static func data(_ name: String) throws -> Data {
        let url = try #require(
            Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

/// Static handler: suites using it must be `.serialized`.
final class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) -> (HTTPURLResponse, Data)
    static let handler = Mutex<Handler?>(nil)
    
    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        guard let handler = Self.handler.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
