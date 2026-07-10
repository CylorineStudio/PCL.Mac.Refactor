//
//  SettingsSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/6.
//

import SwiftUI

struct SettingsSidebar: Sidebar {
    let width: CGFloat = 140
    
    var body: some View {
        VStack {
            MyNavigationList(
                .init(.launcherSettings, .iconSettingsPage, "启动器"),
                .init(.javaSettings, .iconJava, "Java 管理"),
                .init(.otherSettings, .iconBox, "其它")
            )
            Spacer()
        }
    }
}
