import SwiftUI

struct AccountTransactionsView: View {
    let account: Account

    @StateObject private var vm = TransactionsViewModel()
    @State private var showNew = false
    @State private var editTx: Transaction? = nil
    @State private var collapsedMonths: Set<String> = []
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                totalsBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                let balances = runningBalances
                List {
                    ForEach(groupedByMonth, id: \.key) { group in
                        let isCollapsed = collapsedMonths.contains(group.key)
                        Section {
                            if !isCollapsed {
                                ForEach(group.transactions) { tx in
                                    TransactionRow(tx: tx, balance: balances[tx.id], showAccount: false)
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
                .refreshable { await load() }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar transacciones")
        .appBackground()
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
        }
        .sheet(isPresented: $showNew, onDismiss: { Task { await load() } }) {
            NewTransactionView()
        }
        .sheet(item: $editTx) { tx in
            EditTransactionView(transaction: tx) { Task { await load() } }
        }
        .task {
            vm.selectedAccountId = account.id
            vm.startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date())) ?? Date()
            vm.endDate = Date()
            await load()
        }
    }

    private func load() async {
        await vm.search()
    }

    // MARK: - Totals bar

    private var totalsBar: some View {
        HStack(spacing: 0) {
            totalCell(title: "Gastos",   value: vm.totalExpense,        prefix: "-", color: Color(red: 0.9, green: 0.3, blue: 0.3))
            Divider().frame(height: 32)
            totalCell(title: "Ingresos", value: vm.totalIncome,         prefix: "+", color: .green)
            Divider().frame(height: 32)
            totalCell(title: "Saldo",    value: account.currentBalance, prefix: "",  color: account.currentBalance >= 0 ? .green : Color(red: 0.9, green: 0.3, blue: 0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
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

    // MARK: - Running balance

    private var runningBalances: [String: Double] {
        let sorted = vm.transactions.sorted {
            let f  = DateFormatter(); f.dateFormat  = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let f2 = DateFormatter(); f2.dateFormat = "yyyy-MM-dd"
            let d0 = f.date(from: $0.date) ?? f2.date(from: $0.date) ?? Date.distantPast
            let d1 = f.date(from: $1.date) ?? f2.date(from: $1.date) ?? Date.distantPast
            return d0 > d1
        }
        var balances: [String: Double] = [:]
        var running = account.currentBalance
        for tx in sorted {
            balances[tx.id] = running
            switch tx.type {
            case .income:   running -= tx.amount
            case .expense:  running += tx.amount
            default: break
            }
        }
        return balances
    }

    // MARK: - Grouping

    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return vm.transactions }
        let q = searchText.lowercased()
        return vm.transactions.filter {
            $0.description.lowercased().contains(q) ||
            ($0.notes?.lowercased().contains(q) ?? false) ||
            ($0.category?.name.lowercased().contains(q) ?? false)
        }
    }

    private var groupedByMonth: [(key: String, title: String, transactions: [Transaction])] {
        let isoFull  = DateFormatter(); isoFull.dateFormat  = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let isoShort = DateFormatter(); isoShort.dateFormat = "yyyy-MM-dd"
        let titleFmt = DateFormatter(); titleFmt.locale = Locale(identifier: "es_ES"); titleFmt.dateFormat = "MMMM, yyyy"
        let keyFmt   = DateFormatter(); keyFmt.dateFormat = "yyyy-MM"

        func parse(_ s: String) -> Date { isoFull.date(from: s) ?? isoShort.date(from: s) ?? Date() }

        var dict: [String: [Transaction]] = [:]
        for tx in filteredTransactions {
            let key = String(tx.date.prefix(7))
            dict[key, default: []].append(tx)
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
