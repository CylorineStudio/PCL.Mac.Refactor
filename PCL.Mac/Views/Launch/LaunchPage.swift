//
//  LaunchPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI
import Core

struct LaunchPage: View {
    @StateObject private var loadingModel: MyLoadingViewModel = .init(text: "加载中")
    private let listItems: [ListItem] = [
        .init(name: "name1", description: "desc1"),
        .init(name: "name2", description: "desc2"),
        .init(name: "name3", description: "desc3")
    ]
    
    var body: some View {
        CardContainer {
            MyCard("可折叠的卡片") {
                VStack {
                    MyText("文本")
                    HStack {
                        MyButton("普通按钮") {}
                        MyButton("高亮按钮", type: .highlight) {}
                        MyButton("红色按钮", type: .red) {}
                    }
                    .frame(height: 60)
                    HStack {
                        MyButton("普通按钮", subLabel: "但是两行文本") {}
                        MyButton("高亮按钮", subLabel: "但是两行文本", type: .highlight) {}
                        MyButton("红色按钮", subLabel: "但是两行文本", type: .red) {}
                    }
                    .frame(height: 60)
                    MyList(listItems)
                }
            }
            MyCard("不可折叠的卡片", foldable: false) {
                MyText("该卡片默认展开")
            }
            .cardIndex(1)
            
            MyCard("", titled: false) {
                MyText("不可折叠也没有标题的卡片")
            }
            .cardIndex(2)
            
            MyCard("", titled: false) {
                HStack {
                    MyButton(".tasks") {
                        AppRouter.shared.append(.tasks)
                    }
                    .frame(width: 80)
                    
                    MyButton("弹窗") {
                        Task {
                            _ = await MessageBoxManager.shared.showText(
                                title: "普通弹窗",
                                content: "Hello, world!",
                                .init(id: 0, label: "hint（点击这个按钮不会关闭弹窗！）", type: .normal) {
                                    hint("awa!", type: .finish)
                                },
                                .init(id: 1, label: "确认", type: .highlight),
                            )
                            
                            let index: Int? = await MessageBoxManager.shared.showList(title: "列表选择", items: listItems)
                            let text: String? = await MessageBoxManager.shared.showInput(title: "文本输入", initialContent: "111", placeholder: "请输入文本")
                            if let index {
                                hint("你选择的是：\(listItems[index].name)", type: .finish)
                            }
                            if let text {
                                hint("你输入的是：\(text)", type: .finish)
                            }
                        }
                    }
                    .frame(width: 80)
                    
                    MyButton("错误弹窗", type: .red) {
                        Task {
                            _ = await MessageBoxManager.shared.showText(
                                title: "Minecraft 发生崩溃",
                                content: "你的游戏发生了一些问题，无法继续运行。\n很抱歉，PCL.Mac 暂时没有崩溃分析功能……\n\n若要寻求帮助，请点击“导出崩溃报告”并将导出的文件发给他人，而不是发送关于此页面的图片！！！",
                                level: .error
                            )
                        }
                    }
                    .frame(width: 80)
                    
                    MyButton("[临时] Java 安装弹窗") {
                        Task {
                            if await MessageBoxManager.shared.showText(
                                title: "没有可用的 Java",
                                content: "这个实例需要 Java 21 才能启动，但你的电脑上没有安装。\nPCL.Mac.Refactor 暂时没有 Java 安装功能，但是可以帮你打开下载网页。",
                                level: .error,
                                .init(id: 0, label: "取消", type: .normal),
                                .init(id: 1, label: "打开下载网页", type: .normal)
                            ) == 1 {
                                let version: String = "java-21-lts"
                                let arch: String = Architecture.systemArchitecture() == .arm64 ? "arm-64-bit" : "x86-64-bit"
                                let url: String = "https://www.azul.com/downloads/?version=\(version)&os=macos&architecture=\(arch)&package=jdk#zulu"
                                NSWorkspace.shared.open(URL(string: url)!)
                            }
                        }
                    }
                    .frame(width: 160)
                }
                .frame(height: 40)
            }
            .cardIndex(3)
            
            MyLoading(viewModel: loadingModel)
                .cardIndex(4)
            
            MyCard("修改 MyLoading 状态", foldable: false) {
                HStack(spacing: 22) {
                    MyButton("fail()", type: .red) { loadingModel.fail(with: "加载失败") }
                        .frame(width: 120)
                    Spacer()
                }
                .frame(height: 36)
            }
            .cardIndex(5)
            
            MyCard("弹出 hint", foldable: false) {
                HStack(spacing: 22) {
                    MyButton("info") { hint("这是一条 info 类型的 hint！", type: .info) }
                        .frame(width: 120)
                    MyButton("finish", type: .highlight) { hint("这是一条 finish 类型的 hint！", type: .finish) }
                        .frame(width: 120)
                    MyButton("critical", type: .red) { hint("这是一条 critical 类型的 hint！", type: .critical) }
                        .frame(width: 120)
                    Spacer()
                }
                .frame(height: 36)
            }
            .cardIndex(6)
        }
    }
}
