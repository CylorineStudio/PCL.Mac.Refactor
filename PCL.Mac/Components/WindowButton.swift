//
//  WindowButton.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/27.
//

import SwiftUI

struct WindowButton: View {
    @State private var hovered: Bool = false
    private let image: String
    private let action: () -> Void
    
    init(_ image: String, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.top, 3)
            Circle()
                .fill(.white.opacity(hovered ? 0.15 : 0))
                .frame(width: hovered ? 30 : 20)
        }
        .animation(.spring(response: 0.2), value: hovered)
        .frame(width: 30, height: 30)
        .contentShape(.rect)
        .onHover { isHovered in
            self.hovered = isHovered
        }
        .onTapGesture(perform: action)
    }
}
