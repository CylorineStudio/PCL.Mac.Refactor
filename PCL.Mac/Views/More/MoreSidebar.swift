//
//  MoreSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/7.
//

import SwiftUI

struct MoreSidebar: Sidebar {
    let width: CGFloat = 140
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.about, "IconAbout", "关于与鸣谢"),
                .init(.toolbox, "IconBox", "百宝箱")
            )
            Spacer()
        }
    }
}
