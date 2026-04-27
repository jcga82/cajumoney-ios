import Foundation
import UIKit

@MainActor
final class ScheduledViewModel: ObservableObject {
    @Published var items: [ScheduledTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Agrupados por fecha (overdue juntos, luego por día)
    var groups: [(title: String, items: [ScheduledTransaction])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var overdue: [ScheduledTransaction] = []
        var byDate: [Date: [ScheduledTransaction]] = [:]

        for item in items {
            let date = cal.startOfDay(for: item.nextDateParsed)
            if date < today {
                overdue.append(item)
            } else {
                byDate[date, default: []].append(item)
            }
        }

        var result: [(String, [ScheduledTransaction])] = []
        if !overdue.isEmpty {
            result.append(("Vencidas", overdue))
        }
        let sortedDates = byDate.keys.sorted()
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_ES")
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        for date in sortedDates {
            result.append((fmt.string(from: date), byDate[date]!))
        }
        return result
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await APIClient.shared.fetchScheduled()
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }

    func pay(_ item: ScheduledTransaction) async {
        do {
            try await APIClient.shared.payScheduled(id: item.id, date: Date())
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skip(_ item: ScheduledTransaction) async {
        do {
            try await APIClient.shared.skipScheduled(id: item.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: ScheduledTransaction) async {
        do {
            try await APIClient.shared.deleteScheduled(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
