import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = DocumentsViewModel()
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.documents.isEmpty && !vm.isUploading {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.fill",
                        description: Text("Upload documents like passport copies, visa applications, and more.")
                    )
                } else {
                    List {
                        if vm.isUploading {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Uploading...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        ForEach(vm.documents) { doc in
                            HStack(spacing: 12) {
                                Image(systemName: iconForFile(doc.name))
                                    .foregroundColor(.goPrimary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.name)
                                        .font(.subheadline)
                                    if !doc.downloadUrl.isEmpty {
                                        Text("Tap to open")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.goPrimary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let url = URL(string: doc.downloadUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    vm.deleteDocument(doc)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .goTopBar(showThemeToggle: false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        if let data = try? Data(contentsOf: url) {
            vm.upload(data: data, fileName: url.lastPathComponent)
        }
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
