import Foundation
import UIKit
import SwiftUI
import SwiftData

/// Create or edit one expense. When created from a photo and a key exists, the model pre-fills the
/// fields; the person always confirms before anything is saved.
struct ExpenseFormView: View {
    enum Mode {
        case create(image: UIImage?)
        case edit(Expense)
    }

    enum ExtractionState: Equatable {
        case none            // no photo, or editing an existing expense
        case noKey           // photo attached but no API key: manual entry
        case reading
        case filled(Int)     // number of fields the model filled
        case failed(String)
    }

    let mode: Mode
    /// When set, the owner performs the deletion after the sheet is dismissed.
    var onDelete: ((Expense) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var merchant = ""
    @State private var amountText = ""
    @State private var vatText = ""
    @State private var currencyCode = Locale.current.currency?.identifier ?? "EUR"
    @State private var date = Date.now
    @State private var category = ExpenseCategory.other
    @State private var note = ""
    @State private var image: UIImage?
    @State private var extraction = ExtractionState.none
    @State private var extractionTask: Task<Void, Never>?
    @State private var showFullImage = false
    @State private var showSettings = false
    @State private var didLoad = false

    // Values at load time, so extraction never overwrites something the person already changed.
    @State private var initialCurrency = ""
    @State private var initialDate = Date.distantPast
    @State private var initialCategory = ExpenseCategory.other

    private static let currencyChoices = ["EUR", "USD", "GBP", "CHF", "CAD", "JPY", "AUD", "SEK", "NOK", "DKK"]

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var parsedAmount: Decimal? { Money.parse(amountText) }

    private var canSave: Bool {
        parsedAmount != nil && extraction != .reading
    }

    var body: some View {
        NavigationStack {
            Form {
                if image != nil || extraction != .none {
                    receiptSection
                }
                detailsSection
                categorySection
                noteSection
                if isEditing {
                    Section {
                        Button("Delete Expense", role: .destructive, action: deleteExisting)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        extractionTask?.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            // Guard against losing a half-typed new expense; existing expenses dismiss freely (nothing is lost).
            .interactiveDismissDisabled(!isEditing && (!merchant.isEmpty || !amountText.isEmpty))
            // A full-screen cover re-triggers onAppear on this view; load exactly once.
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                load()
            }
            .fullScreenCover(isPresented: $showFullImage) {
                if let image { ReceiptImageView(image: image) }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                // A key added mid-flow starts reading the attached photo right away.
                if extraction == .noKey, KeychainStore.read() != nil { startExtraction() }
            }) {
                SettingsView()
            }
        }
    }

    // MARK: Sections

    private var receiptSection: some View {
        Section {
            if let image {
                Button { showFullImage = true } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption.weight(.semibold))
                                .padding(6)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .padding(8)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Receipt photo, tap to enlarge")
                .listRowInsets(EdgeInsets())
            }
            extractionStatus
        } footer: {
            if case .filled = extraction {
                Text("Check each field against the receipt before saving.")
            }
        }
    }

    @ViewBuilder
    private var extractionStatus: some View {
        switch extraction {
        case .none:
            EmptyView()
        case .noKey:
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manual entry").font(.subheadline.weight(.medium))
                    Text("No API key is set, so this photo isn't read automatically. The photo is kept with the expense.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Open Settings") { showSettings = true }
                        .font(.footnote.weight(.semibold))
                }
            } icon: {
                Image(systemName: "key.slash").foregroundStyle(.secondary)
            }
        case .reading:
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading the receipt…").font(.subheadline.weight(.medium))
                    Text("Usually a few seconds. You can start typing meanwhile.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } icon: {
                ProgressView()
            }
        case .filled(let count):
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("^[\(count) field](inflect: true) pre-filled").font(.subheadline.weight(.medium))
                    Text("Edit anything that looks wrong.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "sparkles").foregroundStyle(Color.accentColor)
            }
        case .failed(let message):
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Couldn't read the receipt").font(.subheadline.weight(.medium))
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                    Button("Try Again", action: startExtraction)
                        .font(.footnote.weight(.semibold))
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Merchant", text: $merchant)
                .textContentType(.organizationName)
                .autocorrectionDisabled()
            LabeledContent("Total incl. VAT") {
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
            }
            LabeledContent("VAT") {
                TextField("Optional", text: $vatText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
            }
            Picker("Currency", selection: $currencyCode) {
                ForEach(currencyOptions, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(ExpenseCategory.allCases) { category in
                    Label(category.title, systemImage: category.symbolName)
                        .tag(category)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField("Client, project, who was there…", text: $note, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    private var currencyOptions: [String] {
        Self.currencyChoices.contains(currencyCode) ? Self.currencyChoices : [currencyCode] + Self.currencyChoices
    }

    // MARK: Lifecycle

    private func load() {
        switch mode {
        case .edit(let expense):
            merchant = expense.merchant
            amountText = Money.plain(expense.amount)
            vatText = expense.vat.map(Money.plain) ?? ""
            currencyCode = expense.currencyCode
            date = expense.date
            category = expense.category
            note = expense.note
            image = expense.receiptImage.flatMap(UIImage.init(data:))
            extraction = .none
        case .create(let picked):
            guard let picked else { return }
            image = picked
            if KeychainStore.read() == nil {
                extraction = .noKey
            } else {
                startExtraction()
            }
        }
        initialCurrency = currencyCode
        initialDate = date
        initialCategory = category
    }

    private func startExtraction() {
        guard let image, let key = KeychainStore.read() else {
            extraction = .noKey
            return
        }
        extraction = .reading
        extractionTask?.cancel()
        extractionTask = Task {
            do {
                let result = try await ClaudeReceiptExtractor(apiKey: key).extract(from: image)
                guard !Task.isCancelled else { return }
                apply(result)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                extraction = .failed(error.localizedDescription)
            }
        }
    }

    /// Fills only fields the person hasn't already changed, so a fast typist never loses work.
    private func apply(_ result: ReceiptExtraction) {
        var filled = 0
        withAnimation(reduceMotion ? nil : .default) {
            if merchant.isEmpty, let value = result.merchant { merchant = value; filled += 1 }
            if amountText.isEmpty, let value = result.total { amountText = Money.plain(value); filled += 1 }
            if vatText.isEmpty, let value = result.vat { vatText = Money.plain(value); filled += 1 }
            if currencyCode == initialCurrency, let value = result.currencyCode { currencyCode = value; filled += 1 }
            if date == initialDate, let value = result.date, value <= .now { date = value; filled += 1 }
            if category == initialCategory, let value = result.category { category = value; filled += 1 }
            extraction = filled == 0
                ? .failed("Nothing legible was found. Fill the fields by hand.")
                : .filled(filled)
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let vat = vatText.isEmpty ? nil : Money.parse(vatText)
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageData = image.flatMap { ClaudeReceiptExtractor.encodeForUpload($0, maxEdge: 1600) }

        withAnimation(reduceMotion ? nil : .spring(duration: 0.45)) {
            switch mode {
            case .edit(let expense):
                expense.merchant = trimmedMerchant
                expense.amount = amount
                expense.vat = vat
                expense.currencyCode = currencyCode
                expense.date = date
                expense.category = category
                expense.note = note
            case .create:
                let expense = Expense(
                    merchant: trimmedMerchant,
                    amount: amount,
                    vat: vat,
                    currencyCode: currencyCode,
                    date: date,
                    category: category,
                    note: note,
                    receiptImage: imageData
                )
                modelContext.insert(expense)
            }
        }
        dismiss()
    }

    private func deleteExisting() {
        guard case .edit(let expense) = mode else { return }
        if let onDelete {
            onDelete(expense)
        } else {
            modelContext.delete(expense)
        }
        dismiss()
    }
}

/// Full-screen, zoomable view of the receipt for checking small print.
struct ReceiptImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .containerRelativeFrame([.horizontal, .vertical]) { length, _ in length * scale }
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = min(max(lastScale * value.magnification, 1), 4)
                            }
                            .onEnded { _ in lastScale = scale }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation { scale = scale > 1 ? 1 : 2.5; lastScale = scale }
                    }
            }
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Manual") {
    ExpenseFormView(mode: .create(image: nil))
        .modelContainer(for: Expense.self, inMemory: true)
}
