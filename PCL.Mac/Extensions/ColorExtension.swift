//
//  ColorExtension.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/13.
//

import SwiftUI

extension Color {
    // https://github.com/CylorineStudio/PCL.Mac.Refactor/issues/13
    // https://github.com/PCL-Community/PCL2-CE/blob/cf2ddb8cbd2a3edc00ebd9ebf7533b0ba7b7de10/Plain%20Craft%20Launcher%202/Application.xaml#L28-L84
    static let color1: Color = .init(0x343d4a)
    static let color2: Color = .init(0x0b5bcb)
    static let color3: Color = .init(0x1370f3)
    static let color4: Color = .init(0x4890f5)
    static let color5: Color = .init(0x96c0f9)
    static let color6: Color = .init(0xd5e6fd)
    static let color7: Color = .init(0xe0eafd)
    static let color8: Color = .init(0xeaf2fe)
    static let colorBg0: Color = .init(0x96c0f9)
    static let colorBg1: Color = .init(0xe0eafd, alpha: 0.75)
    static let colorGray1: Color = .init(0x404040)
    static let colorGray2: Color = .init(0x737373)
    static let colorGray3: Color = .init(0x8c8c8c)
    static let colorGray4: Color = .init(0xa6a6a6)
    static let colorGray5: Color = .init(0xcccccc)
    static let colorGray6: Color = .init(0xebebeb)
    static let colorGray7: Color = .init(0xf0f0f0)
    static let colorGray8: Color = .init(0xf5f5f5)
    
    init(_ hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
