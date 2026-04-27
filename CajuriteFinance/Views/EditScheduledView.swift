import SwiftUI

struct EditScheduledView: View {
    let item: ScheduledTransaction
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var accounts: [Account] = []
    @State private var categories: [Category] = []

    @State private var description: String
    @State private var amount: String
    @State private var selectedAccountId: String
    @State private var selectedCategoryId: String
    @State private var frequency: String
    @State private var nextDate: Date

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let frequencies = [
        ("daily",     "Cada día"),
        ("weekly",    "Cada semana"),
        ("monthly",   "Cada mes"),
        ("quarterly", "Cada 3 meses"),
        ("yearly",    "Cada año"),
    ]

    init(item: ScheduledTransaction, onSave: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        _description       = State(initialValue: item.description)
        _amount            = State(initialValue: String(format: "%.2f", item.amount))
        _selectedAccountId = State(initialValue: item.accountId)
        _selectedCategoryId = State(initialValue: item.categoryId ?? "")
        _frequency         = State(initialValue: item.frequency)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        _nextDate = State(initialValue: f.date(from: String(item.nextDate.prefix(10))) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos") {
                    TextField("Descripción", text: $description)
                    HStack {
                        TextField("0,00", text: $amount)
                            .keyboardType(.decimalPad)
                        Text("€").foregroundStyle(.secondary)
                    }
                }

                Section("Cuenta y categoría") {
                    Picker("Cuenta", selection: $selectedAccountId) {
                        ForEach(accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                    Picker("Categoría", selection: $selectedCategoryId) {
                        Text("Sin categoría").tag("")
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                }

                Section("Recurrencia") {
                    Picker("Frecuencia", selection: $frequency) {
                        ForEach(frequencies, id: \.0) { f in
                            Text(f.1).tag(f.0)
                        }
                    }
                    DatePicker("Próxima fecha", selection: $nextDate, displayedComponents: .date)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Editar programada")
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
        guard !description.isEmpty, Double(clean) != nil, !selectedAccountId.isEmpty else {
            errorMessage = "Rellena todos los campos obligatorios."
            return
        }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        isSaving = true
        errorMessage = nil
        do {
            let body = CreateScheduledBody(
                accountId:  selectedAccountId,
                categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
                amount:     clean,
                currency:   "EUR",
                description: description,
                frequency:  frequency,
                nextDate:   f.string(from: nextDate)
            )
            _ = try await APIClient.shared.updateScheduled(id: item.id, body: body)
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
