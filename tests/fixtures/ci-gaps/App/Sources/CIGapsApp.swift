import SwiftUI

@main
struct CIGapsApp: App {
    var body: some Scene {
        WindowGroup {
            Text(Greeting.text)
        }
    }
}

enum Greeting {
    static let text = "Hello, CI"
}
