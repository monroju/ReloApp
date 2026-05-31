import SwiftUI

/// "Gone in N months" planner — generates a personalized month-by-month relocation
/// checklist from a target timeline + household. Middle-class planner hook.
struct RelocationTimelineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var totalMonths: Double = 12
    @State private var hasKids: Bool = false

    private var buckets: [RelocationTimeline.MonthBucket] {
        RelocationTimeline.generate(totalMonths: Int(totalMonths), hasKids: hasKids)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                controls
                ForEach(buckets) { bucket in
                    bucketCard(bucket)
                }
                disclaimer
            }
            .padding()
        }
        .navigationTitle("My Move Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your move, month by month")
                .font(.title3.bold())
                .foregroundColor(.goPrimary)
            Text("Tell us when you want to be gone — we'll build the plan backwards from your departure.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("I want to be gone in")
                    .font(.subheadline).foregroundColor(.primary)
                Spacer()
                Text("\(Int(totalMonths)) month\(Int(totalMonths) == 1 ? "" : "s")")
                    .font(.subheadline.bold()).foregroundColor(.goPrimary)
            }
            Slider(value: $totalMonths, in: 1...18, step: 1).tint(.goPrimary)
            Toggle(isOn: $hasKids) {
                Text("Moving with children")
                    .font(.subheadline).foregroundColor(.primary)
            }
            .tint(.goPrimary)
        }
        .padding()
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(12)
    }

    private func bucketCard(_ bucket: RelocationTimeline.MonthBucket) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(bucket.label)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color.goPrimary)
                .cornerRadius(8)

            ForEach(bucket.milestones) { m in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.goPrimary)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.title).font(.footnote.bold()).foregroundColor(.primary)
                        Text(m.detail).font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var disclaimer: some View {
        Text("A guide, not a guarantee — visa processing times vary and can dominate your timeline. Start the visa step as early as possible.")
            .font(.caption2).foregroundColor(.secondary)
    }
}
