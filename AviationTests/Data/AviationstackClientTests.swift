import Foundation
import Synchronization
import Testing

@testable import Aviation

final class Captured: Sendable { let request = Mutex<URLRequest?>(nil) }

@Suite(.serialized)
struct AviationstackClientTests {
    private func client() -> AviationstackClient {
        AviationstackClient(accessKey: "KEY", session: StubURLProtocol.session())
    }
    
    private func stub(_ fixture: String, status: Int = 200, captured: Captured? = nil) throws {
        let data = try Fixture.data(fixture)
        StubURLProtocol.handler.withLock {
            $0 = { request in
                captured?.request.withLock { $0 = request }
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
        }
    }
    
    @Test("airports_buildsRequestWithAccessKeyAndSearch")
    func airports_buildsRequestWithAccessKeyAndSearch() async throws {
        let captured = Captured()
        try stub("airports", captured: captured)
        _ = try? await client().airports(search: "madrid")
        let url = try #require(captured.request.withLock { $0 }?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.path == "/v1/airports")
        #expect(items.contains(URLQueryItem(name: "access_key", value: "KEY")))
        #expect(items.contains(URLQueryItem(name: "search", value: "madrid")))
    }
    
    @Test("airports_decodesFixtureIntoAirports")
    func airports_decodesFixtureIntoAirports() async throws {
        try stub("airports")
        let airports = try await client().airports(search: "madrid")
        #expect(airports == [.madrid, .barcelona])
    }
    
    @Test("airports_apiErrorResponse_throwsAPIError")
    func airports_apiErrorResponse_throwsAPIError() async throws {
        try stub("error", status: 200)
        await #expect(throws: APIError.self) {
            try await client().airports(search: "madrid")
        }
    }
}
