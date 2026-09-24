import Testing
import Foundation
import SwiftData
@testable import MyExpenseReports

@MainActor
struct CSVExporterTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Expense.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test("Comma locale uses semicolons, quotes fields that need it, and sorts by date")
    func frenchLocaleCSV() throws {
        let context = try makeContext()
        let later = Expense(merchant: "Café \"Le Zinc\"; Paris", amount: Decimal(string: "12.50")!, vat: Decimal(string: "1.14")!,
                            currencyCode: "EUR", date: Date(timeIntervalSince1970: 1_760_000_000), category: .meals, note: "Client lunch")
        let earlier = Expense(merchant: "SNCF", amount: Decimal(89), vat: nil,
                              currencyCode: "EUR", date: Date(timeIntervalSince1970: 1_759_000_000), category: .transport)
        context.insert(later)
        context.insert(earlier)

        let csv = CSVExporter(locale: Locale(identifier: "fr_FR")).csv(for: [later, earlier])
        let lines = csv.split(separator: "\r\n").map(String.init)

        #expect(lines[0].hasPrefix("\u{FEFF}Date;Merchant;Category;Total incl. VAT;VAT;Currency;Note"))
        #expect(lines[1].contains(";SNCF;Transport;89.00;;EUR;"))
        #expect(lines[2].contains(";\"Café \"\"Le Zinc\"\"; Paris\";Meals;12.50;1.14;EUR;Client lunch"))
        #expect(lines.count == 3)
    }

    @Test("Dot locale uses commas")
    func englishLocaleCSV() throws {
        let context = try makeContext()
        let expense = Expense(merchant: "Amazon", amount: Decimal(string: "19.99")!, currencyCode: "USD", category: .equipment)
        context.insert(expense)

        let csv = CSVExporter(locale: Locale(identifier: "en_US")).csv(for: [expense])
        #expect(csv.contains("Date,Merchant,Category"))
        #expect(csv.contains(",Amazon,Equipment,19.99,,USD,"))
    }
}
