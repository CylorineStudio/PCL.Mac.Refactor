//
//  MyButton.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import SwiftUI

struct MyButton: View {
    @State private var hovered: Bool = false
    @State private var isPressed: Bool = false
    private let label: String
    private let subLabel: String?
    private let type: `Type`
    private let action: () -> Void
    
    private var color: Color { hovered ? type.hoverColor : type.color }
    
    init(_ label: String, subLabel: String? = nil, type: `Type` = .normal, _ action: @escaping () -> Void) {
        self.label = label
        self.subLabel = subLabel
        self.type = type
        self.action = action
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(hovered ? 0.2 : 0.005))
            RoundedRectangle(cornerRadius: 4)
                .stroke(style: .init(lineWidth: 1.2))
                .fill(color)
                .brightness(hovered ? 0.2 : 0)
            VStack(spacing: 4) {
                MyText(label, color: color)
                if let subLabel {
                    MyText(subLabel, size: 12, color: .init(0x8C8C8C))
                }
            }
        }
        .scaleEffect(isPressed ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: hovered)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovered = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    action()
                    isPressed = false
                }
        )
    }
    
    enum `Type` {
        case normal, highlight, red
        
        var color: Color {
            switch self {
            case .normal: Color(0x343D4A)
            case .highlight: Color(0x0B5BCB)
            case .red: Color(0xCE2111)
            }
        }
        
        var hoverColor: Color {
            switch self {
            case .normal: Color(0x1370F3)
            case .highlight: Color(0x1370F3)
            case .red: Color(0xFF4C4C)
            }
        }
    }
}

#Preview {
    MyButton("实例选择", type: .highlight) {
        print("Button pressed")
    }
    .frame(width: 117, height: 32)
    .padding()
    .background(.white)
}
