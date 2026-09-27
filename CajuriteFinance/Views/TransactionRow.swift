import SwiftUI

struct TransactionRow: View {
    let tx: Transaction
    var balance: Double? = nil   // saldo tras esta transacción (opcional)
    var showAccount: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            CategoryIcon(category: tx.category.map {
                CategoryRef(id: $0.id, name: $0.name, color: $0.color, icon: $0.icon)
            }, type: tx.type, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(tx.description)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if showAccount, let acc = tx.account {
                        Text(acc.name).lineLimit(1)
                        Text("·")
                    } else if let notes = tx.notes, !notes.isEmpty {
                        Text(notes).lineLimit(1)
                        Text("·")
                    }
                    Text(shortDate(tx.date))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(formattedAmount)
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(amountColor)
                if let balance {
                    Text(balance.formatted(.number.precision(.fractionLength(2))) + " €")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var amountColor: Color {
        switch tx.type {
        case .income:   return .green
        case .expense:  return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .transfer: return .secondary
        }
    }

    private var formattedAmount: String {
        let prefix = tx.type == .expense ? "-" : (tx.type == .income ? "+" : "")
        return "\(prefix)\(tx.amount.formatted(.number.precision(.fractionLength(2)))) €"
    }

    private func shortDate(_ iso: String) -> String {
        let f  = DateFormatter(); f.dateFormat  = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let f2 = DateFormatter(); f2.dateFormat = "yyyy-MM-dd"
        let date = f.date(from: iso) ?? f2.date(from: iso) ?? Date()
        let out = DateFormatter()
        out.dateStyle = .short; out.timeStyle = .none
        out.locale = Locale(identifier: "es_ES")
        return out.string(from: date)
    }
}
