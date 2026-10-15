import SwiftUI

@main
struct BarberiaApp: App {
    @State private var dependencies = AppDependencies(launchArguments: ProcessInfo.processInfo.arguments)

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies, launchOptions: DemoLaunchOptions(arguments: ProcessInfo.processInfo.arguments))
        }
    }
}
