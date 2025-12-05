//
//  LaunchView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

struct LaunchView: View {
    @State private var text: String = ""
    private let texts: [(String, String)] = [
        ("AAAAAA", "aaaaaa"), ("BBBBBB", "bbbbbb"), ("CCCCCC", "cccccc")
    ]
    
    var body: some View {
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
                            VStack {
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
        MyCard("", titled: false) {
            MyText("不可折叠也没有标题的卡片")
        }
    }
}
