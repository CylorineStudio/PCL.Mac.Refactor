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
                .init(.instanceConfig(id: id), "SettingsPageIcon", "配置")
            )
            Spacer()
        }
    }
}
