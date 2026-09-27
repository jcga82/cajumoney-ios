import SwiftUI

// MARK: - Data model

private struct IncomeStream: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let today: Double
    let goal: Double
    let color: Color
}

private let streams: [IncomeStream] = [
    IncomeStream(name: "Dividendos", icon: "chart.line.uptrend.xyaxis", today: 655, goal: 900, color: .green),
    IncomeStream(name: "Primas opciones", icon: "arrow.up.arrow.down.circle", today: 570, goal: 610, color: .blue),
    IncomeStream(name: "Membresia", icon: "person.2.fill", today: 381, goal: 826, color: .orange),
    IncomeStream(name: "YouTube + Cursos", icon: "play.rectangle.fill", today: 50, goal: 100, color: .red),
]

private let gastos: Double = 1_886
private let totalToday: Double = streams.reduce(0) { $0 + $1.today }
private let totalGoal: Double = streams.reduce(0) { $0 + $1.goal }

// MARK: - View

struct GoalsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    streamsCard
                    summaryCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("IF 2027")
            .appBackground()
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Text("Estado IF hoy")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline) {
                Text(eur(totalToday))
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(totalToday >= gastos ? Color.green : Color.primary)
                Text("/ mes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Objetivo \(eur(totalGoal))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Gastos IF \(eur(gastos))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(totalToday >= gastos ? Color.green : Color.orange)
                        .frame(width: min(geo.size.width * CGFloat(totalToday / totalGoal), geo.size.width), height: 10)
                    let gastosX = geo.size.width * CGFloat(gastos / totalGoal)
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2, height: 16)
                        .offset(x: gastosX - 1, y: -3)
                }
            }
            .frame(height: 10)

            let colchon = totalToday - gastos
            HStack {
                Text(colchon >= 0 ? "Colchon actual" : "Deficit actual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text((colchon >= 0 ? "+" : "") + eur(colchon) + "/mes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colchon >= 0 ? Color.green : Color.red)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Streams

    private var streamsCard: some View {
        VStack(spacing: 0) {
            Text("Fuentes de ingreso")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 12)

            ForEach(Array(streams.enumerated()), id: \.offset) { idx, s in
                if idx > 0 { Divider().padding(.horizontal) }
                VStack(spacing: 8) {
                    HStack {
                        Label(s.name, systemImage: s.icon)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(s.color)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(eur(s.today) + "/mes")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                            Text("obj. " + eur(s.goal))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.12))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(s.color.opacity(0.8))
                                .frame(width: geo.size.width * CGFloat(min(s.today / s.goal, 1.0)), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .padding(.bottom, 4)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Summary 2027

    private var summaryCard: some View {
        VStack(spacing: 0) {
            Text("Objetivo 2027")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 12)

            Divider().padding(.horizontal)
            tile(label: "Total ingresos IF", hoy: totalToday, obj: totalGoal)
            Divider().padding(.horizontal)
            tile(label: "Gastos IF mensuales", hoy: gastos, obj: gastos, isFixed: true)
            Divider().padding(.horizontal)

            HStack {
                Text("Colchon objetivo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("+" + eur(totalGoal - gastos) + "/mes")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    private func tile(label: String, hoy: Double, obj: Double, isFixed: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Hoy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(eur(hoy))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(isFixed ? Color.primary : (hoy >= gastos ? Color.green : Color.orange))
                }
                if !isFixed {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("2027")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(eur(obj))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func eur(_ value: Double) -> String {
        "\(Int(value.rounded()))€"
    }
}

#Preview {
    GoalsView()
        .preferredColorScheme(.dark)
}
