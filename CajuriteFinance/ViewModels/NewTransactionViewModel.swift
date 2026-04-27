import Foundation

@MainActor
final class NewTransactionViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []

    // Form fields
    @Published var amount: String = ""
    @Published var description: String = ""
    @Published var notes: String = ""
    @Published var type: TransactionType = .expense
    @Published var selectedAccountId: String = ""
    @Published var selectedCategoryId: String = ""
    @Published var date: Date = Date()

    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    var filteredCategories: [Category] {
        let t = type == .income ? "income" : "expense"
        return categories.filter { $0.type == t }
    }

    func loadPickerData() async {
        async let accs = APIClient.shared.fetchAccounts()
        async let cats = APIClient.shared.fetchCategories()
        do {
            let (a, c) = try await (accs, cats)
            accounts = a
            categories = c
            if selectedAccountId.isEmpty, let first = a.first {
                selectedAccountId = first.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard !amount.isEmpty, !description.isEmpty, !selectedAccountId.isEmpty else {
            errorMessage = "Rellena importe, descripción y cuenta."
            return
        }
        guard Double(amount.replacingOccurrences(of: ",", with: ".")) != nil else {
            errorMessage = "Importe no válido."
            return
        }

        let cleanAmount = amount.replacingOccurrences(of: ",", with: ".")
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"

        isSaving = true
        errorMessage = nil
        do {
            let body = CreateTransactionBody(
                accountId: selectedAccountId,
                categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
                date: f.string(from: date),
                amount: cleanAmount,
                currency: "EUR",
                description: description,
                notes: notes.isEmpty ? nil : notes,
                type: type.rawValue,
                tags: []
            )
            _ = try await APIClient.shared.createTransaction(body)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func reset() {
        amount = ""
        description = ""
        notes = ""
        type = .expense
        selectedCategoryId = ""
        date = Date()
        errorMessage = nil
        didSave = false
    }
}
