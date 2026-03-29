//
//  InstanceManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/30.
//

import SwiftUI
import Core

class InstanceManager: ObservableObject {
    public static let shared: InstanceManager = .init()
    @Published public var repositories: [MinecraftRepository]
    @Published public var currentRepository: MinecraftRepository?
    @Published public var currentInstance: MinecraftInstance?
    @Published public var reloadErrorMessage: String?
    
    private init() {
        if LauncherConfig.shared.minecraftRepositories.isEmpty {
            let defaultDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
                .appending(path: "Library/Application Support/minecraft")
            LauncherConfig.shared.minecraftRepositories.append(
                .init(name: "默认目录", url: defaultDirectory)
            )
            LauncherConfig.shared.currentRepository = 0
        }
        self.repositories = LauncherConfig.shared.minecraftRepositories
        if let currentRepository: Int = LauncherConfig.shared.currentRepository {
            self.currentRepository = LauncherConfig.shared.minecraftRepositories[currentRepository]
            do {
                try self.currentRepository!.load()
            } catch {
                err("加载游戏仓库失败：\(error.localizedDescription)")
            }
        }
        if let currentInstance: String = LauncherConfig.shared.currentInstance {
            if let currentInstance = try? currentRepository?.instance(id: currentInstance) {
                self.currentInstance = currentInstance
            } else if let currentInstance = currentRepository?.instances?.first {
                log("配置文件中的当前实例失效，切换到当前第一个可用的实例")
                self.currentInstance = currentInstance
                LauncherConfig.shared.currentInstance = currentInstance.name
            } else {
                warn("配置文件中的当前实例失效，且当前没有可用实例")
            }
        }
    }
    
    /// 在当前仓库中加载实例。
    ///
    /// - Parameter id: 实例 ID。
    public func loadInstance(_ id: String) throws -> MinecraftInstance {
        guard let currentRepository else {
            throw SimpleError("未设置当前仓库。")
        }
        if let currentInstance, id == currentInstance.name {
            return currentInstance
        }
        return try currentRepository.instance(id: id)
    }
    
    /// 切换当前实例。
    /// - Parameters:
    ///   - instance: 目标实例。
    ///   - repository: 目标实例所在的仓库。
    public func switchInstance(to instance: MinecraftInstance, _ repository: MinecraftRepository) {
        guard repositories.contains(repository) else {
            err("试图切换到 \(repository.url) 仓库，但 repositories 中不存在它")
            return
        }
        self.currentInstance = instance
        LauncherConfig.shared.currentInstance = instance.name
        if currentRepository != repository {
            switchRepository(to: repository, alsoSwitchInstance: false)
        }
    }
    
    public func deleteInstance(_ instance: MinecraftInstance) throws {
        guard let currentRepository else { return }
        try FileManager.default.removeItem(at: currentRepository.versionsURL.appending(path: instance.name))
        try? currentRepository.load()
        switchRepository(to: currentRepository)
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
    
    public func removeRepository(_ repository: MinecraftRepository) {
        repositories.removeAll { $0.url == repository.url }
        LauncherConfig.shared.minecraftRepositories = repositories
        if currentRepository?.url == repository.url {
            currentRepository = nil
        }
    }
    
    /// 添加游戏目录
    /// - Parameters:
    ///   - name: 目录名。
    ///   - url: 游戏目录的 `URL`。
    public func addRepository(name: String, url: URL) {
        let repository: MinecraftRepository = .init(name: name, url: url)
        repositories.append(repository)
        LauncherConfig.shared.minecraftRepositories.append(repository)
        switchRepository(to: repository)
    }
    
    /// 请求用户选择并添加游戏目录。
    public func requestAddRepository() throws {
        let panel: NSOpenPanel = .init()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.folder]
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            if repositories.contains(where: { $0.url == url }) {
                throw SimpleError("该目录已存在！")
            }
            MessageBoxManager.shared.showInput(
                title: "输入目录名",
                initialContent: "自定义目录"
            ) { name in
                guard let name else { return }
                self.addRepository(name: name, url: url)
            }
        }
    }
    
    /// 启动游戏。
    ///
    /// - Parameters:
    ///   - instance: 目标游戏实例。
    ///   - account: 使用的账号。
    ///   - repository: 游戏仓库。
    @MainActor
    public func launch(_ instance: MinecraftInstance, _ account: Account, in repository: MinecraftRepository) {
        if MinecraftLaunchManager.shared.launch(instance, using: account, in: repository) {
            log("正在启动游戏 \(instance.name)")
        } else {
            hint("有游戏正在运行！", type: .critical)
            log("已有游戏正在运行，停止启动")
        }
    }
}
