//
//  MinecraftInstallTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import Foundation
import SwiftyJSON

public enum MinecraftInstallTask {
    private typealias SubTask = MyTask<Model>.SubTask
    
    public static func create(
        name: String,
        version: MinecraftVersion,
        minecraftDirectory: URL
    ) -> MyTask<Model> {
        let model: Model = .init(
            name: name,
            version: version,
            minecraftDirectory: minecraftDirectory
        )
        return .init(
            name: "\(name) 安装", model: model,
            .init(0, "下载客户端 JSON 文件", downloadClientManifest(task:model:)),
            .init(1, "下载资源索引文件", downloadAssetIndex(task:model:)),
            .init(2, "下载客户端本体", downloadClient(task:model:)),
            .init(2, "下载散列资源文件", downloadAssets(task:model:)),
            .init(2, "下载依赖库文件", downloadLibraries(task:model:)),
        )
    }
    
    private static func downloadClientManifest(task: SubTask, model: Model) async throws {
        guard let manifest = CoreState.versionManifest else {
            err("CoreState.versionManifest 为空")
            throw TaskError.unknownError
        }
        guard let version = manifest.getVersion(model.version.id) else {
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
        model.manifest = ClientManifest(json: try JSON(data: Data(contentsOf: destination)))
    }
    
    private static func downloadAssetIndex(task: SubTask, model: Model) async throws {
        let destination: URL = model.minecraftDirectory
            .appending(path: "assets/indexes/\(model.manifest.assetIndex.id).json")
        try await SingleFileDownloader.download(
            url: model.manifest.assetIndex.url,
            destination: destination,
            sha1: model.manifest.assetIndex.sha1,
            replaceMethod: .skip,
            progressHandler: task.setProgress(_:)
        )
        model.assetIndex = .init(json: try JSON(data: Data(contentsOf: destination)))
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
        // TODO
    }
    
    private static func downloadLibraries(task: SubTask, model: Model) async throws {
        let items: [DownloadItem] = (model.manifest.getLibraries() + model.manifest.getNatives())
            .compactMap(\.artifact)
            .map { DownloadItem(url: $0.url, destination: model.minecraftDirectory.appending(path: "libraries/\($0.path)"), sha1: $0.sha1) }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: task.setProgress(_:)).start()
    }
    
    public class Model: TaskModel {
        public let name: String
        public let version: MinecraftVersion
        public let runningDirectory: URL
        public let minecraftDirectory: URL
        
        public var manifest: ClientManifest!
        public var assetIndex: AssetIndex!
        
        public init(name: String, version: MinecraftVersion, minecraftDirectory: URL) {
            self.name = name
            self.version = version
            self.runningDirectory = minecraftDirectory.appending(path: "versions/\(name)")
            self.minecraftDirectory = minecraftDirectory
        }
    }
}
