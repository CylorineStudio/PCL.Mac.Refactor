//
//  MinecraftInstallTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import Foundation
import SwiftyJSON

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
        completion: (() -> Void)? = nil
    ) -> MyTask<Model> {
        let model: Model = .init(
            name: name,
            version: version,
            repository: repository
        )
        return .init(
            name: "\(name) 安装", model: model,
            .init(0, "下载客户端 JSON 文件", downloadClientManifest(task:model:)),
            .init(1, "下载资源索引文件", downloadAssetIndex(task:model:)),
            .init(2, "下载客户端本体", downloadClient(task:model:)),
            .init(2, "下载散列资源文件", downloadAssets(task:model:)),
            .init(2, "下载依赖库文件", downloadLibraries(task:model:)),
            .init(3, "__completion", display: false) { _, _ in
                try repository.load()
                await MainActor.run {
                    completion?()
                }
            }
        )
    }
    
    private static func downloadClientManifest(task: SubTask, model: Model) async throws {
        guard let manifest = CoreState.versionManifest else {
            err("CoreState.versionManifest 为空")
            throw TaskError.unknownError
        }
        guard let version = manifest.version(for: model.version.id) else {
            err("未找到版本：\(model.version)")
            throw TaskError.unknownError
        }
        
        let destination: URL = model.runningDirectory.appending(path: "\(model.name).json")
        try await SingleFileDownloader.download(
            url: version.url,
            destination: destination,
            sha1: nil,
            replaceMethod: .skip,
            progressHandler: task.setProgress(_:)
        )
        model.manifest = try JSONDecoder.shared.decode(ClientManifest.self, from: Data(contentsOf: destination))
    }
    
    private static func downloadAssetIndex(task: SubTask, model: Model) async throws {
        let destination: URL = model.repository.assetsURL
            .appending(path: "indexes/\(model.manifest.assetIndex.id).json")
        try await SingleFileDownloader.download(
            url: model.manifest.assetIndex.url,
            destination: destination,
            sha1: model.manifest.assetIndex.sha1,
            replaceMethod: .skip,
            progressHandler: task.setProgress(_:)
        )
        model.assetIndex = try JSONDecoder.shared.decode(AssetIndex.self, from: Data(contentsOf: destination))
    }
    
    private static func downloadClient(task: SubTask, model: Model) async throws {
        try await SingleFileDownloader.download(
            url: model.manifest.downloads.client.url,
            destination: model.runningDirectory.appending(path: "\(model.name).jar"),
            sha1: model.manifest.downloads.client.sha1,
            replaceMethod: .skip,
            progressHandler: task.setProgress(_:)
        )
    }
    
    private static func downloadAssets(task: SubTask, model: Model) async throws {
        let root: URL = URL(string: "https://resources.download.minecraft.net")!
        let items: [DownloadItem] = model.assetIndex.objects.map { .init(
            url: root.appending(path: "\($0.hash.prefix(2))/\($0.hash)"),
            destination: model.repository.assetsURL.appending(path: "objects/\($0.hash.prefix(2))/\($0.hash)"),
            sha1: $0.hash
        ) }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: task.setProgress(_:)).start()
    }
    
    private static func downloadLibraries(task: SubTask, model: Model) async throws {
        let items: [DownloadItem] = (model.manifest.getLibraries() + model.manifest.getNatives())
            .compactMap(\.artifact)
            .map { DownloadItem(url: $0.url, destination: model.repository.librariesURL.appending(path: $0.path), sha1: $0.sha1) }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: task.setProgress(_:)).start()
    }
    
    public class Model: TaskModel {
        public let name: String
        public let version: MinecraftVersion
        public let runningDirectory: URL
        public let repository: MinecraftRepository
        
        public var manifest: ClientManifest!
        public var assetIndex: AssetIndex!
        
        public init(name: String, version: MinecraftVersion, repository: MinecraftRepository) {
            self.name = name
            self.version = version
            self.runningDirectory = repository.versionsURL.appending(path: name)
            self.repository = repository
        }
    }
}
