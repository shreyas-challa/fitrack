import SwiftUI

enum Theme {
    enum Color {
        static let background = SwiftUI.Color(hex: 0x0E0E10)
        static let surface = SwiftUI.Color(hex: 0x1A1A1D)
        static let surfaceElevated = SwiftUI.Color(hex: 0x242428)
        static let border = SwiftUI.Color(hex: 0x2E2E33)
        static let textPrimary = SwiftUI.Color(hex: 0xF2F2F4)
        static let textSecondary = SwiftUI.Color(hex: 0x9A9AA0)
        static let textTertiary = SwiftUI.Color(hex: 0x6B6B72)
        static let accent = SwiftUI.Color(hex: 0xD4D4D8)
        static let success = SwiftUI.Color(hex: 0x4ADE80).opacity(0.85)
        static let danger = SwiftUI.Color(hex: 0xF87171).opacity(0.9)
    }

    enum Radius {
        static let chip: CGFloat = 10
        static let button: CGFloat = 14
        static let card: CGFloat = 20
        static let sheet: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Font {
        static func numeric(_ size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func body(_ size: CGFloat = 16, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static let title = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let sectionHeader = SwiftUI.Font.system(size: 13, weight: .semibold, design: .default)
        static let caption = SwiftUI.Font.system(size: 12, weight: .regular, design: .default)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
