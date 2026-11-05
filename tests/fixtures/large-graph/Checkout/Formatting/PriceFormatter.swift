public enum PriceFormatter {
    public static func format(cents: Int) -> String {
        let dollars = cents / 100
        let remainder = cents % 100
        return "$" + String(dollars) + "." + (remainder < 10 ? "0" : "") + String(remainder)
    }
}
