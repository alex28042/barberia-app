import SwiftUI

struct RootView: View {
    @State private var booking: BookingFlowModel
    @State private var dashboard: DashboardModel
    @State private var selectedTab: AppTab
    private let launchOptions: DemoLaunchOptions

    init(dependencies: AppDependencies, launchOptions: DemoLaunchOptions) {
        _booking = State(initialValue: dependencies.makeBookingFlowModel())
        _dashboard = State(initialValue: dependencies.makeDashboardModel())
        _selectedTab = State(initialValue: launchOptions.startsOnDashboard ? .dashboard : .booking)
        self.launchOptions = launchOptions
    }

    var body: some View {
        ZStack {
            switch selectedTab {
            case .booking:
                HomeView(booking: booking, launchOptions: launchOptions)
                    .transition(.opacity)
            case .dashboard:
                DashboardView(model: dashboard)
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BrandTabBar(selection: $selectedTab)
        }
        .background(brandColors.ground.ignoresSafeArea())
        .tint(brandColors.tint)
        .preferredColorScheme(.dark)
        .environment(\.locale, spanishLocale)
    }
}

/// Debug-only shortcuts for checking a screen without tapping through the app.
struct DemoLaunchOptions {
    let startsOnDashboard: Bool
    let opensBooking: Bool
    let opensCheckout: Bool
    /// Opens booking at its first step instead of filling it in.
    let opensEmptyBooking: Bool
    /// Pays as soon as checkout opens, to reach the confirmation.
    let paysOnCheckout: Bool

    init(arguments: [String]) {
        #if DEBUG
        startsOnDashboard = arguments.contains("-startOnDashboard")
        paysOnCheckout = arguments.contains("-openConfirmation")
        opensCheckout = arguments.contains("-openCheckout") || paysOnCheckout
        opensEmptyBooking = arguments.contains("-openBookingStart")
        opensBooking = arguments.contains("-openBooking") || opensCheckout || opensEmptyBooking
        #else
        startsOnDashboard = false
        opensBooking = false
        opensCheckout = false
        opensEmptyBooking = false
        paysOnCheckout = false
        #endif
    }
}
