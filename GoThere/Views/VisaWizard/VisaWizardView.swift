import SwiftUI

struct VisaWizardView: View {
    let countryId: String
    @StateObject private var vm = VisaWizardViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if vm.selectedTrack != nil {
                let progress = Double(vm.currentStep) / Double(max(vm.totalStepCount, 1))
                ProgressView(value: min(progress, 1.0))
                    .tint(.goPrimary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Text("Step \(vm.currentStep) of \(vm.totalStepCount - 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            Group {
                if vm.currentStep == 0 {
                    trackSelectionView
                } else if vm.isOnSummary {
                    summaryView
                } else if let step = vm.currentWizardStep {
                    stepView(step)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: vm.currentStep)
        }
        .navigationTitle("Visa Wizard")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.currentStep > 0 && !vm.saveComplete)
        .toolbar {
            if vm.currentStep > 0 && !vm.saveComplete {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.prevStep()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .task { vm.loadConfig(countryId: countryId) }
    }

    // MARK: - Track Selection

    private var trackSelectionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose Your Visa Path")
                    .font(.title2.bold())
                    .foregroundColor(.goPrimary)

                let countryName = DestinationConfig.getDestination(countryId)?.name ?? "Spain"
                Text("Select the visa type you're pursuing in \(countryName). We'll create a personalized step-by-step checklist.")
                    .font(.body)
                    .foregroundColor(.secondary)

                ForEach(vm.availableTracks, id: \.0) { trackId, track in
                    Button {
                        vm.selectTrack(trackId)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(track.shortName) \u{2022} \(track.steps.count) steps \u{2022} \(track.taskRules.count) tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Step View

    private func stepView(_ step: WizardStep) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(step.title)
                    .font(.title3.bold())
                    .foregroundColor(.goPrimary)

                if let subtitle = step.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ForEach(step.questions) { question in
                    if vm.isQuestionVisible(question) {
                        questionView(question)
                    }
                }

                Spacer(minLength: 20)

                HStack(spacing: 12) {
                    Button("Back") { vm.prevStep() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                    Button(vm.isLastQuestionStep ? "Generate Checklist" : "Next") {
                        vm.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.goPrimary)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Question Renderers

    @ViewBuilder
    private func questionView(_ q: WizardQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(q.label)
                .font(.subheadline.weight(.medium))

            if let hint = q.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            switch q.type {
            case "single_choice":
                singleChoiceView(q)
            case "boolean":
                booleanView(q)
            case "number":
                numberView(q)
            default:
                EmptyView()
            }
        }
    }

    private func singleChoiceView(_ q: WizardQuestion) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(q.options ?? []) { option in
                let selected = (vm.answers[q.id] as? String) == option.id
                Button {
                    vm.setAnswer(q.id, value: option.id)
                } label: {
                    Text(option.label)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selected ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
                        .foregroundColor(selected ? .goPrimary : .primary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected ? Color.goPrimary : .clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func booleanView(_ q: WizardQuestion) -> some View {
        HStack(spacing: 8) {
            ForEach(["Yes", "No"], id: \.self) { label in
                let isYes = label == "Yes"
                let selected = (vm.answers[q.id] as? Bool) == isYes
                Button {
                    vm.setAnswer(q.id, value: isYes)
                } label: {
                    Text(label)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selected ? Color.goPrimary.opacity(0.15) : Color.secondary.opacity(0.1))
                        .foregroundColor(selected ? .goPrimary : .primary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected ? Color.goPrimary : .clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func numberView(_ q: WizardQuestion) -> some View {
        let minVal = q.min ?? 1
        let maxVal = q.max ?? 10
        let current = (vm.answers[q.id] as? Int) ?? minVal

        return HStack {
            Slider(
                value: Binding(
                    get: { Double(current) },
                    set: { vm.setAnswer(q.id, value: Int($0)) }
                ),
                in: Double(minVal)...Double(maxVal),
                step: 1
            )
            Text("\(current)")
                .font(.headline)
                .foregroundColor(.goPrimary)
                .frame(width: 30)
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if vm.saveComplete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.goPrimary)
                        Text("\(vm.generatedTasks.count) tasks added!")
                            .font(.title2.bold())
                            .foregroundColor(.goPrimary)
                        Text("Your personalized visa checklist is ready with due dates based on your timeline.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Go to Tasks") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.goPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    Text("Your Personalized Checklist")
                        .font(.title3.bold())
                        .foregroundColor(.goPrimary)
                    Text("\(vm.generatedTasks.count) tasks tailored to your situation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let grouped = Dictionary(grouping: vm.generatedTasks) { $0.category ?? "Other" }
                    let sortedPhases = grouped.keys.sorted()

                    ForEach(sortedPhases, id: \.self) { phase in
                        Text(phase)
                            .font(.caption.bold())
                            .foregroundColor(.goPrimaryDark)
                            .padding(.top, 8)

                        ForEach(grouped[phase] ?? [], id: \.title) { task in
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.goPrimary)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.subheadline.weight(.medium))
                                    if let due = task.dueAt {
                                        Text("Due: \(due, style: .date)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }

                    Button {
                        Task { await vm.saveTasks() }
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add \(vm.generatedTasks.count) Tasks to My Checklist")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.goPrimary)
                    .disabled(vm.isSaving)
                    .padding(.top, 16)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - FlowLayout (wrapping chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
