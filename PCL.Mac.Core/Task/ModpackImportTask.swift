//
//  ModpackImportTask.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/23.
//

import Foundation
import ZIPFoundation

public enum ModpackImportTask {
    public static func create(
        modpackDirectory: URL,
        index: ModpackIndex,
        repository: MinecraftRepository,
        name: String,
        completion: (@MainActor (MinecraftInstance) -> Void)? = nil
    ) -> MyTask<Model> {
        let minecraftInstallTask: MyTask<Model> = MinecraftInstallTask.create(
            name: name,
            version: index.minecraftVersion,
            repository: repository,
            modLoader: index.modLoader.map { .init(type: $0.0, version: $0.1) },
            completion: completion
        )
        var subTasks: [MyTask<Model>.SubTask] = minecraftInstallTask.subTasks
        
        subTasks.insert(
            contentsOf: [
                .init(6, "下载整合包所需文件") { task, model in
                    let downloadItems: [DownloadItem] = index.files
                        .map { .init(url: $0.url, destination: model.runningDirectory.appending(path: $0.path), checksums: $0.checksums) }
                    try await MultiFileDownloader(items: downloadItems, concurrentLimit: 64, replaceMethod: .skip, progressHandler: task.setProgress(_:)).start()
                },
                .init(7, "应用整合包修改") { task, model in
                    for dirName in index.overridesDirectories {
                        let overridesDirectory: URL = modpackDirectory.appending(path: "modpack/\(dirName)")
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
        case failedToCreateEnumerator
        case failedToApplyOverrides(underlying: Swift.Error)
        
        public var errorDescription: String? {
            switch self {
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
