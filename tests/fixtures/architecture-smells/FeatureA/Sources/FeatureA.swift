import SwiftUI

public struct FeatureAView: View {
    public init() {}

    public var body: some View {
        Text(FeatureATitleFormatter.title(for: "profile"))
            .padding()
    }
}

public enum FeatureATitleFormatter {
    public static func title(for rawValue: String) -> String {
        rawValue.uppercased()
    }
}
