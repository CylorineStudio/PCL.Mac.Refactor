//
//  ModpackImportService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/2.
//

import Foundation
import ZIPFoundation

public class ModpackImportService {
    private let curseforgeClient: CurseForgeAPIClient?
    private var modpackURL: URL
    private var index: ModpackIndex?
    private var tempDirectory: URL
    
    public init(curseforgeClient: CurseForgeAPIClient? = nil, modpackURL: URL, index: ModpackIndex? = nil) {
        self.curseforgeClient = curseforgeClient
        self.modpackURL = modpackURL
        self.index = index
        self.tempDirectory = URLConstants.tempURL.appending(path: "modpack-import-\(modpackURL.lastPathComponent.sha1)")
    }
    
    @discardableResult
    public func load() throws(LoadError) -> ModpackIndex {
        log("正在尝试加载整合包 \(modpackURL.lastPathComponent)")
        
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        } catch {
            throw .failedToCreateDirectory(underlying: error)
        }
        
        let archive: Archive
        do {
            archive = try .init(url: modpackURL, accessMode: .read)
        } catch {
            throw .extractFailed(underlying: error)
        }
        
        if let modpackEntry = archive["modpack.mrpack"] ?? archive["modpack.zip"] { // 包含启动器的整合包
            let nestedModpackURL = tempDirectory.appending(path: modpackEntry.path)
            let nestedArchive: Archive
            do {
                _ = try archive.extract(modpackEntry, to: nestedModpackURL, allowUncontainedSymlinks: false)
                nestedArchive = try .init(url: nestedModpackURL, accessMode: .read)
                self.modpackURL = nestedModpackURL
            } catch {
                throw .extractFailed(underlying: error)
            }
            let index = try loadIndex(from: nestedArchive)
            self.index = index
            return index
        }
        let index = try loadIndex(from: archive)
        self.index = index
        return index
    }
    
    public func createImportTask(
        name: String,
        repository: MinecraftRepository,
        completion: (@MainActor (MinecraftInstance) -> Void)? = nil
    ) throws(ImportError) -> MyTask<ModpackImportTask.Model> {
        guard let index else { throw .notLoaded }
        guard index.format != .simple && index.minecraftVersion != nil else { throw .incorrectTaskType }
        
        let (instanceName, modpackDirectory) = try prepareTask(name: name, repository: repository)
        
        return ModpackImportTask.create(
            modpackDirectory: modpackDirectory,
            index: index,
            repository: repository,
            name: instanceName,
            completion: completion
        )
    }
    
    public func createSimpleImportTask(
        name: String,
        repository: MinecraftRepository,
        completion: (@MainActor (MinecraftInstance) -> Void)? = nil
    ) throws(ImportError) -> MyTask<SimpleModpackImportTask.Model> {
        guard let index else { throw .notLoaded }
        guard index.format == .simple else { throw .incorrectTaskType }
        
        let (instanceName, modpackDirectory) = try prepareTask(name: name, repository: repository)
        
        return SimpleModpackImportTask.create(
            modpackDirectory: modpackDirectory,
            index: index,
            repository: repository,
            name: instanceName
        )
    }
    
    
    private func loadIndex(from archive: Archive) throws(LoadError) -> ModpackIndex {
        if let modrinthIndexEntry = archive["modrinth.index.json"] {
            let index: ModrinthModpackIndex = try decodeIndex(from: modrinthIndexEntry, in: archive)
            let modLoader: (ModLoader, String)? = try index.dependencies.modLoader().map(parseModLoader(_:))
            
            return .init(
                format: .modrinth,
                name: index.name,
                version: index.versionId,
                author: nil,
                description: index.summary,
                minecraftVersion: .init(index.dependencies.minecraft),
                modLoader: modLoader,
                files: index.files.compactMap { file in
                    guard file.env?[.client] != .unsupported, let url = file.downloads.first else { return nil }
                    return ModpackIndex.RegularFile(url: url, path: file.path, checksums: file.hashes)
                },
                overridesDirectories: ["overrides", "client-overrides"]
            )
        } else if let curseforgeIndexEntry = archive["manifest.json"] {
            guard let curseforgeClient else { throw .missingCurseforgeClient }
            
            let index: CurseForgeModpackIndex = try decodeIndex(from: curseforgeIndexEntry, in: archive)
            let modLoader: (ModLoader, String)? = try index.modLoader.map(parseModLoader(_:))
            
            return .init(
                format: archive["mcbbs.metadata"] != nil ? .mcbbs : .curseforge,
                name: index.name,
                version: index.version,
                author: index.author,
                description: nil,
                minecraftVersion: .init(index.minecraftVersion),
                modLoader: modLoader,
                files: index.files.map { ModpackIndex.CurseForgeFile(client: curseforgeClient, file: $0) },
                overridesDirectories: index.overridesDirectory.map { [$0] } ?? []
            )
        }
        
        for entry in archive where entry.path.hasSuffix("/") {
            guard let range = entry.path.range(of: ".minecraft/versions/") else { continue }
            let remaining = entry.path[range.upperBound...]
            let parts = remaining.split(separator: "/")
            guard !parts.isEmpty else { continue }
            
            let instanceName = String(parts[0])
            let instancePath = String(entry.path[..<range.upperBound]) + instanceName
            return .init(
                format: .simple,
                name: instanceName,
                version: "未知",
                author: nil,
                description: "这只是一个包含 .minecraft 的压缩包，所以 PCL.Mac 无法获取它的信息，但依然可以导入它。",
                minecraftVersion: nil,
                modLoader: nil,
                files: [],
                overridesDirectories: [instancePath]
            )
        }
        
        throw .unknownFormat
    }
    
    private func parseModLoader(_ loader: (String, String)) throws(LoadError) -> (ModLoader, String) {
        guard let modLoader = ModLoader(rawValue: loader.0) else {
            throw .unsupportedModLoader(name: loader.0.capitalized)
        }
        return (modLoader, loader.1)
    }
    
    private func decodeIndex<T: Decodable>(from entry: Entry, in archive: Archive) throws(LoadError) -> T {
        var data = Data()
        do {
            _ = try archive.extract(entry, consumer: { data += $0 })
        } catch {
            throw .extractFailed(underlying: error)
        }
        do {
            let index: T = try JSONDecoder.shared.decode(T.self, from: data)
            log("成功解析 \(entry.path)")
            return index
        } catch {
            throw .failedToDecodeIndex(underlying: error)
        }
    }
    
    private func prepareTask(name: String, repository: MinecraftRepository) throws(ImportError) -> (String, URL) {
        let instanceName: String
        do {
            instanceName = try repository.checkInstanceName(name, trim: true)
        } catch {
            throw .invalidName(underlying: error)
        }
        
        let modpackDirectory = tempDirectory.appending(path: "modpack")
        do {
            try FileManager.default.unzipItem(at: self.modpackURL, to: modpackDirectory)
        } catch {
            throw .extractFailed(underlying: error)
        }
        return (instanceName, modpackDirectory)
    }
    
    public enum LoadError: LocalizedError {
        case missingCurseforgeClient
        case failedToCreateDirectory(underlying: Error)
        case extractFailed(underlying: Error)
        case failedToDecodeIndex(underlying: Error)
        case unsupportedModLoader(name: String)
        case unknownFormat
        
        public var errorDescription: String? {
            switch self {
            case .missingCurseforgeClient:
                "内部错误：正在加载 CurseForge 整合包，但没有传入 CurseForgeAPIClient"
            case .failedToCreateDirectory(let underlying):
                "创建临时目录失败：\(underlying.localizedDescription)"
            case .extractFailed(let underlying):
                "解压整合包文件失败：\(underlying.localizedDescription)"
            case .failedToDecodeIndex(let underlying):
                "解析整合包索引失败：\(underlying.localizedDescription)"
            case .unsupportedModLoader(let name):
                "不支持的模组加载器：\(name)"
            case .unknownFormat:
                "未知或不支持的整合包格式。"
            }
        }
    }
    
    public enum ImportError: LocalizedError {
        case notLoaded
        case incorrectTaskType
        case invalidName(underlying: MinecraftRepository.NameCheckError)
        case extractFailed(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .notLoaded:
                "内部错误：尝试创建整合包导入任务，但没有加载它。"
            case .incorrectTaskType:
                "内部错误：错误的任务类型"
            case .invalidName(let underlying):
                "无效的实例名：\(underlying.localizedDescription)"
            case .extractFailed(let underlying):
                "解压整合包文件失败：\(underlying.localizedDescription)"
            }
        }
    }
}
