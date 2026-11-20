import Testing

@testable import Aviation

struct FlightDetailViewModelTests {
    /// Delayed AZ59 MAD -> FCO with every detail present.
    private func fullFlight() -> Flight {
        var flight = Flight.sample(status: .scheduled, delay: 25)
        flight.date = "2026-11-20"
        flight.originIATA = "MAD"
        flight.originName = "Barajas"
        flight.originCity = "Madrid"
        flight.destinationCity = "Roma"
        flight.departureTerminal = "1"
        flight.departureGate = "B12"
        flight.estimatedTime = "06:35"
        flight.arrivalTerminal = "3"
        flight.arrivalGate = "C4"
        flight.arrivalScheduledTime = "08:30"
        flight.arrivalEstimatedTime = "08:55"
        flight.arrivalDelayMinutes = 25
        return flight
    }
    
    @Test("detail_showsRouteAndStatus")
    func detail_showsRouteAndStatus() {
        let viewModel = FlightDetailViewModel(flight: fullFlight())
        #expect(viewModel.originCode == "MAD")
        #expect(viewModel.destinationCode == "FCO")
        #expect(viewModel.status == .delayed)
    }
    
    @Test("detail_showsDepartureAndArrivalValues")
    func detail_showsDepartureAndArrivalValues() {
        let viewModel = FlightDetailViewModel(flight: fullFlight())
        #expect(viewModel.departureTerminal == "1")
        #expect(viewModel.departureGate == "B12")
        #expect(viewModel.departureScheduled == "05:55")
        #expect(viewModel.departureEstimated == "06:35")
        #expect(viewModel.arrivalTerminal == "3")
        #expect(viewModel.arrivalGate == "C4")
        #expect(viewModel.arrivalScheduled == "08:30")
        #expect(viewModel.arrivalEstimated == "08:55")
        #expect(viewModel.airline == "ITA Airways")
        #expect(viewModel.number == "AZ59")
    }
    
    @Test("detail_missingValue_showsDash")
    func detail_missingValue_showsDash() {
        var flight = fullFlight()
        flight.departureGate = nil
        flight.estimatedTime = ""
        flight.arrivalTerminal = nil
        flight.arrivalEstimatedTime = nil
        let viewModel = FlightDetailViewModel(flight: flight)
        #expect(viewModel.departureGate == "—")
        #expect(viewModel.departureEstimated == "—")
        #expect(viewModel.arrivalTerminal == "—")
        #expect(viewModel.arrivalEstimated == "—")
    }
    
    @Test("detail_delay_showsMinutesOrDash")
    func detail_delay_showsMinutesOrDash() {
        var flight = fullFlight()
        #expect(FlightDetailViewModel(flight: flight).departureDelay == "25 min")
        #expect(FlightDetailViewModel(flight: flight).arrivalDelay == "25 min")
        flight.arrivalDelayMinutes = nil
        let none = Flight.sample(delay: 0)
        #expect(FlightDetailViewModel(flight: flight).arrivalDelay == "—")
        #expect(FlightDetailViewModel(flight: none).departureDelay == "—")
        flight.arrivalDelayMinutes = 0
        #expect(FlightDetailViewModel(flight: flight).arrivalDelay == "—")
    }
    
    @Test("detail_date_isFormattedInUTC")
    func detail_date_isFormattedInUTC() {
        let viewModel = FlightDetailViewModel(flight: fullFlight())
        #expect(viewModel.date == "viernes, 20 de noviembre")
    }
    
    @Test("detail_spokenHeader_usesCities")
    func detail_spokenHeader_usesCities() {
        let viewModel = FlightDetailViewModel(flight: fullFlight())
        #expect(viewModel.spokenHeader == "Vuelo A Z 5 9. De Madrid a Roma. Retrasado.")
        
        var noCities = fullFlight()
        noCities.originCity = ""
        noCities.destinationCity = ""
        #expect(
            FlightDetailViewModel(flight: noCities).spokenHeader
                == "Vuelo A Z 5 9. De Barajas a Leonardo Da Vinci (Fiumicino). Retrasado.")
        
        noCities.originName = nil
        #expect(
            FlightDetailViewModel(flight: noCities).spokenHeader
                == "Vuelo A Z 5 9. De MAD a Leonardo Da Vinci (Fiumicino). Retrasado.")
    }
}
