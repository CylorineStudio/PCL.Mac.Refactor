//
//  ContentView.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/8.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var hintManager: HintManager = .shared
    @ObservedObject private var router: AppRouter = .shared
    @ObservedObject private var easterEggManager: EasterEggManager = .shared
    
    @State private var sidebarWidth: CGFloat = AppRouter.shared.sidebar.width
    @State private var sidebarContentAnimationProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            TitleBarView()
                .zIndex(10)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.white)
                    .frame(width: sidebarWidth)
                    .shadow(radius: 2)
                    .onChange(of: router.sidebar.width) { newValue in
                        withAnimation(.spring(response: 0.16, dampingFraction: 1.0)) {
                            sidebarWidth = newValue
                        }
                        switch router.getLast() {
                        case .launch, .tasks:
                            sidebarContentAnimationProgress = 0.0
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                sidebarContentAnimationProgress = 1.0
                            }
                        default:
                            break
                        }
                    }
                    .zIndex(10)
                
                router.content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(0xC0DEF5))
            }
            .overlay {
                HStack {
                    AnyView(router.sidebar)
                        .frame(width: router.sidebar.width)
                        .opacity(sidebarContentAnimationProgress)
                        .scaleEffect(sidebarContentAnimationProgress * 0.04 + 0.96)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { ExtraButtonsOverlay() }
        .overlay { MessageBoxOverlay() }
        .overlay {
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                ForEach(hintManager.hints) { hint in
                    HintView(model: hint)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(.easeOut(duration: 0.2), value: hintManager.hints)
            .padding(.bottom, 100)
        }
        .rotation3DEffect(easterEggManager.rotationAngle, axis: easterEggManager.rotationAxis)
        .contrast(easterEggManager.modifyColor ? -1 : 1)
        .onAppear {
            // 当前一定是启动页面，直接开始动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                sidebarContentAnimationProgress = 1.0
            }
        }
    }
}

private struct HintView: View {
    @State private var appeared: Bool = false
    private let model: HintModel
    
    init(model: HintModel) {
        self.model = model
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RightRoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(height: 22)
            MyText(model.text, color: .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -50)
        .fixedSize(horizontal: true, vertical: false)
        .animation(.spring(duration: 0.2, bounce: 0), value: appeared)
        .onAppear {
            appeared = true
        }
    }
    
    private var color: Color {
        switch model.type {
        case .info: Color(0x0A8EFC)
        case .finish: Color(0x1DA01D)
        case .critical: Color(0xFF2B00)
        }
    }
}

private struct MessageBoxOverlay: View {
    @ObservedObject var messageBoxManager: MessageBoxManager = .shared
    @State private var messageBox: MessageBoxModel?
    
    @State private var opacity: CGFloat = 0
    @State private var rotation: CGFloat = 4
    @State private var offsetY: CGFloat = 40
    
    @State private var animationHideWorkItem: DispatchWorkItem?
    
    var body: some View {
        Group {
            if let messageBox {
                ZStack {
                    Rectangle()
                        .fill(messageBox.level == .error ? Color(0xFF0000).opacity(0.5) : .black.opacity(0.35))
                    MessageBoxView(model: messageBox)
                        .rotationEffect(.degrees(rotation))
                        .offset(y: offsetY)
                }
                .opacity(opacity)
            }
        }
        .onChange(of: messageBoxManager.currentMessageBox) { newValue in
            if newValue != nil { // 移入
                animationHideWorkItem?.cancel()
                messageBox = newValue
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                    offsetY = 0
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 1
                    rotation = 0
                }
            } else { // 移出
                let workItem: DispatchWorkItem = .init {
                    self.messageBox = nil
                    self.rotation = 4
                    self.offsetY = 40
                }
                animationHideWorkItem = workItem
                let duration: CGFloat = 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
                withAnimation(.easeOut(duration: duration)) {
                    opacity = 0
                    offsetY = 60
                }
                withAnimation(.easeIn(duration: duration)) {
                    rotation = 6
                }
            }
        }
    }
}

private struct ExtraButtonsOverlay: View {
    @ObservedObject private var router: AppRouter = .shared
    @ObservedObject private var launchManager: MinecraftLaunchManager = .shared
    @ObservedObject private var taskManager: TaskManager = .shared
    
    var body: some View {
        VStack(spacing: 0) {
            ExtraButton("DownloadPageIcon", showTasksButton) {
                router.append(.tasks)
            }
            ExtraButton("IconPower", launchManager.isRunning) {
                launchManager.stop()
                if launchManager.isLaunching {
                    hint("已取消启动！", type: .finish)
                } else {
                    hint("已关闭游戏！", type: .finish)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.spring(response: 0.4), value: launchManager.isRunning)
        .animation(.spring(response: 0.4), value: showTasksButton)
    }
    
    private var showTasksButton: Bool {
        !taskManager.tasks.filter(\.display).isEmpty && router.getLast() != .tasks
    }
    
    private struct ExtraButton: View {
        @State private var hovered: Bool = false
        @State private var pressed: Bool = false
        private let imageName: String
        private let show: Bool
        private let onClick: () -> Void
        
        init(_ imageName: String, _ show: Bool, onClick: @escaping () -> Void) {
            self.imageName = imageName
            self.show = show
            self.onClick = onClick
        }
        
        var body: some View {
            Circle()
                .fill(hovered ? Color.color4 : .color3)
                .frame(width: show ? 40 : 1)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .foregroundStyle(Color.color8)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressed = true }
                        .onEnded { _ in
                            pressed = false
                            onClick()
                        }
                )
                .onHover { hovered = $0 }
                .scaleEffect(show ? (pressed ? 0.85 : 1) : 0, anchor: .center)
                .padding(show ? 4 : 0)
                .animation(.linear(duration: 0.15), value: hovered)
                .animation(.easeOut(duration: 0.15), value: pressed)
                .animation(.spring(response: 0.4), value: show)
        }
    }
}

#Preview {
    ContentView()
}
