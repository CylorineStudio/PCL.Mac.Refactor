//
//  InstanceViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/30.
//

import SwiftUI
import Core

class InstanceViewModel: ObservableObject {
    @Published public var repositories: [MinecraftRepository] = LauncherConfig.shared.minecraftRepositories
    @Published public var currentInstance: MinecraftInstance?
    @Published public var currentRepository: MinecraftRepository?
    
    /// 切换当前实例。
    /// - Parameters:
    ///   - id: 目标实例的 ID。
    ///   - repository: 目标实例所在的仓库。
    public func switchInstance(_ id: String, _ repository: MinecraftRepository) {
        do {
            self.currentInstance = try .load(from: repository.versionsURL.appending(path: id))
        } catch {
            err("加载实例失败：\(error.localizedDescription)")
        }
        self.currentRepository = repository
    }
    
    /// 添加游戏目录
    /// - Parameter url: 游戏目录的 `URL`。
    public func addRepository(url: URL) {
        let repository: MinecraftRepository = .init(name: "自定义目录", url: url)
        repositories.append(repository)
        LauncherConfig.shared.minecraftRepositories.append(repository)
    }
    
    /// 请求用户选择并添加游戏目录。
    public func requestAddRepository() throws {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.folder]
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            if repositories.contains(where: { $0.url == url }) {
                throw SimpleError("该目录已存在！")
            }
            addRepository(url: url)
        }
    }
}
