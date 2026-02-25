//
//  MyTextField.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import SwiftUI

struct MyTextField: View {
    @Binding private var text: String
    @State private var hovered: Bool = false
    @FocusState private var focused: Bool
    private let placeholder: String
    
    init(text: Binding<String>, placeholder: String = "") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: _text)
                .textFieldStyle(.plain)
                .focused($focused)
                .padding(4)
                .foregroundStyle(Color.color1)
                .background(backgroundColor)
                .onSubmit {
                    focused = false
                }
            RoundedRectangle(cornerRadius: 3)
                .stroke(foregroundColor, lineWidth: 1)
                .padding(.top, 1)
                .allowsHitTesting(false)
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.colorGray3)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .onHover { hovered = $0 }
        .animation(.linear(duration: 0.1), value: hovered)
        .animation(.linear(duration: 0.1), value: focused)
        .onChange(of: text) { newValue in
            if newValue.contains("\n") {
                self.text = newValue.replacingOccurrences(of: "\n", with: "")
            }
        }
    }
    
    private var foregroundColor: Color {
        if focused { return .color3 }
        if hovered { return .color4 }
        return .color5
    }
    
    private var backgroundColor: Color {
        if focused || hovered { return .color7 }
        return .white.opacity(0.5)
    }
}
