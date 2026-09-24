import Foundation
import UIKit
import SwiftUI

/// A slip in the pocket. Exactly three slots on every row: merchant · category + date · amount.
struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.merchant.isEmpty ? "Unnamed merchant" : expense.merchant)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Image(systemName: expense.category.symbolName)
                        .foregroundStyle(expense.category.color)
                        .font(.caption2)
                    Text(expense.category.title)
                    Text("·")
                    Text(expense.date, format: .dateTime.day().month(.abbreviated))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Money.format(expense.amount, code: expense.currencyCode))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = expense.receiptImage, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(expense.category.color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: expense.category.symbolName)
                        .foregroundStyle(expense.category.color)
                }
                .accessibilityHidden(true)
        }
    }
}

/// The pocket's tab: month leading, total trailing in the largest figure on screen, receipt count beneath.
struct MonthHeader: View {
    let group: MonthGroup
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.month.monthTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("^[\(group.expenses.count) receipt](inflect: true)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(group.totalText)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .default, value: group.totalText)
        }
        .textCase(nil)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
