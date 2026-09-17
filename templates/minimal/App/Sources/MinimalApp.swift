import SwiftUI

@main
struct MinimalApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text(Greeting.message)
            .padding()
    }
}

enum Greeting {
    static let message = "Hello, Tuist"
}
