import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpense: Double = 0
    @Published var transactionCount: Int = 0
    @Published var expensesByCategory: [CategoryReport] = []
    @Published var incomeByCategory: [CategoryReport] = []
    @Published var transactions: [Transaction] = []
    @Published var ifSummary: IFSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var monthlyNet: Double { monthlyIncome - monthlyExpense }
    var savingsRate: Double { monthlyIncome > 0 ? (monthlyNet / monthlyIncome) * 100 : 0 }

    private static let investmentAccountKeywords = ["ibkr", "degiro", "myinvestor", "broker"]
    private static let excludedCategoryKeywords  = ["transfer", "traspaso", "inversión", "inversion", "bolsa"]

    var topExpenses: [Transaction] {
        transactions
            .filter { tx in
                guard tx.type == .expense else { return false }
                let acc = tx.account?.name.lowercased() ?? ""
                if Self.investmentAccountKeywords.contains(where: { acc.contains($0) }) { return false }
                let cat = tx.category?.name.lowercased() ?? ""
                return !Self.excludedCategoryKeywords.contains(where: { cat.contains($0) })
            }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    var dailyAvgExpense: Double {
        let elapsed = max(1, Calendar.current.component(.day, from: Date()))
        return monthlyExpense / Double(elapsed)
    }

    var daysInMonth: Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: Date())!
        return range.count
    }

    var daysLeft: Int {
        daysInMonth - Calendar.current.component(.day, from: Date())
    }

    var projectedMonthExpense: Double {
        dailyAvgExpense * Double(daysInMonth)
    }

    func load(period: String = "mes") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let cal = Calendar.current
            let now = Date()
            let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!

            async let txs     = APIClient.shared.fetchTransactions(startDate: startOfMonth, endDate: now, accountId: nil)
            async let expRep  = APIClient.shared.fetchByCategory(type: "expense", period: period)
            async let incRep  = APIClient.shared.fetchByCategory(type: "income", period: period)
            async let ifSum   = APIClient.shared.fetchIFSummary()

            let expResult = try await expRep
            let incResult = try await incRep
            let txList    = try await txs

            transactionCount   = txList.count
            monthlyExpense     = expResult.total
            monthlyIncome      = incResult.total
            expensesByCategory = expResult.data
            incomeByCategory   = incResult.data
            transactions       = txList

            ifSummary = try? await ifSum
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - IF Summary model

struct IFSummary: Decodable {
    struct Dividendos: Decodable {
        struct Cartera: Decodable {
            let neto: Double
        }
        let cajurite: Cartera
        let jucargra: Cartera
        let personal: Cartera
    }
    struct Suscriptores: Decodable {
        let total: Int
    }
    struct Ventas: Decodable {
        struct Stripe: Decodable { let importe: Double }
        let stripe: Stripe
    }
    let dividendos: Dividendos
    let suscriptores: Suscriptores
    let ventas: Ventas

    var totalDividendosNeto: Double {
        dividendos.cajurite.neto + dividendos.jucargra.neto + dividendos.personal.neto
    }
}
