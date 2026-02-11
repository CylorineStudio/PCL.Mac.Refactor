//
//  MinecraftLaunchTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/5.
//

import Foundation
import Core
import AppKit

/// Minecraft 启动任务生成器。
public enum MinecraftLaunchTask {
    private typealias SubTask = MyTask<Model>.SubTask
    
    /// 创建 Minecraft 启动任务。
    /// - Parameters:
    ///   - instance: 启动的 Minecraft 实例。
    ///   - account: 启动时使用的账号。
    ///   - repository: 实例所在的游戏仓库。
    public static func create(
        for instance: MinecraftInstance,
        using account: Account,
        in repository: MinecraftRepository,
        onProcessStarted: @escaping (MinecraftLauncher, Process) -> Void
    ) -> MyTask<Model> {
        return .init(
            name: "启动游戏 - \(instance.name)",
            model: .init(instance: instance, account: account, repository: repository, onProcessStarted: onProcessStarted),
            .init(0, "检查 Java", checkJava(task:model:)),
            .init(1, "刷新账号", refreshAccount(task:model:)),
            .init(2, "预检查", precheck(task:model:)),
            .init(3, "检查资源完整性", checkResources(task:model:)),
            .init(4, "启动游戏", launch(task:model:)),
            .init(5, "等待游戏窗口出现", display: false, waitForWindow(task:model:))
        )
    }
    
    private static func checkJava(task: SubTask, model: Model) async throws {
        var runtime: JavaRuntime?
        
        if let javaRuntime = model.instance.javaRuntime() {
            runtime = javaRuntime
        } else {
            if let javaRuntime: JavaRuntime = model.instance.searchJava() {
                if await MessageBoxManager.shared.showText(
                    title: "未设置 Java",
                    content: "你还没有设置这个实例使用的 Java！\nPCL.Mac 找到了一个可用的 Java：\(javaRuntime.version)，是否切换并继续启动？",
                    level: .info,
                    .init(id: 0, label: "取消", type: .normal),
                    .init(id: 1, label: "切换", type: .highlight)
                ) == 1 {
                    model.instance.setJava(url: javaRuntime.executableURL)
                    runtime = javaRuntime
                } else {
                    try task.cancel()
                }
            } else {
                if await MessageBoxManager.shared.showText(
                    title: "没有可用的 Java",
                    content: "这个实例需要 Java \(model.instance.manifest.javaVersion.majorVersion) 才能启动，但你的电脑上没有安装。\nPCL.Mac.Refactor 暂时没有 Java 安装功能，但是可以帮你打开下载网页。",
                    level: .error,
                    .init(id: 0, label: "取消", type: .normal),
                    .init(id: 1, label: "打开下载网页", type: .normal)
                ) == 1 {
                    let version: String = "java-\(model.instance.manifest.javaVersion.majorVersion)-lts"
                    let arch: String = Architecture.systemArchitecture() == .arm64 ? "arm-64-bit" : "x86-64-bit"
                    let url: String = "https://www.azul.com/downloads/?version=\(version)&os=macos&architecture=\(arch)&package=jdk#zulu"
                    NSWorkspace.shared.open(URL(string: url)!)
                }
                try task.cancel()
            }
        }
        
        if let runtime {
            model.options.javaRuntime = runtime
            model.manifest = NativesMapper.map(model.manifest, to: runtime.architecture)
        }
    }
    
    private static func refreshAccount(task: SubTask, model: Model) async throws {
        if model.account.shouldRefresh() {
            do {
                try await model.account.refresh()
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
                    try task.cancel()
                }
            }
        }
        model.options.accessToken = model.account.accessToken()
    }
    
    private static func precheck(task: SubTask, model: Model) async throws {
        model.options.manifest = model.manifest
        try model.options.validate()
        let entries: [LaunchPrecheck.Entry] = LaunchPrecheck.check(for: model.instance, with: model.options, hasMicrosoftAccount: LauncherConfig.shared.hasMicrosoftAccount)
        log("共 \(entries.count) 个问题：\(entries)")
        for entry in entries {
            switch entry {
            case .javaVersionTooLow(let min):
                _ = await MessageBoxManager.shared.showText(
                    title: "Java 版本过低",
                    content: "你正在使用 Java \(model.options.javaRuntime.versionNumber) 启动游戏，但这个版本需要 \(min)！",
                    level: .error
                )
                try task.cancel()
            case .noMicrosoftAccount:
                if AccountViewModel().accounts.reduce(false, { $0 || ($1.type == .microsoft) }) {
                    LauncherConfig.shared.hasMicrosoftAccount = true
                    continue
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
                        try task.cancel()
                    case 1:
                        hint("游戏将以试玩模式启动！", type: .critical)
                        model.options.demo = true
                    case 2:
                        try task.cancel()
                    default:
                        break
                    }
                }
            case .armNotSupported:
                if let runtime: JavaRuntime = model.instance.searchJava(arch: .x64) {
                    if await MessageBoxManager.shared.showText(
                        title: "不支持的 Java 架构",
                        content: "你正在启动的版本（\(model.instance.version)）不支持使用 ARM64 架构的 Java！\nPCL.Mac 找到了一个可用的 Java，是否切换并继续启动？",
                        level: .error,
                        .init(id: 0, label: "取消", type: .normal),
                        .init(id: 1, label: "切换并继续", type: .highlight)
                    ) == 0 {
                        try task.cancel()
                    }
                    model.instance.setJava(url: runtime.executableURL)
                    model.options.javaRuntime = runtime
                    model.manifest = model.instance.manifest
                }
            }
        }
    }
    
    private static func checkResources(task: SubTask, model: Model) async throws {
        // 防止本地库架构与 Java 架构不同，先清除本地库
        let nativesURL: URL = model.instance.runningDirectory.appending(path: "natives")
        if FileManager.default.fileExists(atPath: nativesURL.path) {
            do {
                try FileManager.default.removeItem(at: nativesURL)
                log("删除本地库目录成功")
            } catch {
                err("删除本地库目录失败：\(error.localizedDescription)")
            }
        }
        
        try await MinecraftInstallTask.completeResources(
            runningDirectory: model.instance.runningDirectory,
            manifest: model.manifest,
            repository: model.repository,
            progressHandler: task.setProgress(_:)
        )
    }
    
    private static func launch(task: SubTask, model: Model) async throws {
        LauncherConfig.shared.launchCount += 1
        let launcher: MinecraftLauncher = .init(options: model.options)
        model.launcher = launcher
        do {
            let process: Process = try launcher.launch()
            model.process = process
            await MainActor.run {
                model.onProcessStarted(launcher, process)
            }
        } catch {
            err("启动游戏失败：\(error.localizedDescription)")
            _ = await MessageBoxManager.shared.showText(
                title: "启动游戏失败",
                content: "启动游戏时发生错误：\(error.localizedDescription)",
                level: .error
            )
        }
    }
    
    private static func waitForWindow(task: SubTask, model: Model) async throws {
        guard let process = model.process else {
            err("model.process 为 nil")
            return
        }
        try await withTaskCancellationHandler {
            while true {
                try Task.checkCancellation()
                if !process.isRunning {
                    log("进程已被关闭，停止检测窗口")
                    break
                }
                if checkWindows(for: process) {
                    break
                }
                try await Task.sleep(seconds: 1)
            }
        } onCancel: {
            process.terminate()
        }
    }
    
    private static func checkWindows(for process: Process) -> Bool {
        let option: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(option, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            if let windowPID: Int = info[kCGWindowOwnerPID as String] as? Int,
               windowPID == process.processIdentifier {
                return true
            }
        }
        return false
    }
    
    public class Model: TaskModel {
        public let instance: MinecraftInstance
        public let account: Account
        public let repository: MinecraftRepository
        public let onProcessStarted: (MinecraftLauncher, Process) -> Void
        public var manifest: ClientManifest
        public var launcher: MinecraftLauncher?
        public var options: LaunchOptions
        public var process: Process?
        
        init(instance: MinecraftInstance, account: Account, repository: MinecraftRepository, onProcessStarted: @escaping (MinecraftLauncher, Process) -> Void) {
            self.instance = instance
            self.account = account
            self.repository = repository
            self.onProcessStarted = onProcessStarted
            self.manifest = instance.manifest
            self.options = .init()
            
            self.options.profile = account.profile
            self.options.runningDirectory = instance.runningDirectory
            self.options.repository = repository
            self.options.memory = instance.config.jvmHeapSize
        }
    }
}
