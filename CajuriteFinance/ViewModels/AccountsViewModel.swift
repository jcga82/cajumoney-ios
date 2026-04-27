import Foundation
import UIKit

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var netWorth: Double {
        accounts.filter { $0.currentBalance > 0 }.reduce(0) { $0 + $1.currentBalance }
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
            accounts = try await APIClient.shared.fetchAccounts()
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }
}
