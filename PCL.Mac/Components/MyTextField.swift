//
//  MyTextField.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import SwiftUI

struct MyTextField: View {
    @State private var text: String
    @State private var hovered: Bool = false
    @FocusState private var focused: Bool
    private let placeholder: String
    private let immediately: Bool
    private let onSubmit: ((String) -> Void)?
    
    init(initial: String = "", placeholder: String = "", immediately: Bool = false, onSubmit: ((String) -> Void)? = nil) {
        self.text = initial
        self.placeholder = placeholder
        self.immediately = immediately
        self.onSubmit = onSubmit
    }
    
    init<T: BinaryInteger>(initial: T? = nil, placeholder: String = "", parse: @escaping (String) -> T?, onSubmit: @escaping (T) -> Void) {
        self.text = initial.map(String.init) ?? ""
        self.placeholder = placeholder
        self.immediately = false
        self.onSubmit = { text in
            guard let value: T = parse(text) else {
                hint("数字格式不正确！", type: .critical)
                return
            }
            onSubmit(value)
        }
    }
    
    init(initial: Int? = nil, placeholder: String = "", onSubmit: @escaping (Int) -> Void) {
        self.init(initial: initial, placeholder: placeholder, parse: { .init($0) }, onSubmit: onSubmit)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
                .padding(4)
                .foregroundStyle(Color.color1)
                .background(backgroundColor)
                .onSubmit {
                    onSubmit?(text)
                    focused = false
                }
                .onChange(of: text) { newValue in
                    if immediately { onSubmit?(newValue) }
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

#Preview {
    MyTextField(initial: nil, placeholder: "请输入文本") { (value: Int) in
        print(value)
    }
    .padding()
    .background(.white)
}
