# cajurite-ios

App iOS personal para registrar transacciones del día a día. Complementa el dashboard web `dashboard.cajurite.es`.

## Stack
- SwiftUI + URLSession, sin dependencias externas
- iOS 17+, Swift
- Xcode, Apple Developer account personal

## Proyecto
- Directorio: `/Users/jcga82/Developer/cajurite-ios/`
- Target: `CajuriteFinance`

## Backend
- API base: `https://dashboard.cajurite.es`
- Auth: header `x-api-key` en todas las peticiones
- API key en `Config.swift`

## Endpoints usados

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/api/finance/transactions?startDate=&endDate=` | Transacciones del día |
| POST | `/api/finance/transactions` | Crear transacción |
| GET | `/api/finance/accounts` | Lista de cuentas (picker) |
| GET | `/api/finance/categories` | Lista de categorías (picker) |

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

## Estructura de archivos

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

- **Hoy:** resumen (ingresos / gastos / balance) + lista de transacciones. Botón `+` abre sheet.
- **Nueva transacción (sheet):** tipo (ingreso/gasto), importe, descripción, cuenta, categoría, fecha, notas.

## Relación con cajurite-metricas
- El middleware `src/middleware.ts` protege `/api/finance/*`
- Peticiones sin `Origin` (servidor) y desde `dashboard.cajurite.es` pasan sin key
- La app móvil siempre envía `x-api-key` en el header
