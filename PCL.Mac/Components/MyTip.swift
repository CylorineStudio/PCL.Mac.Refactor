//
//  MyTip.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/13.
//

import SwiftUI


struct MyTip: View {
    private let text: String
    private let theme: Theme
    
    init(text: String, theme: Theme) {
        self.text = text
        self.theme = theme
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.borderColor)
                .frame(width: 3)
            MyText(text, color: theme.foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
            Spacer(minLength: 0)
        }
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .fixedSize(horizontal: false, vertical: true)
    }
    
    enum Theme {
        case blue, red, yellow
        
        var borderColor: Color {
            let hex: UInt = switch self {
            case .blue: 0x1172D4
            case .red: 0xD82929
            case .yellow: 0xF57A00
            }
            return .init(hex)
        }
        
        var backgroundColor: Color {
            let hex: UInt = switch self {
            case .blue: 0xD9ECFF
            case .red: 0xFFDDDF
            case .yellow: 0xFFEBD7
            }
            return .init(hex)
        }
        
        var foregroundColor: Color {
            let hex: UInt = switch self {
            case .blue: 0x0F64B8
            case .red: 0xBF0B0B
            case .yellow: 0xD86C00
            }
            return .init(hex)
        }
    }
}

#Preview {
    VStack {
        MyTip(text: "Test", theme: .red)
        MyTip(text: "Test", theme: .yellow)
        MyTip(text: "Test", theme: .blue)
    }
    .padding()
}
