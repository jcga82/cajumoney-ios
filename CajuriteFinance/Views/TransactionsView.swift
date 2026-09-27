import SwiftUI

struct TransactionsView: View {
    @StateObject private var vm = TransactionsViewModel()
    @State private var showFilters = false
    @State private var showNew = false
    @State private var editTx: Transaction? = nil
    @State private var collapsedMonths: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    totalsBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemGroupedBackground))

                    List {
                        ForEach(groupedByMonth, id: \.key) { group in
                            let isCollapsed = collapsedMonths.contains(group.key)
                            Section {
                                if !isCollapsed {
                                    ForEach(group.transactions) { tx in
                                        TransactionRow(tx: tx)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button { editTx = tx } label: {
                                                    Label("Editar", systemImage: "pencil")
                                                }
                                                .tint(.blue)
                                            }
                                    }
                                }
                            } header: {
                                monthHeader(group)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable { await vm.search() }
                }
            }
            .navigationTitle("Transacciones")
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilters = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters, onDismiss: { Task { await vm.search() } }) {
                FiltersView(vm: vm)
            }
            .sheet(isPresented: $showNew, onDismiss: { Task { await vm.search() } }) {
                NewTransactionView()
            }
            .sheet(item: $editTx) { tx in
                EditTransactionView(transaction: tx) { Task { await vm.search() } }
            }
            .task {
                await vm.loadAccounts()
                await vm.search()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: { Text(vm.errorMessage ?? "") })
        }
    }

    // MARK: - Totals bar

    private var totalsBar: some View {
        HStack(spacing: 0) {
            totalCell(title: "Gastos",   value: vm.totalExpense, prefix: "-", color: Color(red: 0.9, green: 0.3, blue: 0.3))
            Divider().frame(height: 32)
            totalCell(title: "Ingresos", value: vm.totalIncome,  prefix: "+", color: .green)
            Divider().frame(height: 32)
            VStack(spacing: 2) {
                Text("Movimientos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(vm.transactions.count)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func totalCell(title: String, value: Double, prefix: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(prefix + value.formatted(.number.precision(.fractionLength(2))) + " €")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Month header

    private func monthHeader(_ group: (key: String, title: String, transactions: [Transaction])) -> some View {
        let isCollapsed = collapsedMonths.contains(group.key)
        let income  = group.transactions.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }
        let expense = group.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isCollapsed { collapsedMonths.remove(group.key) }
                else           { collapsedMonths.insert(group.key) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if expense > 0 {
                    Text("-\(expense.formatted(.number.precision(.fractionLength(2)))) €")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                        .fixedSize()
                }
                if income > 0 {
                    Text("+\(income.formatted(.number.precision(.fractionLength(2)))) €")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                        .fixedSize()
                }
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    // MARK: - Grouping

    private var groupedByMonth: [(key: String, title: String, transactions: [Transaction])] {
        let isoFull  = DateFormatter(); isoFull.dateFormat  = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let isoShort = DateFormatter(); isoShort.dateFormat = "yyyy-MM-dd"
        let keyFmt   = DateFormatter(); keyFmt.dateFormat = "yyyy-MM"
        let titleFmt = DateFormatter(); titleFmt.locale = Locale(identifier: "es_ES"); titleFmt.dateFormat = "MMMM, yyyy"

        func parse(_ s: String) -> Date { isoFull.date(from: s) ?? isoShort.date(from: s) ?? Date() }

        var dict: [String: [Transaction]] = [:]
        for tx in vm.transactions {
            dict[String(tx.date.prefix(7)), default: []].append(tx)
        }

        return dict.keys.sorted(by: >).map { key in
            let date  = keyFmt.date(from: key) ?? Date()
            var title = titleFmt.string(from: date).capitalized
            if key == String(keyFmt.string(from: Date()).prefix(7)) {
                let m = DateFormatter(); m.locale = Locale(identifier: "es_ES"); m.dateFormat = "MMMM"
                title = m.string(from: date).capitalized
            }
            return (key: key, title: title, transactions: dict[key]!.sorted { parse($0.date) > parse($1.date) })
        }
    }
}

// MARK: - Filters Sheet

struct FiltersView: View {
    @ObservedObject var vm: TransactionsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Período rápido") {
                    Button("Este mes")        { setMonth(0) }
                    Button("Mes anterior")    { setMonth(-1) }
                    Button("Este trimestre")  { setQuarter() }
                    Button("Este año")        { setYear() }
                }
                Section("Fechas") {
                    DatePicker("Desde", selection: $vm.startDate, displayedComponents: .date)
                    DatePicker("Hasta", selection: $vm.endDate,   displayedComponents: .date)
                }
                Section("Cuenta") {
                    Picker("Cuenta", selection: $vm.selectedAccountId) {
                        Text("Todas").tag("")
                        ForEach(vm.accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Aplicar") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func setMonth(_ offset: Int) {
        let cal = Calendar.current; let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: cal.date(byAdding: .month, value: offset, to: now)!))!
        let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        vm.startDate = start; vm.endDate = min(end, now)
    }

    private func setQuarter() {
        let cal = Calendar.current; let now = Date()
        let month = cal.component(.month, from: now)
        let qStart = ((month - 1) / 3) * 3 + 1
        var comps = cal.dateComponents([.year], from: now); comps.month = qStart; comps.day = 1
        vm.startDate = cal.date(from: comps)!; vm.endDate = now
    }

    private func setYear() {
        let cal = Calendar.current; let now = Date()
        vm.startDate = cal.date(from: cal.dateComponents([.year], from: now))!
        vm.endDate = now
    }
}
