import SwiftUI

struct TodayView: View {
    @StateObject private var vm = TodayViewModel()
    @State private var showNew = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        summarySection
                        transactionsSection
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Hoy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNew = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showNew, onDismiss: {
                Task { await vm.load() }
            }) {
                NewTransactionView()
            }
            .refreshable { await vm.load() }
            .task { await vm.load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await vm.load() } }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                summaryItem(label: "Ingresos", amount: vm.totalIncome, color: .green)
                Divider()
                summaryItem(label: "Gastos",   amount: vm.totalExpense, color: .red)
                Divider()
                summaryItem(label: "Balance",  amount: vm.balance,      color: vm.balance >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private func summaryItem(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(amount.formatted(.number.precision(.fractionLength(2))))€")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var transactionsSection: some View {
        Section {
            if vm.transactions.isEmpty {
                Text("Sin transacciones hoy")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(vm.transactions) { tx in
                    TransactionRow(tx: tx)
                }
            }
        } header: {
            Text("Transacciones (\(vm.transactions.count))")
        }
    }
}
