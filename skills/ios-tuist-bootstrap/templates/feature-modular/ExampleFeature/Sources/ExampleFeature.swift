import SwiftUI

public struct ExampleFeatureView: View {
    private let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        Text(FeatureGreeting.message(for: name))
            .padding()
    }
}

public enum FeatureGreeting {
    public static func message(for name: String) -> String {
        "Hello, \(name)!"
    }
}
