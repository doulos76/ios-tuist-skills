import SwiftUI

public struct StatusBadge: View {
    private let label: String

    public init(label: String) {
        self.label = label
    }

    public var body: some View {
        Text(BadgeFormatter.displayText(for: label))
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.15), in: Capsule())
    }
}

public enum BadgeFormatter {
    public static func displayText(for label: String) -> String {
        label.uppercased()
    }
}
