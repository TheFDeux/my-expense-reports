import SwiftUI
import SwiftData

@main
struct MyExpenseReportsApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Expense.self)
        } catch {
            fatalError("Could not open the expense store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ExpenseListView()
        }
        .modelContainer(container)
    }
}
