//
//  AppDelegate.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import Foundation
import AppKit
import Core
import SwiftScaffolding

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: AppWindow!
    
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
        _ = LauncherConfig.shared
        executeTask("加载版本缓存") {
            try VersionCache.load()
        }
        executeTask("加载字体") {
            let fontURL: URL = URLConstants.resourcesURL.appending(path: "PCL.ttf")
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            if let error = error?.takeUnretainedValue() { throw error }
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
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        log("App 启动完成")
        self.window = AppWindow()
        self.window.makeKeyAndOrderFront(nil)
        log("成功创建窗口")
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
        EasyTierManager.shared.easyTier.terminate()
    }
}
