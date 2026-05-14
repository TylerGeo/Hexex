import Foundation
import CoreGraphics

/// A regular hexagonal board of side length N (all hexes with
/// `max(|q|, |r|, |s|) ≤ N − 1`), with precomputed line indices.
struct HexBoard: Sendable {

    let sideLength: Int

    /// All cells, sorted by (r, q) for deterministic iteration.
    let hexes: [Hex]

    /// Shared key range across all axes: `-(N−1) ... (N−1)`.
    let lineKeys: [Int]

    /// `linesByAxis[axis][key]` → ordered cells on that line.
    /// Ordering convention (matches clue reading direction):
    ///   • horizontal: q ascending (left → right)
    ///   • diagRight:  r ascending (upper-left → lower-right)
    ///   • diagLeft:   r descending (lower-left → upper-right)
    private let linesByAxis: [TraversalAxis: [Int: [Hex]]]

    /// Bounding rectangle of the cell centres + half-hex padding at hexSize = 1.
    let unitBoundingBox: CGRect

    init(sideLength: Int) {
        precondition(sideLength >= 1, "sideLength must be ≥ 1")
        self.sideLength = sideLength

        let N = sideLength

        var hexes: [Hex] = []
        hexes.reserveCapacity(3 * N * N - 3 * N + 1)
        for q in -(N - 1)...(N - 1) {
            let rMin = max(-(N - 1), -(N - 1) - q)
            let rMax = min(  N - 1,    N - 1 - q)
            for r in rMin...rMax {
                hexes.append(Hex(q: q, r: r))
            }
        }
        hexes.sort { ($0.r, $0.q) < ($1.r, $1.q) }
        self.hexes = hexes

        var horizontal: [Int: [Hex]] = [:]
        var diagRight:  [Int: [Hex]] = [:]
        var diagLeft:   [Int: [Hex]] = [:]
        for h in hexes {
            horizontal[h.r, default: []].append(h)
            diagRight[h.q, default: []].append(h)
            diagLeft[h.s, default: []].append(h)
        }
        for k in horizontal.keys { horizontal[k]?.sort { $0.q < $1.q } }
        for k in diagRight.keys  { diagRight[k]?.sort  { $0.r < $1.r } }
        for k in diagLeft.keys   { diagLeft[k]?.sort   { $0.r > $1.r } }

        self.linesByAxis = [
            .horizontal: horizontal,
            .diagRight:  diagRight,
            .diagLeft:   diagLeft,
        ]

        self.lineKeys = Array(-(N - 1)...(N - 1))

        let sqrt3 = CGFloat(3.0).squareRoot()
        let halfW = sqrt3 * (CGFloat(N) - 0.5)
        let halfH = 1.5 * CGFloat(N - 1) + 1.0
        self.unitBoundingBox = CGRect(
            x: -halfW, y: -halfH,
            width: 2 * halfW, height: 2 * halfH
        )
    }

    // MARK: - Lines

    func line(axis: TraversalAxis, key: Int) -> [Hex] {
        linesByAxis[axis]?[key] ?? []
    }

    /// All `(axis, lineKey)` pairs that `hex` belongs to.
    func memberships(of hex: Hex) -> [(axis: TraversalAxis, key: Int)] {
        [(.horizontal, hex.r), (.diagRight, hex.q), (.diagLeft, hex.s)]
    }

    // MARK: - Geometry

    /// Pixel size of the board at the given hex (circumradius) size.
    func pixelSize(hexSize: CGFloat) -> CGSize {
        CGSize(
            width:  unitBoundingBox.width  * hexSize,
            height: unitBoundingBox.height * hexSize
        )
    }

    /// Hex centre in pixel coords, with the board's geometric centre at origin.
    func center(of hex: Hex, hexSize: CGFloat) -> CGPoint {
        hex.cartesian(size: hexSize)
    }

    // MARK: - Hit testing

    /// Returns the hex whose centre is within `hexSize` of `point`, or nil.
    func hex(at point: CGPoint, hexSize: CGFloat) -> Hex? {
        var best: Hex?
        var bestDist: CGFloat = .infinity
        for h in hexes {
            let c = h.cartesian(size: hexSize)
            let d = hypot(point.x - c.x, point.y - c.y)
            if d < bestDist {
                bestDist = d
                best = h
            }
        }
        return bestDist <= hexSize ? best : nil
    }
}
