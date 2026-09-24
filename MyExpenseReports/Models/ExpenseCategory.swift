import SwiftUI

/// Fixed category law: the raw values are the CSV vocabulary and the LLM schema enum,
/// so they must not change casually.
enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case meals = "Meals"
    case travel = "Travel"
    case transport = "Transport"
    case lodging = "Lodging"
    case office = "Office"
    case software = "Software"
    case equipment = "Equipment"
    case telecom = "Telecom"
    case services = "Professional services"
    case other = "Other"

    var id: String { rawValue }

    var title: String { rawValue }

    var symbolName: String {
        switch self {
        case .meals: "fork.knife"
        case .travel: "airplane"
        case .transport: "car.fill"
        case .lodging: "bed.double.fill"
        case .office: "paperclip"
        case .software: "app.badge"
        case .equipment: "desktopcomputer"
        case .telecom: "antenna.radiowaves.left.and.right"
        case .services: "briefcase.fill"
        case .other: "tag.fill"
        }
    }

    /// System colors adapt to dark mode and increased contrast on their own.
    /// Orange and brown are deliberately absent: they would collide with the Kraft tint and read as controls.
    var color: Color {
        switch self {
        case .meals: .red
        case .travel: .blue
        case .transport: .indigo
        case .lodging: .purple
        case .office: .teal
        case .software: .mint
        case .equipment: .cyan
        case .telecom: .green
        case .services: .pink
        case .other: .gray
        }
    }
}
