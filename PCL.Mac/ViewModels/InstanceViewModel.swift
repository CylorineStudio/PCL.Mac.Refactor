//
//  InstanceViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/30.
//

import SwiftUI
import Core

class InstanceViewModel: ObservableObject {
    @Published public var repositories: [UUID: MinecraftRepository]
    @Published public var currentRepository: MinecraftRepository?
    @Published public var currentInstance: MinecraftInstance?
    
    public init() {
        self.repositories = LauncherConfig.shared.minecraftRepositories
        if let currentRepository: UUID = LauncherConfig.shared.currentRepository {
            self.currentRepository = LauncherConfig.shared.minecraftRepositories[currentRepository]
        }
        if let currentInstance: String = LauncherConfig.shared.currentInstance {
            self.currentInstance = try? currentRepository?.instance(id: currentInstance)
        }
    }
    
    /// 切换当前实例。
    /// - Parameters:
    ///   - id: 目标实例的 ID。
    ///   - repository: 目标实例所在的仓库。
    public func switchInstance(_ id: String, _ repository: MinecraftRepository) {
        if !repositories.values.contains(repository) {
            warn("试图切换到 \(repository.url) 仓库，但 repositories 中不存在它")
        }
        do {
            self.currentInstance = try .load(from: repository.versionsURL.appending(path: id))
        } catch {
            err("加载实例失败：\(error.localizedDescription)")
        }
        self.currentRepository = repository
        LauncherConfig.shared.currentInstance = id
        LauncherConfig.shared.currentRepository = repositories.first(where: { $0.value == repository })?.key
    }
    
    /// 添加游戏目录
    /// - Parameter url: 游戏目录的 `URL`。
    public func addRepository(url: URL) {
        let repository: MinecraftRepository = .init(name: "自定义目录", url: url)
        let uuid: UUID = .init()
        repositories[uuid] = repository
        LauncherConfig.shared.minecraftRepositories[uuid] = repository
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
            if repositories.contains(where: { $0.value.url == url }) {
                throw SimpleError("该目录已存在！")
            }
            addRepository(url: url)
        }
    }
}
