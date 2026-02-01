//
//  MultiplayerSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import SwiftUI

struct MultiplayerSidebar: Sidebar {
    let width: CGFloat = 150
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.multiplayerSub, "MultiplayerPageIcon", "联机"),
                .init(.multiplayerSettings, "SettingsPageIcon", "设置")
            )
            Spacer()
        }
    }
}
