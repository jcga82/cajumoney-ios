import Foundation

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var networthHistory: [NetWorthPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private static let excludeFromNetWorth: Set<String> = ["cuenta carmen"]

    var netWorth: Double {
        accounts
            .filter { $0.currentBalance > 0 }
            .filter { !Self.excludeFromNetWorth.contains($0.name.lowercased()) }
            .reduce(0) { $0 + $1.currentBalance }
    }

    var totalDebt: Double {
        accounts.filter { $0.currentBalance < 0 }.reduce(0) { $0 + $1.currentBalance }
    }

    var groupedAccounts: [(type: String, label: String, accounts: [Account])] {
        let order: [(String, String)] = [
            ("checking",   "Cuentas corrientes"),
            ("savings",    "Ahorro"),
            ("investment", "Inversiones"),
            ("credit",     "Crédito"),
            ("cash",       "Efectivo"),
        ]
        return order.compactMap { (type, label) in
            let filtered = accounts.filter { $0.type == type }
            guard !filtered.isEmpty else { return nil }
            return (type: type, label: label, accounts: filtered)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let accs    = APIClient.shared.fetchAccounts()
            async let history = APIClient.shared.fetchNetWorthHistory()
            accounts        = try await accs
            networthHistory = try await history
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
