//
//  MyCard.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import SwiftUI

struct MyCard<Content: View>: View {
    @Environment(\.cardIndex) private var index: Int
    @Environment(\.disableCardAppearAnimation) private var disableCardAppearAnimation: Bool
    @Environment(\.disableHoverAnimation) private var disableHoverAnimation: Bool
    /// 带动画
    @State private var appeared: Bool = false
    /// 无动画，在 `appeared` 动画结束后变更
    @State private var appearFinished: Bool = false
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
    private let initialFolded: Bool?
    private let titled: Bool
    private let limitHeight: Bool
    private let padding: CGFloat
    private let content: () -> Content
    
    /// 创建一个卡片视图。
    /// - Parameters:
    ///   - title: 卡片的标题。在 `titled` 为 `false` 时，该参数会被忽略。
    ///   - foldable: 卡片是否可被折叠。当 `folded` 未被指定时，卡片默认不会被折叠。
    ///   - folded: 卡片的初始折叠状态。
    ///   - titled: 卡片是否拥有标题栏。当 `folded` 未被指定时，卡片默认不会被折叠。
    ///   - limitHeight: 是否限制卡片高度。若该参数为 `false`，请手动设置卡片高度。
    ///   - padding: 卡片的内边距。
    ///   - content: 卡片内容。
    init(_ title: String, foldable: Bool = true, folded: Bool? = nil, titled: Bool = true, limitHeight: Bool = true, padding: CGFloat = 18, @ViewBuilder _ content: @escaping () -> Content) {
        self.title = title
        self.foldable = foldable && titled
        self.initialFolded = folded
        self.titled = titled
        self.limitHeight = limitHeight
        self.padding = padding
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
            .foregroundStyle(appearFinished && !disableHoverAnimation && hovered ? Color.color2 : .color1)
            .frame(height: titled ? 12 : 0)
            .frame(maxWidth: .infinity)
            .padding(titled ? 12 : padding / 2)
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
                        internalContentHeight = min(1000, contentHeight)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        internalContentHeight = contentHeight
                    }
                } else {
                    // 折叠卡片
                    folded = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showContent = false
                    }
                    internalContentHeight = min(1000, contentHeight) // 控制回弹上限
                    withAnimation(.spring(response: 0.35)) {
                        internalContentHeight = 0
                    }
                }
            }
            VStack {
                content()
            }
            .disableHoverAnimation(!appearFinished)
            .padding(EdgeInsets(top: 0, leading: padding, bottom: padding, trailing: padding))
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
            .frame(height: limitHeight ? internalContentHeight : nil, alignment: .top)
            .frame(maxHeight: limitHeight ? nil : .infinity)
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
        .offset(y: appeared ? 0 : -25)
        .opacity(appeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: hovered)
        .onAppear {
            if disableCardAppearAnimation {
                appeared = true
                appearFinished = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { appeared = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04 + 0.4) {
                    appearFinished = true
                }
            }
            
            if let initialFolded {
                folded = initialFolded
            } else {
                if !foldable || !titled {
                    folded = false
                    showContent = true
                    internalContentHeight = contentHeight
                }
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
