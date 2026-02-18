import Foundation

/// City/destination data for the decision engine.
struct Destination: Identifiable, Hashable {
    let id: String
    let name: String
    let region: String
    let type: String          // Big City, Mid City, Town, Village
    let tags: Set<String>
    let costLevel: Int        // 1 low .. 3 high
    let safety: Int           // 1 .. 5
    let climate: String       // warm_coastal, temperate, mountain, continental
    let expatDensity: Int     // 1 .. 5
}
