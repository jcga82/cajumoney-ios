import Foundation
import UIKit

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var selectedAccountId: String = ""   // "" = todas

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func loadAccounts() async {
        guard accounts.isEmpty else { return }
        do {
            accounts = try await APIClient.shared.fetchAccounts()
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            transactions = try await APIClient.shared.fetchTransactions(
                startDate: startDate,
                endDate: endDate,
                accountId: selectedAccountId.isEmpty ? nil : selectedAccountId
            )
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }
}
