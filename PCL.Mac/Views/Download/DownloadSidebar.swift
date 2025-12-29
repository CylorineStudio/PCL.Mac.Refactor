//
//  DownloadSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct DownloadSidebar: Sidebar {
    @EnvironmentObject private var minecraftDownloadPageViewModel: MinecraftDownloadPageViewModel
    
    let width: CGFloat = 150
    
    var body: some View {
        VStack {
            MyNavigationList(
                (.minecraftDownload, "LaunchPageIcon", "游戏下载"),
                (.downloadPage2, "DownloadPageIcon", "Page2"),
                (.downloadPage3, "MultiplayerPageIcon", "Page3")
            ) { router in
                switch router {
                case .minecraftDownload:
                    minecraftDownloadPageViewModel.reload()
                default: break
                }
            }
            Spacer()
        }
    }
}
