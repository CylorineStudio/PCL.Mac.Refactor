//
//  ToolboxPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/25.
//

import SwiftUI
import Core

struct ToolboxPage: View {
    @StateObject private var viewModel: ToolboxViewModel = .init()
    
    var body: some View {
        CardContainer {
            MyTip(text: "回声洞里的消息目前还比较有限，所以很可能会重复……\n你可以前往 https://github.com/CeciliaStudio/PCL.Mac.Refactor/discussions/43 进行投稿！", theme: .blue)
            MyCard("回声洞", foldable: false, limitHeight: false) {
                Color.clear
                    .modifier(CaveMessageModifier(text: viewModel.currentCaveMessage, progress: viewModel.revealProgress))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onTapGesture {
                if !viewModel.refreshCaveMessage() {
                    hint("回声洞中没有消息……", type: .critical)
                }
            }
            .task {
                do {
                    try await viewModel.fetchCaveMessages()
                } catch {
                    err("加载回声洞消息列表失败：\(error.localizedDescription)")
                    hint("加载回声洞消息列表失败：\(error.localizedDescription)", type: .critical)
                }
            }
        }
    }
}

struct CaveMessageModifier: AnimatableModifier {
    let text: String
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        let total: Int = text.count
        let clamped: Double = min(max(progress, 0.0), 1.0)
        let countDouble: Double = Double(total) * clamped
        let count: Int = Int(countDouble.rounded(.down))
        
        return MyText(String(text.prefix(count)))
    }
}
