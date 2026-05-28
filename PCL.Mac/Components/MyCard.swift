//
//  MyCard.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/4.
//

import SwiftUI

struct MyCard<Content: View, Action: View>: View {
    @Environment(\.cardIndex) private var index: Int
    @Environment(\.disableCardAppearAnimation) private var disableCardAppearAnimation: Bool
    @Environment(\.disableHoverAnimation) private var disableHoverAnimation: Bool
    @EnvironmentObject private var interactionState: CardInteractionState
    
    /// 下移出现动画变量。
    @State private var appeared: Bool = false
    
    /// 下移出现动画是否已完成。
    @State private var appearFinished: Bool = false
    
    /// 卡片是否已被折叠。
    @State private var folded: Bool = true
    
    /// 是否被鼠标悬停。
    @State private var hovered: Bool = false
    
    /// 是否显示鼠标悬停样式，用于避免动画冲突。
    @State private var showHovered: Bool = false
    
    /// 是否显示卡片内容，在被折叠时为 `false`。
    @State private var showContent: Bool = false
    
    /// `content()` 的实际高度。
    @State private var actualContentHeight: CGFloat = 0
    
    /// `content()` 的高度限制。
    @State private var contentHeightLimit: CGFloat? = nil
    @State private var foldWorkItem: DispatchWorkItem?
    
    private let title: String
    private let foldable: Bool
    private let initialFolded: Bool
    private let titled: Bool
    private let padding: CGFloat
    private let content: () -> Content
    private let action: () -> Action
    
    /// 创建一个卡片视图。
    /// - Parameters:
    ///   - title: 卡片的标题，为 `nil` 时没有标题栏且不可折叠。
    ///   - foldable: 卡片是否可被折叠。
    ///   - folded: 卡片的初始折叠状态。
    ///   - padding: 卡片的内边距。
    ///   - content: 卡片内容。
    ///   - action: 显示在右上角的内容。如果 `foldable` 为 `true`，或卡片没有标题栏，此参数会被忽略。
    init(
        _ title: String?,
        foldable: Bool = true,
        folded: Bool = true,
        padding: CGFloat = 18,
        @ViewBuilder _ content: @escaping () -> Content,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.title = title ?? ""
        self.titled = title != nil
        self.foldable = foldable && titled
        self.initialFolded = folded
        self.padding = padding
        self.content = content
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if titled {
                HStack {
                    Text(title)
                        .font(.custom("PingFangSC-Semibold", size: 14))
                    Spacer()
                    if foldable {
                        Image(.btnFold)
                            .resizable()
                            .frame(width: 10, height: 6)
                            .rotationEffect(.degrees(folded ? 0 : -180), anchor: .center)
                            .animation(.spring(response: 0.35), value: folded)
                    } else {
                        action()
                    }
                }
                .foregroundStyle(appearFinished && !disableHoverAnimation && showHovered ? Color.color2 : .color1)
                .frame(height: 12)
                .padding(12)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard foldable else { return }
                    self.foldWorkItem?.cancel()
                    interactionState.isTransitioning = true
                    
                    if folded {
                        // 展开卡片
                        folded = false
                        showContent = true
                        withAnimation(.linear(duration: 0.2)) {
                            contentHeightLimit = min(1000, actualContentHeight) + padding
                        }
                        let foldWorkItem: DispatchWorkItem = .init {
                            contentHeightLimit = nil
                            interactionState.isTransitioning = false
                        }
                        self.foldWorkItem = foldWorkItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: foldWorkItem)
                    } else {
                        // 折叠卡片
                        folded = true
                        let foldWorkItem: DispatchWorkItem = .init {
                            showContent = false
                            interactionState.isTransitioning = false
                        }
                        self.foldWorkItem = foldWorkItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: foldWorkItem)
                        contentHeightLimit = min(1000, actualContentHeight) + padding // 控制回弹上限
                        withAnimation(.spring(response: 0.35)) {
                            contentHeightLimit = 0
                        }
                    }
                }
            }
            
            if showContent || actualContentHeight == 0 {
                VStack {
                    content()
                }
                .disableHoverAnimation(!appearFinished)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                actualContentHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size) { newSize in
                                if actualContentHeight != newSize.height {
                                    DispatchQueue.main.async {
                                        actualContentHeight = newSize.height
                                    }
                                }
                            }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: !titled ? padding : 0, leading: padding, bottom: padding, trailing: padding))
                .frame(height: contentHeightLimit, alignment: .top)
                .clipped()
                .opacity(showContent ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .onHover { hovered in
            self.hovered = hovered
            if !interactionState.isTransitioning || !hovered {
                self.showHovered = hovered
            }
        }
        .onChange(of: interactionState.isTransitioning) { newValue in
            if newValue == true || showHovered == hovered { return }
            self.showHovered = hovered
        }
        .background {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.colorGray8)
                .shadow(color: showHovered ? .color3.opacity(0.6) : .black.opacity(0.1), radius: 6)
        }
        .offset(y: appeared ? 0 : -25)
        .opacity(appeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showHovered)
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
            
            if !foldable {
                folded = false
                showContent = true
            } else {
                folded = initialFolded
                showContent = !initialFolded
                if folded {
                    contentHeightLimit = 0
                }
            }
        }
    }
}

#Preview {
    if #available(macOS 13.0, *) {
        CardContainer {
            let content = {
                ZStack(alignment: .center) {
                    Rectangle()
                        .fill(.red)
                    MyText(String(repeating: "关注风花喵 关注风花谢谢喵\n", count: 16))
                        .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            }
            
            Grid(alignment: .top) {
                GridRow {
                    MyCard("foldable, titled") {
                        content()
                    }
                    
                    MyCard("foldable, titled, folded", folded: true) {
                        content()
                    }
                }
                
                GridRow {
                    MyCard("not-foldable, titled", foldable: false) {
                        content()
                    }
                    
                    MyCard(nil) {
                        content()
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}
