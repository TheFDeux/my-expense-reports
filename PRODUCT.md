# Product

<!-- impeccable:product-schema 1 -->

> Interview substitution: the user instructed "work alone, without asking any questions". Every fact below marked **[inferred]** was derived from the brief alone rather than confirmed. Unmarked facts are quoted from the brief.

## Platform

ios

## Stack

delegated: SwiftUI + SwiftData, iOS 26 minimum, Xcode 26, no third-party packages. Receipt extraction calls the Anthropic Messages API over URLSession (no Swift SDK exists). Chosen because the brief pins SwiftUI/SwiftData and a zero-dependency project is the one most likely to open and build unmodified on the user's Mac.

## Users

A solo freelancer keeping their own expense records for accounting or client rebilling. **[inferred]** Typically French/EU-based (the brief asks for VAT, and the working folder is named "App facture"), entering receipts in bursts: at a café right after paying, or at month-end from a stack of paper. One-handed phone use, often with poor light and a crumpled receipt.

## Product Purpose

"My Expense Reports": capture a receipt in seconds, get the total, VAT, date, merchant and category read off the photo by an LLM into editable fields, keep everything on-device, and hand a month's expenses to an accountant as a CSV. Success is: a receipt becomes a correct saved expense in under 15 seconds, and month-end export takes one tap.

## Positioning

Photo-first capture where the model pre-fills every field but the human always confirms: nothing is saved without being seen. **[inferred]** No account, no server, no subscription; the user's own API key is the only credential, and without it the app is a complete manual expense ledger, not a locked demo.

## Operating Context

- Camera or photo library as the entry point; manual entry always available.
- The receipt image is kept with the expense for later proof.
- Monthly grouping mirrors how accountants and VAT declarations work.
- CSV export via the iOS share sheet to Mail, Files, AirDrop, Drive, etc.
- **[inferred]** Currency: the device locale's currency, EUR for the assumed primary user. Amounts are stored as decimals, never floating point.

## Capabilities and Constraints

Confirmed by the brief:
- List of expenses grouped by month with per-month totals.
- Add button → camera or photo library.
- LLM extraction returns: total amount including tax, VAT amount, date, merchant, category; shown as pre-filled editable fields.
- Local storage with SwiftData.
- Monthly CSV export via share sheet.
- Polished native iOS look; dark mode.
- Without an API key the app works with manual entry and says so clearly.

Inferred / decided **[inferred]**:
- API key is entered in a Settings screen and stored in the Keychain, never in UserDefaults or source.
- Category is a fixed enum (Meals, Travel, Transport, Lodging, Office, Software, Equipment, Telecom, Professional services, Other) so CSV columns stay stable.
- Extraction failures degrade to an empty manual form with the photo attached and a one-line reason.
- Editing and deleting an expense are supported (swipe to delete, tap to edit).
- The Simulator has no camera; the camera option hides when unavailable.

Undecided: iPad layout (phone-only for now), multiple currencies per expense, receipt PDF import, iCloud sync.

## Evidence on Hand

None. No logo, no brand assets, no sample receipts, no existing code. Future work must not invent customer names, testimonials or pricing.

## Product Principles

1. The photo is the fastest path, but the human confirms every field before it is saved.
2. No key, no problem: the manual ledger is the product; extraction is an accelerator.
3. Money is exact: decimal storage, locale formatting, VAT as an explicit figure.
4. Month is the unit of work: grouping, totals and export all speak "month".
5. Native first: system components, system colors, system motion; the app should feel like Apple made it.

## Accessibility & Inclusion

Dynamic Type through system text styles, semantic colors for dark mode and increased contrast, 44pt touch targets, VoiceOver labels on icon-only controls, Reduce Motion honored. **[inferred]** No further product-specific requirement established.
