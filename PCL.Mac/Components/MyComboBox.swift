//
//  MyComboBox.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/14.
//

import SwiftUI

struct MyComboBox: View {
    @Binding private var checked: Bool
    @State private var hovered: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var checkedScale: CGFloat = 0.0
    @State private var canClick: Bool = true
    private let text: String
    
    private let scaleAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.5)
    
    init(checked: Binding<Bool>, text: String) {
        self._checked = checked
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(hovered ? Color.color3 : checked ? .color2 : .color1, lineWidth: 1.1)
                    .frame(width: 18, height: 18)
                    .scaleEffect(scale, anchor: .center)
                
                Image(.iconTaskFinished)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12)
                    .scaleEffect(checkedScale)
                    .foregroundStyle(hovered ? Color.color3 : .color2)
            }
            MyText(text, color: hovered ? .color3 : .color1)
        }
        .frame(minWidth: 20, minHeight: 20)
        .fixedSize()
        .contentShape(.rect)
        .onHover { hovered = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !canClick { return }
                    withAnimation(.spring(duration: 0.3)) {
                        scale = 0.95
                    }
                }
                .onEnded { _ in
                    if !canClick { return }
                    canClick = false
                    withAnimation(.spring(duration: 0.1)) {
                        scale = 0.5
                    }
                    
                    let checked = checked
                    self.checked.toggle()
                    
                    if checked {
                        withAnimation(scaleAnimation) {
                            checkedScale = 0
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(scaleAnimation) {
                            scale = 1
                            if !checked { checkedScale = 1 }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            canClick = true
                        }
                    }
                }
        )
        .animation(.easeInOut(duration: 0.2), value: hovered)
        .animation(scaleAnimation, value: checked)
        .onAppear {
            checkedScale = checked ? 1 : 0
        }
        .onChange(of: checked) { newValue in
            guard canClick else { return }
            withAnimation(scaleAnimation) {
                checkedScale = newValue ? 1 : 0
            }
        }
    }
}

#Preview {
    PreviewView()
}

private struct PreviewView: View {
    @State private var checked: Bool = false
    
    var body: some View {
        MyComboBox(checked: $checked, text: "复选框")
            .padding()
            .background(.white)
    }
}
