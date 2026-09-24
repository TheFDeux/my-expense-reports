---
version: 1
slug: "myexpensereports-views-expenselistview-swift"
primary_target: "MyExpenseReports/Views/ExpenseListView.swift"
related_targets: ["MyExpenseReports/Views/ExpenseFormView.swift","MyExpenseReports/Views/SettingsView.swift"]
---

# Surface: Expense list + add/edit flow (iPhone)

Scope: the whole first release of "My Expense Reports": the month-grouped expense list (top level), the add sheet (camera / library / manual), the extraction-review form, the expense detail, settings (API key), and monthly CSV export. Visitor mode: **Operate**.

Audience and job: a solo freelancer logging receipts in short bursts and handing a month to their accountant. Action: photograph → confirm fields → save; at month end, export. Content: real expenses the user enters; the app ships with none and invents none. Constraints: iOS 26 HIG governs structure (navigation stack, sheets, inset grouped lists, system controls, one tint); brand lives in tint, type treatment of figures, motion, and copy. No API key → manual entry, stated plainly on screen.

## Direction contract

THESIS: A kraft accordion file with twelve month pockets: the month is the container, its tab shows the pocket's total, and a receipt is a slip you drop into the current pocket. It refuses the fintech-card arrangement (hero balance, chart, then a flat feed) and the bare "table of transactions".

OWN-WORLD: Kraft as the tint: a warm brown-orange accent (`Kraft` asset, light #A65C1A, dark #D98B45, Increased Contrast #9A5417 / #E8A05E) on system grouped backgrounds. Every amount set in rounded-off monospaced-digit system type (`.monospacedDigit()`), right-aligned on one shared column across headers and rows. Category colors are a fixed law (ten categories, ten fixed system hues on category glyphs only; orange and brown excluded so no glyph reads as a control). Section headers are pocket tabs: month name leading, pocket total trailing in the largest figure on screen (title2 semibold). Slips (rows) carry exactly three slots: merchant · category + date · amount. Receipt thumbnails are square, 44pt, rounded 8, on the leading edge.

STORY: The user opens the app and sees this month's pocket first, its total already summed; they trust the sum because every slip inside is visible and editable. They tap +, choose camera or library, watch a short "reading the receipt" state, then confirm pre-filled fields and save; the slip slides into the pocket and the tab total counts up. Without a key, the same + opens the manual form with a calm one-line notice and a link to Settings.

FIRST VIEWPORT: Large title "Expenses" collapsing on scroll; trailing toolbar: export (square.and.arrow.up) and settings (gearshape). Inset grouped list; first section = current month, header "September 2026" leading and "€1 245,30" trailing, header sits as the first thing under the title. Rows: thumbnail, merchant (body), category glyph + "24 Sep" (footnote, secondary), amount trailing (body, monospaced digits). Primary action: a circular Liquid Glass prominent + button in the Kraft tint, bottom-trailing in the iOS 26 bottom toolbar (ToolbarSpacer pushes it right). The current month's pocket is always the first section, even when empty ("No receipts yet this month"). Empty state: one centered pocket illustration in SF Symbols (`tray.and.arrow.down`), "No expenses yet", and the same + button.

FORM: Kraft accordion file with month tabs; candidate 3 of 7 on my grounded list; seed key a9495d44 (assigned). Raises from declined challengers, each named: Crouwel grid → one strict shared amount column across headers and rows; star atlas → hierarchy carried by figure size, not color; sneaker-box label grid → every row has the identical three-slot label; tensegrity → five distinct extraction states (idle, reading, pre-filled, failed, manual) each with its own copy and glyph; six-pack → the header shows value and count ("12 receipts"); arcade palette law → category hues fixed in code, never ad hoc. Signature interaction: new slip inserts with a spring, header total transitions with `.contentTransition(.numericText())`; Reduce Motion crossfades.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

Unresolved: iPad layout; multi-currency; iCloud sync.
