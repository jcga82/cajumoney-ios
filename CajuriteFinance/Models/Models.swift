import Foundation

// MARK: - Transaction

enum TransactionType: String, Codable, CaseIterable {
    case income   = "income"
    case expense  = "expense"
    case transfer = "transfer"

    var label: String {
        switch self {
        case .income:   return "Ingreso"
        case .expense:  return "Gasto"
        case .transfer: return "Transferencia"
        }
    }

    var symbol: String {
        switch self {
        case .income:   return "arrow.down.circle.fill"
        case .expense:  return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

struct AccountRef: Codable {
    let id: String
    let name: String
}

struct CategoryRef: Codable {
    let id: String
    let name: String
    let color: String?
    let icon: String?
}

struct Transaction: Codable, Identifiable {
    let id: String
    let date: String
    let amount: Double
    let currency: String
    let description: String
    let notes: String?
    let type: TransactionType
    let account: AccountRef?
    let category: CategoryRef?

    var signedAmount: Double {
        type == .expense ? -amount : amount
    }
}

// MARK: - Account

struct Account: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let currency: String
    let currentBalance: Double
    let color: String?
    let icon: String?
}

// MARK: - Category

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let type: String   // "income" | "expense"
    let color: String?
    let icon: String?
}

// MARK: - API Responses

struct TransactionsResponse: Codable {
    let data: [Transaction]
    let total: Int
}
