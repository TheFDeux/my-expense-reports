import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyInput = ""
    @State private var storedKeyExists = KeychainStore.read() != nil
    @State private var saveFailed = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $keyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit(saveKey)
                    Button(storedKeyExists ? "Replace Key" : "Save Key", action: saveKey)
                        .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    if storedKeyExists {
                        Button("Remove Key", role: .destructive) {
                            KeychainStore.delete()
                            storedKeyExists = false
                            keyInput = ""
                        }
                    }
                } header: {
                    Text("Anthropic API key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(storedKeyExists ? "A key is stored in your Keychain. Receipt photos are read automatically."
                                              : "No key stored. The app works fully with manual entry; photos are kept but not read.",
                              systemImage: storedKeyExists ? "checkmark.seal" : "key.slash")
                        Text("The key never leaves this device except to call api.anthropic.com. Receipt photos are sent to that API only while a key is set.")
                        if saveFailed {
                            Text("The key couldn't be saved to the Keychain.").foregroundStyle(.red)
                        }
                    }
                }

                Section("Extraction") {
                    LabeledContent("Model", value: ClaudeReceiptExtractor.model)
                    LabeledContent("Reads", value: "Total, VAT, date, merchant, category")
                    Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                        Label("Get an API key", systemImage: "arrow.up.right.square")
                    }
                }

                Section("Data") {
                    LabeledContent("Storage", value: "On this device")
                    LabeledContent("Export", value: "CSV per month")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveFailed = !KeychainStore.save(trimmed)
        storedKeyExists = KeychainStore.read() != nil
        if !saveFailed { keyInput = "" }
    }
}

#Preview {
    SettingsView()
}
