# Decisions made without asking

You asked for no questions, so every fork below was decided alone. Each entry says what was chosen, what the alternative was, and why. Reverse any of them by telling me.

## 0. Environment: the app has not been compiled or run

This session ran on **Windows 11 with no Xcode, Swift toolchain or Simulator**. The project was written to build cleanly on Xcode 26 and was reviewed statically by a second, fresh-context pass for iOS 26 API mistakes, but the brief's exit condition, "compiles and runs in the simulator", **could not be verified here**. [README.md](README.md) has the exact commands to run on a Mac. If the first build reports errors, paste them back and I will fix them; the risk is concentrated in a few iOS 26-only calls listed in §12.

## 1. Scope and structure

- **One screen hierarchy, no tab bar.** A freelancer's expense ledger has one job; the HIG reserves tab bars for 2-5 peer sections. Export and Settings are toolbar actions on the list; add is a floating button.
- **Sheets for every sub-task** (add/edit form, settings, export): self-contained tasks with Cancel/Done, swipe-to-dismiss honored except when a half-typed new expense would be lost.
- **Edit and delete are supported** although the brief only asked for add: a ledger nobody can correct is not usable. Tap a row to edit; swipe to delete; "Delete Expense" inside the edit form.
- **iPhone only, portrait-first.** `TARGETED_DEVICE_FAMILY = 1`. iPad layout is left undecided in PRODUCT.md.
- **No third-party packages.** A zero-dependency project is the one most likely to open and build unmodified.

## 2. Data model (SwiftData)

- `Expense`: `merchant`, `amount: Decimal`, `vat: Decimal?`, `currencyCode`, `date`, `categoryRaw`, `note`, `receiptImage: Data?` (`.externalStorage`), `createdAt`.
- **Money is `Decimal`, never `Double`.** Floating point produces €0.30 as 0.30000000000000004; accountants notice.
- **VAT is the tax amount, not the rate.** Rates vary by line (5.5 % / 10 % / 20 % on one French receipt); the amount is what a declaration needs. The model is told to sum multiple VAT lines.
- **Currency stored per expense**, defaulting to the device locale's currency (EUR for the assumed user). Month totals are summed **per currency** and shown as "€1 245,30 + $20,00" rather than a meaningless mixed sum.
- **Category is a fixed enum** stored as its raw string (Meals, Travel, Transport, Lodging, Office, Software, Equipment, Telecom, Professional services, Other). Fixed so the CSV column and the LLM's JSON enum stay stable. Free-text categories were rejected: they fragment reports.
- **Receipt photo is kept with the expense**, downscaled to ≤1600 px JPEG, as proof for the accountant. Not keeping it would make the photo flow a one-shot OCR trick.
- **Grouping by month is done in memory** from a single `@Query` sorted by date. A freelancer's volume (hundreds of rows a year) doesn't justify sectioned fetches.

## 3. Receipt extraction (LLM)

- **Provider: Anthropic Messages API, model `claude-opus-5`**, called directly over `URLSession` since there is no official Swift SDK. Model id is a single constant in `ReceiptExtractor.swift`.
- **Vision input**: base64 JPEG, long edge ≤ 1568 px (the API's efficient size), quality 0.8.
- **Structured output** via `output_config.format = json_schema`, so the reply is guaranteed to be the JSON shape the app decodes. No prose parsing, no prefill (prefill is rejected on current models).
- **Amounts come back as decimal strings** ("12.50"), not JSON numbers, and are parsed into `Decimal`. JSON numbers would round-trip through `Double`.
- **Effort `medium`**, `max_tokens` 4096: a receipt is a short extraction, but thinking tokens share the budget on current models, so the JSON block must never be the part that gets cut off. A `max_tokens` stop is surfaced as "The reply was cut short. Try again."
- **Server-side refusal fallback enabled** (`fallbacks: "default"` + beta header) so a safety-classifier decline on one model is retried automatically rather than shown as an error.
- **Every field is optional and nullable**; the prompt says "null rather than guess". Bad photos yield a partial draft, never a crash.
- **Extraction only fills fields the user hasn't changed yet** (text fields empty; currency, date and category still at their load-time values). A fast typist never has their entry overwritten.
- **A key added mid-flow starts reading immediately.** The no-key notice in the form has an "Open Settings" button; on return, if a key now exists, the attached photo is read.
- **A date in the future is ignored** (misread years are common); the date picker is capped at today.
- **Failure copy names the cause** (rejected key, rate limit, network, refusal, unreadable reply) and offers "Try Again"; the form stays usable throughout.
- **The photo is sent to the API only when a key exists**, and this is stated in Settings.
- Not chosen: Apple's on-device Foundation Models framework. In iOS 26 it is text-only; it would need a Vision OCR pass first and would change the product's accuracy story. Worth revisiting.

## 4. API key

- **Entered in Settings, stored in the Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). Never in UserDefaults, source, or an `.xcconfig`. A `SecureField` keeps it off screen; the field clears after saving.
- **No-key behavior**: the + dialog, the empty state, the form and Settings each say, in one line, that photos are attached but not read and that the app works manually. "Says so clearly" without a modal or a nag.

## 5. CSV export

- **One file per month**, named `expenses-2026-09.csv`, offered through `ShareLink` (the system share sheet) from an Export sheet listing every month.
- **Columns**: Date (ISO `yyyy-MM-dd`), Merchant, Category, Total incl. VAT, VAT, Currency, Note. Amounts use a dot decimal with two places so spreadsheets parse them as numbers.
- **Separator follows the locale**: `;` where the decimal separator is `,` (France, Germany…), `,` elsewhere. Excel expects exactly this per locale; a fixed comma opens as one column in French Excel.
- **UTF-8 BOM** prefix so Excel reads accented merchant names correctly.
- RFC 4180 quoting; rows sorted by date ascending.

## 6. Design direction (Impeccable)

- **Mode: Operate.** HIG governs structure; brand lives in tint, figure typography, motion and copy.
- **World: a kraft accordion file with month pockets** (candidate 3 of 7 on my grounded list, chosen by Impeccable's seeded roll, key `a9495d44`; challengers all declined, each donating a discipline recorded in `.impeccable/surfaces/`). Concretely: the month section is the container; its header is the tab, month name leading, total trailing as the largest figure on screen, receipt count beneath; rows are slips with exactly three slots (merchant · category + date · amount).
- **Tint: "Kraft"**, warm brown-orange as `AccentColor`: `#A65C1A` light (≈5.0:1 on white, so tinted 17 pt text passes body contrast), `#D98B45` dark, with Increased Contrast variants `#9A5417` / `#E8A05E`. One tint for interactive elements; category hues are content colors on glyphs only.
- **Figures use `monospacedDigit()`** everywhere so amounts align in a column; the month total is `.title2.semibold`, the largest figure on screen, and animates with `.contentTransition(.numericText())`.
- **The + button is a circular Liquid Glass prominent button in the iOS 26 bottom toolbar** (`ToolbarSpacer(.flexible)` pushes it bottom-trailing). First draft was a hand-rolled floating overlay; the finish review pointed out that the system bottom bar gives the scroll-edge effect, safe-area and keyboard handling for free, and the HIG prefers platform controls over reinvented ones.
- **The current month's pocket is always shown**, even with no receipts yet ("No receipts yet this month", total 0), so the first thing on screen is always *this* month, which is the accordion-file thesis.
- **Category colors are system colors** (`.red`, `.blue`, …) so they adapt to dark mode and increased contrast; no hex per category. Orange and brown are deliberately unused because they sit on the Kraft hue and would make a category glyph read as a control.
- **App icon**: three 1024 px rasters (light / dark / tinted) generated procedurally with Pillow (a kraft pocket with a receipt slip dropping in). Provenance is embedded in each PNG. Replace with a designed icon whenever you like.
- **Dark mode** comes from semantic colors and the dark variant of the tint; nothing is hard-coded.
- **Motion**: springs on insert/delete, numeric text transition on totals; all gated on Reduce Motion.
- DESIGN.md was written after the build from the shipped code, as Impeccable's new-work flow requires.

## 7. Native conventions kept on purpose

Large title collapsing on scroll, inset grouped lists, `ContentUnavailableView` for the empty state, `confirmationDialog` for the add choices, system `DatePicker`/`Picker`, `PhotosPicker`, `UIImagePickerController` for the camera, `ShareLink` for export, SF Symbols only.

## 8. Camera and library

- Camera via `UIImagePickerController` (`.camera`), presented full-screen; the option is hidden when no camera exists (the Simulator).
- Library via `PhotosPicker`, which needs no permission prompt. A `NSPhotoLibraryUsageDescription` is still declared for safety.

## 9. Project file

- Hand-written `project.pbxproj` using Xcode 16+/26 **folder-synchronized groups**, so files on disk are the source of truth and no per-file build entries can be missing. If Xcode complains about the project format, the fallback is: File ▸ New ▸ Project (iOS App, SwiftUI, SwiftData), delete the template files, drag the `MyExpenseReports/` folder in, and add the two `INFOPLIST_KEY_*UsageDescription` settings.
- **Swift language mode 5** with `SWIFT_APPROACHABLE_CONCURRENCY = YES`: the fewest ways for a first build to fail on isolation diagnostics. The code is written to be Swift 6-clean anyway.
- Bundle id `com.example.MyExpenseReports`; change before shipping. Automatic signing with **no `DEVELOPMENT_TEAM`**: the Simulator doesn't need one; pick your team in Signing & Capabilities before running on a device.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` (the Xcode 26 template default) means every file explicitly imports `Foundation`/`UIKit` where it uses their members, rather than relying on SwiftUI re-exporting them.
- Deployment target **26.0**.

## 10. Tests

Swift Testing unit tests for the pure logic: amount parsing (French/English input), CSV shape and quoting in two locales, and the API payload parser including the refusal path and request-body serialization. No UI tests; the views are thin over these.

## 11. Deliberately not built (YAGNI)

iCloud sync, multiple expenses per receipt, receipt PDF import, budgets/charts, search, Face ID lock, localization beyond the system formatters, an accessibility-size stacked row layout (merchant and amount stay side by side at every Dynamic Type size; flagged by the finish review as the next refinement).

## 13. Review trail

- A fresh-context **compile-risk review** (second model pass, since no compiler was available) found no API misuse and six behavioral risks; all six were fixed: onAppear re-firing under the full-screen receipt viewer (which could freeze extraction or wipe edits), delete-while-presented crash path, camera→sheet double presentation, `max_tokens` too small for thinking, zoom gesture resetting, missing explicit imports under member-import visibility.
- The **Impeccable finish review** returned `fix` with eight material items; all eight were applied (Settings link in the no-key form, app icon, current-month pocket always first, bottom toolbar, no overwriting user-changed fields, category-hue collision with the tint, header total size, tint contrast + Increased Contrast variants), then sent back for a verdict pass, which scored all eight **resolved**, found no regressions, and returned **ship** — explicitly scoped to source evidence: render, dark mode and accessibility Dynamic Type sizes stay unverified until the project is opened in Xcode 26.

## 12. Where the compile risk sits

If the first build fails, look here first; everything else is long-stable API:
- `.buttonStyle(.glassProminent)` and `ToolbarSpacer(.flexible, placement: .bottomBar)` (both iOS 26) in `ExpenseListView.swift`; fallbacks `.borderedProminent` and deleting the spacer line.
- `Button(_:systemImage:role:action:)` initializers (iOS 17+).
- `.contentTransition(.numericText())` (iOS 16+), `ContentUnavailableView`, `.photosPicker(isPresented:selection:matching:)`, `MagnifyGesture`, `containerRelativeFrame` (iOS 17+).
- Heterogeneous `[String: Any]` literals in `ReceiptExtractor.requestBody`; if type-checking is slow or fails, split the schema into typed `Encodable` structs.

## 14. Web prototype (claude.ai artifact)

A single-file web version in `web-prototype/index.html`, published as a private claude.ai artifact so the app can be tried on an iPhone without a Mac.
- **Receipt reading uses the viewer's claude.ai account** (`sample` capability) instead of an API key: the artifact sandbox blocks direct calls to api.anthropic.com. When reading is unavailable, the page says so and works manually, mirroring the app's no-key mode.
- **Storage** is the viewer's private per-user space (`db` under `data/users/<id>`), falling back to browser storage. **CSV** goes through the platform's save prompt, falling back to copyable text.
- **Example receipts** appear only while the ledger is empty; they are labelled, never saved, never exported.
- **Appearance switch** (System / Light / Dark) in Settings, remembered per browser. Requested by the user.
- **"This month" dashboard above the list**, requested by the user; it overrides the original direction contract, which had refused a summary-on-top layout. It shows month-to-date total, receipt count and VAT, a comparison with the same days of last month, spending by type, and a six-month trend. It uses one currency (the most used over six months) and says when receipts in other currencies are left out.
- **Meals split into Lunch / Dinner**, requested by the user, with a **5 pm cut-off** (a receipt timed before 17:00 is lunch). Claude reads the printed time and the app applies the rule, so the cut-off is deterministic; the person can change it. The CSV gains a "Meal" column.
- **Spending by type is a donut chart** (requested) with the total in the centre and a legend naming and valuing every slice; more than seven types fold into "Other types". Tap a slice or legend row to single it out.
- The categorical palette validator could not run on this machine (no Node, and the local preview couldn't execute it), so every chart colour is backed by a text label and chart identity never depends on colour alone.
- The Swift app does not have the dashboard, the Lunch/Dinner split or the donut yet.
