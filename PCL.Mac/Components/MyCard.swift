//
//  MyCard.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import SwiftUI

struct MyCard<Content: View>: View {
    @State private var folded: Bool = true
    @State private var hovered: Bool = false
    @State private var showContent: Bool = false
    /// `content()` 的实际高度。
    @State private var contentHeight: CGFloat = 0
    /// `content()` 的高度限制。
    @State private var internalContentHeight: CGFloat = 0
    @State private var lastClick: Date = .distantPast
    private let title: String
    private let foldable: Bool
    private let titled: Bool
    private let content: () -> Content
    
    init(_ title: String, foldable: Bool = true, titled: Bool = true, @ViewBuilder _ content: @escaping () -> Content) {
        self.title = title
        self.foldable = foldable && titled
        self.titled = titled
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if titled {
                    Text(title)
                        .font(.custom("PingFangSC-Semibold", size: 14))
                    Spacer()
                    if foldable {
                        Image("FoldArrow")
                            .resizable()
                            .frame(width: 10, height: 6)
                            .rotationEffect(.degrees(folded ? 0 : -180), anchor: .center)
                            .animation(.spring(response: 0.35), value: folded)
                    }
                }
            }
            .foregroundStyle(hovered ? Color.color2 : .color1)
            .frame(height: titled ? 12 : 0)
            .frame(maxWidth: .infinity)
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                guard foldable else { return }
                guard Date().timeIntervalSince(lastClick) > 0.2 else { return }
                lastClick = Date()
                if folded {
                    // 展开卡片
                    folded = false
                    showContent = true
                    withAnimation(.linear(duration: 0.2)) {
                        internalContentHeight = contentHeight
                    }
                } else {
                    // 折叠卡片
                    folded = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showContent = false
                    }
                    internalContentHeight = min(2000, contentHeight) // 控制回弹上限
                    withAnimation(.spring(response: 0.35)) {
                        internalContentHeight = 0
                    }
                }
            }
            VStack {
                content()
            }
            .padding(EdgeInsets(top: 0, leading: 18, bottom: 18, trailing: 18))
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { contentHeight = proxy.size.height }
                        .onChange(of: proxy.size) { newSize in
                            contentHeight = newSize.height
                            if !folded {
                                internalContentHeight = newSize.height
                            }
                        }
                }
            }
            .frame(height: internalContentHeight, alignment: .top)
            .clipped()
            .opacity(showContent ? 1 : 0)
        }
        .onHover { hovered in
            self.hovered = hovered
        }
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.colorGray8)
                .shadow(color: hovered ? .color3.opacity(0.6) : .black.opacity(0.1), radius: 6)
        }
        .animation(.easeInOut(duration: 0.2), value: hovered)
        .onAppear {
            if !foldable || !titled {
                folded = false
                showContent = true
                internalContentHeight = contentHeight
            }
        }
    }
}

#Preview {
    MyCard("卡片测试") {
        ZStack {
            Rectangle()
                .fill(.red)
            Text("内容")
        }
    }
    .padding()
}
