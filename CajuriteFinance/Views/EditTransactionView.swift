import SwiftUI

struct EditTransactionView: View {
    let transaction: Transaction
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var accounts: [Account] = []
    @State private var categories: [Category] = []

    @State private var amount: String
    @State private var description: String
    @State private var notes: String
    @State private var type: TransactionType
    @State private var selectedAccountId: String
    @State private var selectedCategoryId: String
    @State private var date: Date

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(transaction: Transaction, onSave: @escaping () -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        _amount             = State(initialValue: String(format: "%.2f", transaction.amount))
        _description        = State(initialValue: transaction.description)
        _notes              = State(initialValue: transaction.notes ?? "")
        _type               = State(initialValue: transaction.type)
        _selectedAccountId  = State(initialValue: transaction.account?.id ?? "")
        _selectedCategoryId = State(initialValue: transaction.category?.id ?? "")
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let f2 = DateFormatter(); f2.dateFormat = "yyyy-MM-dd"
        _date = State(initialValue: f.date(from: transaction.date) ?? f2.date(from: transaction.date) ?? Date())
    }

    var filteredCategories: [Category] {
        let t = type == .income ? "income" : "expense"
        return categories.filter { $0.type == t }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        TextField("0,00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                        Text("€").foregroundStyle(.secondary)
                    }
                    TextField("Descripción", text: $description)
                }

                Section {
                    Picker("Cuenta", selection: $selectedAccountId) {
                        ForEach(accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                    Picker("Categoría", selection: $selectedCategoryId) {
                        Text("Sin categoría").tag("")
                        ForEach(filteredCategories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                }

                Section {
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                    TextField("Notas (opcional)", text: $notes)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Editar transacción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") { Task { await save() } }
                            .fontWeight(.semibold)
                    }
                }
            }
            .task {
                async let accs = APIClient.shared.fetchAccounts()
                async let cats = APIClient.shared.fetchCategories()
                if let a = try? await accs { accounts = a }
                if let c = try? await cats { categories = c }
            }
        }
    }

    private func save() async {
        let clean = amount.replacingOccurrences(of: ",", with: ".")
        guard !description.isEmpty, Double(clean) != nil else {
            errorMessage = "Importe o descripción no válidos."
            return
        }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        isSaving = true
        errorMessage = nil
        do {
            let body = CreateTransactionBody(
                accountId:   selectedAccountId,
                categoryId:  selectedCategoryId.isEmpty ? nil : selectedCategoryId,
                date:        f.string(from: date),
                amount:      clean,
                currency:    "EUR",
                description: description,
                notes:       notes.isEmpty ? nil : notes,
                type:        type.rawValue,
                tags:        []
            )
            _ = try await APIClient.shared.updateTransaction(id: transaction.id, body: body)
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
