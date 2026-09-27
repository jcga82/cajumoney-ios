import SwiftUI

struct BudgetsView: View {
    @StateObject private var vm = BudgetsViewModel()
    @State private var collapsedGroups: Set<String> = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            periodPicker
                            if let summary = vm.summary { summaryCard(summary) }
                            ForEach(vm.groups, id: \.title) { group in
                                groupSection(group)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Presupuestos")
            .appBackground()
            .refreshable { await vm.load() }
            .task { await vm.load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await vm.load() } }
            }
            .onChange(of: vm.period) { _ in Task { await vm.load() } }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: { Text(vm.errorMessage ?? "") })
        }
    }

    // MARK: - Period picker

    private var periodPicker: some View {
        Picker("Período", selection: $vm.period) {
            Text("Mes").tag("mes")
            Text("Trimestre").tag("trim")
            Text("Año").tag("anual")
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary card

    private func summaryCard(_ s: BudgetSummary) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("RESTANTE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                Text(fmt(s.totalRemaining))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(s.totalRemaining >= 0 ? Color.primary : Color.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().frame(height: 44)

            VStack(alignment: .trailing, spacing: 6) {
                Text("PRESUPUESTADOS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                Text(fmt(s.totalBudgeted))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Group section (accordion)

    private func groupSection(_ group: (title: String, items: [BudgetItem])) -> some View {
        let isCollapsed = collapsedGroups.contains(group.title)
        let totalSpent    = group.items.reduce(0) { $0 + $1.spent }
        let totalBudgeted = group.items.reduce(0) { $0 + $1.budgeted }
        let groupColor: Color = group.title.contains("Ingreso") || group.title.contains("Renta") ? .green : .orange

        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isCollapsed { collapsedGroups.remove(group.title) }
                    else           { collapsedGroups.insert(group.title) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(fmt(totalSpent)) / \(fmt(totalBudgeted))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(groupColor))
                }
                .padding()
            }

            // Items
            if !isCollapsed {
                VStack(spacing: 8) {
                    ForEach(group.items) { item in
                        BudgetItemRow(item: item)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func fmt(_ v: Double) -> String {
        v.formatted(.number.precision(.fractionLength(0))) + " €"
    }
}

// MARK: - Budget item row (progress bar background)

struct BudgetItemRow: View {
    let item: BudgetItem

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Progress bar background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(barColor.opacity(0.25))

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(barColor.opacity(0.6))
                    .frame(width: min(CGFloat(item.percentage / 100), 1.0) * geo.size.width)

                // 100% threshold line
                Rectangle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 2)
                    .offset(x: geo.size.width - 2)

                // Content
                HStack(spacing: 8) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.3))
                            .frame(width: 32, height: 32)
                        Image(systemName: iconSymbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                    Text(item.categoryName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(fmtShort(item.spent)) / \(fmtShort(item.budgeted)) €")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(height: 48)
    }

    private var barColor: Color {
        if item.isOverBudget { return .red }
        if item.percentage > 80 { return Color(red: 0.9, green: 0.6, blue: 0.1) }
        return .green
    }

    private var iconColor: Color {
        if let hex = item.categoryColor, !hex.isEmpty { return Color(hex: hex) }
        return barColor
    }

    private var iconSymbol: String {
        if let icon = item.categoryIcon, !icon.isEmpty { return icon }
        let name = item.categoryName.lowercased()
        if name.contains("alquiler") { return "house.fill" }
        if name.contains("dividendo") { return "chart.line.uptrend.xyaxis" }
        if name.contains("agua") { return "drop.fill" }
        if name.contains("luz") || name.contains("electricidad") { return "bolt.fill" }
        if name.contains("salud") || name.contains("gym") { return "figure.run" }
        if name.contains("impuesto") { return "doc.text.fill" }
        if name.contains("biomasa") || name.contains("gas") { return "flame.fill" }
        if name.contains("coche") || name.contains("vehiculo") { return "car.fill" }
        return "chart.bar.fill"
    }

    private func fmtShort(_ v: Double) -> String {
        v.formatted(.number.precision(.fractionLength(0)))
    }
}
