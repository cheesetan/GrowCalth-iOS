//
//  Color+Hex.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .displayP3,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(hex: Int) {
       self.init(
           red: (hex >> 16) & 0xFF,
           green: (hex >> 8) & 0xFF,
           blue: hex & 0xFF
       )
   }
}

extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension Color {
    static let background = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        )
    )

    static let outline = LinearGradient(
        colors: [.white.opacity(0.8), .white.opacity(0.05), .white.opacity(0.8)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    static let shadow = Color(
        uiColor: UIColor(hex: 0x2B2B2E)
    ).opacity(0.2)


    static let activityInnerShadow = Color(
        uiColor: UIColor(hex: 0xF4F4F6)
    ).opacity(0.1)

    static let activityOuterShadow = Color(
        uiColor: UIColor(hex: 0x14141F)
    ).opacity(0.1)

    static let activityLeftShadow = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0x2B2B2E).withAlphaComponent(0.2),
            dark: UIColor(hex: 0x0C0C0D).withAlphaComponent(0.6)
        )
    )

    static let lbCapsuleBackground = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xD4D4D9),
            dark: UIColor(hex: 0x4E4E56)
        )
    )

    static let lbPlacingBackground = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xDFDFE5),
            dark: UIColor(hex: 0x3A3A40)
        )
    )

    static let lbHouseColorToFadeTo = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xDFDFE5),
            dark: UIColor(hex: 0x4F4F52)
        )
    )

    static let goalsBackground = Color(hex: 0xDB5461, alpha: 0.8)

    static let announcementEventBackground = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0xDCDCE5),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        )
    )

    static let announcementEventInnerShadow = Color(
        uiColor: .dynamicColor(
            light: UIColor(hex: 0xF4F4F6).withAlphaComponent(0.8),
            dark: UIColor.white.withAlphaComponent(0.25)
        )
    )

    static let announcementEventOuterShadow = Color(
        uiColor: UIColor.dynamicColor(
            light: UIColor(hex: 0x4F4F52).withAlphaComponent(0.25),
            dark: UIColor(hex: 0x2B2B2E).withAlphaComponent(0.05)
        )
    )
}

