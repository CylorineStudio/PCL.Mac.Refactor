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
    ///   - completion: 任务完成回调，会在主线程执行。
    /// - Returns: 实例安装任务。
    public static func create(
        name: String,
        version: MinecraftVersion,
        repository: MinecraftRepository,
        completion: ((MinecraftInstance) -> Void)? = nil
    ) -> MyTask<Model> {
        let model: Model = .init(
            name: name,
            version: version,
            repository: repository
        )
        return .init(
            name: "\(name) 安装", model: model,
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
                model.mappedManifest = NativesMapper.map(manifest)
            },
            .init(1, "下载资源索引文件") { task, model in
                let assetIndex: AssetIndex = try await downloadAssetIndex(
                    assetIndex: model.mappedManifest.assetIndex,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
                model.assetIndex = assetIndex
            },
            .init(2, "下载客户端本体") { task, model in
                try await downloadClient(
                    clientDownload: model.mappedManifest.downloads.client,
                    runningDirectory: model.runningDirectory,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(2, "下载散列资源文件") { task, model in
                try await downloadAssets(
                    assetIndex: model.assetIndex,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(2, "下载依赖库文件") { task, model in
                try await downloadLibraries(
                    manifest: model.mappedManifest,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(3, "解压本地库文件", display: version < .init("1.19.1")) { task, model in
                try await extractNatives(
                    manifest: model.mappedManifest,
                    runningDirectory: model.runningDirectory,
                    repository: model.repository,
                    progressHandler: task.setProgress(_:)
                )
            },
            .init(4, "__completion", display: false) { _, _ in
                let instance: MinecraftInstance = .init(
                    runningDirectory: repository.versionsURL.appending(path: name),
                    version: version,
                    manifest: model.manifest,
                    config: .init()
                )
                repository.instances?.append(instance)
                await MainActor.run {
                    completion?(instance)
                }
            }
        )
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
        var progress: [Double] = Array(repeating: 0, count: 5) {
            didSet {
                progressHandler(progress[0] * 0.15 + progress[1] * 0.05 + progress[2] * 0.5 + progress[3] * 0.25 + progress[4] * 0.05)
            }
        }
        
        try await downloadClient(
            clientDownload: manifest.downloads.client,
            runningDirectory: runningDirectory,
            progressHandler: { progress[0] = $0 }
        )
        let assetIndex: AssetIndex = try await downloadAssetIndex(
            assetIndex: manifest.assetIndex,
            repository: repository,
            progressHandler: { progress[1] = $0 }
        )
        try await downloadAssets(
            assetIndex: assetIndex,
            repository: repository,
            progressHandler: { progress[2] = $0 }
        )
        try await downloadLibraries(
            manifest: manifest,
            repository: repository,
            progressHandler: { progress[3] = $0 }
        )
        try await extractNatives(
            manifest: manifest,
            runningDirectory: runningDirectory,
            repository: repository,
            progressHandler: { progress[4] = $0 }
        )
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
            .map { DownloadItem(url: $0.url, destination: repository.librariesURL.appending(path: $0.path), sha1: $0.sha1) }
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
        
        public init(name: String, version: MinecraftVersion, repository: MinecraftRepository) {
            self.name = name
            self.version = version
            self.runningDirectory = repository.versionsURL.appending(path: name)
            self.repository = repository
        }
    }
}
