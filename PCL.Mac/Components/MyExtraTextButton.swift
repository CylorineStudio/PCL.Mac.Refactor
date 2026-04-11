//
//  MyExtraTextButton.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/12.
//

import SwiftUI

struct MyExtraTextButton: View {
    @State private var hovered: Bool = false
    @State private var pressed: Bool = false
    private let icon: ImageResource
    private let imageSize: CGFloat
    private let text: String
    private let action: () -> Void
    
    init(icon: ImageResource, imageSize: CGFloat, text: String, action: @escaping () -> Void) {
        self.icon = icon
        self.imageSize = imageSize
        self.text = text
        self.action = action
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1000)
                .fill(hovered ? Color.color4 : .color3)
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: imageSize, height: imageSize)
                MyText(text, size: 16, color: .white)
            }
            .padding()
        }
        .fixedSize(horizontal: true, vertical: true)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in
                    pressed = false
                    action()
                }
        )
        .onHover { hovered = $0 }
        .scaleEffect(pressed ? 0.85 : 1, anchor: .center)
        .animation(.linear(duration: 0.15), value: hovered)
        .animation(.easeOut(duration: 0.15), value: pressed)
    }
}
