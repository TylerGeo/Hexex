import Foundation

enum Difficulty: String, Sendable, Codable, CaseIterable, Identifiable {
    case beginner
    case normal
    case difficult
    case expert

    var id: String { rawValue }

    /// Side length N of the hexagonal board. Total cells = 3N² − 3N + 1.
    var sideLength: Int {
        switch self {
        case .beginner:  return 2   //  7 cells
        case .normal:    return 3   // 19 cells
        case .difficult: return 4   // 37 cells
        case .expert:    return 5   // 61 cells
        }
    }

    var cellCount: Int {
        let n = sideLength
        return 3 * n * n - 3 * n + 1
    }

    var displayName: String {
        switch self {
        case .beginner:  return "Beginner"
        case .normal:    return "Normal"
        case .difficult: return "Difficult"
        case .expert:    return "Expert"
        }
    }

    var subtitle: String {
        let n = sideLength
        return "\(n)×\(n) — \(cellCount) cells"
    }

    /// Number of distinct letters drawn from for the puzzle alphabet.
    var alphabetSize: Int {
        switch self {
        case .beginner:  return 5
        case .normal:    return 7
        case .difficult: return 9
        case .expert:    return 11
        }
    }

    /// Weighted budget controlling how "tricky" each generated regex tends to be.
    /// Higher values push the generator toward char classes, quantifiers, anchors
    /// and alternation instead of bare literals.
    var regexComplexity: Double {
        switch self {
        case .beginner:  return 0.2
        case .normal:    return 0.45
        case .difficult: return 0.7
        case .expert:    return 0.9
        }
    }
}
