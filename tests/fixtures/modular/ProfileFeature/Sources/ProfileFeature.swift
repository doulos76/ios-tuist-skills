import SharedUI
import SwiftUI

public struct ProfileView: View {
    private let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text(ProfileFormatter.greeting(for: name))
            StatusBadge(label: "Member")
        }
        .padding()
    }
}

public enum ProfileFormatter {
    public static func greeting(for name: String) -> String {
        "Hello, \(name)"
    }
}
