import Foundation

/// Builds one CSV per month. Follows RFC 4180 quoting; the field separator follows the user's locale
/// (";" where the decimal separator is ",", as Excel expects there), and a UTF-8 BOM makes Excel read accents correctly.
struct CSVExporter {
    var locale: Locale = .current

    var separator: String {
        locale.decimalSeparator == "," ? ";" : ","
    }

    static let header = ["Date", "Merchant", "Category", "Total incl. VAT", "VAT", "Currency", "Note"]

    func csv(for expenses: [Expense]) -> String {
        let rows = expenses
            .sorted { $0.date < $1.date }
            .map { expense in
                [
                    Self.isoDate(expense.date),
                    expense.merchant,
                    expense.category.rawValue,
                    Money.plain(expense.amount),
                    expense.vat.map(Money.plain) ?? "",
                    expense.currencyCode,
                    expense.note,
                ]
            }
        let lines = ([Self.header] + rows).map { row in
            row.map(escape).joined(separator: separator)
        }
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Writes the month's CSV to a temporary file the share sheet can hand to Mail, Files, AirDrop…
    func writeFile(for expenses: [Expense], month: Date) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("expenses-\(month.monthSlug).csv")
        try csv(for: expenses).data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    func escape(_ field: String) -> String {
        let needsQuotes = field.contains(separator) || field.contains("\"") || field.contains("\n") || field.contains("\r")
        guard needsQuotes else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
