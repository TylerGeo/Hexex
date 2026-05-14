import Foundation

/// One of the three lines-of-three-coords through a hex grid.
///
/// In cube coords:
///   * `.horizontal` — lines where `r` is constant (the visual rows).
///   * `.diagRight`  — lines where `q` is constant (upper-left → lower-right).
///   * `.diagLeft`   — lines where `s` is constant (lower-left → upper-right).
enum TraversalAxis: String, Sendable, Codable, CaseIterable {
    case horizontal
    case diagRight
    case diagLeft

    /// The cube-coord value that identifies which line of this axis `hex` is on.
    func lineKey(of hex: Hex) -> Int {
        switch self {
        case .horizontal: return hex.r
        case .diagRight:  return hex.q
        case .diagLeft:   return hex.s
        }
    }

    /// Unit vector (in screen coords, y+ down) along the natural reading
    /// direction of a line of this axis.
    var direction: (dx: Double, dy: Double) {
        let sin60 = (3.0).squareRoot() / 2.0
        switch self {
        case .horizontal: return (1.0, 0.0)
        case .diagRight:  return (0.5, sin60)      // down-right
        case .diagLeft:   return (0.5, -sin60)     // up-right (lines stored bottom→top)
        }
    }
}
