//
//  MyListItem.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/5.
//

import SwiftUI

struct MyListItem<Content: View>: View {
    @State private var hovered: Bool = false
    @State private var backgroundScale: CGFloat = 0.92
    private let content: (Bool) -> Content
    
    init(_ content: @escaping (Bool) -> Content) {
        self.content = content
    }
    
    init(_ content: @escaping () -> Content) {
        self.init({ _ in content() })
    }
    
    var body: some View {
        content(hovered)
            .frame(maxWidth: .infinity)
            .padding(4)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(hovered ? Color.pclBlue.opacity(0.1) : .clear)
                    .scaleEffect(backgroundScale)
            }
            .onHover { hovered in
                withAnimation(.spring(response: 0.2)) {
                    self.hovered = hovered
                    if hovered {
                        backgroundScale = 1
                    } else {
                        backgroundScale = 0.92
                    }
                }
            }
    }
}

#Preview {
    MyListItem {
        HStack {
            VStack {
                MyText("aaa")
                MyText("aaa")
            }
            Spacer()
        }
    }
    .frame(width: 400, height: 50)
    .padding()
    .background(.white)
}
