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
            MyCard("百宝箱", foldable: false) {
                HStack {
                    MyButton("今日人品") {
                        let lucky: Int = viewModel.todayLucky
                        MessageBoxManager.shared.showText(
                            title: "今日人品 - \(viewModel.todayDate)",
                            content: "你今天的人品值是：\(viewModel.formatLucky(lucky))",
                            level: lucky <= 30 ? .error : .info
                        )
                    }
                    .frame(width: 100)
                    
                    MyButton("千万别点", type: .red) {
                        MessageBoxManager.shared.showText(
                            title: "警告",
                            content: "PCL.Mac 作者不会受理由于点击千万别点造成的任何 Bug。\n这是最后的警告，是否继续操作？",
                            level: .error,
                            .init(id: 0, label: "确定", type: .red),
                            .init(id: 1, label: "确定", type: .normal),
                            .init(id: 2, label: "确定", type: .normal)
                        )
                        viewModel.executeEasterEgg()
                    }
                    .frame(width: 100)
                    Spacer()
                }
                .frame(height: 40)
            }
            MyCard("回声洞", foldable: false, limitHeight: false) {
                MyTip(text: "回声洞里的消息目前还比较有限，所以很可能会重复……\n欢迎前往 https://github.com/CylorineStudio/PCL.Mac.Refactor/discussions/43 进行投稿！", theme: .blue)
                    .padding(.bottom, 10)
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
