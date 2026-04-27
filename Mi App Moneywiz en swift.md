# App móvil de finanzas — Swift nativo

App iOS personal para añadir transacciones del día a día. Complementa el dashboard web `dashboard.cajurite.es`.

## Decisiones tomadas

- **Stack:** SwiftUI + URLSession, sin dependencias externas, iOS 17+
- **Auth:** API key en header `x-api-key` (guardada en `Config.swift`)
- **Backend:** consume la API existente de cajurite-metricas
- **Distribución:** Apple Developer account propia ($99/año), instalación directa sin App Store

## API Key

```
78d440f4b52c2510fad827f368266588d0bf55e60bdd4420db06494486321626
```

### Añadir en el servidor tras el deploy
```bash
echo 'MOBILE_API_KEY="78d440f4b52c2510fad827f368266588d0bf55e60bdd4420db06494486321626"' >> /opt/cajurite-metricas/.env.local
pm2 restart cajurite-metricas
```

## Middleware de autenticación

Archivo: `src/middleware.ts` en cajurite-metricas.

- Peticiones desde `dashboard.cajurite.es` o `localhost` → pasan sin key (web sigue funcionando)
- Peticiones externas → requieren `x-api-key` en el header
- Protege todas las rutas `/api/finance/*`

## Endpoints que usa la app

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/api/finance/transactions?startDate=&endDate=` | Transacciones del día |
| POST | `/api/finance/transactions` | Crear transacción |
| GET | `/api/finance/accounts` | Lista de cuentas (picker) |
| GET | `/api/finance/categories` | Lista de categorías (picker) |

## Estructura del proyecto Swift

Proyecto en: `/Users/jcga82/Developer/cajurite-ios/`

```
CajuriteFinance/
├── CajuriteFinanceApp.swift     — entry point (@main)
├── Config.swift                 — baseURL + apiKey
├── Models/
│   └── Models.swift             — Transaction, Account, Category, TransactionType
├── Services/
│   └── APIClient.swift          — URLSession, get/post con x-api-key
├── ViewModels/
│   ├── TodayViewModel.swift     — carga transacciones del día, totales
│   └── NewTransactionViewModel.swift — estado del formulario, save()
└── Views/
    ├── TodayView.swift          — lista del día + resumen ingresos/gastos/balance
    ├── NewTransactionView.swift — sheet con formulario rápido
    └── TransactionRow.swift     — fila individual de transacción
```

## Pantallas

- **Hoy:** resumen (ingresos / gastos / balance) + lista de transacciones del día. Botón `+` para nueva.
- **Nueva transacción (sheet):** tipo (ingreso/gasto), importe, descripción, cuenta, categoría, fecha, notas.

## Pasos para crear el proyecto en Xcode

1. File → New → Project → iOS → App
2. Product Name: `CajuriteFinance`, SwiftUI, Swift, iOS 17
3. Guardar en `/Users/jcga82/Developer/cajurite-ios/`
4. Borrar `ContentView.swift` generado
5. Arrastrar carpeta `CajuriteFinance/` al proyecto (Copy items if needed)
6. Signing → Apple Developer account personal

## POST body — CreateTransaction

```json
{
  "accountId": "uuid",
  "categoryId": "uuid | null",
  "date": "yyyy-MM-dd",
  "amount": "12.50",
  "currency": "EUR",
  "description": "texto",
  "notes": "opcional",
  "type": "income | expense | transfer",
  "tags": []
}
```
