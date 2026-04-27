import Foundation

struct ScheduledTransaction: Codable, Identifiable {
    let id: String
    let accountId: String
    let categoryId: String?
    let amount: Double
    let currency: String
    let description: String
    let frequency: String
    let nextDate: String      // "yyyy-MM-dd"
    let endDate: String?
    let isActive: Bool
    let account: AccountRef?
    let category: CategoryRef?

    var frequencyLabel: String {
        switch frequency {
        case "daily":     return "Cada día"
        case "weekly":    return "Cada semana"
        case "monthly":   return "Cada mes"
        case "quarterly": return "Cada 3 meses"
        case "yearly":    return "Cada año"
        default:          return frequency
        }
    }

    var nextDateParsed: Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: String(nextDate.prefix(10))) ?? Date()
    }

    var isOverdue: Bool { nextDateParsed < Calendar.current.startOfDay(for: Date()) }
    var isDueToday: Bool {
        Calendar.current.isDateInToday(nextDateParsed)
    }
}
