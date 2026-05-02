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
    private static let configFileName: String = ".clconfig.json"
    private static let metadataFileName: String = ".clmetadata.json"
    
    /// 从磁盘加载实例。
    /// - Parameter runningDirectory: 实例运行目录。
    /// - Returns: `MinecraftInstance_` 结构体。
    /// - Throws: `MinecraftInstanceLoader.LoadError`
    public static func load(from runningDirectory: URL) throws(LoadError) -> MinecraftInstance_ {
        if FileManager.default.fileExists(atPath: runningDirectory.appending(path: ".incomplete").path) {
            throw .incomplete
        }
        
        let id: String = runningDirectory.lastPathComponent
        var dirty = false
        
        let metadataURL = runningDirectory.appending(path: metadataFileName)
        let metadata: InstanceMetadata?
        if FileManager.default.fileExists(atPath: metadataURL.path) {
            do {
                let data = try Data(contentsOf: metadataURL)
                metadata = try JSONDecoder.shared.decode(InstanceMetadata.self, from: data)
            } catch {
                err("加载元数据文件失败：\(error.localizedDescription)")
                dirty = true
                metadata = nil
            }
        } else {
            log("元数据文件不存在")
            dirty = true
            metadata = nil
        }
        
        let uuid = metadata?.uuid ?? UUID()
        
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
        if version == nil {
            warn("获取实例版本失败")
        }
        
        let config: MinecraftInstance_.Config
        do {
            config = try loadConfig(runningDirectory: runningDirectory)
        } catch {
            err("加载配置文件失败：“\(error.localizedDescription)”，正在使用默认配置")
            dirty = true
            config = .default
        }
        
        if metadata == nil {
            try? JSONEncoder.shared.encode(InstanceMetadata(uuid: uuid, version: version))
                .write(to: metadataURL)
        }
        
        return .init(
            id: uuid,
            url: runningDirectory,
            version: version ?? .init(id),
            modLoader: detectModLoader(runningDirectory: runningDirectory),
            manifest: manifest,
            config: config,
            dirty: dirty
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
        let configURL = runningDirectory.appending(path: configFileName)
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
        public let version: MinecraftVersion?
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

public extension MinecraftInstanceLoader {
    /// 将实例保存到磁盘。
    /// - Parameter instance: 待保存的实例。
    /// - Throws: `MinecraftInstanceLoader.SaveError`
    static func save(_ instance: MinecraftInstance_) throws(SaveError) {
        let configData: Data
        do {
            configData = try JSONEncoder.shared.encode(instance.config)
        } catch {
            throw .failedToEncodeConfig(underlying: error)
        }
        do {
            try configData.write(to: instance.url.appending(path: configFileName))
        } catch {
            throw .failedToWriteFile(underlying: error)
        }
        
        let metadataData: Data
        let metadata = InstanceMetadata(uuid: instance.id, version: instance.version)
        do {
            metadataData = try JSONEncoder.shared.encode(metadata)
        } catch {
            throw .failedToEncodeMetadata(underlying: error)
        }
        do {
            try metadataData.write(to: instance.url.appending(path: metadataFileName))
        } catch {
            throw .failedToWriteFile(underlying: error)
        }
    }
    
    enum SaveError: LocalizedError {
        /// 配置文件序列化失败。
        /// - Parameter underlying: 序列化时抛出的 `EncodingError`。
        case failedToEncodeConfig(underlying: Error)
        
        /// 元数据序列化失败。
        /// - Parameter underlying: 序列化时抛出的 `EncodingError`。
        case failedToEncodeMetadata(underlying: Error)
        
        /// 写入文件失败。
        /// - Parameter underlying: 写入时抛出的实际错误。
        case failedToWriteFile(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .failedToEncodeConfig(let underlying):
                "配置文件序列化失败：\(underlying.localizedDescription)"
            case .failedToEncodeMetadata(let underlying):
                "元数据序列化失败：\(underlying.localizedDescription)"
            case .failedToWriteFile(let underlying):
                "写入文件失败：\(underlying.localizedDescription)"
            }
        }
    }
}
