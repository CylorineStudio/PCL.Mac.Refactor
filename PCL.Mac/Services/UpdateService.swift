//
//  UpdateService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/26.
//

import SwiftUI
import Core

class UpdateService {
    public static let shared: UpdateService = .init()
    
    private let semaphore: AsyncSemaphore = .init(value: 1)
    
    public func runInteractiveUpdateFlow(manually: Bool = false) {
        Task {
            await semaphore.wait()
            defer { Task { await semaphore.signal() } }
            if manually {
                hint("正在检查更新……")
            }
            let version: UpdateModel.Version?
            do {
                version = try await UpdateManager.shared.checkUpdates()
            } catch {
                err("检查更新失败：\(error.localizedDescription)")
                if manually {
                    hint("检查更新失败：\(error.localizedDescription)", type: .critical)
                }
                return
            }
            guard let version else {
                if manually {
                    hint("当前使用的是最新版本，无需更新！", type: .finish)
                }
                return
            }
            
            guard await MessageBoxManager.shared.showTextAsync(
                title: "PCL.Mac 有更新可用",
                content: "发现新版本：\(version.name)\n更新摘要：\(version.summary)\n\n是否下载并安装更新？",
                level: .info,
                buttons: version.updateLogLinks.enumerated().map { index, link in
                    return .init(id: index + 2, label: link.name, type: .normal) {
                        NSWorkspace.shared.open(link.url)
                    }
                } + [.no(), .yes(label: "下载并安装（\(formatSize(version.downloads.size))）", type: .highlight)]
            ) == 1 else { return }
            hint("正在下载并安装更新，完成后 PCL.Mac 会自动重启……")
            do {
                try await UpdateManager.shared.installUpdate(version)
            } catch {
                err("更新启动器失败：\(error.localizedDescription)")
                hint("更新失败：\(error.localizedDescription)", type: .critical)
            }
        }
    }
    
    private func formatSize(_ size: Int) -> String {
        let units: [String] = ["B", "KB", "MB", "GB", "TB"]
        var value: Double = .init(size)
        var unitIndex: Int = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        let formatted: String = .init(format: value < 10 && unitIndex > 0 ? "%.1f" : "%.0f", value)
        return "\(formatted) \(units[unitIndex])"
    }
}
