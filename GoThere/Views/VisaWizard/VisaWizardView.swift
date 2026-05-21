import SwiftUI

struct VisaWizardView: View {
    let countryId: String
    /// Optional deep-link target — when set, the wizard auto-selects this track
    /// after loadConfig. Used by Decision Tree's "Visas to look at next" rows so
    /// the user lands directly inside the recommended visa flow.
    var initialTrackId: String? = nil
    @StateObject private var vm = VisaWizardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCompare = false

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
        .sheet(isPresented: $showCompare) {
            NavigationStack {
                VisaCompareView(initialCountryId: countryId) { trackId in
                    vm.selectTrack(trackId)
                    showCompare = false
                }
            }
        }
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
        .task {
            vm.loadConfig(countryId: countryId)
            if let trackId = initialTrackId,
               vm.selectedTrackId != trackId,
               vm.availableTracks.contains(where: { $0.0 == trackId }) {
                vm.selectTrack(trackId)
            }
        }
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

                // Compare visa types CTA
                Button {
                    showCompare = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.split.3x1.fill")
                            .font(.title3)
                            .foregroundColor(.goPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compare Visa Types")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text("Side-by-side eligibility, cost & citizenship paths")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.goPrimary.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.goPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                ForEach(vm.availableTracks, id: \.0) { trackId, track in
                    Button {
                        vm.selectTrack(trackId)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(track.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(track.shortName) \u{2022} \(track.steps.count) steps \u{2022} \(track.taskRules.count) tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if track.eligibilityRule?.inFlux == true {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                    Text("Rules changing — verify before you start")
                                        .font(.caption2.weight(.semibold))
                                }
                                .foregroundColor(.goWarning)
                                .padding(.top, 2)
                            }
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
                inFluxBanner

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
                    inFluxBanner

                    Text("Your Personalized Checklist")
                        .font(.title3.bold())
                        .foregroundColor(.goPrimary)
                    Text("\(vm.generatedTasks.count) tasks tailored to your situation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Wave 1 (T1b-finish) — anchor date picker. Drives all
                    // milestone scheduling on the Calendar tab.
                    anchorDatePicker

                    // Wave 1 (T1c-finish) — income-fit card mirroring the
                    // Calculator's affordability grouping. Surfaces here so
                    // the user sees the fit before tapping "Add to checklist".
                    incomeFitCard

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

// FlowLayout is defined in DecisionTreeView.swift

// MARK: - Wave 1 helpers

extension VisaWizardView {
    /// Anchor date picker shown on the wizard summary. Defaults to the config's
    /// `defaultOffsetDays` and feeds straight into `vm.anchorDate` so milestones
    /// regenerate against the user's chosen date when they tap Add.
    var anchorDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target application date")
                .font(.subheadline.weight(.semibold))
            Text("We'll anchor reminders to this date. Pick the date you'd like to submit your visa application. You can adjust later.")
                .font(.caption)
                .foregroundColor(.secondary)
            DatePicker(
                "Anchor date",
                selection: $vm.anchorDate,
                in: Date()...,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(.goPrimary)
        }
        .padding(12)
        .background(Color.goPrimary.opacity(0.06))
        .cornerRadius(10)
    }

    /// Income-fit card — mirrors the Calculator's grouping but on the wizard
    /// side. Read-only here; tapping the card jumps to the Calculator via the
    /// deep-link router for a fuller adjust-your-lifestyle flow.
    @ViewBuilder
    var incomeFitCard: some View {
        if let visa = selectedVisaInfo {
            VStack(alignment: .leading, spacing: 8) {
                Text("Income fit")
                    .font(.subheadline.weight(.semibold))
                if let threshold = visa.monthlyIncomeEUR {
                    let dependents = answeredDependentCount
                    let effective = visa.requiredMonthlyEUR(dependents: dependents) ?? threshold
                    Text("Requires ~€\(effective.formatted())/mo proof of funds\(dependents > 0 ? " for you + \(dependents) dependent\(dependents == 1 ? "" : "s")" : "").")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if dependents == 0, visa.dependentMultiplier != nil {
                        Text("Family threshold scales with dependents — answer the family question on the earlier wizard step to refine.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text("Open the Cost Calculator anytime to compare this against your estimated monthly lifestyle.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                } else {
                    Text("This visa uses non-income criteria (points / employer / ancestry). Check the official requirements in Resources.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color.goSuccess.opacity(0.08))
            .cornerRadius(10)
        }
    }

    private var selectedVisaInfo: VisaInfo? {
        guard let trackId = vm.selectedTrackId else { return nil }
        return VisaCatalog.all.first { $0.wizardTrackId == trackId }
    }

    /// Wave 2 (Ancestry deepening) — warning banner shown across step + summary
    /// views when the underlying citizenship law is in active change. Driven by
    /// `WizardTrack.eligibilityRule.inFlux`. Currently active on Italy Jure
    /// Sanguinis (DL 36/2025) and Canada by-descent (Bill C-3).
    @ViewBuilder
    var inFluxBanner: some View {
        if let rule = vm.selectedTrack?.eligibilityRule, rule.inFlux {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.goWarning)
                    Text("Rules changing — verify before you start")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
                if let note = rule.inFluxNote {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.goWarning.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.goWarning.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }

    /// Read the wizard answers for any dependent-related question we know
    /// about. Currently keys on `num_dependents` (used by Spain NLV); other
    /// tracks adopt the same key as they're audited.
    private var answeredDependentCount: Int {
        if let n = vm.answers["num_dependents"] as? Int { return n }
        if let s = vm.answers["num_dependents"] as? String, let n = Int(s) { return n }
        return 0
    }
}
