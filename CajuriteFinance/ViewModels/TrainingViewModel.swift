import Foundation
import UIKit

@MainActor
final class TrainingViewModel: ObservableObject {
    @Published var sessions: [TrainingSession] = []
    @Published var summary: WeeklySummary?
    @Published var wellness: [GarminWellness] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Current week start (Monday)
    private(set) var weekStart: String = ""

    init() {
        weekStart = Self.currentWeekStart()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let monday = weekStart
        let sunday = Self.addDays(7, to: monday)
        // Load a bit wider (prev day to next Sunday) so we see today even near boundaries
        let rangeEnd = Self.addDays(13, to: monday)

        do {
            async let sessionsTask = APIClient.shared.fetchTrainingSessions(dateFrom: monday, dateTo: rangeEnd)
            async let summaryTask = APIClient.shared.fetchWeeklySummary(weekStart: monday)
            async let wellnessTask = APIClient.shared.fetchWellness(dateFrom: monday, dateTo: sunday)

            let (s, w, wl) = try await (sessionsTask, summaryTask, wellnessTask)
            sessions = s
            summary = w
            wellness = wl
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }

    func previousWeek() {
        weekStart = Self.addDays(-7, to: weekStart)
        Task { await load() }
    }

    func nextWeek() {
        weekStart = Self.addDays(7, to: weekStart)
        Task { await load() }
    }

    var todaySession: TrainingSession? {
        let today = Self.isoDate(Date())
        return sessions.first { $0.date == today }
    }

    var todayWellness: GarminWellness? {
        let today = Self.isoDate(Date())
        return wellness.first { $0.date == today }
            ?? wellness.last
    }

    var weekLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let start = f.date(from: weekStart) else { return weekStart }
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        let out = DateFormatter()
        out.locale = Locale(identifier: "es_ES")
        out.dateFormat = "d MMM"
        return "\(out.string(from: start)) – \(out.string(from: end))"
    }

    // MARK: - Helpers

    static func currentWeekStart() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let monday = cal.date(from: comps)!
        return isoDate(monday)
    }

    static func addDays(_ days: Int, to iso: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: iso) else { return iso }
        let result = Calendar.current.date(byAdding: .day, value: days, to: date)!
        return isoDate(result)
    }

    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
