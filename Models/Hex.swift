import Foundation
import CoreGraphics

/// A hex cell expressed in cube coordinates with the invariant q + r + s = 0.
///
/// Only `q` and `r` are stored; `s` is derived. Axis-aligned line membership is
/// trivial: a hex lies on the horizontal line for its `r`, on the diagRight line
/// for its `q`, and on the diagLeft line for its `s`.
struct Hex: Hashable, Sendable, Codable {
    let q: Int
    let r: Int
    var s: Int { -q - r }

    static let zero = Hex(q: 0, r: 0)

    static func + (lhs: Hex, rhs: Hex) -> Hex { Hex(q: lhs.q + rhs.q, r: lhs.r + rhs.r) }
    static func - (lhs: Hex, rhs: Hex) -> Hex { Hex(q: lhs.q - rhs.q, r: lhs.r - rhs.r) }

    func distance(to other: Hex) -> Int {
        (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2
    }

    // MARK: - Pixel geometry (pointy-top)

    /// Pixel offset from the board origin (0,0) for this hex at a given size.
    /// `size` is the circumradius (centre-to-corner distance).
    func cartesian(size: CGFloat) -> CGPoint {
        let sqrt3 = CGFloat(3.0).squareRoot()
        let x = size * (sqrt3 * CGFloat(q) + sqrt3 / 2 * CGFloat(r))
        let y = size * (3.0 / 2.0 * CGFloat(r))
        return CGPoint(x: x, y: y)
    }
}

extension Hex: CustomStringConvertible {
    var description: String { "(\(q),\(r),\(s))" }
}

/// Lightweight Codable form for persistence — `Dictionary<Hex, _>` can't be
/// Codable directly because Hex isn't a string/int key.
struct HexPair<V: Codable & Sendable>: Codable, Sendable {
    let q: Int
    let r: Int
    let value: V
}
