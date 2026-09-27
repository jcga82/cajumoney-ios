import SwiftUI
import Charts

// MARK: - Grouping constants (hardcoded, mirrors dashboard.cajurite.es)

private let carteraBolsaNames: Set<String> = [
    "ibkr cajurite", "ibkr jucargra", "ibkr juan carlos", "degiro"
]
private let investmentNamedAccounts: Set<String> = ["letter ingenieros", "pisos alquiler"]

private func isBancos(_ name: String) -> Bool {
    let l = name.lowercased()
    return l.contains("bbva") || l.contains("bankinter")
}

// MARK: - Sub-group model

private enum SubContent {
    case section(title: String, accounts: [Account])
    case account(Account)
    case accountSmall(Account)
}

private func subContents(type: String, accounts: [Account]) -> [SubContent] {
    switch type {
    case "checking":
        let bancos = accounts.filter { isBancos($0.name) }
        let otros  = accounts.filter { !isBancos($0.name) }
        var r: [SubContent] = []
        if !bancos.isEmpty { r.append(.section(title: "Bancos", accounts: bancos)) }
        if !otros.isEmpty  { r.append(.section(title: "Otros", accounts: otros)) }
        return r
    case "investment":
        let carteras = accounts.filter { carteraBolsaNames.contains($0.name.lowercased()) }
        let named    = accounts.filter { investmentNamedAccounts.contains($0.name.lowercased()) }
        let otros    = accounts.filter {
            !carteraBolsaNames.contains($0.name.lowercased()) &&
            !investmentNamedAccounts.contains($0.name.lowercased())
        }
        var r: [SubContent] = []
        if !carteras.isEmpty { r.append(.section(title: "Carteras de Bolsa", accounts: carteras)) }
        for a in named { r.append(.account(a)) }
        if !otros.isEmpty { r.append(.section(title: "Otros (Cortijo, tierras...)", accounts: otros)) }
        return r
    case "credit":
        return accounts.map { .accountSmall($0) }
    default:
        return accounts.map { .accountSmall($0) }
    }
}

// MARK: - View

struct AccountsView: View {
    @StateObject private var vm = AccountsViewModel()
    @State private var expanded: Set<String> = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    netWorthCard
                    if !vm.networthHistory.isEmpty {
                        networthChartCard
                    }
                    ForEach(vm.groupedAccounts, id: \.type) { group in
                        accountGroup(group)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .appBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Hola Juan Carlos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Patrimonio")
                            .font(.headline)
                    }
                }
            }
            .refreshable { await vm.load() }
            .task { await vm.load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await vm.load() } }
            }
            .navigationDestination(for: Account.self) { account in
                AccountTransactionsView(account: account)
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: { Text(vm.errorMessage ?? "") })
        }
    }

    // MARK: - Net Worth Card

    private var netWorthCard: some View {
        VStack(spacing: 0) {
            // Accent bar top
            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PATRIMONIO NETO")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text(formatted(vm.netWorth + vm.totalDebt))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 44)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("DEUDAS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.8))
                    Text(formatted(vm.totalDebt))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(vm.totalDebt < 0 ? .red : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    // MARK: - Account Group (accordion)

    private func accountGroup(_ group: (type: String, label: String, accounts: [Account])) -> some View {
        let isExpanded = expanded.contains(group.type)
        let total = group.accounts.reduce(0) { $0 + $1.currentBalance }
        let contents = subContents(type: group.type, accounts: group.accounts)

        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expanded.remove(group.type) }
                    else { expanded.insert(group.type) }
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(group.label)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formatted(total))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(total >= 0 ? .green : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.tertiarySystemBackground)))
                }
                .padding()
            }

            if isExpanded {
                Divider().padding(.leading, 56)
                ForEach(Array(contents.enumerated()), id: \.offset) { idx, content in
                    subContentRow(content)
                    if idx < contents.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
        )
        .onAppear {
            if expanded.isEmpty { expanded.insert(group.type) }
        }
    }

    @ViewBuilder
    private func subContentRow(_ content: SubContent) -> some View {
        switch content {
        case .section(let title, let accounts):
            subSectionHeader(title: title, accounts: accounts)
            ForEach(accounts) { account in
                Divider().padding(.leading, 72)
                indentedAccountRow(account)
            }
        case .account(let account):
            accountRow(account)
        case .accountSmall(let account):
            indentedAccountRow(account)
        }
    }

    // MARK: - Row types

    private func subSectionHeader(title: String, accounts: [Account]) -> some View {
        let total = accounts.reduce(0) { $0 + $1.currentBalance }
        return HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatted(total))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(total >= 0 ? Color.primary : Color.red)
        }
        .padding(.horizontal)
        .padding(.leading, 40)
        .padding(.vertical, 8)
    }

    private func indentedAccountRow(_ account: Account) -> some View {
        NavigationLink(value: account) {
            HStack(spacing: 12) {
                AccountIcon(account: account, size: 32)
                    .padding(.leading, 16)
                Text(account.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(formatted(account.currentBalance))
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(account.currentBalance >= 0 ? .green : .red)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func accountRow(_ account: Account) -> some View {
        NavigationLink(value: account) {
            HStack(spacing: 12) {
                AccountIcon(account: account, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(account.type.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatted(account.currentBalance))
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(account.currentBalance >= 0 ? .green : .red)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Net Worth Chart

    private var networthYDomain: ClosedRange<Double> {
        let values = vm.networthHistory.map(\.netWorth)
        guard let lo = values.min(), let hi = values.max(), lo < hi else { return 0...1 }
        let pad = (hi - lo) * 0.1
        return (lo - pad)...(hi + pad)
    }

    private var networthChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Evolución patrimonio")
                    .font(.headline)
                Spacer()
                Text("12m")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.opacity(0.15)))
            }
            .padding(.horizontal)
            .padding(.top)

            Chart(vm.networthHistory) { point in
                LineMark(
                    x: .value("Mes", point.month),
                    y: .value("Patrimonio", point.netWorth)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Mes", point.month),
                    y: .value("Patrimonio", point.netWorth)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: networthYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    if let str = value.as(String.self) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        AxisValueLabel { Text(str.suffix(5)).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let v = value.as(Double.self) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                        AxisValueLabel {
                            Text(v >= 1000 ? "\(Int(v / 1000))K" : "\(Int(v))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [.blue.opacity(0.5), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " €"
    }
}
