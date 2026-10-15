import CoreUtilities

public enum LegacyStringHelper {
    public static func clean(_ text: String) -> String {
        TextUtilities.trimmed(text).lowercased()
    }
}
