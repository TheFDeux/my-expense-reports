import Foundation
import UIKit

/// What the model reads off a receipt. Every field is optional: a blurry photo yields a partial draft, never a crash.
struct ReceiptExtraction: Equatable {
    var merchant: String?
    var total: Decimal?
    var vat: Decimal?
    var currencyCode: String?
    var date: Date?
    var category: ExpenseCategory?
}

enum ExtractionError: LocalizedError {
    case noAPIKey
    case badImage
    case network(String)
    case http(Int, String)
    case refused
    case truncated
    case unreadable

    var errorDescription: String? {
        switch self {
        case .truncated: "The reply was cut short. Try again."
        case .noAPIKey: "No API key. Add one in Settings to read receipts automatically."
        case .badImage: "That image couldn't be encoded."
        case .network(let message): "Couldn't reach the API: \(message)"
        case .http(401, _): "The API key was rejected. Check it in Settings."
        case .http(429, _): "Rate limited by the API. Try again in a moment."
        case .http(let code, let message): "The API returned an error (\(code)). \(message)"
        case .refused: "The model declined to read this image."
        case .unreadable: "The reply couldn't be understood."
        }
    }
}

protocol ReceiptExtracting {
    func extract(from image: UIImage) async throws -> ReceiptExtraction
}

/// Calls the Anthropic Messages API directly over URLSession (there is no official Swift SDK).
/// Vision input as base64 JPEG; the reply is constrained to a JSON schema via `output_config.format`.
struct ClaudeReceiptExtractor: ReceiptExtracting {
    static let model = "claude-opus-5"
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    var apiKey: String
    var session: URLSession = .shared

    func extract(from image: UIImage) async throws -> ReceiptExtraction {
        guard !apiKey.isEmpty else { throw ExtractionError.noAPIKey }
        guard let jpeg = Self.encodeForUpload(image) else { throw ExtractionError.badImage }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: Self.requestBody(imageBase64: jpeg.base64EncodedString()))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ExtractionError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw ExtractionError.unreadable }
        guard (200..<300).contains(http.statusCode) else {
            throw ExtractionError.http(http.statusCode, Self.apiErrorMessage(from: data))
        }
        return try Self.parseResponse(data)
    }

    // MARK: Request

    static func requestBody(imageBase64: String) -> [String: Any] {
        [
            "model": model,
            // Thinking tokens share this budget on current models; leave room so the JSON block is never cut off.
            "max_tokens": 4096,
            "fallbacks": "default",
            "system": systemPrompt,
            "output_config": [
                "effort": "medium",
                "format": ["type": "json_schema", "schema": schema],
            ],
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": imageBase64]],
                    ["type": "text", "text": "Read this receipt and fill the schema. Today is \(ISO8601DateFormatter.string(from: .now, timeZone: .current, formatOptions: [.withFullDate]))."],
                ],
            ]],
        ]
    }

    static let systemPrompt = """
    You read photos of purchase receipts for a freelancer's expense report. \
    Return only the fields in the schema. Amounts are decimal strings with a dot, e.g. "12.50", \
    with the total being the final amount paid including all taxes. The VAT field is the tax amount \
    (not the rate); when several VAT lines exist, sum them. Dates are YYYY-MM-DD. \
    Use null for anything you cannot read with reasonable confidence rather than guessing. \
    Pick the single best category from the list.
    """

    static var schema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "required": ["merchant", "total", "vat", "currency", "date", "category"],
            "properties": [
                "merchant": ["type": ["string", "null"], "description": "Business name as printed, cleaned of address lines."],
                "total": ["type": ["string", "null"], "description": "Total paid including tax, as a decimal string like \"42.90\"."],
                "vat": ["type": ["string", "null"], "description": "Total VAT/tax amount, as a decimal string, or null."],
                "currency": ["type": ["string", "null"], "description": "ISO 4217 code such as EUR, USD, GBP, CHF."],
                "date": ["type": ["string", "null"], "description": "Purchase date, YYYY-MM-DD."],
                "category": ["type": "string", "enum": ExpenseCategory.allCases.map(\.rawValue)],
            ],
        ]
    }

    // MARK: Response

    private struct MessageResponse: Decodable {
        struct Block: Decodable {
            var type: String
            var text: String?
        }
        var content: [Block]
        var stop_reason: String?
    }

    private struct ExtractionPayload: Decodable {
        var merchant: String?
        var total: String?
        var vat: String?
        var currency: String?
        var date: String?
        var category: String?
    }

    static func parseResponse(_ data: Data) throws -> ReceiptExtraction {
        let message: MessageResponse
        do {
            message = try JSONDecoder().decode(MessageResponse.self, from: data)
        } catch {
            throw ExtractionError.unreadable
        }
        if message.stop_reason == "refusal" { throw ExtractionError.refused }
        if message.stop_reason == "max_tokens" { throw ExtractionError.truncated }
        guard let text = message.content.first(where: { $0.type == "text" })?.text,
              let json = text.data(using: .utf8) else { throw ExtractionError.unreadable }
        return try parsePayload(json)
    }

    /// Exposed for tests: turns the model's JSON object into a typed extraction.
    static func parsePayload(_ json: Data) throws -> ReceiptExtraction {
        let payload: ExtractionPayload
        do {
            payload = try JSONDecoder().decode(ExtractionPayload.self, from: json)
        } catch {
            throw ExtractionError.unreadable
        }
        var result = ReceiptExtraction()
        result.merchant = payload.merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.merchant?.isEmpty == true { result.merchant = nil }
        result.total = payload.total.flatMap(Money.parse)
        result.vat = payload.vat.flatMap(Money.parse)
        result.currencyCode = payload.currency?.uppercased()
        if let code = result.currencyCode, code.count != 3 { result.currencyCode = nil }
        result.date = payload.date.flatMap(parseDate)
        result.category = payload.category.flatMap(ExpenseCategory.init(rawValue:))
        return result
    }

    private static func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }

    private static func apiErrorMessage(from data: Data) -> String {
        struct APIError: Decodable {
            struct Inner: Decodable { var message: String? }
            var error: Inner?
        }
        return (try? JSONDecoder().decode(APIError.self, from: data))?.error?.message ?? ""
    }

    // MARK: Image

    /// Downscales to keep the request small (long edge ≤ 1568 px, the API's sweet spot) and re-encodes as JPEG.
    static func encodeForUpload(_ image: UIImage, maxEdge: CGFloat = 1568) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxEdge ? maxEdge / longest : 1
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: 0.8)
    }
}
