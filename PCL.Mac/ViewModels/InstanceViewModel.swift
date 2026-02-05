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
    @Published public var reloadErrorMessage: String?
    
    public init() {
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
    
    /// 启动游戏。
    /// 
    /// - Parameters:
    ///   - instance: 目标游戏实例。
    ///   - account: 使用的账号。
    ///   - repository: 游戏仓库。
    public func launch(_ instance: MinecraftInstance, _ account: Account, in repository: MinecraftRepository) {
        log("正在启动游戏 \(instance.name)")
        Task.detached {
            guard let javaRuntime: JavaRuntime = instance.javaRuntime() else {
                _ = await MessageBoxManager.shared.showText(
                    title: "启动失败",
                    content: "你还没有设置 Java！", // TODO:
                    level: .error
                )
                return
            }
            
            if account.shouldRefresh() {
                do {
                    try await account.refresh()
                    log("刷新 accessToken 成功")
                } catch {
                    err("刷新 accessToken 失败")
                    if await MessageBoxManager.shared.showText(
                        title: "刷新访问令牌失败",
                        content: "在刷新访问令牌时发生错误：\(error.localizedDescription)\n\n如果继续启动，可能会导致无法加入部分需要正版验证的服务器！\n是否继续启动？\n\n若要寻求帮助，请将完整日志发送给他人，而不是发送此页面相关的图片。",
                        level: .error,
                        .init(id: 0, label: "取消", type: .normal),
                        .init(id: 1, label: "继续", type: .red)
                    ) == 0 {
                        return
                    }
                }
            }
            
            var options: LaunchOptions = .init()
            options.profile = account.profile
            options.accessToken = account.accessToken()
            options.runningDirectory = instance.runningDirectory
            options.javaRuntime = javaRuntime
            options.manifest = instance.manifest
            options.repository = repository
            options.memory = 4096
            
            try options.validate()
            LauncherConfig.shared.launchCount += 1
            
            let entries: [LaunchPrecheck.Entry] = LaunchPrecheck.check(for: instance, with: options, hasMicrosoftAccount: LauncherConfig.shared.hasMicrosoftAccount)
            for entry in entries {
                switch entry {
                case .javaVersionTooLow(let min):
                    _ = await MessageBoxManager.shared.showText(
                        title: "Java 版本过低",
                        content: "你正在使用 Java \(javaRuntime.versionNumber) 启动游戏，但这个版本需要 \(min)！",
                        level: .error
                    )
                    return
                case .noMicrosoftAccount:
                    if AccountViewModel().accounts.reduce(false, { $0 || ($1.type == .microsoft) }) {
                        LauncherConfig.shared.hasMicrosoftAccount = true
                        return
                    }
                    // https://github.com/Meloong-Git/PCL/blob/73bdc533097cfd36867b9249416cd681ec0b5a28/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModLaunch.vb#L263-L285
                    if LocaleUtils.isSystemLocaleChinese() {
                        if [3, 8, 15, 30, 50, 70, 90, 110, 130, 180, 220, 280, 330, 380, 450, 550, 660, 750, 880, 950, 1100, 1300, 1500, 1700, 1900]
                            .contains(LauncherConfig.shared.launchCount) {
                            Task {
                                if await MessageBoxManager.shared.showText(
                                    title: "考虑一下正版？",
                                    content: "你已经启动了 \(LauncherConfig.shared.launchCount) 次 Minecraft 啦！\n如果觉得 Minecraft 还不错，可以购买正版支持一下，毕竟开发游戏也真的很不容易……不要一直白嫖啦。\n\n在登录一次正版账号后，就不会再出现这个提示了！",
                                    level: .info,
                                    .init(id: 1, label: "支持正版游戏！", type: .highlight),
                                    .init(id: 2, label: "下次一定", type: .normal)
                                ) == 1 {
                                    NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                                }
                            }
                        }
                    } else {
                        let result: Int = await MessageBoxManager.shared.showText(
                            title: "正版验证",
                            content: "你必须先登录正版账号，才能进行离线登录！",
                            level: .info,
                            .init(id: 0, label: "购买正版", type: .highlight),
                            .init(id: 1, label: "试玩", type: .normal),
                            .init(id: 2, label: "返回", type: .normal)
                        )
                        switch result {
                        case 0:
                            NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                            return
                        case 1:
                            hint("游戏将以试玩模式启动！", type: .critical)
                            options.demo = true
                        case 2:
                            return
                        default:
                            break
                        }
                    }
                }
            }
            
            let launcher: MinecraftLauncher = .init(options: options)
            let _ = try launcher.launch()
        }
    }
}
