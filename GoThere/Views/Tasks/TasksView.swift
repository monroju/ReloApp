import SwiftUI

struct TasksView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = TasksViewModel()
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskCategory = "Phase 1: Research & Planning"
    @State private var showImportSeed = false
    @State private var importCountry = DestinationConfig.spain

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Country selector with flags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DestinationConfig.allDestinations) { dest in
                            let isUnlocked = purchaseManager.isCountryUnlocked(dest.id)
                            FilterChip(
                                title: "\(dest.flagEmoji) \(dest.name)\(isUnlocked ? "" : " \u{1F512}")",
                                isSelected: vm.selectedCountry == dest.id
                            ) {
                                if isUnlocked {
                                    vm.selectedCountry = vm.selectedCountry == dest.id ? nil : dest.id
                                }
                            }
                        }

                        FilterChip(title: vm.showCompleted ? "Hide Done" : "Show Done",
                                   isSelected: vm.showCompleted) {
                            vm.showCompleted.toggle()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Import Seed button — teal outlined pill (matches Android)
                Button {
                    showImportSeed = true
                } label: {
                    Text("Import Seed")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.goPrimary)
                        .cornerRadius(20)
                }
                .padding(.bottom, 8)

                // Task list by phase
                if vm.tasksByPhase.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "checklist",
                        description: Text("Import seed tasks or add your own to track relocation progress.")
                    )
                } else {
                    List {
                        ForEach(vm.tasksByPhase, id: \.0) { phaseName, tasks in
                            Section(phaseName) {
                                ForEach(tasks) { task in
                                    TaskRow(task: task) {
                                        vm.toggleCompleted(task)
                                    }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                addTaskSheet
            }
            .confirmationDialog("Import Seed Tasks", isPresented: $showImportSeed) {
                ForEach(DestinationConfig.allDestinations) { dest in
                    if purchaseManager.isCountryUnlocked(dest.id) {
                        Button("\(dest.flagEmoji) \(dest.name)") {
                            importCountry = dest.id
                            importSeedTasks(for: dest.id)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                vm.startListening()
            }
        }
    }

    private func importSeedTasks(for countryId: String) {
        // Load from actual JSON seed files (matches Android seed import)
        let fileName: String
        switch countryId {
        case "portugal": fileName = "portugal_tasks"
        case "mexico": fileName = "mexico_tasks"
        default: fileName = "spain_tasks"
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        struct SeedTask: Codable {
            let title: String
            let description: String?
            let phaseId: String
            let visaTrackId: String?
            let order: Int?
            let links: [SeedLink]?
        }
        struct SeedLink: Codable {
            let label: String?
            let url: String?
        }

        guard let seedTasks = try? JSONDecoder().decode([SeedTask].self, from: data) else { return }

        let taskItems = seedTasks.map { seed in
            TaskItem(
                title: seed.title,
                description: seed.description,
                category: Phases.getDisplayName(seed.phaseId),
                countryId: countryId,
                links: seed.links?.map { AppLink(label: $0.label, url: $0.url) }
            )
        }

        Task {
            try? await TaskRepository.shared.insertTasks(taskItems)
        }
    }

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
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    @State private var isExpanded = false

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

                if task.description != nil || task.links != nil {
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

            // Expandable details
            if isExpanded {
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 44)
                }

                if let links = task.links {
                    ForEach(links) { link in
                        if let urlStr = link.url, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.caption2)
                                    Text(link.label ?? urlStr)
                                        .font(.caption)
                                }
                                .foregroundColor(.goPrimary)
                            }
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
