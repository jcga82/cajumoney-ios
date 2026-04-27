import SwiftUI

// MARK: - Account Icon (logo del banco via Clearbit + fallback SF Symbol)

struct AccountIcon: View {
    let account: Account
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let assetName = assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(iconColor.gradient)
                .frame(width: size, height: size)
            Image(systemName: iconSymbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // Busca un asset con el nombre clave del banco (ej. "bbva", "bankinter", "ibkr")
    private var assetName: String? {
        let name = account.name.lowercased()
        let keys = ["bbva", "bankinter", "ibkr", "degiro", "myinvestor",
                    "crescenta", "coinbase", "metamask", "ninja", "stripe", "letter"]
        return keys.first(where: { name.contains($0) })
    }

    // MARK: - Fallback SF Symbol

    private var iconSymbol: String {
        if let icon = account.icon, !icon.isEmpty { return icon }
        let name = account.name.lowercased()
        if name.contains("ibkr") || name.contains("interactive") { return "chart.line.uptrend.xyaxis" }
        if name.contains("préstamo") || name.contains("prestamo") { return "house.fill" }
        if name.contains("cash") || name.contains("efectivo")     { return "banknote.fill" }
        if name.contains("crypto") || name.contains("kucoin")     { return "bitcoinsign.circle.fill" }
        if name.contains("iphone") || name.contains("apple")      { return "iphone" }
        switch account.type {
        case "investment": return "chart.line.uptrend.xyaxis"
        case "credit":     return "creditcard.fill"
        case "cash":       return "banknote.fill"
        default:           return "building.columns.fill"
        }
    }

    private var iconColor: Color {
        if let hex = account.color, !hex.isEmpty { return Color(hex: hex) }
        let name = account.name.lowercased()
        if name.contains("bbva")      { return Color(hex: "004B9D") }
        if name.contains("bankinter") { return Color(hex: "E8450A") }
        if name.contains("ibkr")      { return Color(hex: "C8102E") }
        if name.contains("degiro")    { return Color(hex: "1B6ECF") }
        if name.contains("préstamo") || name.contains("prestamo") { return .purple }
        switch account.type {
        case "investment": return .blue
        case "credit":     return .orange
        case "cash":       return .green
        default:           return Color(hex: "3A7BD5")
        }
    }
}

// MARK: - Category Icon (SF Symbols)

struct CategoryIcon: View {
    let category: CategoryRef?
    let type: TransactionType
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor.gradient)
                .frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var symbol: String {
        if let icon = category?.icon, !icon.isEmpty { return icon }
        guard let name = category?.name.lowercased() else {
            return type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
        }

        // Vivienda y alquileres
        if name.contains("alquiler")                              { return "house.fill" }
        if name.contains("hipoteca")                              { return "house.circle.fill" }
        if name.contains("comunidad") || name.contains("ibi")    { return "building.2.fill" }
        if name.contains("agua")                                  { return "drop.fill" }
        if name.contains("luz") || name.contains("electricidad")  { return "bolt.fill" }
        if name.contains("gas") || name.contains("biomasa")       { return "flame.fill" }
        if name.contains("basura") || name.contains("residuo")   { return "trash.fill" }

        // Ingresos
        if name.contains("sueldo") || name.contains("salario") || name.contains("nómina") { return "briefcase.fill" }
        if name.contains("dividendo")                             { return "chart.line.uptrend.xyaxis" }
        if name.contains("renta") || name.contains("pasiva")     { return "arrow.down.left.circle.fill" }
        if name.contains("stripe") || name.contains("suscripción") || name.contains("subscripción") { return "repeat.circle.fill" }
        if name.contains("venta") || name.contains("producto")   { return "bag.fill" }
        if name.contains("interés") || name.contains("interes")  { return "percent" }

        // Alimentación
        if name.contains("super") || name.contains("mercado") || name.contains("compra") { return "cart.fill" }
        if name.contains("restaurante") || name.contains("bar") || name.contains("cafetería") { return "fork.knife" }
        if name.contains("comida") || name.contains("alimenta")  { return "takeoutbag.and.cup.and.straw.fill" }

        // Transporte
        if name.contains("gasolina") || name.contains("combustible") { return "fuelpump.fill" }
        if name.contains("coche") || name.contains("vehículo") || name.contains("auto") { return "car.fill" }
        if name.contains("metro") || name.contains("tren") || name.contains("transporte público") { return "tram.fill" }
        if name.contains("taxi") || name.contains("uber")         { return "car.circle.fill" }
        if name.contains("avión") || name.contains("vuelo") || name.contains("viaje") { return "airplane" }
        if name.contains("parking") || name.contains("aparca")   { return "p.circle.fill" }

        // Salud
        if name.contains("salud") || name.contains("médico") || name.contains("médica") { return "cross.fill" }
        if name.contains("gym") || name.contains("deporte") || name.contains("fitness") { return "figure.run" }
        if name.contains("farmacia") || name.contains("medicamento") { return "pills.fill" }
        if name.contains("dental") || name.contains("dentista")  { return "mouth.fill" }

        // Ocio y entretenimiento
        if name.contains("netflix") || name.contains("streaming") || name.contains("tv") { return "tv.fill" }
        if name.contains("música") || name.contains("spotify")   { return "music.note" }
        if name.contains("cine") || name.contains("película")    { return "film.fill" }
        if name.contains("juego") || name.contains("game")       { return "gamecontroller.fill" }
        if name.contains("libro") || name.contains("lectura")    { return "book.fill" }
        if name.contains("ocio") || name.contains("entreteni")   { return "star.fill" }

        // Tecnología y comunicación
        if name.contains("móvil") || name.contains("teléfono") || name.contains("phone") { return "iphone" }
        if name.contains("internet") || name.contains("fibra") || name.contains("wifi")  { return "wifi" }
        if name.contains("informática") || name.contains("ordenador") { return "laptopcomputer" }
        if name.contains("software") || name.contains("app")     { return "app.fill" }

        // Ropa y personal
        if name.contains("ropa") || name.contains("moda")        { return "tshirt.fill" }
        if name.contains("peluquería") || name.contains("belleza") { return "scissors" }
        if name.contains("higiene") || name.contains("cuidado")  { return "shower.fill" }

        // Educación
        if name.contains("educación") || name.contains("escuela") || name.contains("curso") { return "graduationcap.fill" }
        if name.contains("libro") || name.contains("material")   { return "book.closed.fill" }

        // Finanzas e impuestos
        if name.contains("impuesto") || name.contains("hacienda") || name.contains("irpf") { return "doc.text.fill" }
        if name.contains("seguro")                                { return "shield.fill" }
        if name.contains("inversión") || name.contains("bolsa")  { return "chart.xyaxis.line" }
        if name.contains("ahorro")                                { return "banknote.fill" }
        if name.contains("transfer")                              { return "arrow.left.arrow.right.circle.fill" }

        // Mascotas
        if name.contains("mascota") || name.contains("veterinario") { return "pawprint.fill" }

        // Hogar
        if name.contains("mueble") || name.contains("hogar") || name.contains("decor") { return "sofa.fill" }
        if name.contains("limpieza")                              { return "bubbles.and.sparkles.fill" }
        if name.contains("reforma") || name.contains("obra")     { return "hammer.fill" }

        // Fallback por tipo
        return type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }

    private var bgColor: Color {
        if let hex = category?.color, !hex.isEmpty { return Color(hex: hex) }
        switch type {
        case .income:   return .green
        case .expense:  return Color(red: 0.85, green: 0.2, blue: 0.2)
        case .transfer: return .blue
        }
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
