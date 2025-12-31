//
//  InstanceViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/30.
//

import SwiftUI
import Core

class InstanceViewModel: ObservableObject {
    @Published public var repositories: [MinecraftRepository]
    @Published public var currentRepository: MinecraftRepository?
    @Published public var currentInstance: MinecraftInstance?
    
    public init() {
        self.repositories = LauncherConfig.shared.minecraftRepositories
        if let currentRepository: Int = LauncherConfig.shared.currentRepository {
            self.currentRepository = LauncherConfig.shared.minecraftRepositories[currentRepository]
        }
        if let currentInstance: String = LauncherConfig.shared.currentInstance {
            self.currentInstance = try? currentRepository?.instance(id: currentInstance)
        }
    }
    
    /// 切换当前实例。
    /// - Parameters:
    ///   - instance: 目标实例。
    ///   - repository: 目标实例所在的仓库。
    public func switchInstance(to instance: MinecraftRepository.Instance, _ repository: MinecraftRepository) {
        switchInstance(id: instance.id, version: instance.version, repository)
    }
    
    /// 切换当前实例。
    /// - Parameters:
    ///   - id: 目标实例的 ID。
    ///   - version: （可选）该实例的版本。
    ///   - repository: 目标实例所在的仓库。
    public func switchInstance(id: String, version: MinecraftVersion? = nil, _ repository: MinecraftRepository) {
        guard repositories.contains(repository) else {
            err("试图切换到 \(repository.url) 仓库，但 repositories 中不存在它")
            return
        }
        do {
            self.currentInstance = try repository.instance(id: id, version: version)
        } catch {
            err("加载实例失败：\(error.localizedDescription)")
        }
        LauncherConfig.shared.currentInstance = id
        if currentRepository != repository {
            switchRepository(to: repository, alsoSwitchInstance: false)
        }
    }
    
    /// 切换当前仓库。
    /// - Parameter repository: 目标仓库。
    public func switchRepository(to repository: MinecraftRepository, alsoSwitchInstance: Bool = true) {
        guard let index: Int = repositories.firstIndex(of: repository) else {
            err("试图切换到 \(repository.url) 仓库，但 repositories 中不存在它")
            return
        }
        self.currentRepository = repository
        LauncherConfig.shared.currentRepository = index
        if alsoSwitchInstance {
            if let instance = repository.instances?.first {
                switchInstance(to: instance, repository)
            } else {
                self.currentInstance = nil
                LauncherConfig.shared.currentInstance = nil
            }
        }
    }
    
    /// 添加游戏目录
    /// - Parameter url: 游戏目录的 `URL`。
    public func addRepository(url: URL) {
        let repository: MinecraftRepository = .init(name: "自定义目录", url: url)
        repositories.append(repository)
        LauncherConfig.shared.minecraftRepositories.append(repository)
        switchRepository(to: repository)
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
