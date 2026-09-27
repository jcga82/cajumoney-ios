import SwiftUI

struct TrainingView: View {
    @StateObject private var vm = TrainingViewModel()
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
                            if vm.todayWellness != nil { wellnessCard }
                            weekNavigatorCard
                            if vm.summary != nil { summaryCard }
                            sessionsCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .refreshable { await vm.load() }
                }
            }
            .navigationTitle("Entrenamiento")
            .appBackground()
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

    // MARK: - Wellness card

    @ViewBuilder
    private var wellnessCard: some View {
        if let w = vm.todayWellness {
            VStack(spacing: 12) {
                Text("Estado hoy")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    if let score = w.training_readiness_score {
                        wellnessTile(value: "\(score)", label: "Readiness",
                                     sub: w.readinessLabel, colorName: w.readinessColor)
                        Divider()
                    }
                    if let max = w.body_battery_max, let min = w.body_battery_min {
                        wellnessTile(value: "\(max)", label: "Body Battery",
                                     sub: "min \(min)",
                                     colorName: max >= 70 ? "green" : max >= 40 ? "orange" : "red")
                        Divider()
                    }
                    if let hrv = w.hrv_ms {
                        wellnessTile(value: "\(Int(hrv))", label: "HRV", sub: "ms", colorName: "secondary")
                        Divider()
                    }
                    if let rhr = w.resting_heart_rate {
                        wellnessTile(value: "\(rhr)", label: "FC Reposo", sub: "bpm", colorName: "secondary")
                    }
                }
                .frame(maxWidth: .infinity)

                if let status = w.training_status {
                    Divider()
                    HStack {
                        Text("Estado de carga").foregroundStyle(.secondary)
                        Spacer()
                        Text(trainingStatusLabel(status))
                            .fontWeight(.medium)
                            .foregroundStyle(trainingStatusColor(status))
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }

    private func wellnessTile(value: String, label: String, sub: String, colorName: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(colorForName(colorName))
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(sub).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "green":  return .green
        case "orange": return .orange
        case "red":    return .red
        default:       return .secondary
        }
    }

    private func trainingStatusLabel(_ status: String) -> String {
        switch status.uppercased() {
        case "PRODUCTIVE":   return "Productivo"
        case "MAINTAINING":  return "Mantenimiento"
        case "PEAKING":      return "Pico de forma"
        case "RECOVERY":     return "Recuperacion"
        case "OVERREACHING": return "Sobre-entreno"
        default:             return status
        }
    }

    private func trainingStatusColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "PRODUCTIVE", "PEAKING": return .green
        case "MAINTAINING":           return .blue
        case "RECOVERY":              return .orange
        case "OVERREACHING":          return .red
        default:                      return .primary
        }
    }

    // MARK: - Week navigator card

    private var weekNavigatorCard: some View {
        HStack {
            Button { vm.previousWeek() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            Spacer()
            Text(vm.weekLabel).font(.subheadline.weight(.medium))
            Spacer()
            Button { vm.nextWeek() } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Weekly summary card

    @ViewBuilder
    private var summaryCard: some View {
        if let s = vm.summary {
            VStack(spacing: 8) {
                Text("Semana: planificado / real")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    summaryTile(planned: String(format: "%.1f km", s.total_km),
                                actual: String(format: "%.1f km", s.actual_km),
                                label: "Distancia")
                    Divider()
                    summaryTile(planned: WeeklySummary.formatDuration(s.total_min),
                                actual: WeeklySummary.formatDuration(s.actual_min),
                                label: "Duracion")
                    Divider()
                    summaryTile(planned: "\(s.session_count) ses.",
                                actual: "\(s.completed_count) hec.",
                                label: "Sesiones")
                    if s.total_tss > 0 {
                        Divider()
                        summaryTile(planned: "—",
                                    actual: String(format: "%.0f TSS", s.total_tss),
                                    label: "Carga")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }

    private func summaryTile(planned: String, actual: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(actual).font(.subheadline.monospacedDigit().weight(.semibold))
            Text(planned).font(.caption2).foregroundStyle(.secondary)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    // MARK: - Sessions card

    private var sessionsCard: some View {
        VStack(spacing: 0) {
            Text("Sesiones")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 12)

            if vm.sessions.isEmpty {
                Text("Sin sesiones planificadas")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(vm.sessions.enumerated()), id: \.offset) { idx, session in
                    if idx > 0 { Divider().padding(.horizontal) }
                    TrainingSessionRow(session: session)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }
                .padding(.bottom, 8)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - Session Row

struct TrainingSessionRow: View {
    let session: TrainingSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(session.type.emoji)
                    Text(session.name).font(.subheadline.weight(.medium))
                    Spacer()
                    Text(session.dateFormatted).font(.caption).foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if session.km > 0   { label(String(format: "%.1f km", session.km)) }
                    if session.min > 0  { label(session.durationFormatted) }
                    if session.d_plus > 0 { label("+\(session.d_plus)m") }
                    if let rpe = session.rpe { label("RPE \(rpe)") }
                }

                if session.status == .completed {
                    HStack(spacing: 8) {
                        if let km = session.actual_km, km > 0 {
                            actualLabel(String(format: "%.1f km", km))
                        }
                        if let m = session.actual_min, m > 0 {
                            actualLabel(WeeklySummary.formatDuration(m))
                        }
                        if let rpe = session.actual_rpe { actualLabel("RPE \(rpe)") }
                        if let tss = session.tss, tss > 0 {
                            actualLabel(String(format: "%.0f TSS", tss))
                        }
                    }
                }

                if !session.notes.isEmpty {
                    Text(session.notes).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch session.status {
        case .completed: return .green
        case .skipped:   return .orange
        case .planned:   return .blue
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.1))
            .clipShape(Capsule())
    }

    private func actualLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    TrainingView()
        .preferredColorScheme(.dark)
}
