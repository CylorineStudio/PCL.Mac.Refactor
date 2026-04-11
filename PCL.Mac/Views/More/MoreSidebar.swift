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
                .init(.about, .iconAbout, "关于与鸣谢"),
                .init(.toolbox, .iconBox, "百宝箱")
            )
            Spacer()
        }
    }
}
