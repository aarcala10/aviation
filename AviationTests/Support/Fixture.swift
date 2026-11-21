import Foundation
import Testing

private final class BundleToken {}

enum Fixture {
    static func data(_ name: String) throws -> Data {
        let url = try #require(
            Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
    
    static func bundledAirports(filePath: String = #filePath) throws -> Data {
        let root = URL(fileURLWithPath: filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appending(path: "Aviation/Data/Airports/airports.json"))
    }
}
