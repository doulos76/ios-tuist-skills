import DesignSystem

public enum Layout {
    public static func padded(_ value: Double) -> Double {
        value + Tokens.spacing
    }
}
