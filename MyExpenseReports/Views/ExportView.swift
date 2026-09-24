import Foundation
import SwiftUI

/// One row per month; each hands a CSV file to the system share sheet.
struct ExportView: View {
    let months: [MonthGroup]
    @Environment(\.dismiss) private var dismiss
    @State private var files: [Date: URL] = [:]
    @State private var failure: String?

    private let exporter = CSVExporter()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(months) { group in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.month.monthTitle).font(.body)
                                Text("^[\(group.expenses.count) receipt](inflect: true) · \(group.totalText)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Spacer()
                            if let url = files[group.month] {
                                ShareLink(
                                    item: url,
                                    preview: SharePreview("Expenses \(group.month.monthTitle)", image: Image(systemName: "tablecells"))
                                ) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .labelStyle(.iconOnly)
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Share \(group.month.monthTitle) as CSV")
                            } else {
                                ProgressView().frame(width: 44, height: 44)
                            }
                        }
                    }
                } footer: {
                    Text("Columns: date, merchant, category, total incl. VAT, VAT, currency, note. Opens in Excel, Numbers and Google Sheets.")
                }
                if let failure {
                    Section {
                        Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: months.map(\.expenses.count)) { prepareFiles() }
        }
    }

    private func prepareFiles() {
        var prepared: [Date: URL] = [:]
        for group in months {
            do {
                prepared[group.month] = try exporter.writeFile(for: group.expenses, month: group.month)
            } catch {
                failure = "Couldn't write the file for \(group.month.monthTitle): \(error.localizedDescription)"
            }
        }
        files = prepared
    }
}
