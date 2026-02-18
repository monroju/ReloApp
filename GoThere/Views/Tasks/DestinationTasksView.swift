import SwiftUI

struct DestinationTasksView: View {
    @StateObject private var vm = DestinationsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Phase filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All Phases", isSelected: vm.filterPhase == nil) {
                        vm.filterPhase = nil
                    }
                    ForEach(Phases.allPhases) { phase in
                        FilterChip(title: phase.shortName, isSelected: vm.filterPhase == phase.id) {
                            vm.filterPhase = phase.id
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if vm.tasksByPhase.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Tasks will appear when you select a destination and visa track.")
                )
            } else {
                List {
                    ForEach(vm.tasksByPhase, id: \.0.id) { phase, tasks in
                        Section {
                            ForEach(tasks) { task in
                                HStack(spacing: 12) {
                                    Button {
                                        vm.toggleTask(task)
                                    } label: {
                                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.completed ? .goSuccess : .secondary)
                                    }
                                    .buttonStyle(.plain)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.subheadline)
                                            .strikethrough(task.completed)
                                        if let desc = task.description {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(phase.displayName)
                                Spacer()
                                let progress = vm.phaseProgress(phase.id)
                                Text("\(progress.completed)/\(progress.total)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $vm.searchQuery, prompt: "Search tasks")
        .navigationTitle("Destination Tasks")
        .task {
            await vm.loadDestination()
        }
    }
}
