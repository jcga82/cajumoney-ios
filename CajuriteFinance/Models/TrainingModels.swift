import Foundation

// MARK: - Enums

enum TrainingType: String, Codable, CaseIterable {
    case base, recovery, tempo, intervals, long, rest, strength

    var label: String {
        switch self {
        case .base:      return "Base"
        case .recovery:  return "Recuperacion"
        case .tempo:     return "Tempo"
        case .intervals: return "Series"
        case .long:      return "Largo"
        case .rest:      return "Descanso"
        case .strength:  return "Fuerza"
        }
    }

    var emoji: String {
        switch self {
        case .base:      return "🏃"
        case .recovery:  return "🚶"
        case .tempo:     return "⚡️"
        case .intervals: return "🔥"
        case .long:      return "🛣️"
        case .rest:      return "💤"
        case .strength:  return "💪"
        }
    }
}

enum SessionStatus: String, Codable {
    case planned, completed, skipped
}

// MARK: - Models

struct TrainingSession: Identifiable, Codable {
    let id: String
    let name: String
    let date: String
    let type: TrainingType
    var status: SessionStatus
    let km: Double
    let min: Int
    let d_plus: Int
    let fc_target: Int
    let rpe: Int?
    let notes: String
    let actual_km: Double?
    let actual_min: Int?
    let actual_d_plus: Int?
    let actual_fc_avg: Int?
    let actual_rpe: Int?
    let actual_notes: String?
    let tss: Double?
    let garmin_activity_id: String?
    let block_id: String?
    let template_id: String?
}

struct WeeklySummary: Codable {
    let week_start: String
    let week_end: String
    let total_km: Double
    let total_min: Int
    let total_d_plus: Int
    let avg_rpe: Double?
    let session_count: Int
    let actual_km: Double
    let actual_min: Int
    let actual_d_plus: Int
    let total_tss: Double
    let completed_count: Int
}

struct GarminWellness: Identifiable, Codable {
    var id: String { date }
    let date: String
    let training_readiness_score: Int?
    let training_readiness_level: String?
    let body_battery_max: Int?
    let body_battery_min: Int?
    let vo2max: Double?
    let training_status: String?
    let hrv_ms: Double?
    let resting_heart_rate: Int?
}

// MARK: - Helpers

extension TrainingSession {
    var dateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return date }
        let out = DateFormatter()
        out.locale = Locale(identifier: "es_ES")
        out.dateFormat = "EEEE d MMM"
        return out.string(from: d).capitalized
    }

    var durationFormatted: String {
        let h = min / 60
        let m = min % 60
        if h > 0 { return "\(h)h \(m)min" }
        return "\(m)min"
    }
}

extension WeeklySummary {
    static func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)min" }
        return "\(m)min"
    }
}

extension GarminWellness {
    var readinessColor: String {
        switch training_readiness_level?.uppercased() {
        case "HIGH":     return "green"
        case "GOOD":     return "green"
        case "MODERATE": return "orange"
        case "POOR":     return "red"
        default:         return "secondary"
        }
    }

    var readinessLabel: String {
        switch training_readiness_level?.uppercased() {
        case "HIGH":     return "Alta"
        case "GOOD":     return "Buena"
        case "MODERATE": return "Moderada"
        case "POOR":     return "Baja"
        default:         return training_readiness_level ?? "—"
        }
    }
}

