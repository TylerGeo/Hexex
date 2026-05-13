import Foundation

struct Puzzle: Codable, Sendable, Identifiable {
    let id: String
    /// solution[row][col] — each element is a single uppercase letter string
    let solution: [[String]]
    let horizontal: [String]
    let diagRight: [String]
    let diagLeft: [String]

    /// The numeric portion of `id`. For purely numeric IDs like "001" this returns
    /// the integer value. For non-numeric IDs a stable hash-derived positive integer
    /// is returned instead.
    var puzzleNumber: Int {
        if let n = Int(id) {
            return n
        }
        // Strip leading/trailing non-digits and try again
        let digits = id.filter { $0.isNumber }
        if !digits.isEmpty, let n = Int(digits) {
            return n
        }
        // Fall back to a stable positive hash
        let hashValue = id.utf8.reduce(0) { (acc: UInt64, byte: UInt8) -> UInt64 in
            // FNV-1a style mix
            (acc ^ UInt64(byte) &* 16777619)
        }
        return Int(hashValue % 100_000) + 1
    }
}
