import SwiftUI
import UniformTypeIdentifiers

/// Editable detail screen for a tracked document — expiration, category,
/// apostille/translation sub-checklist, issuing country, notes, plus view /
/// replace-file actions. Saving persists metadata and (re)schedules reminders.
struct DocumentDetailView: View {
    let document: UserDocument
    @ObservedObject var vm: DocumentsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var hasExpiry: Bool
    @State private var expirationDate: Date
    @State private var category: DocumentCategory
    @State private var apostilleRequired: Bool
    @State private var swornTranslationRequired: Bool
    @State private var apostilleDone: Bool
    @State private var translationDone: Bool
    @State private var issuingCountry: String
    @State private var notes: String
    @State private var showReplacePicker = false

    init(document: UserDocument, vm: DocumentsViewModel) {
        self.document = document
        self.vm = vm
        _name = State(initialValue: document.name)
        _hasExpiry = State(initialValue: document.expirationDate != nil)
        _expirationDate = State(initialValue: document.expirationDate ?? Date())
        _category = State(initialValue: document.category ?? .other)
        _apostilleRequired = State(initialValue: document.apostilleRequired ?? false)
        _swornTranslationRequired = State(initialValue: document.swornTranslationRequired ?? false)
        _apostilleDone = State(initialValue: document.apostilleDone ?? false)
        _translationDone = State(initialValue: document.translationDone ?? false)
        _issuingCountry = State(initialValue: document.issuingCountry ?? "")
        _notes = State(initialValue: document.notes ?? "")
    }

    var body: some View {
        Form {
            // Live expiry header reflecting the current picker state.
            Section {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .foregroundColor(.goPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(.subheadline.weight(.semibold))
                        Text(previewExpiryLabel)
                            .font(.caption)
                            .foregroundColor(previewUrgency.color)
                    }
                }
            }

            Section("Name") {
                TextField("Document name", text: $name)
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    ForEach(DocumentCategory.allCases) { c in
                        Label(c.label, systemImage: c.icon).tag(c)
                    }
                }
            }

            Section("Expiration") {
                Toggle("Has an expiry date", isOn: $hasExpiry)
                    .tint(.goPrimary)
                if hasExpiry {
                    DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                }
                Text("Validity periods are informational — verify with official sources.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section("Apostille & translation") {
                Toggle("Apostille required", isOn: $apostilleRequired).tint(.goPrimary)
                if apostilleRequired {
                    Toggle("Apostille obtained", isOn: $apostilleDone).tint(.goSuccess)
                }
                Toggle("Sworn translation required", isOn: $swornTranslationRequired).tint(.goPrimary)
                if swornTranslationRequired {
                    Toggle("Translation obtained", isOn: $translationDone).tint(.goSuccess)
                }
            }

            Section("Details") {
                TextField("Issuing country", text: $issuingCountry)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                if let url = URL(string: document.downloadUrl), !document.downloadUrl.isEmpty {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Label("View file", systemImage: "doc.text.magnifyingglass")
                    }
                }
                Button {
                    showReplacePicker = true
                } label: {
                    Label("Replace file", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .navigationTitle("Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .fileImporter(
            isPresented: $showReplacePicker,
            allowedContentTypes: [.pdf, .png, .jpeg, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleReplace(result)
        }
    }

    // MARK: - Derived preview

    private var previewExpiryLabel: String {
        guard hasExpiry else { return "No expiry date" }
        var probe = document
        probe.expirationDate = expirationDate
        return probe.expiryLabel
    }

    private var previewUrgency: DocumentUrgency {
        var probe = document
        probe.expirationDate = hasExpiry ? expirationDate : nil
        probe.apostilleRequired = apostilleRequired
        probe.swornTranslationRequired = swornTranslationRequired
        probe.apostilleDone = apostilleDone
        probe.translationDone = translationDone
        return probe.urgency
    }

    // MARK: - Actions

    private func save() {
        var updated = document
        updated.name = name
        updated.category = category
        updated.expirationDate = hasExpiry ? expirationDate : nil
        updated.apostilleRequired = apostilleRequired
        updated.swornTranslationRequired = swornTranslationRequired
        updated.apostilleDone = apostilleDone
        updated.translationDone = translationDone
        updated.issuingCountry = issuingCountry.isEmpty ? nil : issuingCountry
        updated.notes = notes.isEmpty ? nil : notes
        vm.updateMeta(updated)
        dismiss()
    }

    private func handleReplace(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first,
              url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? Data(contentsOf: url) {
            vm.replaceFile(document, data: data, fileName: url.lastPathComponent)
            dismiss()
        }
    }
}
