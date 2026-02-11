//
//  MinecraftRepository.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/26.
//

import Foundation

/// Minecraft 仓库（`.minecraft`）。
public class MinecraftRepository: ObservableObject, Codable, Hashable, Equatable {
    @Published public var name: String
    @Published public var url: URL
    @Published public var instances: [MinecraftInstance]?
    @Published public var errorInstances: [ErrorInstance]?
    
    public lazy var assetsURL: URL = { url.appending(path: "assets") }()
    public lazy var librariesURL: URL = { url.appending(path: "libraries") }()
    public lazy var versionsURL: URL = { url.appending(path: "versions") }()
    
    public init(name: String, url: URL, instances: [MinecraftInstance]? = nil) {
        self.name = name
        self.url = url
        self.instances = instances
    }
    
    /// 创建必要目录。
    public func createDirectories() throws {
        let fileManager: FileManager = .default
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: librariesURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: versionsURL, withIntermediateDirectories: true)
    }
    
    /// 加载该仓库中的所有实例。
    /// 只会在读取目录失败时抛出错误。
    public func load() throws {
        let (instances, errorInstances) = try getInstanceList()
        self.instances = instances
        self.errorInstances = errorInstances
    }
    
    /// 异步加载该仓库中的所有实例。
    /// 只会在读取目录失败时抛出错误。
    public func loadAsync() async throws {
        let (instances, errorInstances) = try getInstanceList()
        await MainActor.run {
            self.instances = instances
            self.errorInstances = errorInstances
        }
    }
    
    /// 从仓库中加载实例。
    /// - Parameter id: 实例的 ID。
    /// - Returns: 实例对象。
    public func instance(id: String, version: MinecraftVersion? = nil) throws -> MinecraftInstance {
        return try .load(from: versionsURL.appending(path: id))
    }
    
    
    private func getInstanceList() throws -> ([MinecraftInstance], [ErrorInstance]) {
        try createDirectories()
        var instances: [MinecraftInstance] = []
        var errorInstances: [ErrorInstance] = []
        let contents: [URL] = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        for content in contents where try content.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
            let instance: MinecraftInstance
            do {
                log("正在加载实例 \(content.lastPathComponent)")
                instance = try MinecraftInstance.load(from: content)
            } catch MinecraftError.unknownManifestFormat {
                err("加载实例失败：不支持的客户端清单格式。")
                errorInstances.append(.init(name: content.lastPathComponent, message: "不支持的客户端清单格式。"))
                continue
            } catch {
                err("加载实例失败：\(error.localizedDescription)")
                continue
            }
            instances.append(instance)
        }
        return (instances, errorInstances)
    }
    
    public static func == (lhs: MinecraftRepository, rhs: MinecraftRepository) -> Bool {
        return lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(name)
    }
    
    public enum CodingKeys: String, CodingKey { case name, url, instances }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.url, forKey: .url)
    }
    
    public struct ErrorInstance {
        public let name: String
        public let message: String
    }
}
