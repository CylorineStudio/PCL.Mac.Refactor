//
//  LaunchView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

struct LaunchView: View {
    @State private var text: String = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                MyCard("可折叠的卡片") {
                    VStack {
                        MyText("文本")
                        Rectangle()
                            .fill(.red)
                            .frame(height: 400)
                    }
                }
                MyCard("不可折叠的卡片", foldable: false) {
                    MyText("该卡片默认展开")
                }
                MyCard("", foldable: false, titled: false) {
                    MyText("不可折叠也没有标题的卡片")
                }
            }
            .padding(24)
            Spacer()
        }
    }
}
