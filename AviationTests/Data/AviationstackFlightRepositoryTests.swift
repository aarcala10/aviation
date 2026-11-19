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
    
    @Test("departures_errorBody_throwsAPIError")
    func departures_errorBody_throwsAPIError() async throws {
        let body = Data(
            #"{"error":{"code":"usage_limit_reached","message":"Quota exceeded"}}"#.utf8)
        let repo = try makeRepo(body: body)
        await #expect(
            throws: APIError(code: "usage_limit_reached", message: "Quota exceeded")
        ) {
            try await repo.departures(from: "MAD", limit: 20, offset: 0)
        }
    }
}
