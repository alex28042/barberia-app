# Navaja · app de reservas para barbería

App de iOS (SwiftUI, iOS 26): el cliente reserva barbero, servicio y hora, paga una señal y recibe un recordatorio; el barbero ve su agenda, lo facturado y la lista de espera.

Esta versión funciona sola, sin servidor: los datos son de ejemplo (en memoria, los mismos en cada arranque) y el pago está simulado. El backend (API, PostgreSQL y Stripe) no va incluido.

## Arrancar

```sh
cd ios
xcodegen generate
open Barberia.xcodeproj
```

Hace falta [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) y Xcode 26 o posterior. Para probarla en un iPhone, pon tu equipo en `DEVELOPMENT_TEAM` dentro de `ios/project.yml`.

Desde Xcode, el esquema `Barberia` arranca con `-demoReminder`: el recordatorio "del día antes" llega a los 6 segundos de reservar, para no tener que esperar.

Atajos solo en Debug: `-openBookingStart`, `-openBooking`, `-openCheckout`, `-openConfirmation`, `-startOnDashboard`.

## Diseño

```
BarberiaApp ──> AppDependencies (raíz de composición · Factory)
                   ├─> InMemoryBookingRepository ──> «BookingRepository»   (Repository)
                   │        └─ sembrado por DemoScheduleSeeder + DemoCatalog
                   ├─> SimulatedPaymentGateway ──> «PaymentGateway»          (Strategy: Stripe después)
                   ├─> LocalNotificationReminderScheduler ──> «ReminderScheduler»
                   ├─> BookingFlowModel (@Observable) ──> SlotGenerator (puro)
                   └─> DashboardModel   (@Observable)
RootView ─ BrandTabBar ─┬─ HomeView ─> BookingView (3 pasos) ─> CheckoutSheet ─> ConfirmationView
                        └─ DashboardView
```

- Marca en `DesignSystem/Brand.swift`: colores, Bricolage Grotesque (OFL, en `Resources/Fonts`) y animaciones.
- Para usar una barbería real: cambia nombre, dirección, barberos y precios en `Data/DemoCatalog.swift`.
- Para cobrar de verdad: implementa `PaymentGateway` contra un backend con Stripe y cámbialo en `AppDependencies`.
