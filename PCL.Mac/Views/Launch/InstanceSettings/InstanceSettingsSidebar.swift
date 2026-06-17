//
//  InstanceSettingsSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/2.
//

import SwiftUI

struct InstanceSettingsSidebar: Sidebar {
    let width: CGFloat = 140
    private let id: String
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.instanceConfig(id: id), .iconSettingsPage, "配置"),
                .init(.installedResources(id: id, type: .mod), .iconMod, "Mod 管理"),
                .init(.installedResources(id: id, type: .resourcepack), .iconPicture, "资源包"),
                .init(.installedResources(id: id, type: .shader), .iconSun, "光影包")
            )
            Spacer()
        }
    }
}
