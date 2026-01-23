//
//  MessageBoxView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/23.
//

import SwiftUI

struct MessageBoxView: View {
    private let model: MessageBoxModel
    
    init(model: MessageBoxModel) {
        self.model = model
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white)
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
                    .padding(.leading, 7)
            }
            .padding(22)
        }
        .frame(minWidth: 400)
        .fixedSize(horizontal: true, vertical: true)
    }
    
    private var foregroundColor: Color {
        switch model.level {
        case .info: .color2
        case .error: .red
        }
    }
    
    private var content: some View {
        switch model.body {
        case .text(let text):
            MyText(text)
        }
    }
}

#Preview {
    MessageBoxView(model: .init(title: "测试", body: .text(text: "test"), level: .info))
        .padding()
}
