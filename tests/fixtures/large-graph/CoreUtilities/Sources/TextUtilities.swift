import Foundation

public enum TextUtilities {
    public static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces)
    }
}
