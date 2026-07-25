import SwiftUI
import PhotosUI
import UIKit

/// "Scan a document" — photograph or pick an official letter/form, get a
/// plain-English explanation with any deadline surfaced and quoted. Free for the
/// first few scans, then paywalled (mirrors the AI assistant's quota gate).
struct DocumentScanView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @ObservedObject private var service = DocumentAnalysisService.shared

    @State private var showScanner = false
    @State private var photoItem: PhotosPickerItem?
    @State private var analysis: DocumentAnalysis?
    @State private var errorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if service.isAnalyzing {
                    analyzingState
                } else if let analysis {
                    DocumentResultView(analysis: analysis)
                    Button {
                        self.analysis = nil
                        self.errorMessage = nil
                    } label: {
                        Label("Scan another document", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.goPrimary)
                } else {
                    intro
                    captureButtons
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                quotaHint
                disclaimer
            }
            .padding()
        }
        .navigationTitle("Scan a Document")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            DocumentCameraView { image in
                if let image { handle(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    handle(image)
                }
                photoItem = nil
            }
        }
    }

    // MARK: - Sections

    private var intro: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 52))
                .foregroundColor(.goPrimary)
            Text("Got a letter you can't read?")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Photograph any official letter or form — from immigration, tax, your landlord, the bank, or the health service. We explain it in plain English and flag any deadline, even if it's in another language.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var captureButtons: some View {
        VStack(spacing: 12) {
            Button { startCamera() } label: {
                Label("Scan with camera", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.goPrimary)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose a photo", systemImage: "photo.on.rectangle")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.goPrimary)
        }
    }

    private var analyzingState: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Reading your document…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var quotaHint: some View {
        if !purchaseManager.hasAllAccess {
            Text(service.remainingFreeScans > 0
                 ? "\(service.remainingFreeScans) free scan\(service.remainingFreeScans == 1 ? "" : "s") left"
                 : "Free scans used — upgrade for unlimited")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var disclaimer: some View {
        Text("GoThere explains documents to help you understand them. It is not legal, tax, or immigration advice. Always verify with the office that sent it, or a qualified professional, before acting.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    // MARK: - Actions

    private func startCamera() {
        if service.isScanGated { showPaywall = true; return }
        showScanner = true
    }

    private func handle(_ image: UIImage) {
        if service.isScanGated { showPaywall = true; return }
        guard let data = Self.processed(image) else {
            errorMessage = "Couldn't process that image. Please try again."
            return
        }
        errorMessage = nil
        analysis = nil
        Task {
            do {
                let result = try await service.analyze(imageData: data, country: nil)
                analysis = result
                Analytics.log(.purchaseCompleted, properties: [
                    "product_id": "document_scan",
                    "readable": !result.unreadable
                ])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Downscale (longest side ≤ 1600px) + JPEG-compress so payloads stay small
    /// and comfortably under the function's body cap.
    static func processed(_ image: UIImage) -> Data? {
        let maxDim: CGFloat = 1600
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDim ? maxDim / longest : 1
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}

// MARK: - Result

private struct DocumentResultView: View {
    let analysis: DocumentAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if analysis.unreadable {
                unreadableCard
            } else if !analysis.isDocument {
                notADocumentCard
            } else {
                header
                if !analysis.deadlines.isEmpty {
                    ForEach(Array(analysis.deadlines.enumerated()), id: \.offset) { _, dl in
                        deadlineCard(dl)
                    }
                } else {
                    Label("No deadline stated in this document.", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let summary = analysis.summary, !summary.isEmpty {
                    section("What this says", summary)
                }
                if let next = analysis.nextStep, !next.isEmpty {
                    nextStepCard(next)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(analysis.docType ?? "Document")
                    .font(.title3.bold())
                Spacer()
                confidenceBadge
            }
            if let sender = analysis.sender, !sender.isEmpty {
                Text(sender)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let lang = analysis.originalLanguage, !lang.isEmpty {
                Text("Original language: \(lang)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var confidenceBadge: some View {
        if let c = analysis.confidence {
            let color: Color = c == "high" ? .goSuccess : (c == "low" ? .red : .orange)
            Text(c.capitalized)
                .font(.caption2.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .clipShape(Capsule())
        }
    }

    private func deadlineCard(_ dl: DocumentAnalysis.Deadline) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(dl.dateAsWritten, systemImage: "clock.badge.exclamationmark")
                .font(.headline)
                .foregroundColor(.orange)
            if !dl.action.isEmpty {
                Text(dl.action).font(.subheadline)
            }
            if !dl.sourceQuote.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From the document:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("“\(dl.sourceQuote)”")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).foregroundColor(.goPrimary)
            Text(body).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nextStepCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Your next step", systemImage: "arrow.right.circle.fill")
                .font(.headline)
                .foregroundColor(.goPrimary)
            Text(text).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goCard()
    }

    private var unreadableCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.slash").font(.title).foregroundColor(.secondary)
            Text("Couldn't read this clearly")
                .font(.headline)
            Text("Try again with good light, the document flat, and the camera straight on. Make sure the whole page is in frame.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var notADocumentCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "questionmark.folder").font(.title).foregroundColor(.secondary)
            Text("That doesn't look like an official document")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Point the camera at a letter or form you received — from immigration, tax, your landlord, the bank, or the health service.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
