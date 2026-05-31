import SwiftUI

/// "Bring your job abroad" view — employer-letter templates (copyable) + the
/// tax-residency warnings remote workers miss. Middle-class remote-worker hook.
struct RemoteWorkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copiedId: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro

                Text("📄 Letter templates")
                    .font(.subheadline.bold()).foregroundColor(.secondary)
                ForEach(RemoteWorkKit.templates) { template in
                    templateCard(template)
                }

                Text("⚠️ Tax-residency warnings")
                    .font(.subheadline.bold()).foregroundColor(.secondary)
                    .padding(.top, 4)
                ForEach(RemoteWorkKit.taxWarnings) { warning in
                    warningCard(warning)
                }

                Text(RemoteWorkKit.disclaimer)
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Bring Your Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Take your remote job with you")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("The two things remote workers get wrong: proving employment to a consulate, and tax residency. Here's both.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func templateCard(_ t: RemoteWorkKit.LetterTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t.title).font(.subheadline.bold()).foregroundColor(.primary)
            Text(t.subtitle).font(.caption).foregroundColor(.secondary)
            Text(t.body)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
            Button {
                UIPasteboard.general.string = t.body
                copiedId = t.id
            } label: {
                Label(copiedId == t.id ? "Copied!" : "Copy template",
                      systemImage: copiedId == t.id ? "checkmark" : "doc.on.doc")
                    .font(.caption.bold())
                    .foregroundColor(.goPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func warningCard(_ w: RemoteWorkKit.TaxWarning) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(w.title).font(.footnote.bold()).foregroundColor(.primary)
            }
            Text(w.detail).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(10)
    }
}
