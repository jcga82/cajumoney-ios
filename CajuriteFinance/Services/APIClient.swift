import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Transactions

    func fetchTodayTransactions() async throws -> [Transaction] {
        let today = isoDate(Date())
        return try await fetchTransactions(startDate: Date(), endDate: Date(), accountId: nil)
    }

    func fetchTransactions(startDate: Date, endDate: Date, accountId: String?) async throws -> [Transaction] {
        var components = URLComponents(string: "\(Config.baseURL)/api/finance/transactions")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "startDate", value: isoDate(startDate)),
            URLQueryItem(name: "endDate",   value: isoDate(endDate)),
            URLQueryItem(name: "limit",     value: "200"),
        ]
        if let accountId { items.append(URLQueryItem(name: "accountId", value: accountId)) }
        components.queryItems = items
        let response: TransactionsResponse = try await get(components.url!)
        return response.data
    }

    func createTransaction(_ body: CreateTransactionBody) async throws -> Transaction {
        try await post(URL(string: "\(Config.baseURL)/api/finance/transactions")!, body: body)
    }

    // MARK: - Accounts

    func fetchAccounts() async throws -> [Account] {
        try await get(URL(string: "\(Config.baseURL)/api/finance/accounts")!)
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [Category] {
        try await get(URL(string: "\(Config.baseURL)/api/finance/categories")!)
    }

    // MARK: - Budgets

    func fetchBudgetExecution(period: String) async throws -> BudgetExecution {
        let url = URL(string: "\(Config.baseURL)/api/finance/budgets/execution?period=\(period)")!
        return try await get(url)
    }

    // MARK: - Scheduled

    func fetchScheduled() async throws -> [ScheduledTransaction] {
        try await get(URL(string: "\(Config.baseURL)/api/finance/scheduled")!)
    }

    func payScheduled(id: String, date: Date) async throws {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        struct Body: Encodable { let date: String }
        let _: [String: String] = (try? await post(
            URL(string: "\(Config.baseURL)/api/finance/scheduled/\(id)/pay")!,
            body: Body(date: f.string(from: date))
        )) ?? [:]
    }

    func skipScheduled(id: String) async throws {
        let _: [String: String] = (try? await post(
            URL(string: "\(Config.baseURL)/api/finance/scheduled/\(id)/skip")!,
            body: EmptyBody()
        )) ?? [:]
    }

    func updateScheduled(id: String, body: CreateScheduledBody) async throws -> ScheduledTransaction {
        var req = URLRequest(url: URL(string: "\(Config.baseURL)/api/finance/scheduled/\(id)")!)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: req)
        return try decoder.decode(ScheduledTransaction.self, from: data)
    }

    func updateTransaction(id: String, body: CreateTransactionBody) async throws -> Transaction {
        var req = URLRequest(url: URL(string: "\(Config.baseURL)/api/finance/transactions/\(id)")!)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: req)
        try checkResponse(response, data: data)
        return try decoder.decode(Transaction.self, from: data)
    }

    func deleteTransaction(id: String) async throws {
        var req = URLRequest(url: URL(string: "\(Config.baseURL)/api/finance/transactions/\(id)")!)
        req.httpMethod = "DELETE"
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        _ = try await session.data(for: req)
    }

    func deleteScheduled(id: String) async throws {
        var req = URLRequest(url: URL(string: "\(Config.baseURL)/api/finance/scheduled/\(id)")!)
        req.httpMethod = "DELETE"
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        _ = try await session.data(for: req)
    }

    // MARK: - Training

    func fetchTrainingSessions(dateFrom: String, dateTo: String) async throws -> [TrainingSession] {
        let url = URL(string: "\(Config.baseURL)/api/training/sessions?date_from=\(dateFrom)&date_to=\(dateTo)")!
        return try await get(url)
    }

    func fetchWeeklySummary(weekStart: String) async throws -> WeeklySummary {
        let url = URL(string: "\(Config.baseURL)/api/training/summary?week_start=\(weekStart)")!
        return try await get(url)
    }

    func fetchWellness(dateFrom: String, dateTo: String) async throws -> [GarminWellness] {
        let url = URL(string: "\(Config.baseURL)/api/training/wellness?date_from=\(dateFrom)&date_to=\(dateTo)")!
        return try await get(url)
    }

    // MARK: - Reports

    func fetchNetWorthHistory(range: String = "1y") async throws -> [NetWorthPoint] {
        let url = URL(string: "\(Config.baseURL)/api/finance/reports/networth-history?range=\(range)")!
        return try await get(url)
    }

    func fetchByCategory(type: String, period: String = "month") async throws -> CategoryReportResponse {
        let url = URL(string: "\(Config.baseURL)/api/finance/reports/by-category?type=\(type)&period=\(period)")!
        return try await get(url)
    }

    func fetchIFSummary() async throws -> IFSummary {
        let url = URL(string: "\(Config.baseURL)/api/resumen-if?period=mes")!
        return try await get(url)
    }

    // MARK: - Helpers

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var req = URLRequest(url: url)
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        let (data, response) = try await session.data(for: req)
        try checkResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func post<B: Encodable, T: Decodable>(_ url: URL, body: B) async throws -> T {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: req)
        try checkResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(sin cuerpo)"
            throw URLError(.badServerResponse, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"
            ])
        }
    }

    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

}

// MARK: - Request bodies

private struct EmptyBody: Encodable {}

struct CreateScheduledBody: Encodable {
    let accountId: String
    let categoryId: String?
    let amount: String
    let currency: String
    let description: String
    let frequency: String
    let nextDate: String
}

struct CreateTransactionBody: Encodable {
    let accountId: String
    let categoryId: String?
    let date: String           // "yyyy-MM-dd"
    let amount: String         // "12.50"
    let currency: String
    let description: String
    let notes: String?
    let type: String           // "income" | "expense" | "transfer"
    let tags: [String]
}

