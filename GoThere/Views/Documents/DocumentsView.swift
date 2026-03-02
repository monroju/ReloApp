import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var vm = DocumentsViewModel()
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header row: title + refresh + Upload button (matches Android)
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

                    // Info card (matches Android)
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

                    // Document list
                    if vm.documents.isEmpty && !vm.isUploading {
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
                    } else {
                        VStack(spacing: 0) {
                            ForEach(vm.documents) { doc in
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

                                Divider()
                            }
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
                        .cornerRadius(12)
                    }
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
