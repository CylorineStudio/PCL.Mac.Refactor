//
//  DownloadSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/10.
//

import SwiftUI
import Core

struct DownloadSidebar: Sidebar {
    @EnvironmentObject private var minecraftDownloadPageViewModel: MinecraftDownloadPageViewModel
    
    let width: CGFloat = 150
    
    var body: some View {
        VStack(spacing: 4) {
            MyText("Minecraft", size: 12, color: .colorGray2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 13)
                .padding(.top, 10)
            MyNavigationList(
                .init(.minecraftDownload, .iconBlock, "游戏下载")
            ) { route in
                switch route {
                case .minecraftDownload:
                    minecraftDownloadPageViewModel.reload()
                default: break
                }
            }
            
            MyText("社区资源", size: 12, color: .colorGray2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 13)
                .padding(.top, 20)
            MyNavigationList(
                .init(.modDownload, .iconMod, "Mod"),
                .init(.resourcepackDownload, .iconPicture, "资源包"),
                .init(.shaderpackDownload, .iconSun, "光影包"),
                .init(.modpackDownload, .iconBox, "整合包")
            )
            Spacer()
        }
    }
}
