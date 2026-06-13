//
//  ModLoadService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import ZIPFoundation
import TOMLDecoder

public class ModLoadService {
    private let remoteLookupService: ModRemoteLookupService
    private let cache: ModCache
    private let tomlDecoder: TOMLDecoder = .init()
    private let validPathExtensions = ["jar", "disabled"]
    
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
                guard validPathExtensions.contains(fileURL.pathExtension) && (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                do {
                    try body(fileURL)
                } catch {
                    err("处理文件 \(fileURL.lastPathComponent) 失败：\(error.localizedDescription)")
                }
            }
        }
        
        var total = 0
        var cached = 0
        var loaded = 0
        var unsupported = 0
        var failed = 0
        
        defer { debug("模组目录加载完成，共 \(total) 个文件，\(cached) 个命中缓存，\(loaded) 个加载成功，\(unsupported) 个无法识别，\(failed) 个加载失败") }
        
        var result: [URL: Mod] = [:]
        var hashes: [URL: String] = [:]
        enumerateFiles { url in
            total += 1
            try autoreleasepool {
                let hash = try FileUtils.sha1(of: url)
                if let mod = cache.mod(forHash: hash) {
                    cached += 1
                    result[url] = mod
                } else {
                    hashes[url] = hash
                }
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
                guard let mod = try loadModFile(at: fileURL, sha1: hash, remoteInfo: remoteLookupResult[hash]) else {
                    unsupported += 1
                    warn("无法识别 \(fileURL.lastPathComponent) 的类型")
                    continue
                }
                result[fileURL] = mod
                loaded += 1
                cache.store(mod, forHash: hash)
            } catch {
                err("处理模组 \(fileURL.lastPathComponent) 失败：\(error.localizedDescription)")
                failed += 1
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
                "模组文件或文件夹不存在。"
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
        
        var jarManifest: [String: String] = [:]
        if let entry = archive["META-INF/MANIFEST.MF"] {
            do {
                let data = try archive.extract(entry)
                guard let content = String(data: data, encoding: .utf8) else { throw SimpleError("解码字符串失败。") }
                jarManifest = JarUtils.parseManifest(content)
            } catch {
                err("加载 MANIFEST.MF 失败：\(error.localizedDescription)")
            }
        }
        
        var loaders: [ModLoader] = []
        var meta: ModMeta?
        
        for (path, loader, type) in [
            ("fabric.mod.json", loadFabric(from:), ModLoader.fabric),
            ("META-INF/mods.toml", { try self.loadForge(from: $0, jarManifest: jarManifest) }, .forge),
            ("META-INF/neoforge.mods.toml", { try self.loadForge(from: $0, jarManifest: jarManifest) }, .neoforge)
        ] {
            if let entry = archive[path] {
                do {
                    let data = try archive.extract(entry)
                    let parsedMeta = try loader(data)
                    loaders.append(type)
                    if meta == nil { meta = parsedMeta }
                } catch let error as DecodingError {
                    err("解析模组元数据失败：\(error)")
                } catch {
                    err("解压 \(path) 失败：\(error.localizedDescription)")
                }
            }
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
            tags: remoteInfo?.tags ?? [],
            sources: (remoteInfo?.source).map { [$0] } ?? [],
            disabled: url.pathExtension == "disabled"
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
    
    private func loadForge(from data: Data, jarManifest: [String: String]) throws -> ModMeta {
        var values: [String: String] = [:]
        
        if let version = jarManifest["Implementation-Version"] {
            values["file.jarVersion"] = version
        }
        
        let forgeMeta: ForgeMeta = try tomlDecoder.decode(ForgeMeta.self, from: data)
        return .init(
            id: forgeMeta.modId,
            name: forgeMeta.displayName,
            description: forgeMeta.description,
            version: forgeMeta.version.replacingPlaceholders(with: values, dollarPrefix: true),
            icon: forgeMeta.logoFile
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
    
    private struct ForgeMeta: Decodable {
        let modId: String
        let version: String
        let displayName: String?
        let description: String?
        let logoFile: String?
        
        private enum CodingKeys: CodingKey {
            case mods
        }
        
        private enum ModCodingKeys: CodingKey {
            case modId, version, displayName, description, logoFile
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var modsContainer = try container.nestedUnkeyedContainer(forKey: .mods)
            
            let first = try modsContainer.nestedContainer(keyedBy: ModCodingKeys.self)
            self.modId = try first.decode(String.self, forKey: .modId)
            self.version = try first.decode(String.self, forKey: .version)
            self.displayName = try first.decodeIfPresent(String.self, forKey: .displayName)
            self.description = try first.decodeIfPresent(String.self, forKey: .description)
            self.logoFile = try first.decodeIfPresent(String.self, forKey: .logoFile)
        }
    }
}
