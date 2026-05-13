import SwiftUI

extension Color {
    static let hexCorrect   = Color(red: 0.18, green: 0.80, blue: 0.44)  // emerald green
    static let hexIncorrect = Color(red: 0.95, green: 0.27, blue: 0.27)  // coral red
    static let hexReveal    = Color.indigo.opacity(0.25)
}

extension Font {
    static func jetBrainsMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrainsMono-Regular", size: size).weight(weight)
    }
}
