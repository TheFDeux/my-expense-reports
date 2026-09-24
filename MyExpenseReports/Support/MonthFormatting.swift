import Foundation

extension Date {
    /// "September 2026" in the user's locale.
    var monthTitle: String {
        formatted(.dateTime.month(.wide).year())
    }

    /// "2026-09" for filenames.
    var monthSlug: String {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
