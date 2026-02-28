//
//  TasksSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/9.
//

import SwiftUI

struct TasksSidebar: Sidebar {
    @ObservedObject private var taskManager: TaskManager = .shared
    let width: CGFloat = 220
    
    var body: some View {
        VStack(spacing: 40) {
            PanelView("剩余任务数", "\(taskManager.tasks.count)")
            PanelView("下载速度", formatSpeed(taskManager.downloadSpeed))
            PanelView("缓存命中率", "80.00 %")
        }
    }
    
    private func formatSpeed(_ speed: Int64) -> String {
        let units: [String] = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
        var value: Double = Double(speed)
        var unitIndex: Int = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        let formatted: String = .init(format: value < 10 && unitIndex > 0 ? "%.1f" : "%.0f", value)
        return "\(formatted) \(units[unitIndex])"
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
            MyText(title, size: 16, color: .color2)
            Rectangle()
                .fill(Color.color2)
                .frame(width: 180, height: 2)
            MyText(value, size: 16)
        }
    }
}
