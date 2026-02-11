//
//  MinecraftInstance.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/25.
//

import Foundation
import SwiftyJSON

public class MinecraftInstance {
    private static let configFileName: String = ".clconfig.json"
    public let runningDirectory: URL
    public let version: MinecraftVersion
    public let manifest: ClientManifest
    public let config: Config
    
    public var name: String { runningDirectory.lastPathComponent }
    public var manifestURL: URL { runningDirectory.appending(path: "\(name).json") }
    
    /// 根据运行目录、版本与客户端清单创建实例对象。
    ///
    /// 如果只需要从磁盘加载实例，请使用 `MinecraftInstance.load(from:)`。
    /// - Parameters:
    ///   - runningDirectory: 实例运行目录。
    ///   - version: 实例的 Minecraft 版本。
    ///   - manifest: 客户端清单。
    ///   - config: 实例配置。
    public init(runningDirectory: URL, version: MinecraftVersion, manifest: ClientManifest, config: Config) {
        self.runningDirectory = runningDirectory
        self.version = version
        self.manifest = manifest
        self.config = config
        VersionCache.add(version: version, for: self)
        if config.javaURL == nil {
            setJava(url: searchJava().map(\.executableURL))
        }
    }
    
    /// 设置 JVM Heap Size 并保存。
    public func setJVMHeapSize(_ heapSize: UInt64) {
        config.jvmHeapSize = heapSize
        saveConfig()
    }
    
    /// 设置实例使用的 Java 并保存。
    public func setJava(url: URL?) {
        config.javaURL = url
        saveConfig()
    }
    
    /// 搜索最适合的 Java。
    /// - Parameters:
    ///   - arch: 目标 Java 架构。
    ///   - research: 是否重新构建 Java 列表。
    /// - Returns: 搜到的 Java。
    @discardableResult
    public func searchJava(arch: Architecture? = nil, research: Bool = false) -> JavaRuntime? {
        if research {
            do {
                try JavaManager.shared.research()
            } catch {
                err("重新搜索 Java 失败：\(error.localizedDescription)")
            }
        }
        func getScore(of runtime: JavaRuntime) -> Int {
            var score: Int = 0
            if runtime.architecture == (version > .init("1.7.2") ? .systemArchitecture() : .x64) { score += 3 }
            if runtime.versionNumber == manifest.javaVersion.majorVersion { score += 2 }
            if runtime.type == .jdk { score += 1 }
            if runtime.implementor.contains("Azul") { score += 1 }
            return score
        }
        
        if let runtime: JavaRuntime = JavaManager.shared.javaRuntimes
            .filter({ $0.architecture == (arch ?? $0.architecture) })
            .filter({ $0.versionNumber >= manifest.javaVersion.majorVersion })
            .max(by: { getScore(of: $0) > getScore(of: $1) }) {
            return runtime
        }
        warn("未找到 \(version) 可用的 Java")
        return nil
    }
    
    /// 获取实例使用的 `JavaRuntime` 对象。
    public func javaRuntime() -> JavaRuntime? {
        guard let javaURL = config.javaURL else {
            return nil
        }
        do {
            return try JavaSearcher.load(from: javaURL)
        } catch {
            err("加载 Java 失败")
            setJava(url: nil)
            return nil
        }
    }
    
    private func saveConfig() {
        let url: URL = runningDirectory.appending(path: Self.configFileName)
        do {
            let data: Data = try JSONEncoder.shared.encode(config)
            try data.write(to: url)
        } catch {
            err("保存配置失败：\(error.localizedDescription)")
        }
    }
    
    /// 从磁盘加载实例。
    ///
    /// 对于老版本（如 `1.8.9`），可能无法正确检测 Minecraft 版本，所以请在安装完成时调用 `MinecraftInstance.init` 而不是本函数。
    /// - Parameters:
    ///   - runningDirectory: 实例运行目录。
    ///   - version: （可选）缓存的版本号。
    /// - Returns: 实例对象。
    public static func load(from runningDirectory: URL) throws -> MinecraftInstance {
        // 加载客户端清单
        let manifestURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else { throw MinecraftError.missingManifest }
        let manifest: ClientManifest
        do {
            manifest = try JSONDecoder.shared.decode(ClientManifest.self, from: Data(contentsOf: manifestURL))
        } catch {
            err("加载客户端清单失败：\(error)")
            throw MinecraftError.unknownManifestFormat
        }
        // 获取版本
        let version: MinecraftVersion
        if let cachedVersion = VersionCache.version(of: manifestURL) {
            version = cachedVersion
        } else {
            let jarURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).jar")
            if FileManager.default.fileExists(atPath: jarURL.path),
               try ArchiveUtils.hasEntry(url: jarURL, path: "version.json"),
               let json: JSON = try? JSON(data: ArchiveUtils.getEntry(url: jarURL, path: "version.json")) {
                log("成功解析 version.json")
                version = .init(json["id"].stringValue)
            } else {
                warn("\(jarURL.lastPathComponent)!/version.json 不存在或解析失败，使用客户端清单中的 id 作为版本号")
                version = .init(manifest.id)
            }
            VersionCache.add(version: version.id, for: manifestURL)
        }
        
        let configURL: URL = runningDirectory.appending(path: configFileName)
        var config: Config? = nil
        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                config = try JSONDecoder.shared.decode(Config.self, from: Data(contentsOf: configURL))
            } catch {
                err("加载实例配置失败：\(error.localizedDescription)")
            }
        }
        
        let instance: MinecraftInstance = .init(
            runningDirectory: runningDirectory,
            version: version,
            manifest: manifest,
            config: config ?? .init()
        )
        return instance
    }
    
    
    public class Config: Codable {
        public var jvmHeapSize: UInt64
        public var javaURL: URL?
        
        public init() {
            self.jvmHeapSize = 4096
            self.javaURL = nil
        }
        
        private enum CodingKeys: String, CodingKey {
            case jvmHeapSize, javaURL
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.jvmHeapSize = try container.decode(UInt64.self, forKey: .jvmHeapSize)
            self.javaURL = try container.decodeIfPresent(URL.self, forKey: .javaURL)
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jvmHeapSize, forKey: .jvmHeapSize)
            try container.encodeIfPresent(javaURL, forKey: .javaURL)
        }
    }
}
