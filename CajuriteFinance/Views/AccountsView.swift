import SwiftUI

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
    default:
        return accounts.map { .account($0) }
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
                    ForEach(vm.groupedAccounts, id: \.type) { group in
                        accountGroup(group)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Cuentas")
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
                        .foregroundStyle(.blue)
                    Text(formatted(vm.totalDebt))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(vm.totalDebt < 0 ? .red : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " €"
    }
}
