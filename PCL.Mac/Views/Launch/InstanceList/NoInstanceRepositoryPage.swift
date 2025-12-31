//
//  NoInstanceRepositoryPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI

/// 未添加任何 `MinecraftRepository` 时显示的视图
struct NoInstanceRepositoryPage: View {
    var body: some View {
        MyCard("", titled: false) {
            MyText("你还没有添加任何目录！")
            MyText("点击左侧按钮添加")
        }
        .fixedSize()
    }
}
