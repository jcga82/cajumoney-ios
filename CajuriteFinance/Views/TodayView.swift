import SwiftUI
import Charts

struct TodayView: View {
    @StateObject private var vm = TodayViewModel()
    @State private var period = "mes"
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            periodPicker
                            summaryCard
                            projectionRow
                            if let summary = vm.ifSummary {
                                ifCard(summary)
                            }
                            if !vm.expensesByCategory.isEmpty || !vm.incomeByCategory.isEmpty {
                                categoryChartsCard
                            }
                            if !vm.topExpenses.isEmpty {
                                topExpensesCard
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Este Mes")
            .appBackground()
            .refreshable { await vm.load(period: period) }
            .task { await vm.load(period: period) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await vm.load(period: period) } }
            }
            .onChange(of: period) { _, _ in
                Task { await vm.load(period: period) }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    // MARK: - Period picker

    private var periodPicker: some View {
        Picker("Período", selection: $period) {
            Text("Mes").tag("mes")
            Text("Trimestre").tag("trim")
            Text("Año").tag("anual")
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Monthly summary card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    summaryCol(
                        label: "Ingresos",
                        amount: vm.monthlyIncome,
                        color: .green,
                        sub: "\(vm.transactionCount) transacciones"
                    )
                    Divider().frame(height: 56)
                    summaryCol(
                        label: "Gastos",
                        amount: vm.monthlyExpense,
                        color: .red,
                        sub: "en el período"
                    )
                    Divider().frame(height: 56)
                    summaryCol(
                        label: "Neto",
                        amount: vm.monthlyNet,
                        color: vm.monthlyNet >= 0 ? .green : .red,
                        sub: "ingresos − gastos"
                    )
                }
                .frame(maxWidth: .infinity)

                Divider()

                HStack {
                    Text("Tasa de ahorro")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", vm.savingsRate))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(vm.savingsRate >= 30 ? .green : vm.savingsRate >= 15 ? .orange : .red)
                }
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [.green.opacity(0.4), .teal.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    private func summaryCol(label: String, amount: Double, color: Color, sub: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatted(amount))
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category charts (moved from Patrimonio)

    private var categoryChartsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Este mes por categoría")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 12)

            HStack(alignment: .top, spacing: 0) {
                if !vm.expensesByCategory.isEmpty {
                    categoryPie(title: "Gastos", items: Array(vm.expensesByCategory.prefix(6)), baseColor: .red)
                }
                if !vm.expensesByCategory.isEmpty && !vm.incomeByCategory.isEmpty {
                    Divider()
                }
                if !vm.incomeByCategory.isEmpty {
                    categoryPie(title: "Ingresos", items: Array(vm.incomeByCategory.prefix(6)), baseColor: .green)
                }
            }
            .padding(.bottom)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func categoryPie(title: String, items: [CategoryReport], baseColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Chart(items) { item in
                SectorMark(
                    angle: .value("Importe", item.amount),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Categoría", item.categoryName))
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(height: 130)
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(items) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .frame(width: 7, height: 7)
                            .foregroundStyle(baseColor.opacity(
                                0.4 + 0.6 * (Double(items.firstIndex(where: { $0.id == item.id }) ?? 0)
                                / Double(max(items.count - 1, 1)))
                            ))
                        Text(item.categoryName)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Projection row

    private var projectionRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Media diaria")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatted(vm.dailyAvgExpense))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().frame(height: 32)

            VStack(alignment: .center, spacing: 2) {
                Text("Quedan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(vm.daysLeft) días")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Proyección mes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatted(vm.projectedMonthExpense))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(vm.projectedMonthExpense > vm.monthlyIncome ? .red : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.primary.opacity(0.07), lineWidth: 0.5))
    }

    // MARK: - IF Summary card

    private func ifCard(_ s: IFSummary) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            VStack(spacing: 10) {
                HStack {
                    Text("INDEPENDENCIA FINANCIERA")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.purple)
                    Spacer()
                    Text("este mes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 0) {
                    ifMetric(label: "Dividendos", value: formatted(s.totalDividendosNeto), sub: "neto cobrado", color: .purple)
                    Divider().frame(height: 36)
                    ifMetric(label: "Suscriptores", value: "\(s.suscriptores.total)", sub: "Cajurite Premium", color: .indigo)
                    Divider().frame(height: 36)
                    ifMetric(label: "Stripe", value: formatted(s.ventas.stripe.importe), sub: "facturado", color: .blue)
                }
            }
            .padding()
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(LinearGradient(colors: [.purple.opacity(0.4), .indigo.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }

    private func ifMetric(label: String, value: String, sub: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Top expenses card

    private var topExpensesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Mayores gastos del período")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 10)

            ForEach(Array(vm.topExpenses.enumerated()), id: \.element.id) { idx, tx in
                if idx > 0 { Divider().padding(.leading, 16) }
                HStack(spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tx.description)
                            .font(.subheadline)
                            .lineLimit(1)
                        if let cat = tx.category?.name {
                            Text(cat)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("-\(tx.amount.formatted(.number.precision(.fractionLength(2)))) €")
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .padding(.bottom, 4)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.07), lineWidth: 0.5))
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " €"
    }
}
