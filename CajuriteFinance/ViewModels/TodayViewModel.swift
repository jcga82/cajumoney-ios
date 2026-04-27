import Foundation
import UIKit

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double { totalIncome - totalExpense }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            transactions = try await APIClient.shared.fetchTodayTransactions()
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }
}
