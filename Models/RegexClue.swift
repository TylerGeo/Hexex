import Foundation

/// A single regex constraint attached to one line of one axis.
struct RegexClue: Sendable, Hashable, Codable, Identifiable {
    let axis: TraversalAxis
    /// The constant cube-coord value identifying this line (r for horizontal,
    /// q for diagRight, s for diagLeft).
    let lineKey: Int
    let pattern: String

    var id: String { "\(axis.rawValue)_\(lineKey)" }
}
