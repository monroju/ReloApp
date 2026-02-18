import Foundation

/// Standard phases used across all destinations.
enum Phases {
    static let phase1Plan = "phase_1_plan"
    static let phase2Documents = "phase_2_documents"
    static let phase3Application = "phase_3_application"
    static let phase4Arrival = "phase_4_arrival_setup"
    static let phase5Followup = "phase_5_residency_followup"

    struct PhaseInfo: Identifiable {
        let id: String
        let displayName: String
        let shortName: String
        let order: Int
    }

    static let allPhases: [PhaseInfo] = [
        PhaseInfo(id: phase1Plan, displayName: "Phase 1: Research & Planning", shortName: "Plan", order: 1),
        PhaseInfo(id: phase2Documents, displayName: "Phase 2: Documentation", shortName: "Docs", order: 2),
        PhaseInfo(id: phase3Application, displayName: "Phase 3: Application", shortName: "Apply", order: 3),
        PhaseInfo(id: phase4Arrival, displayName: "Phase 4: Arrival & Setup", shortName: "Arrive", order: 4),
        PhaseInfo(id: phase5Followup, displayName: "Phase 5: Residency Follow-up", shortName: "Follow-up", order: 5),
    ]

    static func getDisplayName(_ phaseId: String) -> String {
        allPhases.first { $0.id == phaseId }?.displayName ?? phaseId
    }

    static func getOrder(_ phaseId: String) -> Int {
        allPhases.first { $0.id == phaseId }?.order ?? Int.max
    }

    static func categoryToPhaseId(_ category: String?) -> String {
        guard let category = category, !category.isEmpty else { return phase1Plan }

        let lower = category.lowercased()
        if lower.contains("phase 1") || lower.contains("research") || lower.contains("planning") {
            return phase1Plan
        } else if lower.contains("phase 2") || lower.contains("documentation") || lower.contains("visa application") {
            return phase2Documents
        } else if lower.contains("phase 3") || lower.contains("pre-move") {
            return phase3Application
        } else if lower.contains("phase 4") || lower.contains("arrival") || lower.contains("settling") {
            return phase4Arrival
        } else if lower.contains("phase 5") || lower.contains("long-term") || lower.contains("compliance") {
            return phase5Followup
        }
        return phase1Plan
    }
}
