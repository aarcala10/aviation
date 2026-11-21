import Foundation
import Testing

@testable import Aviation

struct AviationstackFlightRepositoryTests {
    private actor RequestSpy {
        private(set) var request: URLRequest?
        func record(_ request: URLRequest) { self.request = request }
    }
    
    private func makeRepo(
        body: Data? = nil, spy: RequestSpy = RequestSpy()
    ) throws -> AviationstackFlightRepository {
        let data = try body ?? Fixture.data("flights")
        return AviationstackFlightRepository(accessKey: "KEY") { request in
            await spy.record(request)
            return data
        }
    }
    
    @Test("departures_requestsDepIataLimitOffsetAndAccessKeyOverHTTPS")
    func departures_requestsDepIataLimitOffsetAndAccessKeyOverHTTPS() async throws {
        let spy = RequestSpy()
        let repo = try makeRepo(spy: spy)
        _ = try await repo.departures(from: "MAD", limit: 20, offset: 0)
        let url = try #require(await spy.request?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value) })
        #expect(url.scheme == "https")
        #expect(url.path.hasSuffix("/flights"))
        #expect(query["dep_iata"] == "MAD")
        #expect(query["limit"] == "20")
        #expect(query["offset"] == "0")
        #expect(query["access_key"] == "KEY")
    }
    
    @Test("departures_decodesFlights")
    func departures_decodesFlights() async throws {
        let flights = try await makeRepo().departures(from: "MAD", limit: 20, offset: 0)
        #expect(flights.count == 3)
        let operated = try #require(flights.last)
        #expect(operated.number == "AZ59")
        #expect(operated.airline == "ITA Airways")
        #expect(operated.destinationIATA == "FCO")
        #expect(operated.destinationName == "Leonardo Da Vinci (Fiumicino)")
        #expect(operated.delayMinutes == 25)
        #expect(operated.reportedStatus == .scheduled)
    }
    
    @Test("departures_scheduledTime_isAirportLocalTime")
    func departures_scheduledTime_isAirportLocalTime() async throws {
        let flights = try await makeRepo().departures(from: "MAD", limit: 20, offset: 0)
        #expect(flights.first?.scheduledTime == "05:55")
        #expect(flights.last?.scheduledTime == "06:10")
    }
    
    @Test("departures_mapsCodeshared")
    func departures_mapsCodeshared() async throws {
        let flights = try await makeRepo().departures(from: "MAD", limit: 20, offset: 0)
        #expect(flights.map(\.isCodeshare) == [true, true, false])
    }
    
    @Test(
        "departures_errorBody_throwsMatchingServiceError",
        arguments: [
            ("usage_limit_reached", ServiceError.quotaExceeded),
            ("rate_limit_reached", .quotaExceeded),
            ("missing_access_key", .missingKey),
            ("invalid_access_key", .invalidKey),
            ("something_else", .unknown),
        ])
    func departures_errorBody_throwsMatchingServiceError(
        code: String, expected: ServiceError
    ) async throws {
        let body = Data(#"{"error":{"code":"\#(code)","message":"boom"}}"#.utf8)
        let repo = try makeRepo(body: body)
        await #expect(throws: expected) {
            try await repo.departures(from: "MAD", limit: 20, offset: 0)
        }
    }
    
    @Test("live_emptyKey_throwsMissingKeyWithoutRequest")
    func live_emptyKey_throwsMissingKeyWithoutRequest() async {
        let repo = AviationstackFlightRepository.live(accessKey: "")
        await #expect(throws: ServiceError.missingKey) {
            try await repo.departures(from: "MAD", limit: 20, offset: 0)
        }
    }
    
    private func response(_ status: Int) -> URLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.aviationstack.com")!, statusCode: status,
            httpVersion: nil, headerFields: nil)!
    }
    
    @Test("validate_ok_returnsData")
    func validate_ok_returnsData() throws {
        let data = Data("ok".utf8)
        #expect(try AviationstackFlightRepository.validate(data, response(200)) == data)
    }
    
    @Test("validate_5xx_throwsServer")
    func validate_5xx_throwsServer() {
        #expect(throws: ServiceError.server) {
            try AviationstackFlightRepository.validate(Data(), response(503))
        }
    }
    
    @Test("validate_4xx_returnsDataForErrorBody")
    func validate_4xx_returnsDataForErrorBody() throws {
        let data = Data(#"{"error":{"code":"invalid_access_key","message":"x"}}"#.utf8)
        #expect(try AviationstackFlightRepository.validate(data, response(401)) == data)
    }
}
