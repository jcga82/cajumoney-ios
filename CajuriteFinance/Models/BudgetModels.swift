import Foundation

struct BudgetSummary: Codable {
    let totalBudgeted: Double
    let totalSpent: Double
    let totalRemaining: Double
    let percentageUsed: Double
    let overBudgetCount: Int
}

struct BudgetItem: Codable, Identifiable {
    var id: String { budgetId }
    let budgetId: String
    let categoryId: String
    let categoryName: String
    let categoryColor: String?
    let categoryIcon: String?
    let period: String
    let budgeted: Double
    let spent: Double
    let remaining: Double
    let percentage: Double
    let isOverBudget: Bool
    let transactionCount: Int
}

struct BudgetExecution: Codable {
    let summary: BudgetSummary
    let items: [BudgetItem]
}
