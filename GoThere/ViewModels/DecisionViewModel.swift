import Foundation

@MainActor
final class DecisionViewModel: ObservableObject {
    @Published var profile = UserProfile()
    @Published var results: [RankedDestination] = []
    @Published var currentStep = 0
    @Published var showResults = false

    let totalSteps = 9

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            calculateResults()
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func calculateResults() {
        let destinations = DecisionEngine.destinationsForCountry(profile.countryId)
        results = DecisionEngine.rank(profile: profile, destinations: destinations)
        showResults = true
    }

    func reset() {
        profile = UserProfile()
        results = []
        currentStep = 0
        showResults = false
    }

    func addStarterTasks(for ranked: RankedDestination) async {
        let tasks = TaskRepository.shared.starterTasks(
            for: ranked.destination.id,
            cityName: ranked.destination.name,
            countryId: profile.countryId
        )
        try? await TaskRepository.shared.insertTasks(tasks)
    }
}
