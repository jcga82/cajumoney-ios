import SwiftUI

struct NewTransactionView: View {
    @StateObject private var vm = NewTransactionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Tipo
                Section {
                    Picker("Tipo", selection: $vm.type) {
                        ForEach(TransactionType.allCases.filter { $0 != .transfer }, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Importe y descripción
                Section {
                    HStack {
                        TextField("0,00", text: $vm.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                    TextField("Descripción", text: $vm.description)
                }

                // Cuenta y categoría
                Section {
                    Picker("Cuenta", selection: $vm.selectedAccountId) {
                        ForEach(vm.accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }

                    Picker("Categoría", selection: $vm.selectedCategoryId) {
                        Text("Sin categoría").tag("")
                        ForEach(vm.filteredCategories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                }

                // Fecha y notas
                Section {
                    DatePicker("Fecha", selection: $vm.date, displayedComponents: .date)
                    TextField("Notas (opcional)", text: $vm.notes)
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nueva transacción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if vm.isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") {
                            Task { await vm.save() }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: vm.didSave) { saved in
                if saved { dismiss() }
            }
            .task { await vm.loadPickerData() }
        }
    }
}
