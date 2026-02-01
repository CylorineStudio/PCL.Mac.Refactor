//
//  ContentView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var hintManager: HintManager = .shared
    @ObservedObject private var router: AppRouter = .shared
    @State private var sidebarWidth: CGFloat = AppRouter.shared.sidebar.width
    
    var body: some View {
        VStack(spacing: 0) {
            TitleBarView()
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.white)
                    .frame(width: sidebarWidth)
                    .overlay(AnyView(router.sidebar))
                    .onChange(of: router.sidebar.width) { newValue in
                        withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                            sidebarWidth = newValue
                        }
                    }
                router.content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(0xC0DEF5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .shadow(color: .color1.opacity(0.8), radius: 20)
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

#Preview {
    ContentView()
}
