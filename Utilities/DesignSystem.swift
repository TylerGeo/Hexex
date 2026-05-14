import SwiftUI

extension Color {
    // Themed hex fills — lavender family.
    static let hexFill        = Color(red: 0.902, green: 0.902, blue: 0.980)   // #E6E6FA
    static let hexFillFilled  = Color(red: 0.835, green: 0.835, blue: 0.957)   // a deeper lavender for filled cells
    static let hexFillEmpty   = Color(red: 0.949, green: 0.949, blue: 0.992)   // lighter for empties

    // Active selection.
    static let hexActiveBorder = Color(red: 0.0, green: 0.251, blue: 1.0)      // #0040FF — bold blue

    // State colors (kept from prior palette).
    static let hexCorrect     = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let hexIncorrect   = Color(red: 0.95, green: 0.27, blue: 0.27)
    static let hexReveal      = Color.indigo.opacity(0.30)
}

extension Font {
    static func jetBrainsMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrainsMono-Regular", size: size).weight(weight)
    }
}
