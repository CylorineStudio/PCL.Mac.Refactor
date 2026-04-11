//
//  MultiplayerSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/15.
//

import SwiftUI

struct MultiplayerSidebar: Sidebar {
    let width: CGFloat = 150
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.multiplayerSub, .iconMultiplayerPage, "联机"),
                .init(.multiplayerSettings, .iconSettingsPage, "设置")
            )
            Spacer()
        }
    }
}
