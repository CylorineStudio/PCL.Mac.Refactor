//
//  MoreSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/7.
//

import SwiftUI

struct MoreSidebar: Sidebar {
    let width: CGFloat = 140
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.about, "IconAbout", "关于与鸣谢")
            )
            Spacer()
        }
    }
}
