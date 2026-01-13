//
//  LaunchPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

struct LaunchPage: View {
    private let loadingModel: MyLoadingViewModel = .init(text: "加载中")
    private let texts: [(String, String)] = [
        ("AAAAAA", "aaaaaa"), ("BBBBBB", "bbbbbb"), ("CCCCCC", "cccccc")
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
                    VStack(spacing: 0) {
                        ForEach(texts, id: \.0) { text in
                            MyListItem {
                                VStack(alignment: .leading) {
                                    MyText(text.0)
                                    MyText(text.1)
                                }
                            }
                        }
                    }
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
                MyButton(".tasks") {
                    AppRouter.shared.append(.tasks)
                }
                .frame(width: 80, height: 40)
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
