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
    @State private var downloadURL: String = ""
    @State private var savePath: String = ""
    @State private var fileName: String = ""
    
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
                    .frame(width: 120)
                    
                    MyButton("千万别点", type: .red) {
                        MessageBoxManager.shared.showText(
                            title: "警告",
                            content: "PCL.Mac 作者不会受理由于点击千万别点造成的任何 Bug。\n这是最后的警告，是否继续操作？",
                            level: .error,
                            .init(id: 0, label: "确定", type: .red),
                            .init(id: 1, label: "确定", type: .normal),
                            .init(id: 2, label: "确定", type: .normal)
                        ) { _ in
                            viewModel.executeEasterEgg()
                        }
                    }
                    .frame(width: 120)
                    Spacer()
                }
                .frame(height: 40)
            }
            MyCard("回声洞", foldable: false) {
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
            MyCard("下载自定义文件", foldable: false) {
                            MyText("使用 PCL.Mac 的多线程下载引擎下载任意文件。请注意，部分网站（例如百度网盘）可能会报错（403）已禁止，无法正常下载。")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                HStack(spacing: 10) {
                                    MyText("下载链接")
                                    MyTextField(text: $downloadURL, placeholder: "输入文件直链地址")
                                        .onChange(of: downloadURL) { newValue in
                                            fileName = ""
                                            if let lastComponent = newValue.split(separator: "/").last,
                                               !lastComponent.isEmpty {
                                                fileName = String(lastComponent)
                                            }
                                        }
                                }
                                
                                HStack(spacing: 10) {
                                    MyText("保存到")
                                        .frame(width: 56, alignment: .leading)
                                    MyTextField(text: $savePath, placeholder: "文件保存路径")
                                    MyText("选择")
                                        .contentShape(.rect)
                                        .onTapGesture {
                                            selectSavePath()
                                        }
                                }
                                
                                HStack(spacing: 10) {
                                    MyText("文件名")
                                        .frame(width: 56, alignment: .leading)
                                    MyTextField(text: $fileName, placeholder: "文件下载之后的名字(包含后缀)")
                                }
                                
                                HStack(spacing: 20) {
                                    MyButton("开始下载", disabled: downloadURL.isEmpty || savePath.isEmpty || fileName.isEmpty) {}
                                        .frame(width: 160)
                                    MyButton("打开文件夹", disabled: savePath.isEmpty) {}
                                        .frame(width: 160)
                                }
                                .frame(height: 50)
                                .padding(.top, 10)
                            }
                        }
        }
    }
    
    private func selectSavePath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择保存位置"
        panel.message = "选择文件下载后保存的文件夹"
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            savePath = url.path
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
