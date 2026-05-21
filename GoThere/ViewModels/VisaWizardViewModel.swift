import Foundation
import SwiftUI

@MainActor
final class VisaWizardViewModel: ObservableObject {
    @Published var availableTracks: [(String, WizardTrack)] = []
    @Published var selectedTrackId: String?
    @Published var selectedTrack: WizardTrack?
    @Published var currentStep = 0 // 0 = track selection, 1+ = wizard steps
    @Published var answers: [String: Any] = [:]
    @Published var generatedTasks: [TaskItem] = []
    @Published var isSaving = false
    @Published var saveComplete = false
    /// User-selected anchor date for milestone scheduling. Defaults to
    /// +`anchorDateQuestion.defaultOffsetDays` from today on first wizard open.
    /// Foundation Wave 1.
    @Published var anchorDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 90)

    private let repo = WizardRepository.shared

    func loadConfig(countryId: String) {
        availableTracks = repo.tracksForCountry(countryId)
        if availableTracks.count == 1 {
            selectTrack(availableTracks[0].0)
        }
        // Reset anchor to the config-driven default each time we load.
        if let offset = repo.loadConfig()?.anchorDateQuestion?.defaultOffsetDays {
            anchorDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? anchorDate
        }
    }

    func selectTrack(_ trackId: String) {
        selectedTrackId = trackId
        selectedTrack = repo.loadConfig()?.tracks[trackId]
        currentStep = 1
        answers = [:]
        generatedTasks = []
        saveComplete = false
        Analytics.log(.wizardStarted, properties: [
            "track_id": trackId,
            "country_id": selectedTrack?.countryId ?? "unknown"
        ])
    }

    func setAnswer(_ questionId: String, value: Any) {
        answers[questionId] = value
        objectWillChange.send()
    }

    func nextStep() {
        guard let track = selectedTrack else { return }
        if currentStep < track.steps.count {
            currentStep += 1
        } else {
            generatePreview()
            currentStep += 1 // -> summary
        }
    }

    func prevStep() {
        if currentStep > 1 {
            currentStep -= 1
        } else if currentStep == 1 && availableTracks.count > 1 {
            currentStep = 0
            selectedTrackId = nil
            selectedTrack = nil
        }
    }

    var totalStepCount: Int {
        guard let track = selectedTrack else { return 1 }
        return track.steps.count + 2 // selection + N steps + summary
    }

    var currentWizardStep: WizardStep? {
        guard let track = selectedTrack else { return nil }
        let idx = currentStep - 1
        return idx >= 0 && idx < track.steps.count ? track.steps[idx] : nil
    }

    var isOnSummary: Bool {
        guard let track = selectedTrack else { return false }
        return currentStep > track.steps.count
    }

    var isLastQuestionStep: Bool {
        guard let track = selectedTrack else { return false }
        return currentStep == track.steps.count
    }

    func isQuestionVisible(_ question: WizardQuestion) -> Bool {
        guard let showIf = question.showIf else { return true }
        for (qId, expected) in showIf {
            guard let actual = answers[qId] else { return false }
            if !expected.matches(actual) { return false }
        }
        return true
    }

    private func generatePreview() {
        guard let track = selectedTrack else { return }
        let targetWeeks = WizardRepository.targetWeeks(
            from: answers["target_move"] as? String ?? "6_months"
        )
        generatedTasks = repo.generateTasks(
            track: track,
            answers: answers,
            targetWeeksFromNow: targetWeeks
        )
    }

    func saveTasks() async {
        guard !generatedTasks.isEmpty else { return }
        isSaving = true
        do {
            try await TaskRepository.shared.insertTasks(generatedTasks)
            // Save target move date for countdown
            let targetChoice = answers["target_move"] as? String ?? "6_months"
            let weeks = WizardRepository.targetWeeks(from: targetChoice)
            let targetMillis = Date().timeIntervalSince1970 * 1000 + Double(weeks) * 7 * 24 * 60 * 60 * 1000
            UserDefaults.standard.set(targetMillis, forKey: "target_move_millis")

            // Auto-create Calendar events for tasks with a due date. Tagged source="wizard"
            // so a future bulk-clear path can distinguish them from manually-added events.
            // Per-task try? so one failure doesn't block the rest of the wizard save.
            for task in generatedTasks where task.dueAt != nil {
                try? await EventsRepository.shared.addEventFromTask(task)
            }

            // Item 21 — upsert any documentSlot-annotated rules as DocumentSlots
            // so they appear in the Documents tab. Idempotent by (trackId, key);
            // existing status + uploadedDocumentId survive a wizard re-run.
            if let track = selectedTrack, let trackId = selectedTrackId {
                let slots = WizardRepository.shared.generateSlots(
                    track: track, trackId: trackId, answers: answers
                )
                if !slots.isEmpty {
                    try? await DocumentsRepository.shared.upsertSlots(slots)
                }

                // Foundation Wave 1 — milestones anchored to the user-chosen
                // anchor date. Each milestone becomes a Calendar EventItem with
                // category/notification metadata. Push reminders fire at 9am
                // local time on the event day for milestones flagged
                // notificationEnabled=true.
                let milestones = WizardRepository.shared.generateMilestones(
                    track: track, trackId: trackId, answers: answers, anchorDate: anchorDate
                )
                for (_, event) in milestones {
                    try? await EventsRepository.shared.addEventFromMilestone(event)
                }

                // Cross-feature bus — let any current/future subscriber know
                // the wizard completed without modifying this fan-out.
                IntegrationEvents.shared.publish(
                    .visaCompletion(trackId: trackId, countryId: track.countryId, anchorDate: anchorDate)
                )
            }

            // First-time wizard completion: ask for notification permission so
            // milestone reminders actually fire. Idempotent — iOS will only
            // prompt once; subsequent calls are no-ops.
            NotificationManager.shared.requestPermission()

            Analytics.log(.wizardCompleted, properties: [
                "track_id": selectedTrackId ?? "unknown",
                "country_id": selectedTrack?.countryId ?? "unknown",
                "tasks_generated": generatedTasks.count,
                "target_weeks": weeks
            ])

            saveComplete = true
        } catch {
            print("VisaWizard: Failed to save tasks: \(error)")
        }
        isSaving = false
    }
}
