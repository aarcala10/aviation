import Testing

@testable import Aviation

struct FlightSpokenTests {
    @Test("spokenDestination_usesCity_thenAirportName")
    func spokenDestination_usesCity_thenAirportName() {
        var rome = Flight.sample()
        rome.destinationCity = "Rome"
        #expect(rome.spokenDestination == "Rome")
        #expect(Flight.sample().spokenDestination == "Leonardo Da Vinci (Fiumicino)")
    }
    
    @Test("spokenTitle_isLateOnlyWhenLandedLate")
    func spokenTitle_isLateOnlyWhenLandedLate() {
        #expect(FlightStatus.landed.spokenTitle(landedLate: true) == "Aterrizado con retraso")
        #expect(FlightStatus.landed.spokenTitle(landedLate: false) == FlightStatus.landed.title)
        #expect(FlightStatus.active.spokenTitle(landedLate: false) == FlightStatus.active.title)
    }
}
