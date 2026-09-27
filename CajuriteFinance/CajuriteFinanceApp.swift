import SwiftUI

@main
struct CajuriteFinanceApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                AccountsView()
                    .tabItem { Label("Patrimonio", systemImage: "chart.pie") }
                TodayView()
                    .tabItem { Label("Este Mes", systemImage: "calendar") }
                GoalsView()
                    .tabItem { Label("IF 2027", systemImage: "flag.checkered") }
                TrainingView()
                    .tabItem { Label("Entrena", systemImage: "figure.run") }
                TransactionsView()
                    .tabItem { Label("Transacciones", systemImage: "list.bullet") }
                BudgetsView()
                    .tabItem { Label("Presupuestos", systemImage: "chart.bar.doc.horizontal") }
                ScheduledView()
                    .tabItem { Label("Programadas", systemImage: "calendar.badge.clock") }
            }
            .preferredColorScheme(.dark)
        }
    }
}
