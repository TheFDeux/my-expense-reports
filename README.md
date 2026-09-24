# My Expense Reports

A native iPhone app (SwiftUI, SwiftData, iOS 26) for a freelancer's expense receipts.

- Expenses grouped by month, each month with its total and receipt count.
- **+** → take a photo, pick one from the library, or enter by hand.
- With an Anthropic API key set in Settings, the receipt photo is read by Claude and the
  total (incl. VAT), VAT, date, merchant and category arrive as pre-filled, editable fields.
- Without a key the app is a complete manual ledger and says so on screen.
- Everything is stored on-device with SwiftData; the key lives in the Keychain.
- Export any month as CSV through the share sheet.
- Light and dark mode, Dynamic Type, Reduce Motion, VoiceOver labels.

## Build and run

Requirements: a Mac with **Xcode 26** (iOS 26 SDK). No dependencies, no package resolution.

```bash
open MyExpenseReports.xcodeproj
```

Pick an iPhone simulator (e.g. iPhone 17) and press **⌘R**. Or from the terminal:

```bash
xcodebuild -project MyExpenseReports.xcodeproj -scheme MyExpenseReports -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Run the unit tests (money parsing, CSV, API payload parsing):

```bash
xcodebuild -project MyExpenseReports.xcodeproj -scheme MyExpenseReports -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The project uses Xcode's folder-synchronized groups, so any file added under `MyExpenseReports/`
or `MyExpenseReportsTests/` joins the right target automatically.

The Simulator has no camera; the "Take Photo" option appears only on a device. Use
"Choose from Library" (drag an image onto the Simulator window to add one to its library).

## Using receipt reading

Settings (gear icon) → paste an Anthropic API key → Save. The next photo you add is sent
to `api.anthropic.com` once and the fields fill in; you confirm and save. Remove the key
at any time; existing expenses are untouched.

## Layout

```
MyExpenseReports/
  App/        MyExpenseReportsApp.swift      entry point, SwiftData container
  Models/     Expense.swift                  @Model, Decimal money, external-storage image
              ExpenseCategory.swift          fixed category list, symbols, colors
  Services/   ReceiptExtractor.swift         Anthropic Messages API (vision + JSON schema)
              KeychainStore.swift            API key storage
              CSVExporter.swift              RFC 4180 CSV, locale-aware separator
  Views/      ExpenseListView.swift          month-grouped list, add flow, toolbar
              ExpenseRow.swift               row + month header
              ExpenseFormView.swift          create/edit, extraction states, receipt viewer
              CameraPicker.swift             UIImagePickerController wrapper
              SettingsView.swift             key entry, model info
              ExportView.swift               per-month ShareLink
  Support/    Money.swift, MonthFormatting.swift
MyExpenseReportsTests/                       Swift Testing unit tests
DECISIONS.md                                 every choice made without asking
PRODUCT.md, DESIGN.md, .impeccable/          design context (Impeccable)
```
