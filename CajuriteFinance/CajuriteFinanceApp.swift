import SwiftUI

@main
struct CajuriteFinanceApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                AccountsView()
                    .tabItem { Label("Cuentas", systemImage: "creditcard") }
                TransactionsView()
                    .tabItem { Label("Transacciones", systemImage: "list.bullet") }
                BudgetsView()
                    .tabItem { Label("Presupuestos", systemImage: "chart.bar.doc.horizontal") }
                ScheduledView()
                    .tabItem { Label("Programadas", systemImage: "calendar.badge.clock") }
                TodayView()
                    .tabItem { Label("Hoy", systemImage: "calendar") }
            }
            .preferredColorScheme(.dark)
        }
    }
}
