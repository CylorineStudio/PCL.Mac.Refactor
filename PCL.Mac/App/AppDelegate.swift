//
//  AppDelegate.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import Foundation
import AppKit
import Core

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: AppWindow!
    
    private func executeTask(_ name: String, _ start: @escaping () throws -> Void) {
        do {
            try start()
            log("\(name)成功")
        } catch {
            err("\(name)失败：\(error.localizedDescription)")
        }
    }
    
    private func executeAsyncTask(_ name: String, _ start: @escaping () async throws -> Void) {
        Task {
            do {
                try await start()
                log("\(name)成功")
            } catch {
                err("\(name)失败：\(error.localizedDescription)")
            }
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        AppURLs.createDirectories()
        LogManager.shared.enableLogging(logsURL: AppURLs.logsDirectoryURL)
        log("App 正在启动")
        executeTask("加载字体") {
            let fontURL: URL = AppURLs.resourcesURL.appending(path: "PCL.ttf")
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            if let error = error?.takeUnretainedValue() { throw error }
        }
        executeTask("从缓存中加载版本列表") {
            let cacheURL: URL = AppURLs.cacheURL.appending(path: "version_manifest.json")
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                let cachedData: Data = try .init(contentsOf: AppURLs.cacheURL.appending(path: "version_manifest.json"))
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
}
