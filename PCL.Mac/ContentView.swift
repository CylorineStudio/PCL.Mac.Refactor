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
                    .background(.green)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(height: 22)
                .offset(x: -5)
            MyText(model.text, color: .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
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

#Preview {
    ContentView()
}
