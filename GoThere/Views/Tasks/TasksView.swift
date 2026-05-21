import SwiftUI

struct TasksView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var countrySelection: CountrySelection
    @StateObject private var vm = TasksViewModel()
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskCategory = "Phase 1: Research & Planning"
    @State private var showImportSeed = false

    // Deep-link state for in-app Visa Wizard sheet (gothere://wizard)
    @State private var presentWizard = false

    // Date picker
    @State private var datePickerTask: TaskItem?
    @State private var selectedDate = Date()

    // Notes editor
    @State private var notesTask: TaskItem?
    @State private var notesText = ""

    // Celebration
    @State private var celebratePhase: String?

    // Tip dismissed
    @State private var tipDismissed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.tasksByPhase.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "checklist",
                        description: Text("Add your own tasks to track relocation progress."))
                } else {
                    List {
                        // Progress Dashboard
                        progressSection

                        // Countdown
                        countdownSection

                        // Tip of the Day
                        tipSection

                        // Task phases
                        ForEach(vm.tasksByPhase, id: \.0) { phaseName, tasks in
                            Section(phaseName) {
                                ForEach(tasks) { task in
                                    TaskRow(
                                        task: task,
                                        onToggle: { vm.toggleCompleted(task) },
                                        onSetDate: {
                                            selectedDate = task.dueAt ?? Date()
                                            datePickerTask = task
                                        },
                                        onEditNotes: {
                                            notesText = task.notes ?? ""
                                            notesTask = task
                                        },
                                        onLinkClick: { urlStr in
                                            handleTaskLink(urlStr)
                                        }
                                    )
                                    .swipeActions(edge: .trailing) {
                                        if task.dueAt != nil {
                                            Button {
                                                vm.addToCalendar(task)
                                            } label: {
                                                Label("Calendar", systemImage: "calendar.badge.plus")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $vm.searchQuery, prompt: "Search tasks")
            .goTopBar()
            .onAppear { vm.selectedCountry = countrySelection.current }
            .onChange(of: countrySelection.current) { _, newId in
                vm.selectedCountry = newId
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Share
                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }

                        Menu {
                            Button {
                                vm.showCompleted.toggle()
                            } label: {
                                Label(vm.showCompleted ? "Hide Completed" : "Show Completed",
                                      systemImage: vm.showCompleted ? "eye.slash" : "eye")
                            }
                            Divider()
                            Button { showImportSeed = true } label: {
                                Label("Re-import Seed Tasks", systemImage: "arrow.down.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }

                        Button { showAddTask = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTask) { addTaskSheet }
            .sheet(item: $datePickerTask) { task in datePickerSheet(task) }
            .sheet(isPresented: $presentWizard) {
                VisaWizardView(countryId: countrySelection.current)
            }
            .alert("Notes", isPresented: Binding(
                get: { notesTask != nil },
                set: { if !$0 { notesTask = nil } }
            )) {
                TextField("Add personal notes...", text: $notesText)
                Button("Save") {
                    if let task = notesTask {
                        Task { try? await TaskRepository.shared.setNotes(task, notes: notesText.isEmpty ? nil : notesText) }
                    }
                    notesTask = nil
                }
                Button("Cancel", role: .cancel) { notesTask = nil }
            }
            .alert("Phase Complete! \u{1F389}", isPresented: Binding(
                get: { celebratePhase != nil },
                set: { if !$0 { celebratePhase = nil } }
            )) {
                Button("Awesome!") { celebratePhase = nil }
            } message: {
                Text("You've completed all tasks in \(celebratePhase ?? ""). Keep going!")
            }
            .confirmationDialog("Import Seed Tasks", isPresented: $showImportSeed) {
                ForEach(DestinationConfig.allDestinations) { dest in
                    if purchaseManager.isCountryUnlocked(dest.id) {
                        Button("\(dest.flagEmoji) \(dest.name)") { importSeedTasks(for: dest.id) }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                vm.startListening()
                vm.autoSeedUnlockedCountries(purchaseManager)
                // Mirror global country selection on first appearance so the chip
                // filter agrees with the top-bar flag.
                if vm.selectedCountry == nil {
                    vm.selectedCountry = countrySelection.current
                }
            }
            .onChange(of: countrySelection.current) { newCountry in
                // Keep Tasks scoped to whatever the top-bar selector picks.
                // User can still tap a chip again to deselect ("show all").
                vm.selectedCountry = newCountry
            }
            .onChange(of: vm.tasksByPhase.map { $0.1.map(\.completed) }) { _ in
                checkPhaseCompletion()
            }
        }
    }

    // MARK: - Progress Dashboard

    @ViewBuilder
    private var progressSection: some View {
        let allTasks = vm.tasksByPhase.flatMap(\.1)
        let total = allTasks.count
        let completed = allTasks.filter(\.completed).count
        if total > 0 {
            let progress = Double(completed) / Double(total)
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.goPrimary.opacity(0.2), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.goPrimary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(progress * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(.goPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(completed) of \(total) tasks completed")
                            .font(.subheadline.weight(.semibold))
                        let remaining = total - completed
                        if remaining > 0 {
                            Text("\(remaining) tasks remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("All tasks complete!")
                                .font(.caption.bold())
                                .foregroundColor(.goPrimary)
                        }
                    }
                }
                ProgressView(value: progress)
                    .tint(.goPrimary)
            }
        }
    }

    // MARK: - Countdown

    @ViewBuilder
    private var countdownSection: some View {
        let targetMillis = UserDefaults.standard.double(forKey: "target_move_millis")
        if targetMillis > Date().timeIntervalSince1970 * 1000 {
            let days = Int((targetMillis / 1000 - Date().timeIntervalSince1970) / 86400)
            Section {
                HStack(spacing: 12) {
                    Text("\u{2708}\u{FE0F}")
                        .font(.title)
                    VStack(alignment: .leading) {
                        Text("\(days) days until your move")
                            .font(.subheadline.bold())
                        Text("Stay on track with your checklist!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Tip of the Day

    @ViewBuilder
    private var tipSection: some View {
        if !tipDismissed, let tip = TipsRepository.shared.todaysTip(for: vm.selectedCountry ?? "spain") {
            Section {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.goPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tip of the Day")
                            .font(.caption.bold())
                            .foregroundColor(.goPrimary)
                        Text(tip.tip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { tipDismissed = true } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Share text

    private var shareText: String {
        let allTasks = vm.tasksByPhase
        var text = "GoThere - Relocation Checklist\n\n"
        for (phase, tasks) in allTasks {
            text += "\(phase)\n"
            for t in tasks {
                text += "  \(t.completed ? "\u{2705}" : "\u{2B1C}") \(t.title)\n"
            }
            text += "\n"
        }
        let total = allTasks.flatMap(\.1).count
        let done = allTasks.flatMap(\.1).filter(\.completed).count
        text += "Progress: \(done)/\(total) completed"
        return text
    }

    // MARK: - Phase completion check

    private func checkPhaseCompletion() {
        for (phase, tasks) in vm.tasksByPhase {
            if !tasks.isEmpty && tasks.allSatisfy(\.completed) {
                let key = "celebrated_\(phase)"
                if !UserDefaults.standard.bool(forKey: key) {
                    celebratePhase = phase
                    UserDefaults.standard.set(true, forKey: key)
                    break
                }
            }
        }
    }

    // MARK: - Date Picker Sheet

    private func datePickerSheet(_ task: TaskItem) -> some View {
        NavigationStack {
            DatePicker("Due Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Set Due Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            Task { try? await TaskRepository.shared.setDue(task, date: nil) }
                            datePickerTask = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Set") {
                            Task { try? await TaskRepository.shared.setDue(task, date: selectedDate) }
                            datePickerTask = nil
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Add Task Sheet

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $newTaskTitle)
                Picker("Phase", selection: $newTaskCategory) {
                    ForEach(Phases.allPhases) { phase in
                        Text(phase.displayName).tag(phase.displayName)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddTask = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let task = TaskItem(title: newTaskTitle, category: newTaskCategory)
                        Task { try? await TaskRepository.shared.addTask(task) }
                        newTaskTitle = ""
                        showAddTask = false
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Seed Import

    private func importSeedTasks(for countryId: String) {
        let fileName: String
        switch countryId {
        case "portugal": fileName = "portugal_tasks"
        case "mexico": fileName = "mexico_tasks"
        default: fileName = "spain_tasks"
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        struct SeedTask: Codable {
            let title: String; let description: String?; let phaseId: String
            let visaTrackId: String?; let order: Int?; let links: [SeedLink]?
        }
        struct SeedLink: Codable { let label: String?; let url: String? }
        guard let seedTasks = try? JSONDecoder().decode([SeedTask].self, from: data) else { return }
        let taskItems = seedTasks.map { seed in
            TaskItem(title: seed.title, description: seed.description,
                     category: Phases.getDisplayName(seed.phaseId), countryId: countryId,
                     links: seed.links?.map { AppLink(label: $0.label, url: $0.url) })
        }
        Task { try? await TaskRepository.shared.insertTasks(taskItems) }
    }

    // MARK: - Deep-link handler

    /// Routes task link URLs. `gothere://<path>` triggers in-app navigation
    /// (Wizard sheet, or tab switch via NotificationCenter); anything else opens
    /// externally. Keeps parity with Android's `handleTaskLink`.
    private func handleTaskLink(_ urlStr: String) {
        if urlStr.hasPrefix("gothere://") {
            let path = String(urlStr.dropFirst("gothere://".count))
                .components(separatedBy: "?").first?
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                .lowercased() ?? ""
            switch path {
            case "wizard", "compare":
                presentWizard = true
            case "tasks", "calendar", "documents", "resources", "decision", "decisiontree":
                NotificationCenter.default.post(
                    name: .gothereDeepLink,
                    object: nil,
                    userInfo: ["route": path]
                )
            default:
                break
            }
            return
        }
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onSetDate: () -> Void
    let onEditNotes: () -> Void
    let onLinkClick: (String) -> Void
    // Default expanded so resource links/description aren't hidden behind a chevron
    // tap. The chevron and inner content sections gate themselves on actual content,
    // so a task with no details still renders correctly.
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.completed ? .goSuccess : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .strikethrough(task.completed)
                        .foregroundColor(task.completed ? .secondary : .primary)
                    if let dueAt = task.dueAt {
                        Text(dueAt, style: .date)
                            .font(.caption)
                            .foregroundColor(dueAt < Date() && !task.completed ? .goError : .secondary)
                    }
                }

                Spacer()

                // Date picker button
                Button(action: onSetDate) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                // Notes button
                Button(action: onEditNotes) {
                    Image(systemName: "square.and.pencil")
                        .font(.caption)
                        .foregroundColor(task.notes?.isEmpty == false ? .goPrimary : .secondary)
                }
                .buttonStyle(.plain)

                if task.description != nil || task.links != nil || task.notes != nil {
                    Button {
                        withAnimation { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isExpanded {
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 44)
                }
                if let notes = task.notes, !notes.isEmpty {
                    Text("\u{1F4DD} \(notes)")
                        .font(.caption)
                        .foregroundColor(.goPrimary)
                        .padding(.leading, 44)
                }
                if let links = task.links {
                    ForEach(links) { link in
                        if let urlStr = link.url, !urlStr.isEmpty {
                            let isInternal = urlStr.hasPrefix("gothere://")
                            Button {
                                onLinkClick(urlStr)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isInternal ? "arrow.forward.circle" : "link")
                                        .font(.caption2)
                                    Text(link.label ?? urlStr).font(.caption)
                                }
                                .foregroundColor(.goPrimary)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .goPrimary : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.goPrimary : Color.clear, lineWidth: 1)
                )
        }
    }
}
