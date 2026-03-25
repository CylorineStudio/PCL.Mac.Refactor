//
//  AppDelegate.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/8.
//

import Foundation
import AppKit
import Core
import SwiftScaffolding

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: AppWindow!
    private lazy var isUnderTesting: Bool = ProcessInfo.processInfo.environment["PCL_MAC_TESTING"] != nil
    
    private func executeTask(_ name: String, silent: Bool = false, _ start: @escaping () throws -> Void) {
        do {
            try start()
            if !silent {
                log("\(name)成功")
            }
        } catch {
            err("\(name)失败：\(error.localizedDescription)")
        }
    }
    
    private func executeAsyncTask(_ name: String, silent: Bool = false, _ start: @escaping () async throws -> Void) {
        Task {
            do {
                try await start()
                if !silent {
                    log("\(name)成功")
                }
            } catch {
                err("\(name)失败：\(error.localizedDescription)")
            }
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        URLConstants.createDirectories()
        LogManager.shared.enableLogging()
        log("正在启动 PCL.Mac.Refactor \(Metadata.appVersion)")
        executeTask("开启 SwiftScaffolding 日志", silent: true) {
            try SwiftScaffolding.Logger.enableLogging(url: URLConstants.logsDirectoryURL.appending(path: "swift-scaffolding.log"))
        }
        executeTask("清理临时文件") {
            for url in try FileManager.default.contentsOfDirectory(at: URLConstants.tempURL, includingPropertiesForKeys: nil) {
                try FileManager.default.removeItem(at: url)
            }
        }
        executeTask("从缓存中加载版本列表") {
            let cacheURL: URL = URLConstants.cacheURL.appending(path: "version_manifest.json")
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                let cachedData: Data = try .init(contentsOf: URLConstants.cacheURL.appending(path: "version_manifest.json"))
                let manifest: VersionManifest = try JSONDecoder.shared.decode(VersionManifest.self, from: cachedData)
                CoreState.versionManifest = manifest
            } else {
                self.executeAsyncTask("拉取版本列表") {
                    let response = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
                    let manifest: VersionManifest = try response.decode(VersionManifest.self)
                    CoreState.versionManifest = manifest
                    try response.data.write(to: cacheURL)
                }
            }
        }
        
        if !isUnderTesting {
            _ = LauncherConfig.shared
            _ = JavaManager.shared
            executeTask("加载字体") {
                let fontURL: URL = URLConstants.resourcesURL.appending(path: "PCL.ttf")
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
                if let error = error?.takeUnretainedValue() { throw error }
            }
            executeTask("加载版本缓存") {
                try VersionCache.load()
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if isUnderTesting { return }
        log("App 启动完成")
        self.window = AppWindow()
        self.window.makeKeyAndOrderFront(nil)
        log("成功创建窗口")
        if !LauncherConfig.shared.hasEnteredLauncher {
            MessageBoxManager.shared.showText(
                title: "欢迎使用 PCL.Mac！",
                content: "PCL.Mac 是 Plain Craft Launcher 的非官方衍生版，使用 SwiftUI 框架完全重构了 PCL 以支持 macOS。\n本启动器还处于开发阶段，有许多功能尚未完成，Bug 可能也比较多……\n若要获取帮助或查看更多信息，请访问 Cylorine Studio 官方网站！\n\n在开始使用前，请先阅读 Cylorine Studio 隐私政策。",
                level: .info,
                .init(id: 0, label: "打开 Cylorine Studio 官网", type: .normal) {
                    NSWorkspace.shared.open(URL(string: "https://cylorine.studio/projects/PCL.Mac.Refactor")!)
                },
                .init(id: 1, label: "查看隐私政策", type: .normal) {
                    NSWorkspace.shared.open(URL(string: "https://cylorine.studio/privacy")!)
                },
                .init(id: 2, label: "开始使用", type: .highlight)
            ) { _ in
                LauncherConfig.shared.hasEnteredLauncher = true
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        executeTask("保存版本缓存") {
            try VersionCache.save()
        }
        executeTask("保存启动器配置") {
            try LauncherConfig.save()
        }
        EasyTierManager.shared.terminateAll()
    }
}
