//
//  MinecraftInstanceLoader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/4/15.
//

import Foundation
import SwiftyJSON

public enum MinecraftInstanceLoader {
    private static let maxManifestInheritanceDepth: Int = 5
    
    /// 从磁盘加载实例。
    /// - Parameter runningDirectory: 实例运行目录。
    /// - Returns: `MinecraftInstance_` 结构体。
    /// - Throws: `MinecraftInstanceLoader.Error`
    public static func load(from runningDirectory: URL) throws(LoadError) -> MinecraftInstance_ {
        if FileManager.default.fileExists(atPath: runningDirectory.appending(path: ".incomplete").path) {
            throw .incomplete
        }
        
        let id: String = runningDirectory.lastPathComponent
        
        let metadataURL = runningDirectory.appending(path: ".clmetadata.json")
        let metadata: InstanceMetadata?
        if FileManager.default.fileExists(atPath: metadataURL.path) {
            do {
                let data = try Data(contentsOf: metadataURL)
                metadata = try JSONDecoder.shared.decode(InstanceMetadata.self, from: data)
            } catch {
                err("加载元数据文件失败：\(error.localizedDescription)")
                metadata = nil
            }
        } else {
            log("元数据文件不存在")
            metadata = nil
        }
        
        let manifestURL = runningDirectory.appending(path: "\(id).json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw .missingManifest
        }
        let manifest: ClientManifest
        do {
            manifest = try loadManifest(at: manifestURL)
        } catch {
            throw .failedToLoadManifest(underlying: error)
        }
        
        let version: MinecraftVersion? = metadata?.version ?? detectVersion(runningDirectory: runningDirectory, manifest: manifest)
        if let version {
            VersionCache.add(version: version.id, for: manifestURL)
        } else {
            warn("获取实例版本失败")
        }
        
        let config: MinecraftInstance_.Config
        do {
            config = try loadConfig(runningDirectory: runningDirectory)
        } catch {
            err("加载配置文件失败：\(error.localizedDescription)，正在使用默认配置")
            config = .default
        }
        
        return .init(
            id: metadata?.uuid ?? .init(),
            url: runningDirectory,
            version: version ?? .init(id),
            modLoader: detectModLoader(runningDirectory: runningDirectory),
            manifest: manifest,
            config: config
        )
    }
    
    /// 从磁盘加载客户端清单，并递归加载父清单。
    /// - Parameter url: 清单文件的 `URL`。
    /// - Returns: `ClientManifest`
    /// - Throws: `ManifestLoadError`
    private static func loadManifest(at url: URL, recursionDepth: Int = 0) throws(ManifestLoadError) -> ClientManifest {
        guard recursionDepth < maxManifestInheritanceDepth else { throw ManifestLoadError.tooManyRecursions }
        
        let data: Data
        do {
            data = try .init(contentsOf: url)
        } catch {
            throw .failedToRead(underlying: error)
        }
        
        let manifest: ClientManifest
        do {
            manifest = try JSONDecoder.shared.decode(ClientManifest.self, from: data)
        } catch let error as DecodingError {
            debug("客户端清单 \(url) 加载失败：\n\(error)")
            throw .manifestDecodingError(underlying: error)
        } catch {
            debug("客户端清单 \(url) 加载失败：发生未知错误：\n\(error)")
            throw .unexpectedError(underlying: error)
        }
        
        if let parentId: String = manifest.inheritsFrom {
            let versionsDirectory: URL = url.deletingLastPathComponent().deletingLastPathComponent()
            let id = url.deletingLastPathComponent().lastPathComponent
            
            let parentURLs: [URL] = [
                versionsDirectory.appending(path: "\(id)/.parent/\(parentId).json"),
                versionsDirectory.appending(path: "\(parentId)/\(parentId).json")
            ]
            
            for parentURL in parentURLs where FileManager.default.fileExists(atPath: parentURL.path) {
                let parentManifest = try loadManifest(at: parentURL, recursionDepth: recursionDepth + 1)
                return manifest.merge(to: parentManifest)
            }
            throw .missingParentManifest
        }
        return manifest
    }
    
    /// 加载实例配置。
    /// - Parameter runningDirectory: 实例运行目录。
    /// - Returns: `MinecraftInstance_.Config`
    /// - Throws: `ConfigLoadError`
    private static func loadConfig(runningDirectory: URL) throws(ConfigLoadError) -> MinecraftInstance_.Config {
        let configURL = runningDirectory.appending(path: ".clconfig.json")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw .fileDoesNotExist
        }
        do {
            let data = try Data(contentsOf: configURL)
            return try JSONDecoder.shared.decode(MinecraftInstance_.Config.self, from: data)
        } catch {
            throw .failedToDecodeConfig(underlying: error)
        }
    }
    
    private static func detectVersion(runningDirectory: URL, manifest: ClientManifest) -> MinecraftVersion? {
        if let clVersion = manifest.version {
            return .init(clVersion)
        }
        
        let id = runningDirectory.lastPathComponent
        if let cachedVersion = VersionCache.version(of: runningDirectory.appending(path: "\(id).json")) {
            return cachedVersion
        }
        do {
            let jarURL = runningDirectory.appending(path: "\(id).jar")
            guard FileManager.default.fileExists(atPath: jarURL.path),
                  try ArchiveUtils.hasEntry(url: jarURL, path: "version.json")
            else { return nil }
            
            let versionInfo: JSON = try JSON(data: ArchiveUtils.getEntry(url: jarURL, path: "version.json"))
            return .init(versionInfo["id"].stringValue)
        } catch { return nil }
    }
    
    private static func detectModLoader(runningDirectory: URL) -> ModLoader? {
        let manifestURL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        do {
            let data = try Data(contentsOf: manifestURL)
            guard let str = String(data: data, encoding: .utf8) else { return nil }
            if str.contains("neoforge") {
                return .neoforge
            } else if str.contains("forge") {
                return .forge
            } else if str.contains("fabric") {
                return .fabric
            } else {
                return nil
            }
        } catch { return nil }
    }
    
    private struct InstanceMetadata: Codable {
        public let uuid: UUID
        public let version: MinecraftVersion
    }
    
    public enum LoadError: LocalizedError {
        /// 实例未完成安装（有 `.incomplete` 标记）。
        case incomplete
        
        /// 未找到客户端清单。
        case missingManifest
        
        /// 客户端清单加载失败。
        case failedToLoadManifest(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .incomplete:
                "实例未完成安装进程。"
            case .missingManifest:
                "缺少客户端清单文件。"
            case .failedToLoadManifest(let underlying):
                "加载客户端清单失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    public enum ManifestLoadError: LocalizedError {
        /// 读取清单文件失败。
        case failedToRead(underlying: Error)
        
        /// 清单解析失败。
        /// - Parameter underlying: `DecodingError`
        case manifestDecodingError(underlying: Error)
        
        /// 解析清单时抛出了 `DecodingError` 外的错误。
        case unexpectedError(underlying: Error)
        
        /// 未找到父清单（`inheritsFrom`）文件。
        case missingParentManifest
        
        /// 清单继承深度超限。
        case tooManyRecursions
        
        public var errorDescription: String? {
            switch self {
            case .failedToRead(let underlying):
                "读取清单文件失败：\(underlying.localizedDescription)"
            case .manifestDecodingError(let underlying):
                "解析清单失败：\(underlying.localizedDescription)"
            case .unexpectedError(let underlying):
                "意外错误：\(underlying.localizedDescription)"
            case .missingParentManifest:
                "找不到父清单文件。"
            case .tooManyRecursions:
                "清单继承深度超限。"
            }
        }
    }
    
    public enum ConfigLoadError: LocalizedError {
        /// 配置文件不存在。
        case fileDoesNotExist
        
        /// 解析配置文件失败。
        case failedToDecodeConfig(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileDoesNotExist:
                "配置文件不存在。"
            case .failedToDecodeConfig(let underlying):
                "解析配置文件失败：\(underlying.localizedDescription)"
            }
        }
    }
}
