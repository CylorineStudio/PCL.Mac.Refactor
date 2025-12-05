//
//  DownloadSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI

struct DownloadSidebar: Sidebar {
    let width: CGFloat = 120
    
    var content: some View {
        VStack {
            MyNavigationList(
                (.downloadPage1, "LaunchPageIcon", "Page1"),
                (.downloadPage2, "DownloadPageIcon", "Page2"),
                (.downloadPage3, "MultiplayerPageIcon", "Page3")
            )
            Spacer()
        }
    }
}
