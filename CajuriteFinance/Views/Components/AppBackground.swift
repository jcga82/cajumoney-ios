import SwiftUI

extension View {
    func appBackground() -> some View {
        self.background(
            ZStack {
                Color.black.ignoresSafeArea()
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.05, green: 0.12, blue: 0.42), location: 0),
                        .init(color: Color(red: 0.12, green: 0.05, blue: 0.32), location: 0.45),
                        .init(color: Color(red: 0.02, green: 0.18, blue: 0.28), location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                Circle()
                    .fill(Color.blue.opacity(0.50))
                    .frame(width: 360)
                    .blur(radius: 70)
                    .offset(x: -60, y: -80)
                    .ignoresSafeArea()
                Circle()
                    .fill(Color.cyan.opacity(0.35))
                    .frame(width: 280)
                    .blur(radius: 65)
                    .offset(x: 150, y: 220)
                    .ignoresSafeArea()
                Circle()
                    .fill(Color.indigo.opacity(0.45))
                    .frame(width: 240)
                    .blur(radius: 60)
                    .offset(x: -80, y: 500)
                    .ignoresSafeArea()
            }
        )
    }
}
