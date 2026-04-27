import Foundation

enum Config {
    static let baseURL: String = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["API_ENV"] == "local" {
            return "http://localhost:3001"
        }
        #endif
        return "https://dashboard.cajurite.es"
    }()

    static let apiKey = "78d440f4b52c2510fad827f368266588d0bf55e60bdd4420db06494486321626"
}
