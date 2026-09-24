import Foundation
import UIKit
import SwiftUI
import SwiftData
import PhotosUI

/// Top level: the accordion file. One section per month, newest first; the header is the pocket's tab.
struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showAddOptions = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showLibrary = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var newExpense: NewExpenseRequest?
    @State private var editingExpense: Expense?
    @State private var pendingDeletion: Expense?
    @State private var showSettings = false
    @State private var showExport = false
    @State private var hasAPIKey = KeychainStore.read() != nil

    private var months: [MonthGroup] { MonthGroup.group(expenses, includingCurrentMonth: true) }

    var body: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export", systemImage: "square.and.arrow.up") { showExport = true }
                        .disabled(expenses.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
                // Primary action in the iOS 26 bottom bar: system glass, scroll-edge effect and safe-area handling for free.
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("Add expense", systemImage: "plus") { showAddOptions = true }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .labelStyle(.iconOnly)
                        .font(.title3.weight(.semibold))
                }
            }
            .confirmationDialog("Add an expense", isPresented: $showAddOptions, titleVisibility: .visible) {
                if CameraPicker.isAvailable {
                    Button("Take Photo", systemImage: "camera") { showCamera = true }
                }
                Button("Choose from Library", systemImage: "photo.on.rectangle") { showLibrary = true }
                Button("Enter Manually", systemImage: "square.and.pencil") { newExpense = NewExpenseRequest(image: nil) }
            } message: {
                Text(hasAPIKey
                     ? "Photos are read automatically; you confirm every field before saving."
                     : "No API key set, so photos are attached but not read. Add a key in Settings to fill fields automatically.")
            }
            // Present the form only after the camera has fully dismissed; two presentations in one update can drop the second.
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if let image = capturedImage {
                    capturedImage = nil
                    newExpense = NewExpenseRequest(image: image)
                }
            }) {
                CameraPicker { image in
                    capturedImage = image
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showLibrary, selection: $libraryItem, matching: .images)
            .onChange(of: libraryItem) { _, item in
                guard let item else { return }
                Task { await loadLibraryImage(item) }
            }
            .sheet(item: $newExpense) { request in
                ExpenseFormView(mode: .create(image: request.image))
            }
            // Deletion from the edit sheet is deferred until the sheet is gone, so the sheet never holds an invalidated model.
            .sheet(item: $editingExpense, onDismiss: {
                if let doomed = pendingDeletion {
                    pendingDeletion = nil
                    delete(doomed)
                }
            }) { expense in
                ExpenseFormView(mode: .edit(expense), onDelete: { pendingDeletion = $0 })
            }
            .sheet(isPresented: $showSettings, onDismiss: { hasAPIKey = KeychainStore.read() != nil }) {
                SettingsView()
            }
            .sheet(isPresented: $showExport) {
                ExportView(months: months.filter { !$0.expenses.isEmpty })
            }
        }
    }

    // MARK: Pieces

    private var list: some View {
        List {
            ForEach(months) { group in
                Section {
                    if group.expenses.isEmpty {
                        Text("No receipts yet this month")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(group.expenses) { expense in
                        Button { editingExpense = expense } label: {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(expense) }
                        }
                    }
                } header: {
                    MonthHeader(group: group)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: expenses.count)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No expenses yet", systemImage: "tray.and.arrow.down")
        } description: {
            Text(hasAPIKey
                 ? "Photograph a receipt and the fields fill themselves. You confirm, then save."
                 : "Add receipts by hand, or set an API key in Settings and let photos fill the fields for you.")
        } actions: {
            if !hasAPIKey {
                Button("Open Settings") { showSettings = true }
            }
        }
    }

    // MARK: Actions

    private func delete(_ expense: Expense) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4)) {
            modelContext.delete(expense)
        }
    }

    private func loadLibraryImage(_ item: PhotosPickerItem) async {
        defer { libraryItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        newExpense = NewExpenseRequest(image: image)
    }
}

struct NewExpenseRequest: Identifiable {
    let id = UUID()
    var image: UIImage?
}

/// One pocket of the file: a month, its slips, and its totals per currency.
struct MonthGroup: Identifiable {
    var month: Date
    var expenses: [Expense]

    var id: Date { month }

    /// Totals keyed by currency code; a freelancer paying in two currencies sees both, never a mixed sum.
    var totals: [(code: String, amount: Decimal)] {
        var sums: [String: Decimal] = [:]
        for expense in expenses { sums[expense.currencyCode, default: 0] += expense.amount }
        return sums.sorted { $0.key < $1.key }.map { (code: $0.key, amount: $0.value) }
    }

    var totalText: String {
        if totals.isEmpty {
            return Money.format(0, code: Locale.current.currency?.identifier ?? "EUR")
        }
        return totals.map { Money.format($0.amount, code: $0.code) }.joined(separator: " + ")
    }

    /// Newest month first. With `includingCurrentMonth`, this month's pocket is always present, even empty.
    static func group(_ expenses: [Expense], includingCurrentMonth: Bool = false) -> [MonthGroup] {
        var buckets = Dictionary(grouping: expenses, by: \.monthStart)
        if includingCurrentMonth, let thisMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start {
            buckets[thisMonth, default: []] += []
        }
        return buckets
            .map { MonthGroup(month: $0.key, expenses: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)
}
