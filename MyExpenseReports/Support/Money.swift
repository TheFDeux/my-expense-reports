import Foundation

enum Money {
    /// Locale-aware currency string, e.g. "1 245,30 €" in fr_FR.
    static func format(_ amount: Decimal, code: String) -> String {
        amount.formatted(.currency(code: code))
    }

    /// Parses what a person types into an amount field: accepts "12,34", "12.34", "1 234,56", "€12.34".
    static func parse(_ text: String) -> Decimal? {
        var cleaned = text
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isNumber || $0 == "," || $0 == "." || $0 == "-" }
        guard !cleaned.isEmpty else { return nil }

        // Whichever of "," or "." appears last is the decimal separator; the other is grouping.
        if let lastComma = cleaned.lastIndex(of: ","), let lastDot = cleaned.lastIndex(of: ".") {
            if lastComma > lastDot {
                cleaned.removeAll { $0 == "." }
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned.removeAll { $0 == "," }
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Plain machine form for CSV and API payloads: "1234.56".
    static func plain(_ amount: Decimal) -> String {
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .bankers)
        return rounded.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).grouping(.never).precision(.fractionLength(2)))
    }
}
