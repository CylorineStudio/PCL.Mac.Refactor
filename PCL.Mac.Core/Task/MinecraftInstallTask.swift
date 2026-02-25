//
//  MinecraftInstallTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import Foundation
import SwiftyJSON
import ZIPFoundation

/// Minecraft 安装任务生成器。
public enum MinecraftInstallTask {
    private typealias SubTask = MyTask<Model>.SubTask
    
    /// 创建一个 Minecraft 实例安装任务。
    /// - Parameters:
    ///   - name: 实例名。
    ///   - version: Minecraft 版本。
    ///   - minecraftDirectory: 实例所在的 Minecraft 目录。
    ///   - modLoader: 需要附加的模组加载器。
    ///   - completion: 任务完成回调，会在主线程执行。
    /// - Returns: 实例安装任务。
    public static func create(
        name: String,
        version: MinecraftVersion,
        repository: MinecraftRepository,
        modLoader: Loader?,
        completion: ((MinecraftInstance) -> Void)? = nil
    ) -> MyTask<Model> {
        let model: Model = .init(
            name: name,
            version: version,
            repository: repository
        )
        var subTasks: [SubTask] = [
            .init(0, "__pre", display: false) { _, model in
                try FileManager.default.createDirectory(at: model.runningDirectory, withIntermediateDirectories: true)
                FileManager.default.createFile(atPath: model.runningDirectory.appending(path: ".incomplete").path, contents: nil)
            },
            .init(0, "下载客户端 JSON 文件") { task, model in
                guard let versionManifest = CoreState.versionManifest else {
                    err("CoreState.versionManifest 为空")
                    throw TaskError.unknownError
                }
                let manifest: ClientManifest = try await downloadClientManifest(
                    versionManifest: versionManifest,
                    versionId: version.id,
                    runningDirectory: model.runningDirectory,
                    progressHandler: task.setProgress(_:)
                )
                model.manifest = manifest
            },
            .init(1, "下载资源索引文件") { task, model in
                let assetIndex: AssetIndex = try await downloadAssetIndex(
                    assetIndex: model.manifest.assetIndex,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
                model.assetIndex = assetIndex
            },
            .init(2, "下载客户端本体") { task, model in
                try await downloadClient(
                    clientDownload: model.manifest.downloads.client,
                    runningDirectory: model.runningDirectory,
                    progressHandler: task.setProgress(_:)
                )
            },
            
            // Forge / NeoForge
            
            .init(5, "__modify_manifest", display: false) { task, model in
                let manifestURL: URL = model.runningDirectory.appending(path: "\(model.name).json")
                if var dict: [String: Any] = try JSON(data: Data(contentsOf: manifestURL)).dictionaryObject {
                    dict["id"] = model.name
                    dict["version"] = model.version.id
                    let manifestData: Data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys])
                    try manifestData.write(to: manifestURL, options: .atomic)
                }
                model.mappedManifest = NativesMapper.map(model.manifest)
            },
            .init(6, "下载散列资源文件") { task, model in
                try await downloadAssets(
                    assetIndex: model.assetIndex,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(6, "下载依赖库文件") { task, model in
                try await downloadLibraries(
                    manifest: model.mappedManifest,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(7, "解压本地库文件", display: version < .init("1.19.1")) { task, model in
                try await extractNatives(
                    manifest: model.mappedManifest,
                    runningDirectory: model.runningDirectory,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(8, "__completion", display: false) { _, _ in
                let instance: MinecraftInstance = .init(
                    runningDirectory: repository.versionsURL.appending(path: name),
                    version: version,
                    manifest: model.manifest,
                    config: .init(),
                    modLoader: modLoader?.type
                )
                repository.instances?.append(instance)
                try? FileManager.default.removeItem(at: model.runningDirectory.appending(path: ".incomplete"))
                await MainActor.run {
                    completion?(instance)
                }
            }
        ]
        
        if let modLoader {
            switch modLoader.type {
            case .fabric:
                subTasks.insert(
                    .init(3, "安装 Fabric Loader") { task, model in
                        let manifest: ClientManifest = try await downloadFabricManifest(
                            version: version,
                            repository: repository,
                            runningDirectory: model.runningDirectory,
                            loaderVersion: modLoader.version,
                            progressHandler: task.setProgress(_:)
                        )
                        model.manifest = manifest.merge(to: model.manifest)
                    },
                    at: 3
                )
                
            case .forge:
                subTasks.insert(
                    .init(3, "下载 Forge 安装器文件") { task, model in
                        let service: ForgeInstallService = .init(minecraftVersion: model.version, version: modLoader.version, repository: model.repository, manifest: model.manifest, runningDirectory: model.runningDirectory)
                        model.forgeInstallService = service
                        try await service.downloadFiles(progressHandler: task.setProgress(_:))
                    },
                    at: 3
                )
                subTasks.insert(
                    .init(4, "执行 Forge 安装器") { task, model in
                        try await model.forgeInstallService!.executeProcessors(progressHandler: task.setProgress(_:))
                        model.manifest = try .load(at: model.runningDirectory.appending(path: "\(model.name).json")).0
                    },
                    at: 4
                )
            }
        }
        
        return .init(name: "\(name) 安装", model: model, subTasks) { _ in
            try? FileManager.default.removeItem(at: repository.versionsURL.appending(path: name))
        }
    }
    
    /// 补全实例资源文件。
    /// - Parameters:
    ///   - repository: 实例所在的 `MinecraftRepository`。
    ///   - progressHandler: 进度回调。
    public static func completeResources(
        runningDirectory: URL,
        manifest: ClientManifest,
        repository: MinecraftRepository,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws {
        let progressHandler: ConcurrentProgressHandler = .init(totalHandler: progressHandler)
        progressHandler.startCalculate(interval: 0.1)
        
        if let downloads = manifest.downloads {
            try await downloadClient(
                clientDownload: downloads.client,
                runningDirectory: runningDirectory,
                progressHandler: progressHandler.handler(withMultiplier: 0.15)
            )
        } else {
            warn("manifest.downloads 为空")
            await progressHandler.handler(withMultiplier: 0.15)(1)
        }
        
        let assetIndex: AssetIndex = try await downloadAssetIndex(
            assetIndex: manifest.assetIndex,
            repository: repository,
            progressHandler: progressHandler.handler(withMultiplier: 0.05)
        )
        try await downloadAssets(
            assetIndex: assetIndex,
            repository: repository,
            progressHandler: progressHandler.handler(withMultiplier: 0.5)
        )
        try await downloadLibraries(
            manifest: manifest,
            repository: repository,
            progressHandler: progressHandler.handler(withMultiplier: 0.25)
        )
        try await extractNatives(
            manifest: manifest,
            runningDirectory: runningDirectory,
            repository: repository,
            progressHandler: progressHandler.handler(withMultiplier: 0.05)
        )
        
        await progressHandler.stopCalculate()
    }
    
    private static func downloadClientManifest(
        versionManifest: VersionManifest,
        versionId: String,
        runningDirectory: URL,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws -> ClientManifest {
        guard let version = versionManifest.version(for: versionId) else {
            err("未找到版本：\(versionId)")
            throw TaskError.unknownError
        }
        
        let destination: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        try await SingleFileDownloader.download(
            url: version.url,
            destination: destination,
            sha1: nil,
            replaceMethod: .skip,
            progressHandler: progressHandler
        )
        return try JSONDecoder.shared.decode(ClientManifest.self, from: Data(contentsOf: destination))
    }
    
    private static func downloadAssetIndex(
        assetIndex: ClientManifest.AssetIndex,
        repository: MinecraftRepository,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws -> AssetIndex {
        let destination: URL = repository.assetsURL
            .appending(path: "indexes/\(assetIndex.id).json")
        try await SingleFileDownloader.download(
            url: assetIndex.url,
            destination: destination,
            sha1: assetIndex.sha1,
            replaceMethod: .skip,
            progressHandler: progressHandler
        )
        return try JSONDecoder.shared.decode(AssetIndex.self, from: Data(contentsOf: destination))
    }
    
    private static func downloadClient(
        clientDownload: ClientManifest.Downloads.Download,
        runningDirectory: URL,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws {
        try await SingleFileDownloader.download(
            url: clientDownload.url,
            destination: runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).jar"),
            sha1: clientDownload.sha1,
            replaceMethod: .skip,
            progressHandler: progressHandler
        )
    }
    
    private static func downloadAssets(
        assetIndex: AssetIndex,
        repository: MinecraftRepository,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws {
        let root: URL = URL(string: "https://resources.download.minecraft.net")!
        let items: [DownloadItem] = autoreleasepool {
            assetIndex.objects.map { .init(
                url: root.appending(path: "\($0.hash.prefix(2))/\($0.hash)"),
                destination: repository.assetsURL.appending(path: "objects/\($0.hash.prefix(2))/\($0.hash)"),
                sha1: $0.hash
            ) }
        }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: progressHandler).start()
    }
    
    private static func downloadLibraries(
        manifest: ClientManifest,
        repository: MinecraftRepository,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws {
        let items: [DownloadItem] = (manifest.getLibraries() + manifest.getNatives())
            .compactMap(\.artifact)
            .compactMap { $0.downloadItem(destinationDirectory: repository.librariesURL) }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: progressHandler).start()
    }
    
    private static func extractNatives(
        manifest: ClientManifest,
        runningDirectory: URL,
        repository: MinecraftRepository,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws {
        let natives: [ClientManifest.Library] = manifest.getNatives()
        for native in natives {
            guard let path: String = native.artifact?.path else {
                err("本地库 \(native.name) 通过了 rules 检查，但 classifiers 中没有其对应的 artifact")
                continue
            }
            let url: URL = repository.librariesURL.appending(path: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                err("本地库 \(native.name) 似乎未被下载")
                continue
            }
            
            let nativesDirectory: URL = runningDirectory.appending(path: "natives")
            let archive: Archive = try .init(url: url, accessMode: .read)
            for entry in archive where entry.type == .file {
                if entry.path.hasSuffix(".dylib") || entry.path.hasSuffix(".jnilib") {
                    guard let name: String = entry.path.split(separator: "/").last.map(String.init) else {
                        warn("获取 \(entry.path) 的文件名失败")
                        continue
                    }
                    let destination: URL = nativesDirectory.appending(path: name)
                    if FileManager.default.fileExists(atPath: destination.path) { continue }
                    _ = try archive.extract(entry, to: destination)
                }
            }
        }
        await MainActor.run {
            progressHandler(1)
        }
    }
    
    public class Model: TaskModel {
        public let name: String
        public let version: MinecraftVersion
        public let runningDirectory: URL
        public let repository: MinecraftRepository
        
        public var manifest: ClientManifest!
        public var mappedManifest: ClientManifest!
        public var assetIndex: AssetIndex!
        
        public var forgeInstallService: ForgeInstallService?
        
        public init(name: String, version: MinecraftVersion, repository: MinecraftRepository) {
            self.name = name
            self.version = version
            self.runningDirectory = repository.versionsURL.appending(path: name)
            self.repository = repository
        }
    }
    
    public struct Loader {
        public let type: ModLoader
        public let version: String
        
        public init(type: ModLoader, version: String) {
            self.type = type
            self.version = version
        }
    }
}

// MARK: - Fabric 安装
extension MinecraftInstallTask {
    private static func downloadFabricManifest(
        version: MinecraftVersion,
        repository: MinecraftRepository,
        runningDirectory: URL,
        loaderVersion: String,
        progressHandler: @MainActor @escaping (Double) -> Void
    ) async throws -> ClientManifest {
        let manifestURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        let parentURL: URL = runningDirectory.appending(path: ".parent/\(version).json")
        if !FileManager.default.fileExists(atPath: parentURL.path) {
            try FileManager.default.createDirectory(at: runningDirectory.appending(path: ".parent"), withIntermediateDirectories: false)
            try FileManager.default.moveItem(at: manifestURL, to: parentURL)
        }
        if FileManager.default.fileExists(atPath: manifestURL.path) {
            try FileManager.default.removeItem(at: manifestURL)
        }
        let url: URL = .init(string: "https://meta.fabricmc.net/v2/versions/loader/\(version)/\(loaderVersion)/profile/json")!
        try await SingleFileDownloader.download(
            url: url,
            destination: manifestURL,
            sha1: nil,
            replaceMethod: .throw,
            progressHandler: progressHandler
        )
        return try JSONDecoder.shared.decode(ClientManifest.self, from: Data(contentsOf: manifestURL))
    }
}
