//
//  MessageBoxView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/23.
//

import SwiftUI

struct MessageBoxView: View {
    private let model: MessageBoxModel
    @State private var selectedItemIndex: Int?
    @State private var inputText: String = ""
    
    init(model: MessageBoxModel) {
        self.model = model
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white)
                .shadow(color: .color1.opacity(0.8), radius: 20)
            VStack(alignment: .leading, spacing: 0) {
                MyText(model.title, size: 23, color: foregroundColor)
                    .padding(.leading, 7)
                Rectangle()
                    .fill(foregroundColor)
                    .frame(height: 2)
                    .padding(.top, 9)
                    .padding(.bottom, 13)
                content
                    .frame(minHeight: 1)
                    .padding(.horizontal, 7)
                    .padding(.bottom, 17)
                HStack(spacing: 12) {
                    Spacer(minLength: 0)
                    ForEach(model.buttons, id: \.id) { button in
                        MyButton(button.label, textPadding: .init(top: 7, leading: 12, bottom: 7, trailing: 12), type: button.type) {
                            onButtonTap(button)
                        }
                        .fixedSize()
                    }
                }
            }
            .padding(22)
        }
        .frame(minWidth: 400, maxWidth: 800)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            if case .input(let initialContent, _) = model.content, let initialContent {
                inputText = initialContent
            }
        }
    }
    
    private var foregroundColor: Color {
        switch model.level {
        case .info: .color2
        case .error: .red
        }
    }
    
    private var content: some View {
        Group {
            switch model.content {
            case .text(let text):
                MyText(text)
            case .list(let items):
                MyList(items: items, onSelect: { self.selectedItemIndex = $0 })
            case .input(let initial, let placeholder):
                MyTextField(initial: initial ?? "", placeholder: placeholder ?? "", immediately: true) { newValue in
                    inputText = newValue
                }
            }
        }
    }
    
    private func onButtonTap(_ button: MessageBoxModel.Button) {
        switch model.content {
        case .text(_):
            MessageBoxManager.shared.onButtonTap(button)
        case .list(_):
            if button.id == MessageBoxManager.cancelButtonID { // 取消
                MessageBoxManager.shared.onListSelect(index: nil)
            } else if button.id == MessageBoxManager.okButtonID { // 确定
                MessageBoxManager.shared.onListSelect(index: selectedItemIndex)
            } else {
                MessageBoxManager.shared.onButtonTap(button)
            }
        case .input(_, _):
            if button.id == MessageBoxManager.cancelButtonID { // 取消
                MessageBoxManager.shared.onInputFinished(text: nil)
            } else if button.id == MessageBoxManager.okButtonID { // 确定
                MessageBoxManager.shared.onInputFinished(text: inputText)
            } else {
                MessageBoxManager.shared.onButtonTap(button)
            }
        }
    }
}

#Preview {
    MessageBoxView(
        model: .init(
            title: "测试",
            content: .text(text: "test"),
            level: .info,
            buttons: [
                .init(id: 0, label: "高亮", type: .highlight),
                .init(id: 1, label: "普通", type: .normal),
                .init(id: 2, label: "千万别点", type: .red)
            ]
        )
    )
    .padding()
}
