import SwiftUI

// MARK: - HomeDashboardView

struct HomeDashboardView: View {

    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    destinationBanner
                    progressSection
                    phaseList
                    upcomingEventsSection
                    documentsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showProfileSheet) {
                ProfileEditView(viewModel: viewModel)
            }
            .overlay { loadingOverlay }
            .onAppear { viewModel.loadDashboard() }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting + ",")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.displayName.isEmpty ? "Traveler" : viewModel.displayName)
                    .font(.title2.bold())
            }

            Spacer()

            Button {
                viewModel.showProfileSheet = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            Text(initials)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        let parts = viewModel.displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    // MARK: - Destination Banner

    @ViewBuilder
    private var destinationBanner: some View {
        if let dest = viewModel.destination, let track = viewModel.activeVisaTrack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(dest.flagEmoji)
                        .font(.largeTitle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dest.name)
                            .font(.headline)
                        Text(track.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let time = track.estimatedProcessingTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                if !track.requirements.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(track.requirements.prefix(4), id: \.self) { req in
                            Text(req)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                        if track.requirements.count > 4 {
                            Text("+\(track.requirements.count - 4)")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                        }
                    }
                }

                // Visa track picker when multiple tracks exist
                if let tracks = viewModel.destination?.visaTracks, tracks.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tracks) { t in
                                Button {
                                    viewModel.selectVisaTrack(t)
                                } label: {
                                    Text(t.shortName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            t.id == track.id
                                                ? AnyShapeStyle(Color.accentColor)
                                                : AnyShapeStyle(.ultraThinMaterial),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(t.id == track.id ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Overall Progress", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.progressStats.percentage)%")
                    .font(.title3.bold())
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
            }

            ProgressView(value: Double(viewModel.progressStats.percentage), total: 100)
                .tint(Color.accentColor)
                .scaleEffect(y: 2)

            HStack(spacing: 16) {
                statBadge(
                    value: "\(viewModel.progressStats.completedTasks)",
                    label: "Done",
                    color: .green
                )
                statBadge(
                    value: "\(viewModel.progressStats.totalTasks - viewModel.progressStats.completedTasks)",
                    label: "Remaining",
                    color: .orange
                )
                statBadge(
                    value: "\(viewModel.totalPhasesCompleted)",
                    label: "Phases",
                    color: .purple
                )
                statBadge(
                    value: "\(viewModel.upcomingEvents.count)",
                    label: "Events",
                    color: .blue
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phase List

    private var phaseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Task Phases", systemImage: "list.bullet.clipboard")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.phaseGroups.isEmpty {
                emptyState(
                    icon: "checklist",
                    title: "No tasks yet",
                    subtitle: "Select a destination to load your task roadmap."
                )
            } else {
                ForEach(Array(viewModel.phaseGroups.enumerated()), id: \.offset) { _, group in
                    phaseGroupRow(group)
                }
            }
        }
    }

    private func phaseGroupRow(_ group: TaskPhaseGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.displayName)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(group.completedCount)/\(group.totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(group.completedCount), total: max(Double(group.totalCount), 1))
                .tint(group.completedCount == group.totalCount ? .green : Color.accentColor)

            ForEach(group.tasks.prefix(3)) { task in
                taskRow(task)
            }

            if group.tasks.count > 3 {
                Text("+\(group.tasks.count - 3) more")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(.leading, 28)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func taskRow(_ task: DestinationTask) -> some View {
        HStack(spacing: 10) {
            Button {
                viewModel.toggleTaskCompleted(task)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.completed ? .green : .secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.subheadline)
                .strikethrough(task.completed, color: .secondary)
                .foregroundStyle(task.completed ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            if let dueAt = task.dueAt {
                Text(formattedDate(millis: dueAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Events", systemImage: "calendar")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.upcomingEvents.isEmpty {
                emptyState(
                    icon: "calendar.badge.plus",
                    title: "No upcoming events",
                    subtitle: "Events you add will appear here."
                )
            } else {
                ForEach(viewModel.upcomingEvents.prefix(5)) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: EventItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(formattedDate(millis: event.dateMillis))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let notes = event.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Documents

    @ViewBuilder
    private var documentsSection: some View {
        if !viewModel.recentDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recent Documents", systemImage: "doc.fill")
                    .font(.headline)
                    .padding(.horizontal, 4)

                ForEach(viewModel.recentDocuments) { doc in
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color.accentColor)
                        Text(doc.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Shared Components

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.subheadline.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ZStack {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .padding(24)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let url = viewModel.destination?.officialImmigrationUrl,
                   let link = URL(string: url) {
                    SwiftUI.Link(destination: link) {
                        Label("Immigration Portal", systemImage: "globe")
                    }
                }
                Button {
                    viewModel.loadDashboard()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formattedDate(millis: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - FlowLayout (Requirement Chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }
        return (CGSize(width: totalWidth, height: totalHeight), origins)
    }
}

// MARK: - ProfileEditView

struct ProfileEditView: View {

    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var draftEmail: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Display Name", text: $draftName)
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    TextField("Email", text: $draftEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if let dest = viewModel.destination {
                    Section("Destination") {
                        LabeledContent("Country") {
                            Text("\(dest.flagEmoji) \(dest.name)")
                        }
                        if let track = viewModel.activeVisaTrack {
                            LabeledContent("Visa Track") {
                                Text(track.name)
                            }
                            if let time = track.estimatedProcessingTime {
                                LabeledContent("Est. Processing") {
                                    Text(time)
                                }
                            }
                        }
                    }
                }

                Section("Progress Snapshot") {
                    LabeledContent("Tasks Completed") {
                        Text("\(viewModel.progressStats.completedTasks) / \(viewModel.progressStats.totalTasks)")
                            .monospacedDigit()
                    }
                    LabeledContent("Completion") {
                        Text("\(viewModel.progressStats.percentage)%")
                            .bold()
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateProfile(name: draftName, email: draftEmail)
                        dismiss()
                    }
                    .bold()
                    .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                draftName = viewModel.displayName
                draftEmail = viewModel.email
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    HomeDashboardView()
}
