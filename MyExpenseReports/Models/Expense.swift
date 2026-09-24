import Foundation
import SwiftData

/// One receipt. Money is stored as `Decimal`, never as a floating-point number.
@Model
final class Expense {
    var id: UUID
    var merchant: String
    /// Total paid, VAT included.
    var amount: Decimal
    /// VAT portion of `amount`, when known.
    var vat: Decimal?
    /// ISO 4217 code, e.g. "EUR".
    var currencyCode: String
    var date: Date
    var categoryRaw: String
    var note: String
    @Attribute(.externalStorage) var receiptImage: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Decimal,
        vat: Decimal? = nil,
        currencyCode: String = Locale.current.currency?.identifier ?? "EUR",
        date: Date = .now,
        category: ExpenseCategory = .other,
        note: String = "",
        receiptImage: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.vat = vat
        self.currencyCode = currencyCode
        self.date = date
        self.categoryRaw = category.rawValue
        self.note = note
        self.receiptImage = receiptImage
        self.createdAt = createdAt
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// The first instant of the month this expense belongs to. Used as the grouping key.
    var monthStart: Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }
}
