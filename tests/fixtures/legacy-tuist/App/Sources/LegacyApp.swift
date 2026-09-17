import SwiftUI

@main
struct LegacyApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            Text(LoginMessage.defaultText)
                .padding()
        }
    }
}

enum LoginMessage {
    static let defaultText = "Welcome back"
}
