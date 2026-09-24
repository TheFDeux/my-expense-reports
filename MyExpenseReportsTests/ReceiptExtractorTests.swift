import Testing
import Foundation
@testable import MyExpenseReports

struct ReceiptExtractorTests {
    @Test("Parses a full structured reply")
    func parsesFullPayload() throws {
        let json = """
        {"merchant":" Boulangerie Martin ","total":"8.40","vat":"0.44","currency":"eur","date":"2026-09-12","category":"Meals"}
        """.data(using: .utf8)!

        let result = try ClaudeReceiptExtractor.parsePayload(json)

        #expect(result.merchant == "Boulangerie Martin")
        #expect(result.total == Decimal(string: "8.40"))
        #expect(result.vat == Decimal(string: "0.44"))
        #expect(result.currencyCode == "EUR")
        #expect(result.category == .meals)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result.date!)
        #expect(components.year == 2026 && components.month == 9 && components.day == 12)
    }

    @Test("Nulls and junk degrade to nil, never a crash")
    func parsesPartialPayload() throws {
        let json = """
        {"merchant":null,"total":null,"vat":"n/a","currency":"euros","date":"12/09/2026","category":"Snacks"}
        """.data(using: .utf8)!

        let result = try ClaudeReceiptExtractor.parsePayload(json)

        #expect(result.merchant == nil)
        #expect(result.total == nil)
        #expect(result.vat == nil)
        #expect(result.currencyCode == nil)
        #expect(result.date == nil)
        #expect(result.category == nil)
    }

    @Test("Unwraps the Messages API envelope and rejects refusals")
    func parsesEnvelope() throws {
        let ok = """
        {"id":"msg_1","type":"message","role":"assistant","model":"claude-opus-5","stop_reason":"end_turn",
         "content":[{"type":"text","text":"{\\"merchant\\":\\"Uber\\",\\"total\\":\\"23.10\\",\\"vat\\":null,\\"currency\\":\\"EUR\\",\\"date\\":null,\\"category\\":\\"Transport\\"}"}]}
        """.data(using: .utf8)!
        let result = try ClaudeReceiptExtractor.parseResponse(ok)
        #expect(result.merchant == "Uber")
        #expect(result.category == .transport)

        let refused = """
        {"id":"msg_2","type":"message","role":"assistant","stop_reason":"refusal","content":[]}
        """.data(using: .utf8)!
        #expect(throws: ExtractionError.self) {
            try ClaudeReceiptExtractor.parseResponse(refused)
        }
    }

    @Test("Request body carries the schema, the image, and the model")
    func requestBodyShape() throws {
        let body = ClaudeReceiptExtractor.requestBody(imageBase64: "AAAA")
        #expect(body["model"] as? String == "claude-opus-5")
        let output = body["output_config"] as? [String: Any]
        let format = output?["format"] as? [String: Any]
        #expect(format?["type"] as? String == "json_schema")
        // Must serialize: a bad literal here would fail at runtime on every receipt.
        _ = try JSONSerialization.data(withJSONObject: body)
    }
}
