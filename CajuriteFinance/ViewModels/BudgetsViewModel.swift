import Foundation
import UIKit

@MainActor
final class BudgetsViewModel: ObservableObject {
    @Published var execution: BudgetExecution?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var period: String = "anual"   // mes | trim | anual

    var summary: BudgetSummary? { execution?.summary }

    // Agrupa ingresos primero, luego gastos
    var groups: [(title: String, items: [BudgetItem])] {
        guard let items = execution?.items, !items.isEmpty else { return [] }
        // Determina tipo por el icono/nombre (la API no devuelve tipo directamente)
        // Usamos heurística: categorías conocidas de ingreso vs gasto
        // Por simplicidad agrupamos todos en un único grupo por periodo
        // Si hay una jerarquía en el futuro se puede refinar
        let incomeKeywords = ["alquiler", "dividendo", "sueldo", "salario", "ingreso", "renta", "stripe", "suscripción"]
        let income  = items.filter { item in incomeKeywords.contains(where: { item.categoryName.lowercased().contains($0) }) }
        let expense = items.filter { item in !incomeKeywords.contains(where: { item.categoryName.lowercased().contains($0) }) }
        var result: [(String, [BudgetItem])] = []
        if !income.isEmpty  { result.append(("Ingresos / Rentas", income)) }
        if !expense.isEmpty { result.append(("Gastos", expense)) }
        return result
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            execution = try await APIClient.shared.fetchBudgetExecution(period: period)
        } catch {
            guard !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            errorMessage = error.localizedDescription
        }
    }
}
