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
                    let progressHandler = ConcurrentProgressHandler(totalHandler: task.setProgress(_:))
                    
                    let fetchProgressHandler = await progressHandler.handler(withMultiplier: 0.2)
                    let total = Double(index.files.count)
                    var completed = 0.0
                    var downloadItems: [DownloadItem] = []
                    
                    progressHandler.startCalculate()
                    
                    try await withThrowingTaskGroup(of: DownloadItem?.self) { group in
                        for file in index.files {
                            group.addTask {
                                try await file.fetchInfo()
                                guard let url = file.url, let path = file.path else { return nil }
                                return .init(url: url, destination: model.runningDirectory.appending(path: path), checksums: file.checksums ?? [:])
                            }
                        }
                        for try await item in group {
                            if let item {
                                downloadItems.append(item)
                            }
                            completed += 1
                            await fetchProgressHandler(completed / total)
                        }
                    }
                    
                    let downloadProgressHandler = await progressHandler.handler(withMultiplier: 0.8)
                    try await MultiFileDownloader(items: downloadItems, concurrentLimit: 64, replaceMethod: .skip, progressHandler: downloadProgressHandler).start()
                },
                .init(7, "应用整合包修改") { task, model in
                    for dirName in index.overridesDirectories {
                        let overridesDirectory: URL = modpackDirectory.appending(path: dirName)
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
            name: "整合包安装：\(index.name)",
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
    
    fileprivate static func apply(_ source: URL, to destination: URL) throws {
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

public enum SimpleModpackImportTask {
    public static func create(
        modpackDirectory: URL,
        index: ModpackIndex,
        repository: MinecraftRepository,
        name: String,
        completion: (@MainActor (MinecraftInstance) -> Void)? = nil
    ) -> MyTask<Model> {
        let runningDirectory = repository.versionsDirectory.appending(path: name)
        
        return .init(
            name: "整合包安装：\(index.name)",
            .init(0, "拷贝整合包文件") { task, model in
                try FileManager.default.createDirectory(at: runningDirectory, withIntermediateDirectories: true)
                
                for dirName in index.overridesDirectories {
                    let overridesDirectory = modpackDirectory.appending(path: dirName)
                    if FileManager.default.fileExists(atPath: overridesDirectory.path) {
                        do {
                            try ModpackImportTask.apply(overridesDirectory, to: runningDirectory)
                        } catch {
                            throw ModpackImportTask.Error.failedToApplyOverrides(underlying: error)
                        }
                    }
                }
            },
            .init(1, "__completion", display: false) { task, model in
                try? FileManager.default.removeItem(at: runningDirectory.appending(path: ".incomplete"))
                try await repository.load()
                guard let instance = repository.instance(named: name) else {
                    try? FileManager.default.removeItem(at: runningDirectory)
                    throw SimpleError("该实例无法被加载。")
                }
                await MainActor.run {
                    completion?(instance)
                }
            }
        ) { _ in
            try? FileManager.default.removeItem(at: runningDirectory)
        }
    }
    
    public typealias Model = EmptyModel
}
