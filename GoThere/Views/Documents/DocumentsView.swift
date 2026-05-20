import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var vm = DocumentsViewModel()
    @State private var showFilePicker = false
    /// When non-nil the file picker is uploading INTO this slot, not to the loose pool.
    @State private var pendingSlot: DocumentSlot? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Your Documents")
                            .font(.title2.bold())

                        Button {
                            Task { vm.startListening() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.goPrimary)
                        }

                        Spacer()

                        Button {
                            pendingSlot = nil
                            showFilePicker = true
                        } label: {
                            Text("Upload")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.goPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.goPrimary, lineWidth: 1.5)
                                )
                        }
                    }

                    // Info card
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.goPrimary)
                            .font(.title3)
                        Text("Upload and save important documents, correspondence, and PDFs related to your move for easy access.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.goPrimary.opacity(0.08))
                    .cornerRadius(12)

                    // Upload progress
                    if vm.isUploading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Uploading...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Section 1 — Documents you need (Wizard-generated slots)
                    if !vm.slots.isEmpty {
                        slotsSection
                    }

                    // Section 2 — Other uploads (legacy free-form list)
                    otherUploadsSection
                }
                .padding()
            }
            .goTopBar(showThemeToggle: false)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .png, .jpeg, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .task {
                vm.startListening()
            }
            .onAppear {
                Analytics.log(.documentsTabOpened)
            }
        }
    }

    // MARK: - Sections

    private var slotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents you need")
                .font(.headline)
                .padding(.top, 4)

            ForEach(vm.slotsByTrack, id: \.trackId) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.trackId.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    VStack(spacing: 0) {
                        ForEach(group.slots) { slot in
                            slotRow(slot)
                            if slot.id != group.slots.last?.id {
                                Divider().padding(.leading, 36)
                            }
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func slotRow(_ slot: DocumentSlot) -> some View {
        let attachedDoc = vm.document(forSlot: slot)
        return HStack(spacing: 12) {
            Image(systemName: slot.status == .uploaded ? "checkmark.circle.fill" : "circle")
                .foregroundColor(slot.status == .uploaded ? .goSuccess : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.label)
                    .font(.subheadline)
                if let desc = slot.slotDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let doc = attachedDoc {
                    Text(doc.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.goPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            if attachedDoc != nil {
                Menu {
                    Button("Replace…") {
                        pendingSlot = slot
                        showFilePicker = true
                    }
                    Button("Detach", role: .destructive) {
                        vm.detachSlot(slot)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.goPrimary)
                }
            } else {
                Button("Upload") {
                    pendingSlot = slot
                    showFilePicker = true
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.goPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.goPrimary, lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if let doc = attachedDoc, let url = URL(string: doc.downloadUrl) {
                UIApplication.shared.open(url)
            }
        }
    }

    @ViewBuilder
    private var otherUploadsSection: some View {
        if vm.slots.isEmpty {
            // No wizard run yet — keep the historical single-section behaviour
            // so the empty state is still informative.
            if vm.unattachedDocuments.isEmpty && !vm.isUploading {
                emptyState
            } else if !vm.unattachedDocuments.isEmpty {
                docList(vm.unattachedDocuments)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Other uploads")
                    .font(.headline)
                    .padding(.top, 4)
                if vm.unattachedDocuments.isEmpty && !vm.isUploading {
                    Text("Anything you upload outside a checklist slot lands here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    docList(vm.unattachedDocuments)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.largeTitle)
                .foregroundColor(.goPrimary.opacity(0.4))
            Text("No documents yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func docList(_ docs: [UserDocument]) -> some View {
        VStack(spacing: 0) {
            ForEach(docs) { doc in
                HStack(spacing: 12) {
                    Image(systemName: iconForFile(doc.name))
                        .foregroundColor(.goPrimary)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name)
                            .font(.subheadline)
                        Text("Tap to view")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: doc.downloadUrl) {
                        UIApplication.shared.open(url)
                    }
                }

                if doc.id != docs.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
        .cornerRadius(12)
    }

    // MARK: - File import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            pendingSlot = nil
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            pendingSlot = nil
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if let data = try? Data(contentsOf: url) {
            if let slot = pendingSlot {
                vm.uploadForSlot(slot, data: data, fileName: url.lastPathComponent)
            } else {
                vm.upload(data: data, fileName: url.lastPathComponent)
            }
        }
        pendingSlot = nil
    }

    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "png", "jpg", "jpeg": return "photo"
        case "txt": return "doc.text"
        default: return "doc"
        }
    }
}
