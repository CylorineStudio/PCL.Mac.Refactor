//
//  UpdateManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/26.
//

import Foundation
import AppKit
import Core
import ZIPFoundation

class UpdateManager {
    public static let shared: UpdateManager = .init(URL(string: "https://cylorine.studio/meta/PCL.Mac/update.json")!)
    
    private let updateMetadataURL: URL
    
    private init(_ updateMetadataURL: URL) {
        self.updateMetadataURL = updateMetadataURL
    }
    
    public func checkUpdates() async throws -> UpdateModel.Version? {
        if Metadata.debugMode || Metadata.bundleVersion == 0 { return nil }
        let model: UpdateModel = try await Requests.get(updateMetadataURL, noCache: true).decode(UpdateModel.self)
        return Metadata.bundleVersion >= model.latestVersion.bundleVersion ? nil : model.latestVersion
    }
    
    public func installUpdate(_ version: UpdateModel.Version, useMirror: Bool = true) async throws {
        let destination: URL = URLConstants.tempURL.appending(path: "launcher-update-\(version.bundleVersion)")
        let downloadItem: DownloadItem = .init(
            url: useMirror ? version.downloads.mirror : version.downloads.github,
            destination: destination,
            sha1: version.downloads.sha1
        )
        defer { try? FileManager.default.removeItem(at: destination) }
        try await SingleFileDownloader.download(downloadItem, replaceMethod: .skip)
        try FileManager.default.unzipItem(at: destination, to: destination.deletingLastPathComponent())
        let newBundle: URL = URLConstants.tempURL.appending(path: "PCL.Mac.app")
        if !FileManager.default.fileExists(atPath: newBundle.path) {
            throw SimpleError("更新包格式错误，请手动安装更新。")
        }
        try FileManager.default.removeItem(at: Bundle.main.bundleURL)
        try FileManager.default.moveItem(at: newBundle, to: Bundle.main.bundleURL)
        
        log("App Bundle 替换完成，正在重启")
        // 使用 bash 延迟开启新进程，确保同时只有一个进程存在
        let command: String = "sleep 0.2; open -n \(Bundle.main.bundleURL.path)"
        let process: Process = .init()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        try process.run()
        await NSApplication.shared.terminate(nil)
    }
}
