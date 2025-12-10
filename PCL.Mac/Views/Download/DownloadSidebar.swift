//
//  DownloadSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI

struct DownloadSidebar: Sidebar {
    let width: CGFloat = 120
    
    var body: some View {
        VStack {
            MyNavigationList(
                (.minecraftDownload, "LaunchPageIcon", "游戏下载"),
                (.downloadPage2, "DownloadPageIcon", "Page2"),
                (.downloadPage3, "MultiplayerPageIcon", "Page3")
            )
            Spacer()
        }
    }
}
