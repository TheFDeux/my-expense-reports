---
name: My Expense Reports
description: A kraft accordion file of month pockets; native iOS 26 SwiftUI, one warm tint, figures set in monospaced digits.
colors:
  # Kraft is the only literal color in the build. It lives solely in Assets.xcassets/AccentColor.colorset and
  # reaches the UI as the system tint (Color.accentColor). Four appearance variants, one asset.
  kraft: "#A65C1A"
  kraft-dark: "#D98B45"
  kraft-increased-contrast: "#9A5417"
  kraft-dark-increased-contrast: "#E8A05E"
  # Everything below is a SwiftUI semantic system color. The Swift name is normative; the hex is the
  # iOS light-appearance rendering, recorded so tooling can draw a swatch. Dark renderings are in the sidecar.
  label: "#000000"
  secondary-label: "rgba(60, 60, 67, 0.6)"
  grouped-background: "#F2F2F7"
  grouped-cell: "#FFFFFF"
  # Fixed category law: ten categories, ten system hues, applied to category glyphs and thumbnail placeholders only.
  category-meals: "#FF3B30"
  category-travel: "#007AFF"
  category-transport: "#5856D6"
  category-lodging: "#AF52DE"
  category-office: "#30B0C7"
  category-software: "#00C7BE"
  category-equipment: "#32ADE6"
  category-telecom: "#34C759"
  category-services: "#FF2D55"
  category-other: "#8E8E93"
  destructive: "#FF3B30"
typography:
  # All roles are system Dynamic Type styles on SF Pro. Sizes are the default (Large) content size; they scale.
  large-title:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "34pt"
    fontWeight: 700
  pocket-total:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "22pt"
    fontWeight: 600
    fontFeature: "tnum"
  add-glyph:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "20pt"
    fontWeight: 600
  headline:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "17pt"
    fontWeight: 600
  body:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "17pt"
    fontWeight: 400
  amount:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "17pt"
    fontWeight: 400
    fontFeature: "tnum"
  status-title:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "15pt"
    fontWeight: 500
  footnote:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "13pt"
    fontWeight: 400
  footnote-action:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "13pt"
    fontWeight: 600
  badge:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "12pt"
    fontWeight: 600
  glyph-inline:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "11pt"
    fontWeight: 400
rounded:
  sm: "6pt"
  md: "8pt"
  lg: "12pt"
  circle: "50%"
spacing:
  hairline: "2pt"
  tight: "3pt"
  xs: "4pt"
  badge: "6pt"
  sm: "8pt"
  md: "12pt"
  target: "44pt"
components:
  add-button:
    backgroundColor: "{colors.kraft}"
    textColor: "{colors.grouped-cell}"
    typography: "{typography.add-glyph}"
    rounded: "{rounded.circle}"
    size: "44pt"
  receipt-thumbnail:
    rounded: "{rounded.md}"
    size: "44pt"
  receipt-thumbnail-placeholder:
    backgroundColor: "{colors.category-other}"
    rounded: "{rounded.md}"
    size: "44pt"
  receipt-hero:
    rounded: "{rounded.lg}"
    height: "180pt"
  expand-badge:
    typography: "{typography.badge}"
    rounded: "{rounded.sm}"
    padding: "6pt"
  month-header-total:
    textColor: "{colors.label}"
    typography: "{typography.pocket-total}"
  month-header-title:
    textColor: "{colors.label}"
    typography: "{typography.headline}"
  row-amount:
    textColor: "{colors.label}"
    typography: "{typography.amount}"
  row-meta:
    textColor: "{colors.secondary-label}"
    typography: "{typography.footnote}"
---

# Design System: My Expense Reports

## Overview

**Creative North Star: "The Kraft Accordion File"**

The app is a paper accordion file with one pocket per month. The month is the container: its tab carries the month name, the receipt count, and the pocket's total set in the largest figure on screen. A receipt is a slip dropped into the current pocket, and every slip carries the same three slots (merchant, category with date, amount). The system refuses the fintech arrangement (hero balance, chart, then a feed) and the bare transaction table; hierarchy is carried by figure size and a shared amount column, never by color.

Structurally the app is stock iOS 26: navigation stack, inset grouped lists, sheets for every sub-task, system pickers, confirmation dialogs, swipe actions, `ContentUnavailableView` for the empty state, and a Liquid Glass bottom toolbar for the single primary action. Brand lives in the one layer the platform leaves open: a warm kraft tint on system grouped backgrounds, monospaced-digit figures, a short spring when a slip lands, and plain copy. There is no custom navigation, no hand-drawn material, no shadow, and no hex value in Swift source.

The build is source-derived: it was authored on Windows and no Simulator screenshot exists, so every value below is read from the shipped Swift and asset catalog, not from a render.

**Key Characteristics:**
- One tint (Kraft) for every interactive element; category hues appear on glyphs only.
- Every amount is `.monospacedDigit()`, right-aligned, on one shared trailing column across headers and rows.
- Hierarchy by figure size: month total (title2 semibold) > row amount (body) > count and date (footnote).
- Continuous-corner radii in three steps (6 / 8 / 12pt) plus the circle; nothing else.
- System text styles throughout; no hard-coded point size anywhere.
- Depth comes from system materials (grouped list insets, `.thinMaterial`, `.glassProminent`), never from shadows.

## Colors

A single warm accent on Apple's semantic grouped palette, with a fixed ring of ten system hues reserved for category glyphs.

### Primary
- **Kraft** (`{colors.kraft}` light, `{colors.kraft-dark}` dark, with increased-contrast variants): the tint. It is defined once, in `Assets.xcassets/AccentColor.colorset`, and reaches the UI only as `Color.accentColor` through the toolbar buttons, the glass + button, links, pickers, `Save`/`Done`, and the `sparkles` glyph of the "pre-filled" extraction state. No view sets `.tint()`; the asset is the whole mechanism.

### Neutral
- **Label / Secondary Label** (`.primary`, `.secondary`): merchant, month name, amounts and totals in primary; category, date, receipt count, explanatory footnotes in secondary. Both come from the system and adapt to Dark Mode and Increased Contrast unaided.
- **Grouped Background / Grouped Cell**: supplied by `.insetGrouped` list style and `Form`; the app never paints a background of its own except the full-screen receipt viewer, which is pure black behind the photo.
- **Destructive** (`.red`, role `.destructive`): delete actions, Keychain save failure, CSV write failure. Always system red, always via a role or `.red`.

### Category hues (fixed law)
Ten categories map to ten system colors in `ExpenseCategory.color`: Meals red, Travel blue, Transport indigo, Lodging purple, Office teal, Software mint, Equipment cyan, Telecom green, Professional services pink, Other gray. They are applied to exactly two things: the category SF Symbol in a row, and the 15%-opacity placeholder fill (plus its glyph) of a thumbnail that has no photo. Orange and brown are deliberately absent so that no glyph can be mistaken for a Kraft control.

### Named Rules
**The One Tint Rule.** Kraft is the only color that means "tappable". If it is not interactive, it is not Kraft; if it is interactive, it is not any other hue.

**The Ten Hues Rule.** Category colors are fixed in code, one system color per category, and appear only on category glyphs and empty-thumbnail placeholders. Never on text, never on backgrounds, never chosen ad hoc.

**The No Hex In Swift Rule.** Literal color values live in the asset catalog. Swift source uses `Color.accentColor`, semantic colors, and named system colors only.

## Typography

**Display Font:** SF Pro (system) via `.largeTitle` / `.title2`
**Body Font:** SF Pro (system) via `.body`, `.headline`, `.subheadline`, `.footnote`
**Figure treatment:** SF Pro with `.monospacedDigit()` on every amount

**Character:** Plain system type at system weights; the only expressive move is that money is always set in tabular figures and sized so the month total outranks every row. Weight steps are semibold (600) for month names and totals, medium (500) for extraction-status titles, regular elsewhere.

### Hierarchy
- **Large Title** (`.navigationTitle("Expenses")`, bold 34pt at default size): the top-level screen only; collapses to inline on scroll. Sheets (`New Expense`, `Edit Expense`, `Settings`, `Export CSV`) use `.inline`.
- **Pocket Total** (`.title2.weight(.semibold)` + `.monospacedDigit()`, 22pt): the month's total in the section header. The largest figure on screen; the screen has no larger number.
- **Add Glyph** (`.title3.weight(.semibold)`, 20pt): the `plus` symbol inside the glass button.
- **Headline** (`.headline`, semibold 17pt): the month name in the section header, `.textCase(nil)` so it is never uppercased.
- **Body** (`.body`, 17pt): merchant name in a row; month name in the Export list; every Form field.
- **Amount** (`.body` + `.monospacedDigit()`, 17pt): the trailing figure in a row; the amount and VAT text fields, trailing-aligned.
- **Status Title** (`.subheadline.weight(.medium)`, 15pt): the first line of each extraction state ("Reading the receipt…", "3 fields pre-filled").
- **Footnote** (`.footnote`, 13pt, secondary): category + date under the merchant; receipt count under the month; status explanations; Export subtitles (with monospaced digits when they carry a total).
- **Footnote Action** (`.footnote.weight(.semibold)`): inline `Open Settings` / `Try Again` buttons inside a status label.
- **Badge** (`.caption.weight(.semibold)`, 12pt): the enlarge glyph on the receipt hero.
- **Inline Glyph** (`.caption2`, 11pt): the category symbol beside the footnote line.

### Named Rules
**The Shared Column Rule.** Every amount is `.monospacedDigit()` and sits on the trailing edge, so totals in headers and amounts in rows align on one column down the screen.

**The Figure Size Rule.** Hierarchy among numbers is carried by size and weight only (title2 semibold > body > footnote); no amount is ever colored to stand out.

**The System Style Rule.** Text uses system text styles exclusively. A hard-coded point size is a defect.

## Layout

Single-column iPhone layout inside a `NavigationStack`. The top level is an `.insetGrouped` `List` with one `Section` per month, newest first; the current month is always the first section even when empty (its body reads "No receipts yet this month" in secondary). Each section header is the pocket tab: a leading `VStack` (month name over receipt count, 2pt apart) and a trailing total on a `firstTextBaseline` alignment, with 4pt vertical padding.

Rows are an `HStack` at 12pt spacing: 44pt thumbnail, a leading `VStack` (3pt spacing) of merchant and meta line (the meta `HStack` at 5pt spacing), a `Spacer(minLength: 8)`, and the amount. The whole row is a `.plain` button with a rectangular content shape and a single combined accessibility element.

Forms (`New Expense`, `Edit Expense`, `Settings`) are stock `Form` sections in this order: receipt (photo + extraction status), Details, Category, Note, then Delete when editing. The receipt photo removes its row insets so the image fills the cell. Sheets end with `Cancel` / `Save` or `Done` in the standard toolbar placements. Secondary screens (`Export CSV`, `Settings`) are sheets with inline titles.

Toolbar: `Export` and `Settings` trailing at the top; the primary `+` in the iOS 26 bottom bar, pushed trailing by a flexible `ToolbarSpacer`. The empty state is a `ContentUnavailableView` with `tray.and.arrow.down`.

Spacing rhythm as observed: 2, 3, 4, 5, 6, 8, 12pt for internal gaps; 44pt for touch targets and thumbnails; 180pt for the receipt hero. No other values appear. iPad layout is unresolved and not documented.

## Elevation & Depth

No shadows anywhere in the build. Depth is entirely tonal and material: inset grouped cells on the grouped background, the system's `.glassProminent` Liquid Glass for the + button, `.thinMaterial` behind the small enlarge badge on the receipt photo, and the system's own sheet and bar materials. The receipt viewer inverts this once, going full black and forcing dark appearance so the photo is the only lit thing.

### Named Rules
**The System Material Rule.** Blur and translucency come from `.thinMaterial` and `.glassProminent` only; no custom opacity stacks, no `.shadow()`.

## Shapes

Continuous (squircle) corners at three radii and the circle: 6pt for the enlarge badge, 8pt for the 44pt receipt thumbnail and its placeholder, 12pt for the 180pt receipt hero, and a circle for the glass + button (`.buttonBorderShape(.circle)`). Every `RoundedRectangle` in the build uses `style: .continuous`. Thumbnails are square and `scaledToFill`; the hero is full-width and `scaledToFill`; the viewer is `scaledToFit`. List cells, sheets, and controls keep their system shapes.

## Components

### Buttons
- **Primary (+)**: `.glassProminent` in the Kraft tint, `.buttonBorderShape(.circle)`, `.labelStyle(.iconOnly)`, `plus` symbol at `.title3.weight(.semibold)`; lives in the bottom toolbar. Label "Add expense" for VoiceOver.
- **Toolbar**: borderless system buttons with SF Symbols (`square.and.arrow.up` Export, disabled when there are no expenses; `gearshape` Settings). Sheet chrome uses `.cancellationAction` / `.confirmationAction` text buttons; `Save` is disabled until an amount parses and extraction is not running.
- **Destructive**: `role: .destructive` (`Delete` swipe action with `trash`, `Delete Expense` centered in its own Form section, `Remove Key`).
- **Inline text actions**: `.footnote.weight(.semibold)` buttons inside status labels (`Open Settings`, `Try Again`); `Link` with `arrow.up.right.square` for external URLs.
- **States**: system-provided; no custom pressed or hover treatment exists.

### Cards / Containers
- **Month section (the pocket)**: `.insetGrouped` `Section` with `MonthHeader`; no custom background or border.
- **Receipt hero**: full-width image, 180pt tall, 12pt continuous radius, zero row insets, tappable to a full-screen zoomable viewer (1x-4x pinch, double-tap toggles 2.5x). Bottom-trailing enlarge badge: `arrow.up.left.and.arrow.down.right` at caption semibold, 6pt padding on `.thinMaterial` with 6pt radius, inset 8pt.

### Inputs / Fields
- **Style**: stock `Form` rows. `TextField` for merchant (organization-name content type, autocorrect off) and note (vertical axis, 1-4 lines); `LabeledContent` wrapping trailing-aligned, `.monospacedDigit()`, `.decimalPad` fields for amount and VAT; `Picker` for currency; `.navigationLink` picker with `Label(title, systemImage:)` for category; `DatePicker` capped at today; `SecureField` for the API key with `.password` content type.
- **Focus / Error**: system focus. Errors appear as secondary footnote copy or a `.red` line in the footer, never as a red field border.

### Navigation
- `NavigationStack` with a large title at the top level, inline titles in sheets. Sheets are the only modality for sub-tasks; the camera and the receipt viewer are `fullScreenCover`. Swipe-to-dismiss is disabled only on a half-typed new expense.

### Slip Row (signature)
Three slots, never more: thumbnail (44pt, radius 8; or a category-tinted 15% placeholder with the category glyph), merchant in body over `[category glyph] Category · 24 Sep` in secondary footnote, and the amount trailing in body monospaced digits. Empty merchant reads "Unnamed merchant". Full-swipe trailing delete.

### Pocket Tab (signature)
Section header: month name (`.headline`) over `"^[n receipt](inflect: true)"` (`.footnote`, secondary) leading; total (`.title2.weight(.semibold)`, monospaced digits, `.contentTransition(.numericText())`) trailing. Multiple currencies are shown as separate totals joined with " + ", never summed. `.textCase(nil)`, 4pt vertical padding, one combined accessibility element.

### Extraction Status (signature)
One `Label` per state, each with its own glyph and two-line copy: `key.slash` (secondary) for no key with an `Open Settings` action; `ProgressView` for reading; `sparkles` in Kraft for pre-filled, with an inflected field count and a section footer "Check each field against the receipt before saving."; `exclamationmark.triangle` for failed, with `Try Again`. Filled fields never overwrite a value the person has already typed.

### Motion
- **Slip insert / delete**: `.spring(duration: 0.45)` on the list keyed to expense count; delete `.spring(duration: 0.4)`; both `nil` under Reduce Motion.
- **Form pre-fill**: `.default`, `nil` under Reduce Motion.
- **Pocket total**: `.contentTransition(.numericText())` with `.default` animation keyed to the total text.
- **Viewer zoom**: `withAnimation` default on double-tap.

## Do's and Don'ts

### Do:
- **Do** route every interactive tint through the `AccentColor` asset; never call `.tint()` or write a hex in Swift.
- **Do** set every amount with `.monospacedDigit()` and align it trailing so it lands on the shared column.
- **Do** keep the month total at `.title2.weight(.semibold)` as the largest figure on screen; rows stay at `.body`.
- **Do** use system text styles and semantic colors (`.primary`, `.secondary`, `.red` via roles) so Dark Mode, Increased Contrast, and Dynamic Type work unaided.
- **Do** use continuous corners at 6 / 8 / 12pt or the circle; thumbnails are 44pt squares at 8pt.
- **Do** gate springs and fills on `accessibilityReduceMotion` (`nil` animation when set).
- **Do** keep the current month's pocket first, even when empty, with the "No receipts yet this month" line.

### Don't:
- **Don't** add a shadow, a custom material, or a painted background; depth is inset grouping, `.thinMaterial`, and `.glassProminent` only.
- **Don't** color a category name, an amount, or a background with a category hue; hues go on glyphs and empty-thumbnail placeholders only.
- **Don't** use orange or brown as a category hue; they collide with Kraft and read as controls.
- **Don't** hard-code a point size or a font name.
- **Don't** add a fourth slot to a row (no badges, tags, or secondary amounts on a slip).
- **Don't** sum totals across currencies; show one total per currency joined with " + ".
- **Don't** replace system controls (pickers, date picker, swipe actions, confirmation dialog, share sheet) with bespoke ones.
