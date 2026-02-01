//
//  EasyTierManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core
import SwiftyJSON

class EasyTierManager {
    public static let shared: EasyTierManager = .init()
    
    public let easyTier: EasyTier
    
    private let coreURL: URL = URLConstants.easyTierURL.appending(path: "easytier-core")
    private let cliURL: URL = URLConstants.easyTierURL.appending(path: "easytier-cli")
    private let logURL: URL = URLConstants.logsDirectoryURL.appending(path: "easytier.log")
    
    private let downloadItems: [ComponentType: DownloadItem]
    
    private var isEasyTierInstalled: Bool?
    
    private init() {
        if Architecture.systemArchitecture() == .arm64 {
            self.downloadItems = [
                .cli: .init(
                    url: URL(string: "https://gitee.com/yizhimcqiu/easytier-mirror/releases/download/v2.5.0/easytier-cli-macos-aarch64")!,
                    destination: cliURL,
                    sha1: "6fced91a4aeb4c9d1776704a6d00438331408056"
                ),
                .core: .init(
                    url: URL(string: "https://gitee.com/yizhimcqiu/easytier-mirror/releases/download/v2.5.0/easytier-core-macos-aarch64")!,
                    destination: coreURL,
                    sha1: "bcc229e65d2652e538efd59ea88e21a7e6ff2375"
                )
            ]
        } else {
            self.downloadItems = [
                .cli: .init(
                    url: URL(string: "https://gitee.com/yizhimcqiu/easytier-mirror/releases/download/v2.5.0/easytier-cli-macos-x86_64")!,
                    destination: cliURL,
                    sha1: "4dd10266baa8b70b64a953da78632e2d0d581ca9"
                ),
                .core: .init(
                    url: URL(string: "https://gitee.com/yizhimcqiu/easytier-mirror/releases/download/v2.5.0/easytier-core-macos-x86_64")!,
                    destination: coreURL,
                    sha1: "3185b21c0f3085e313d89fa32a32b7c1013ff1de"
                )
            ]
        }
        
        self.easyTier = .init(
            coreURL: coreURL,
            cliURL: cliURL,
            logURL: logURL,
            .p2pOnly,
            .peer(address: "tcp://public.easytier.top:11010"),
            .peer(address: "tcp://public2.easytier.cn:54321")
        )
    }
    
    /// 判断是否已经安装 EasyTier。
    public func isInstalled(refresh: Bool = false) -> Bool {
        if let isEasyTierInstalled, !refresh {
            return isEasyTierInstalled
        }
        let installed: Bool = autoreleasepool { checkSingle(type: .cli) && checkSingle(type: .core) }
        isEasyTierInstalled = installed
        return installed
    }
    
    /// 如果没有安装 EasyTier，提示用户安装。
    /// - Returns: 是否未安装 EasyTier。
    public func hintInstall() async -> Bool {
        if isInstalled() { return false }
        log("用户未安装 EasyTier")
        if await MessageBoxManager.shared.showText(
            title: "错误",
            content: "你需要安装 EasyTier 才能使用这个功能！",
            level: .error,
            .init(id: 1, label: "安装", type: .highlight),
            .init(id: 0, label: "取消", type: .normal)
        ) == 1 {
            let task: MyTask = makeInstallTask()
            await MainActor.run {
                TaskManager.shared.execute(task: task)
                AppRouter.shared.append(.tasks)
            }
        }
        return true
    }
    
    /// 删除 EasyTier。
    public func delete() {
        if !isInstalled() {
            hint("你还没有安装 EasyTier！", type: .critical)
            return
        }
        do {
            for url in downloadItems.values.map(\.destination) {
                try FileManager.default.removeItem(at: url)
            }
            hint("删除成功！", type: .finish)
        } catch {
            hint("删除 EasyTier 失败：\(error.localizedDescription)", type: .critical)
        }
        _ = isInstalled(refresh: true)
    }
    
    /// 创建一个安装任务。
    public func makeInstallTask() -> MyTask<EmptyModel> {
        let cliDownloadItem: DownloadItem = downloadItems[.cli]!
        let coreDownloadItem: DownloadItem = downloadItems[.core]!
        return .init(
            name: "安装 EasyTier",
            .init(0, "下载 easytier-cli") { task, _ in
                try await SingleFileDownloader.download(cliDownloadItem, replaceMethod: .skip, progressHandler: task.setProgress(_:))
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cliDownloadItem.destination.path)
            },
            .init(0, "下载 easytier-core") { task, _ in
                try await SingleFileDownloader.download(coreDownloadItem, replaceMethod: .skip, progressHandler: task.setProgress(_:))
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: coreDownloadItem.destination.path)
            },
            .init(1, "__completion", display: false) { task, _ in
                EasyTierManager.shared.isEasyTierInstalled = true
                if AppRouter.shared.getLast() == .tasks {
                    await MainActor.run {
                        AppRouter.shared.removeLast()
                    }
                }
            }
        )
    }
    
    public enum ComponentType {
        case cli, core
    }
    
    private func checkSingle(type: ComponentType) -> Bool {
        let item: DownloadItem = downloadItems[type]!
        return FileUtils.isExecutable(at: item.destination) && (try? FileUtils.sha1(of: item.destination)) == item.sha1
    }
}
