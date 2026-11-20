/// Resolves an airport IATA code to its city, so VoiceOver can say «A Barcelona».
nonisolated protocol CityLookup: Sendable {
    func city(forIATA iata: String) -> String?
}
