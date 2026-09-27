import SwiftUI

struct ScheduledView: View {
    @StateObject private var vm = ScheduledViewModel()
    @State private var itemToDelete: ScheduledTransaction?
    @State private var itemToEdit: ScheduledTransaction?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(vm.groups, id: \.title) { group in
                            Section {
                                ForEach(group.items) { item in
                                    ScheduledRow(item: item)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                                        .contextMenu {
                                            Button {
                                                Task { await vm.pay(item) }
                                            } label: {
                                                Label("Pagar", systemImage: "checkmark.circle.fill")
                                            }

                                            Button {
                                                Task { await vm.skip(item) }
                                            } label: {
                                                Label("Omitir", systemImage: "forward.end")
                                            }

                                            Button {
                                                itemToEdit = item
                                            } label: {
                                                Label("Editar", systemImage: "pencil")
                                            }

                                            Divider()

                                            Button(role: .destructive) {
                                                itemToDelete = item
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                Task { await vm.pay(item) }
                                            } label: {
                                                Label("Pagar", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                itemToDelete = item
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                            Button {
                                                Task { await vm.skip(item) }
                                            } label: {
                                                Label("Omitir", systemImage: "forward.end")
                                            }
                                            .tint(.orange)
                                        }
                                }
                            } header: {
                                Text(group.title)
                                    .foregroundStyle(group.title == "Vencidas" ? .red : .secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Programadas")
            .appBackground()
            .refreshable { await vm.load() }
            .task { await vm.load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await vm.load() } }
            }
            .sheet(item: $itemToEdit) { item in
                EditScheduledView(item: item) { Task { await vm.load() } }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: { Text(vm.errorMessage ?? "") })
            .confirmationDialog(
                "¿Eliminar programada?",
                isPresented: .constant(itemToDelete != nil),
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let item = itemToDelete {
                        Task { await vm.delete(item) }
                        itemToDelete = nil
                    }
                }
                Button("Cancelar", role: .cancel) { itemToDelete = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Sin transacciones programadas")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row extraído como struct (necesario para contextMenu en List)

struct ScheduledRow: View {
    let item: ScheduledTransaction

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(
                category: item.category.map {
                    CategoryRef(id: $0.id, name: $0.name, color: $0.color, icon: $0.icon)
                },
                type: .expense,
                size: 42
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let acc = item.account { Text(acc.name).lineLimit(1) }
                    Text("·")
                    Text(item.frequencyLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(item.amount.formatted(.number.precision(.fractionLength(2)))) €")
                .font(.body.monospacedDigit().weight(.medium))
                .foregroundStyle(item.isOverdue ? .red : .primary)
        }
    }
}
