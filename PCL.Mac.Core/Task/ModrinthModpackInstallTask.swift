//
//  ModrinthModpackInstallTask.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/23.
//

import Foundation
import ZIPFoundation

public enum ModrinthModpackInstallTask {
    public static func create(
        url: URL,
        index: ModrinthModpackIndex,
        repository: MinecraftRepository,
        name: String,
        completion: ((MinecraftInstance) -> Void)? = nil
    ) throws -> MyTask<Model> {
        let minecraftVersion: MinecraftVersion = .init(index.dependencies.minecraft)
        let loader: MinecraftInstallTask.Loader?
        if let forgeVersion: String = index.dependencies.forge {
            loader = .init(type: .forge, version: forgeVersion)
        } else if let neoforgeVersion: String = index.dependencies.neoforge {
            loader = .init(type: .neoforge, version: neoforgeVersion)
        } else if let fabricLoaderVersion: String = index.dependencies.fabricLoader {
            loader = .init(type: .fabric, version: fabricLoaderVersion)
        } else if let _: String = index.dependencies.quiltLoader {
            throw Error.quiltUnsupported
        } else {
            loader = nil
        }
        
        let minecraftInstallTask: MyTask<Model> = MinecraftInstallTask.create(
            name: name,
            version: minecraftVersion,
            repository: repository,
            modLoader: loader,
            completion: completion
        )
        var subTasks: [MyTask<Model>.SubTask] = minecraftInstallTask.subTasks
        
        subTasks.insert(
            contentsOf: [
                .init(6, "下载整合包所需文件") { task, model in
                    let downloadItems: [DownloadItem] = index.files
                        .filter { $0.env?[.client] != .unsupported }
                        .compactMap { file in
                            guard let url: URL = file.downloads.first else { return nil }
                            return .init(url: url, destination: model.runningDirectory.appending(path: file.path), sha1: file.hashes["sha1"])
                        }
                    try await MultiFileDownloader(items: downloadItems, concurrentLimit: 64, replaceMethod: .skip, progressHandler: task.setProgress(_:)).start()
                },
                .init(7, "应用整合包修改") { task, model in
                    let tempDirectory: URL = URLConstants.tempURL.appending(path: "modpack-install-\(UUID().uuidString.lowercased())")
                    defer { try? FileManager.default.removeItem(at: tempDirectory) }
                    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                    try FileManager.default.unzipItem(at: url, to: tempDirectory.appending(path: "modpack"))
                    
                    for dirName in ["overrides", "client-overrides"] {
                        let overridesDirectory: URL = tempDirectory.appending(path: "modpack/\(dirName)")
                        if FileManager.default.fileExists(atPath: overridesDirectory.path) {
                            do {
                                try apply(overridesDirectory, to: model.runningDirectory)
                            } catch {
                                throw Error.failedToApplyOverrides(underlying: error)
                            }
                        }
                    }
                }
            ],
            at: subTasks.count - 2
        )
        
        return .init(
            name: "整合包安装：\(name)",
            model: minecraftInstallTask.model,
            subTasks
        )
    }
    
    public typealias Model = MinecraftInstallTask.Model
    
    public enum Error: LocalizedError {
        case quiltUnsupported
        case failedToCreateEnumerator
        case failedToApplyOverrides(underlying: Swift.Error)
        
        public var errorDescription: String? {
            switch self {
            case .quiltUnsupported:
                "该整合包需要安装 Quilt Loader，但 PCL.Mac 目前暂不支持。"
            case .failedToCreateEnumerator:
                "创建文件枚举器失败。"
            case .failedToApplyOverrides(let underlying):
                "应用整合包修改失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    private static func apply(_ source: URL, to destination: URL) throws {
        guard let enumerator = FileManager.default.enumerator(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            throw Error.failedToCreateEnumerator
        }
        
        for case let fileURL as URL in enumerator {
            if try fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == false {
                let dest: URL = destination.appending(path: fileURL.pathComponents.dropFirst(source.pathComponents.count).joined(separator: "/"))
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                log("正在拷贝文件 \(fileURL.lastPathComponent)")
                try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: fileURL, to: dest)
            }
        }
    }
}
