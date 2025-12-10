//
//  TasksSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/9.
//

import SwiftUI

struct TasksSidebar: Sidebar {
    @EnvironmentObject private var dataManager: DataManager
    let width: CGFloat = 220
    
    var body: some View {
        VStack(spacing: 40) {
            PanelView("总进度", "100.0 %")
            PanelView("下载速度", "12345.6 MB/s")
            PanelView("剩余文件", "0")
        }
    }
}

private struct PanelView: View {
    private let title: String
    private let value: String
    
    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack {
            MyText(title, size: 16, color: .pclBlue)
            Rectangle()
                .fill(Color.pclBlue)
                .frame(width: 180, height: 2)
            MyText(value, size: 16)
        }
    }
}
