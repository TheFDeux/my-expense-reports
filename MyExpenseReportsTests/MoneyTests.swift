import Testing
import Foundation
@testable import MyExpenseReports

struct MoneyTests {
    @Test("Parses French and English decimal input")
    func parsesTypedAmounts() {
        #expect(Money.parse("12,34") == Decimal(string: "12.34"))
        #expect(Money.parse("12.34") == Decimal(string: "12.34"))
        #expect(Money.parse("1 234,56") == Decimal(string: "1234.56"))
        #expect(Money.parse("1,234.56") == Decimal(string: "1234.56"))
        #expect(Money.parse("€42") == Decimal(42))
        #expect(Money.parse("") == nil)
        #expect(Money.parse("abc") == nil)
    }

    @Test("Plain form is machine-readable with two decimals")
    func plainForm() {
        #expect(Money.plain(Decimal(string: "1234.5")!) == "1234.50")
        #expect(Money.plain(Decimal(string: "0.005")!) == "0.00")
        #expect(Money.plain(Decimal(7)) == "7.00")
    }
}
