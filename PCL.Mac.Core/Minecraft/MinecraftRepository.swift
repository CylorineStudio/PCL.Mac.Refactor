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
    @Published public var instances: [Instance]?
    
    public lazy var assetsURL: URL = { url.appending(path: "assets") }()
    public lazy var librariesURL: URL = { url.appending(path: "libraries") }()
    public lazy var versionsURL: URL = { url.appending(path: "versions") }()
    
    public init(name: String, url: URL, instances: [Instance]? = nil) {
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
    @discardableResult
    public func load() throws -> [Instance] {
        try createDirectories()
        var instances: [Instance] = []
        let contents: [URL] = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        for content in contents where try content.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
            guard let instance: MinecraftInstance = try? MinecraftInstance.load(from: content) else {
                continue
            }
            let model: Instance = .init(
                id: instance.name,
                version: instance.version
            )
            instances.append(model)
        }
        self.instances = instances
        return instances
    }
    
    /// 异步加载该仓库中的所有实例。
    @discardableResult
    public func loadAsync() async throws -> [Instance] {
        try createDirectories()
        var instances: [Instance] = []
        let contents: [URL] = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        for content in contents where try content.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
            guard let instance: MinecraftInstance = try? MinecraftInstance.load(from: content) else {
                continue
            }
            let model: Instance = .init(
                id: instance.name,
                version: instance.version
            )
            instances.append(model)
        }
        let loadedInstances: [Instance] = instances
        await MainActor.run {
            self.instances = loadedInstances
        }
        return loadedInstances
    }
    
    /// 从仓库中加载实例。
    /// - Parameter id: 实例的 ID。
    /// - Returns: 实例对象。
    public func instance(id: String, version: MinecraftVersion? = nil) throws -> MinecraftInstance {
        return try .load(from: versionsURL.appending(path: id), version: version)
    }
    
    /// 将 `MinecraftRepository.Instance` 模型加载成 `MinecraftInstance` 对象。
    /// - Parameter instance: `Instance` 实例。
    /// - Returns: `MinecraftInstance` 对象。
    public func instance(_ instance: Instance) throws -> MinecraftInstance {
        return try self.instance(id: instance.id, version: instance.version)
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
        self.instances = try container.decode([Instance].self, forKey: .instances)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.instances, forKey: .instances)
    }
    
    public struct Instance: Codable, Hashable, Identifiable {
        public let id: String
        public let version: MinecraftVersion
    }
}
