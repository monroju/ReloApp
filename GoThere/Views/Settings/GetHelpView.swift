import SwiftUI

/// Organizations that support people moving abroad, from the `HelpOrgs` feed.
/// Opened from Settings. The entry is hidden while the list is empty.
struct GetHelpView: View {
    @ObservedObject private var help = HelpOrgs.shared

    var body: some View {
        List {
            Section {
                ForEach(help.orgs) { org in
                    if let url = org.link {
                        Link(destination: url) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: org.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.primary)
                                    if !org.blurb.isEmpty {
                                        Text(verbatim: org.blurb)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, 2)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("Opens their website in your browser")
                    }
                }
            } header: {
                Text("Organizations that support people moving abroad. GoThere is not affiliated with them unless stated.")
                    .font(.footnote)
                    .textCase(nil)
            }
        }
        .navigationTitle("Get help")
        .navigationBarTitleDisplayMode(.inline)
        .task { await help.refresh() }
    }
}
