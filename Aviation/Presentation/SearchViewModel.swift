import Foundation
import Observation

@MainActor @Observable
final class SearchViewModel {
    enum State: Equatable {
        case idle, loading
        case loaded([Airport])
        case empty(String)
        case failed(String)
    }
    
    private(set) var state: State = .idle
    private let searchAirports: SearchAirportsUseCase
    
    init(searchAirports: SearchAirportsUseCase) {
        self.searchAirports = searchAirports
    }
    
    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= SearchAirportsUseCase.minimumLength else {
            state = .idle
            return
        }
        state = .loading
        do {
            let airports = try await searchAirports(trimmed)
            // A cancelled search must never overwrite the newer one's state.
            guard !Task.isCancelled else { return }
            state = airports.isEmpty ? .empty(trimmed) : .loaded(airports)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(Self.message(for: error))
        }
    }
    
    private static func message(for error: Error) -> String {
        switch error {
        case let api as APIError where api.code.contains("limit"):
            String(localized: "Se ha agotado la cuota de la API")
        case let api as APIError where api.code.contains("access_key"):
            String(localized: "La clave de la API no es válida")
        case is URLError:
            String(localized: "Comprueba tu conexión")
        default:
            String(localized: "No se ha podido completar la búsqueda")
        }
    }
}
