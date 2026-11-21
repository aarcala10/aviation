extension Flight {
    /// What VoiceOver says for the destination: the city, or the API's airport name.
    var spokenDestination: String { destinationCity.isEmpty ? destinationName : destinationCity }
}
