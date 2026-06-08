//
//  ModLoadService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import ZIPFoundation

public class ModLoadService {
    private let remoteLookupService: ModRemoteLookupService
    private let cache: ModCache
    
    public init(remoteLookupService: ModRemoteLookupService, cache: ModCache) {
        self.remoteLookupService = remoteLookupService
        self.cache = cache
    }
    
    /// 将单个模组文件加载为 `Mod` 结构体。
    /// - Returns: 一个 `Mod`，若无法识别模组则返回 `nil`。
    /// - Throws: `LoadError`
    public func load(from fileURL: URL) async throws(LoadError) -> Mod? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
            throw .fileNotExists
        }
        guard isDirectory.boolValue == false else { throw .foundDirectory }
        
        let sha1: String
        do {
            sha1 = try FileUtils.sha1(of: fileURL)
        } catch {
            throw .readError(underlying: error)
        }
        
        if let cached = cache.mod(forHash: sha1) { return cached }
        
        let remoteInfo: ModRemoteLookupService.RemoteModInfo?
        do {
            remoteInfo = try await remoteLookupService.lookup(hash: sha1)
        } catch {
            err("加载 \(fileURL.lastPathComponent) 的远端模组信息失败：\(error.localizedDescription)")
            remoteInfo = nil
        }
        
        if let mod = try loadModFile(at: fileURL, sha1: sha1, remoteInfo: remoteInfo) {
            cache.store(mod, forHash: sha1)
            return mod
        }
        return nil
    }
    
    /// 遍历目录中的模组文件，并将它们加载为 `Mod` 结构体。
    /// - Parameter directoryURL: 目录的 `URL`。
    /// - Returns: `[URL: Mod]` 字典，包含所有加载成功的模组。
    /// - Throws: `LoadError`
    public func loadMods(in directoryURL: URL) async throws(LoadError) -> [URL: Mod] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) else {
            throw .fileNotExists
        }
        guard isDirectory.boolValue == true else { throw .foundFile }
        
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { throw .failedToCreateEnumerator }
        
        func enumerateFiles(body: (URL) throws -> Void) {
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "jar" && (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                do {
                    try body(fileURL)
                } catch {
                    err("处理文件 \(fileURL.lastPathComponent) 失败：\(error.localizedDescription)")
                }
            }
        }
        
        var result: [URL: Mod] = [:]
        var hashes: [URL: String] = [:]
        enumerateFiles { url in
            let hash = try FileUtils.sha1(of: url)
            if let mod = cache.mod(forHash: hash) {
                result[url] = mod
            } else {
                hashes[url] = hash
            }
        }
        
        if hashes.isEmpty {
            return result
        }
        
        let remoteLookupResult: [String: ModRemoteLookupService.RemoteModInfo]
        do {
            remoteLookupResult = try await remoteLookupService.lookup(hashes: Array(hashes.values))
        } catch {
            err("加载远端模组信息失败：\(error.localizedDescription)")
            remoteLookupResult = [:]
        }
        
        for (fileURL, hash) in hashes {
            do {
                guard let mod = try loadModFile(at: fileURL, sha1: hash, remoteInfo: remoteLookupResult[hash]) else { continue }
                result[fileURL] = mod
                cache.store(mod, forHash: hash)
            } catch {
                err("处理模组 \(fileURL.lastPathComponent) 失败：\(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    public enum LoadError: LocalizedError {
        case fileNotExists
        case foundDirectory
        case foundFile
        case failedToCreateEnumerator
        case readError(underlying: Error)
        case extractError(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotExists:
                "模组文件不存在。"
            case .foundDirectory:
                "期望获得文件，但找到了一个文件夹。"
            case .foundFile:
                "期望获得文件夹，但找到了一个文件。"
            case .failedToCreateEnumerator:
                "创建文件遍历器失败。"
            case .readError(let underlying):
                "读取文件失败：\(underlying.localizedDescription)"
            case .extractError(let underlying):
                "解压文件失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    
    private func loadModFile(at url: URL, sha1: String, remoteInfo: ModRemoteLookupService.RemoteModInfo?) throws(LoadError) -> Mod? {
        let archive: Archive
        do {
            archive = try .init(url: url, accessMode: .read)
        } catch {
            throw .extractError(underlying: error)
        }
        
        var loaders: [ModLoader] = []
        var meta: ModMeta?
        if let fabricMeta = loadModMeta(archive, "fabric.mod.json", loader: loadFabric(from:)) {
            loaders.append(.fabric)
            if meta == nil { meta = fabricMeta }
        }
        
        guard let meta else { return nil }
        
        let icon: ResourceIcon?
        if let iconPath = meta.icon, let entry = archive[iconPath] {
            do {
                let iconData = try archive.extract(entry)
                let hash = try cache.store(iconData, relativePath: iconPath, jarHash: sha1)
                icon = .archiveEntry(path: iconPath, globalHash: hash)
            } catch {
                err("写入缓存失败：\(error.localizedDescription)")
                icon = nil
            }
        } else if let iconURL = remoteInfo?.icon {
            icon = .network(url: iconURL)
        } else {
            icon = nil
        }
        
        return .init(
            name: meta.name ?? remoteInfo?.name ?? meta.id,
            version: meta.version,
            description: meta.description ?? remoteInfo?.description,
            icon: icon,
            loaders: loaders,
            sources: (remoteInfo?.source).map { [$0] } ?? []
        )
    }
    
    private func loadModMeta(_ archive: Archive, _ path: String, loader: (Data) throws -> ModMeta) -> ModMeta? {
        if let entry = archive[path] {
            do {
                let data = try archive.extract(entry)
                return try loader(data)
            } catch let error as DecodingError {
                err("解析模组元数据失败：\(error)")
            } catch {
                err("解压 \(path) 失败：\(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    private func loadFabric(from data: Data) throws -> ModMeta {
        let fabricMeta: FabricMeta = try JSONDecoder.shared.decode(FabricMeta.self, from: data)
        return .init(
            id: fabricMeta.id,
            name: fabricMeta.name,
            description: fabricMeta.description,
            version: fabricMeta.version,
            icon: fabricMeta.icon
        )
    }
    
    // MARK: - 数据模型
    
    private struct ModMeta {
        let id: String
        let name: String?
        let description: String?
        let version: String
        let icon: String?
    }
    
    private struct FabricMeta: Codable {
        let schemaVersion: Int
        let id: String
        let version: String
        let name: String?
        let description: String?
        let icon: String?
    }
}
