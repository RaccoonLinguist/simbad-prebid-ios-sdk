import SwiftUI

@main
struct MyApp: App {
    // Связываем запуск приложения с нашим AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}